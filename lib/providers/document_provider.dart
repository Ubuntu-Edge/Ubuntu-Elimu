import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/document.dart';
import '../services/document_processing_isolate.dart';
import '../services/crash_logger_service.dart';

class DocumentProvider with ChangeNotifier {
  List<Document> _documents = [];
  String _searchQuery = '';
  String _selectedCategory = 'all';
  bool _isLoading = false;
  String? _error;

  late Box _documentBox;

  // ─────────────────────────────────────────────
  // Getters
  // ─────────────────────────────────────────────

  bool get isLoading => _isLoading;
  String? get error => _error;
  String get searchQuery => _searchQuery;
  String get selectedCategory => _selectedCategory;

  /// Filtered list (search + category) — used by the Library screen.
  List<Document> get documents {
    return _documents.where((doc) {
      final matchesSearch = doc.name.toLowerCase().contains(
            _searchQuery.toLowerCase(),
          );

      final matchesCategory = _selectedCategory == 'all' ||
          doc.type.name.toLowerCase() == _selectedCategory.toLowerCase();

      return matchesSearch && matchesCategory;
    }).toList();
  }

  /// Unfiltered list — use wherever search/category state must not hide docs
  /// (e.g., the AI Tutor doc picker).
  List<Document> get allDocuments => List.unmodifiable(_documents);

  /// Looks up a document by its ID from the live (unfiltered) list.
  /// Returns null if not found.
  Document? getDocumentById(String id) {
    try {
      return _documents.firstWhere((d) => d.id == id);
    } catch (_) {
      return null;
    }
  }

  List<Document> get recentUploads {
    final sorted = List<Document>.from(_documents);
    sorted.sort((a, b) => b.addedAt.compareTo(a.addedAt));
    return sorted.take(3).toList();
  }

  // ─────────────────────────────────────────────
  // Init Hive
  // ─────────────────────────────────────────────

  Future<void> init() async {
    _documentBox = await Hive.openBox('documents');
    _loadFromHive();
  }

  void _loadFromHive() {
    final stored = _documentBox.values.toList();

    _documents = stored
        .map((e) => Document.fromMap(Map<String, dynamic>.from(e)))
        .toList();

    notifyListeners();
  }

  // ─────────────────────────────────────────────
  // Upload Document
  // ─────────────────────────────────────────────

