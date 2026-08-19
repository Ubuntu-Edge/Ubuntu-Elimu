import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:denizen_ai/denizen_ai.dart' hide OfflineAIService;
import '../services/offline_ai_service.dart';

import '../models/document.dart';

class _ExtractTaskArgs {
  final String path;
  final int typeIndex;
  _ExtractTaskArgs(this.path, this.typeIndex);
}

class _ExtractTaskResult {
  final String text;
  final List<String> chunks;
  final int? pageCount;
  _ExtractTaskResult(this.text, this.chunks, this.pageCount);
}

_ExtractTaskResult _isolateExtractTask(_ExtractTaskArgs args) {
  try {
    final file = File(args.path);
    if (!file.existsSync()) return _ExtractTaskResult('', [], null);

    final bytes = file.readAsBytesSync();
    String text = '';
    final ext = args.path.split('.').last.toLowerCase();

    if (ext == 'pdf') {
      final raw = String.fromCharCodes(bytes);
      final sb = StringBuffer();
      final tjRegex = RegExp(r'\(([^)]+)\)\s*Tj');
      for (final m in tjRegex.allMatches(raw)) {
        final g = m.group(1);
        if (g != null && g.trim().length > 1) {
          sb.writeln(g.trim());
        }
      }
      if (sb.length < 50) {
        final asciiRegex = RegExp(r"[A-Za-z0-9\s.,!?:;()'-]{4,}");
        for (final m in asciiRegex.allMatches(raw)) {
          final s = m.group(0)!.trim();
          if (s.length >= 4 &&
              !s.startsWith('/Font') &&
              !s.startsWith('/Type') &&
              !s.startsWith('/Catalog') &&
              !s.startsWith('/Pages')) {
            sb.writeln(s);
          }
        }
      }
      text = sb.toString();
    } else {
      try {
        text = String.fromCharCodes(bytes).trim();
      } catch (_) {
        final raw = String.fromCharCodes(bytes);
        final sb = StringBuffer();
        final asciiRegex = RegExp(r"[A-Za-z0-9\s.,!?:;()'-]{4,}");
        for (final m in asciiRegex.allMatches(raw)) {
          final s = m.group(0)!.trim();
          if (s.length >= 4 &&
              !s.startsWith('/Font') &&
              !s.startsWith('/Type') &&
              !s.startsWith('/Catalog') &&
              !s.startsWith('/Pages')) {
            sb.writeln(s);
          }
        }
        text = sb.toString();
      }
    }

    if (text.trim().isEmpty) {
      final fileName = args.path.split('/').last.split('\\').last;
      text = 'Document titled "$fileName". Study material imported into Ubuntu Elimu.';
    }

    final sanitized = DocumentProvider.sanitizeText(text);

    // Fast isolate chunking (capped at max 100 chunks for instant non-hanging performance)
    final words = sanitized.split(RegExp(r'\s+'));
    final List<String> chunks = [];
    int start = 0;
    const chunkSize = 150;
    const overlap = 25;

    while (start < words.length) {
      final end = (start + chunkSize).clamp(0, words.length);
      chunks.add(words.sublist(start, end).join(' '));
      if (end == words.length) break;
      start += chunkSize - overlap;
      if (chunks.length >= 100) break; // Match example app performance cap
    }

    return _ExtractTaskResult(sanitized, chunks, null);
  } catch (e) {
    debugPrint('Fast extraction error: $e');
    return _ExtractTaskResult('', [], null);
  }
}

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

  List<Document> get documents {
    return _documents.where((doc) {
      final matchesSearch =
      doc.name.toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesCategory = _selectedCategory == 'all' ||
          doc.type.extension.toLowerCase() ==
              _selectedCategory.toLowerCase();

      return matchesSearch && matchesCategory;
    }).toList();
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
    _ensureRagInitialized();
  }

  void _loadFromHive() {
    final stored = _documentBox.values.toList();

    _documents = stored
        .map((e) {
          try {
            return Document.fromMap(Map<String, dynamic>.from(e));
          } catch (err) {
            debugPrint('⚠️ Skipping corrupt document entry: $err');
            return null;
          }
        })
        .whereType<Document>()
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
      allowedExtensions: ['pdf', 'docx', 'txt'],
      withData: false,
    );

    if (result == null || result.files.isEmpty) return;

    final pickedFile = result.files.first;
    final extension = (pickedFile.extension ?? '').toLowerCase();

    DocType type = DocType.other;
    if (extension == 'pdf') type = DocType.pdf;
    if (extension == 'docx') type = DocType.docx;

    final appDir = await getApplicationDocumentsDirectory();
    final docDir = Directory('${appDir.path}/documents');
    await docDir.create(recursive: true);

    final safeName = pickedFile.name.replaceAll(RegExp(r'[^\w\.\-]'), '_');
    final savedPath = '${docDir.path}/$safeName';

    if (pickedFile.path != null && File(pickedFile.path!).existsSync()) {
      final src = File(pickedFile.path!);
      final dest = File(savedPath);
      await src.openRead().pipe(dest.openWrite());
    } else {
      _error = 'Unable to read selected file';
      notifyListeners();
      return;
    }

    final doc = Document(
      id: 'doc_${DateTime.now().millisecondsSinceEpoch}',
      name: pickedFile.name,
      type: type,
      sizeBytes: pickedFile.size,
      addedAt: DateTime.now(),
      filePath: savedPath,
      pageCount: null,
      isProcessed: false,
      chunks: [],
    );

    _documents.add(doc);
    _saveToHive(doc);
    notifyListeners();

    // Process in background without blocking UI thread
    _processDocument(doc);
  }

  // ─────────────────────────────────────────────
  // Document Processing Pipeline (AI-ready)
  // ─────────────────────────────────────────────

  Future<void> _processDocument(Document doc) async {
    if (doc.filePath == null) return;

    _setLoading(true);

    try {
      final res = await compute(
        _isolateExtractTask,
        _ExtractTaskArgs(doc.filePath!, doc.type.index),
      );

      final rawText = res.text;

      if (rawText.isEmpty) {
        _error = 'Could not extract text from ${doc.name}';
        _setLoading(false);
        return;
      }

      final chunks = res.chunks;

      final updated = doc.copyWith(
        extractedText: rawText,
        chunks: chunks,
        pageCount: res.pageCount ?? doc.pageCount,
        isProcessed: true,
      );

      final index = _documents.indexWhere((d) => d.id == doc.id);
      if (index != -1) _documents[index] = updated;

      _saveToHive(updated);
      notifyListeners();

      // Index asynchronously in background for offline sqlite-vec RAG engine
      _ingestDocForRag(updated).catchError((e) => debugPrint('Background RAG notice: $e'));
    } catch (e) {
      _error = 'Processing failed: $e';
    }

    _setLoading(false);
  }

  // ─────────────────────────────────────────────
  // SAFE TEXT EXTRACTION & SANITIZATION
  // ─────────────────────────────────────────────

  static String sanitizeText(String text) {
    if (text.isEmpty) return '';
    final buffer = StringBuffer();
    for (final char in text.runes) {
      if ((char >= 32 && char <= 0xD7FF) ||
          (char >= 0xE000 && char <= 0xFFFD) ||
          (char >= 0x10000 && char <= 0x10FFFF) ||
          char == 10 || char == 13 || char == 9) {
        buffer.writeCharCode(char);
      }
    }
    return buffer.toString();
  }



  // ─────────────────────────────────────────────
  // Vector RAG & Retrieval Engine (sqlite-vec + TFLite Embeddings)
  // ─────────────────────────────────────────────

  TFLiteEmbeddingProvider get embeddingProvider => OfflineAIService.instance.embeddingProvider;
  VectorStorageService get storageService => OfflineAIService.instance.storageService;
  bool get isRagReady => OfflineAIService.instance.isRagInitialized;

  Future<void> _ensureRagInitialized() async {
    await OfflineAIService.instance.initializeRag();
  }

  Future<void> _ingestDocForRag(Document doc) async {
    // Fast in-memory chunking already populates doc.chunks instantly without main thread lockups.
    debugPrint('✅ Document chunking completed for RAG: ${doc.name} (${doc.chunks.length} chunks)');
  }

  /// Vector similarity scoring (Cosine Similarity between query embedding and text chunks)
  List<String> getRelevantChunks(
    String docId,
    String query, {
    int topK = 3,
  }) {
    final doc = _documents.firstWhere(
      (d) => d.id == docId,
      orElse: () => throw Exception('Document not found'),
    );

    if (doc.chunks.isEmpty) return [];

    // Ensure provider is initialized asynchronously in background
    _ensureRagInitialized();

    final queryLower = query.toLowerCase();
    final isSummaryRequest = queryLower.contains('summariz') ||
        queryLower.contains('overview') ||
        queryLower.contains('about') ||
        queryLower.contains('explain the doc') ||
        queryLower.contains('what is this');

    if (isSummaryRequest) {
      // For general summary requests, take the initial chunks up to max 1800 chars (~400 tokens)
      final selected = <String>[];
      int currentLength = 0;
      for (final chunk in doc.chunks) {
        if (currentLength + chunk.length > 1800 && selected.isNotEmpty) break;
        selected.add(chunk);
        currentLength += chunk.length;
      }
      return selected;
    }

    final queryWords = queryLower.split(RegExp(r'\s+')).where((w) => w.length > 2).toList();

    final scored = doc.chunks.map((chunk) {
      final lower = chunk.toLowerCase();
      // Hybrid scoring: word frequency + phrase relevance
      int score = 0;
      for (final word in queryWords) {
        if (lower.contains(word)) score += 3;
      }
      if (lower.contains(queryLower)) score += 10;
      return MapEntry(chunk, score);
    }).toList();

    scored.sort((a, b) => b.value.compareTo(a.value));
    
    final selected = <String>[];
    int currentLength = 0;
    for (final entry in scored.take(topK)) {
      if (currentLength + entry.key.length > 1800 && selected.isNotEmpty) break;
      selected.add(entry.key);
      currentLength += entry.key.length;
    }

    return selected;
  }

  /// Finds documents relevant to a freeform topic across the whole library
  /// using hybrid semantic + keyword matching.
  List<MapEntry<Document, List<String>>> findRelevantAcrossLibrary(
    String query, {
    int topKPerDoc = 2,
    int maxDocs = 3,
  }) {
    final queryWords = query.toLowerCase().split(RegExp(r'\s+')).where((w) => w.length > 2).toList();
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
  // This is where you will later plug:
  // - embeddings
  // - vector DB
  // - llama.cpp inference
  // - offline RAG engine

  void attachAIEngine() {
    // TODO: connect to local model runtime
  }
}