  Future<void> pickAndUploadDocument() async {
    _error = null;

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'docx'],
      withData: false,
    );

    if (result == null || result.files.isEmpty) return;

    final pickedFile = result.files.first;
    if (pickedFile.path == null) return;

    final sourceFile = File(pickedFile.path!);
    final extension = pickedFile.extension?.toLowerCase() ?? '';

    DocType? type;
    if (extension == 'pdf') type = DocType.pdf;
    if (extension == 'docx') type = DocType.docx;

    if (type == null) {
      _error = 'Unsupported file type';
      notifyListeners();
      return;
    }

    // Save locally
    final appDir = await getApplicationDocumentsDirectory();
    final savedPath = '${appDir.path}/${pickedFile.name}';
    await sourceFile.copy(savedPath);

    final doc = Document(
      id: 'doc_${DateTime.now().millisecondsSinceEpoch}',
      name: pickedFile.name,
      type: type,
      sizeBytes: pickedFile.size,
      addedAt: DateTime.now(),
      filePath: savedPath,
      isProcessed: false,
      chunks: [],
    );

    _documents.add(doc);
    _saveToHive(doc);
    notifyListeners();

    // Process asynchronously
    await _processDocument(doc);
  }

  // ─────────────────────────────────────────────
  // Document Processing Pipeline (AI-ready)
  // ─────────────────────────────────────────────

  /// Process document in background isolate to prevent OOM
  Future<void> _processDocument(Document doc) async {
    if (doc.filePath == null) return;

    _setLoading(true);
    _error = null;

    try {
      debugPrint('🔄 Processing document: ${doc.name}');

      // Extract text in background isolate (prevents OOM on main thread)
      final rawText = await DocumentProcessingIsolate.extractTextInIsolate(
        doc.filePath!,
        doc.type,
      );

      if (rawText.isEmpty) {
        _error = 'Could not extract text from ${doc.name}';
        debugPrint('❌ Text extraction returned empty');
        notifyListeners();
        return;
      }

      debugPrint('✅ Text extracted (${rawText.length} chars)');

      // Chunk text in background isolate (prevents UI freeze)
      final chunks = await DocumentProcessingIsolate.chunkTextInIsolate(
        rawText,
        chunkSize: 500,
        overlap: 50,
      );

      debugPrint('✅ Text chunked into ${chunks.length} pieces');

      // Update document with processed content
      final updated = doc.copyWith(
        extractedText: rawText,
        chunks: chunks,
        isProcessed: true,
      );

      final index = _documents.indexWhere((d) => d.id == doc.id);
      if (index != -1) {
        _documents[index] = updated;
      }

      _saveToHive(updated);
      notifyListeners();

      debugPrint('✅ Document processing complete: ${doc.name}');
    } catch (e, stackTrace) {
      _error = 'Processing failed: $e';
      debugPrint('❌ Document processing error: $e\n$stackTrace');

      // Log crash with context
      CrashLoggerService.instance.logCrash(
        message: 'Document processing failed',
        error: e,
        stackTrace: stackTrace,
        context: {'documentName': doc.name, 'type': doc.type.toString()},
      );

      notifyListeners();
    }

    _setLoading(false);
  }

  // ─────────────────────────────────────────────
  // Retrieval (basic RAG)
  // ─────────────────────────────────────────────

  static final Map<String, String> _irregularVerbs = {
    'met': 'meet',
    'saw': 'see',
    'seen': 'see',
    'went': 'go',
    'gone': 'go',
    'came': 'come',
    'said': 'say',
    'got': 'get',
    'gotten': 'get',
    'told': 'tell',
    'thought': 'think',
    'felt': 'feel',
    'heard': 'hear',
    'knew': 'know',
    'known': 'know',
    'wrote': 'write',
    'written': 'write',
    'took': 'take',
    'taken': 'take',
    'brought': 'bring',
    'bought': 'buy',
    'lost': 'lose',
    'found': 'find',
    'gave': 'give',
    'given': 'give',
    'made': 'make',
    'held': 'hold',
    'kept': 'keep',
    'spent': 'spend',
    'stood': 'stand',
    'sat': 'sit',
    'spoken': 'speak',
    'spoke': 'speak',
    'fell': 'fall',
    'fallen': 'fall',
    'ran': 'run',
    'read': 'read',
  };

  String _stemWord(String w) {
    String word = w.toLowerCase().trim();
    if (word.isEmpty) return '';

    if (_irregularVerbs.containsKey(word)) {
      return _irregularVerbs[word]!;
    }

    if (word.endsWith('ies')) {
      return '${word.substring(0, word.length - 3)}y';
    }
    if (word.endsWith('ing')) {
      final base = word.substring(0, word.length - 3);
      if (base.length > 3 &&
          base[base.length - 1] == base[base.length - 2] &&
          !_isVowel(base[base.length - 1])) {
        return base.substring(0, base.length - 1);
      }
      return base;
    }
    if (word.endsWith('ed')) {
      return word.substring(0, word.length - 2);
    }
    if (word.endsWith('ly')) {
      return word.substring(0, word.length - 2);
    }
    if (word.endsWith('s') &&
        !word.endsWith('ss') &&
        !word.endsWith('us') &&
        !word.endsWith('is')) {
      if (word.endsWith('es')) {
        return word.substring(0, word.length - 2);
      }
      return word.substring(0, word.length - 1);
    }
    return word;
  }

  bool _isVowel(String char) {
    return const ['a', 'e', 'i', 'o', 'u'].contains(char);
  }

  List<String> getRelevantChunks(String docId, String query, {int topK = 3}) {
    final doc = _documents.firstWhere(
      (d) => d.id == docId,
      orElse: () => throw Exception('Document not found'),
    );

    if (doc.chunks.isEmpty) return [];

    final stopWords = {
      'what', 'whats', 'is', 'an', 'a', 'the', 'of', 'to', 'in', 'it', 
      'that', 'this', 'you', 'i', 'and', 'for', 'on', 'with', 'as', 
      'at', 'by', 'from', 'about', 'how', 'why', 'where', 'who', 'were', 
      'was', 'are', 'be', 'been', 'or', 'but', 'not', 'they', 'them', 
      'their', 'his', 'her', 'she', 'he', 'we', 'our', 'us', 'can', 'will', 
      'would', 'should', 'could', 'me', 'my', 'your', 'did', 'do', 'does'
    };

    final cleanQuery = query.toLowerCase().replaceAll(RegExp(r'[^\w\s]'), '');
    final words = cleanQuery.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();

    // Stem query words
    final queryStems = words
        .where((w) => !stopWords.contains(w))
        .map(_stemWord)
        .where((s) => s.isNotEmpty)
        .toList();

    // Fallback to all words if queryStems is empty
    final finalStems = queryStems.isEmpty 
        ? words.map(_stemWord).where((s) => s.isNotEmpty).toList() 
        : queryStems;

    if (finalStems.isEmpty) return doc.chunks.take(topK).toList();

    final scored = doc.chunks.map((chunk) {
      final chunkWords = chunk
          .toLowerCase()
          .replaceAll(RegExp(r'[^\w\s]'), '')
          .split(RegExp(r'\s+'))
          .where((w) => w.isNotEmpty);

      final chunkStems = chunkWords.map(_stemWord).toSet();

      int score = 0;
      for (final qStem in finalStems) {
        if (chunkStems.contains(qStem)) {
          score += 5; // Stem matched
        } else if (chunk.toLowerCase().contains(qStem)) {
          score += 2; // Substring matched
        }
      }
      return MapEntry(chunk, score);
    }).toList();

    scored.sort((a, b) => b.value.compareTo(a.value));

    // Return matched chunks (having score > 0), otherwise fallback to first chunks
    final matches = scored.where((e) => e.value > 0).map((e) => e.key).toList();
    if (matches.isNotEmpty) {
      return matches.take(topK).toList();
    }

    return doc.chunks.take(topK).toList();
  }

  /// Finds documents relevant to a freeform topic across the whole library
  /// (unlike getRelevantChunks, which is scoped to one known document id).
  /// Used by the Research report flow to ground a report in real sources.
  List<MapEntry<Document, List<String>>> findRelevantAcrossLibrary(
    String query, {
    int topKPerDoc = 2,
    int maxDocs = 3,
  }) {
    final stopWords = {
      'what', 'whats', 'is', 'an', 'a', 'the', 'of', 'to', 'in', 'it', 
      'that', 'this', 'you', 'i', 'and', 'for', 'on', 'with', 'as', 
      'at', 'by', 'from', 'about', 'how', 'why', 'where', 'who', 'were', 
      'was', 'are', 'be', 'been', 'or', 'but', 'not', 'they', 'them', 
      'their', 'his', 'her', 'she', 'he', 'we', 'our', 'us', 'can', 'will', 
      'would', 'should', 'could', 'me', 'my', 'your'
    };

    final cleanQuery = query.toLowerCase().replaceAll(RegExp(r'[^\w\s]'), '');
    final filteredWords = cleanQuery
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty && !stopWords.contains(w) && w.length > 2)
        .toList();

    final queryWords = filteredWords.isEmpty 
        ? cleanQuery.split(RegExp(r'\s+')).where((w) => w.length > 2).toList() 
        : filteredWords;

    final results = <MapEntry<Document, List<String>>>[];

    for (final doc in _documents) {
      if (!doc.isProcessed || doc.chunks.isEmpty) continue;
      final chunks = getRelevantChunks(doc.id, query, topK: topKPerDoc);
      final hasMatch = chunks.any((c) {
        final lower = c.toLowerCase();
        return queryWords.any((w) => lower.contains(w));
      });
      if (hasMatch) results.add(MapEntry(doc, chunks));
    }

    results.sort((a, b) => b.value.length.compareTo(a.value.length));
    return results.take(maxDocs).toList();
  }

  // ─────────────────────────────────────────────
  // Hive Persistence
  // ─────────────────────────────────────────────

  void _saveToHive(Document doc) {
    _documentBox.put(doc.id, doc.toMap());
  }

  void removeDocument(String id) {
    _documents.removeWhere((doc) => doc.id == id);
    _documentBox.delete(id);
    notifyListeners();
  }

  // ─────────────────────────────────────────────
  // UI Helpers
  // ─────────────────────────────────────────────

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setSelectedCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void _setLoading(bool val) {
    _isLoading = val;
    notifyListeners();
  }

  // ─────────────────────────────────────────────
  // FUTURE AI HOOK (IMPORTANT)
  // ─────────────────────────────────────────────

  void attachAIEngine() {
    // TODO: connect to local model runtime
  }
}
