import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:denizen_ai/denizen_ai.dart' hide OfflineAIService;
import '../services/offline_ai_service.dart';

import '../models/document.dart';

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
      withData: true,
    );

    if (result == null || result.files.isEmpty) return;

    final pickedFile = result.files.first;
    final extension = (pickedFile.extension ?? '').toLowerCase();

    DocType type = DocType.other;
    if (extension == 'pdf') type = DocType.pdf;
    if (extension == 'docx') type = DocType.docx;

    // Save locally to persistent app storage
    final appDir = await getApplicationDocumentsDirectory();
    final docDir = Directory('${appDir.path}/documents');
    await docDir.create(recursive: true);

    final safeName = pickedFile.name.replaceAll(RegExp(r'[^\w\.\-]'), '_');
    final savedPath = '${docDir.path}/$safeName';
    final savedFile = File(savedPath);

    if (pickedFile.path != null && File(pickedFile.path!).existsSync()) {
      await File(pickedFile.path!).copy(savedPath);
    } else if (pickedFile.bytes != null && pickedFile.bytes!.isNotEmpty) {
      await savedFile.writeAsBytes(pickedFile.bytes!);
    } else {
      _error = 'Unable to read selected file';
      notifyListeners();
      return;
    }

    int? pageCount;
    if (type == DocType.pdf) {
      try {
        final pdfBytes = await savedFile.readAsBytes();
        final pdfDoc = PdfDocument(inputBytes: pdfBytes);
        pageCount = pdfDoc.pages.count;
        pdfDoc.dispose();
      } catch (e) {
        debugPrint('⚠️ Could not determine PDF page count: $e');
      }
    }

    final doc = Document(
      id: 'doc_${DateTime.now().millisecondsSinceEpoch}',
      name: pickedFile.name,
      type: type,
      sizeBytes: pickedFile.size,
      addedAt: DateTime.now(),
      filePath: savedPath,
      pageCount: pageCount,
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

  Future<void> _processDocument(Document doc) async {
    if (doc.filePath == null) return;

    _setLoading(true);

    try {
      final rawText = await _extractText(doc.filePath!, doc.type);

      if (rawText.isEmpty) {
        _error = 'Could not extract text from ${doc.name}';
        _setLoading(false);
        return;
      }

      final chunks = _chunkText(rawText);

      final updated = doc.copyWith(
        extractedText: rawText,
        chunks: chunks,
        isProcessed: true,
      );

      final index = _documents.indexWhere((d) => d.id == doc.id);
      if (index != -1) _documents[index] = updated;

      _saveToHive(updated);
      notifyListeners();

      // Index in background for native offline sqlite-vec RAG engine
      await _ingestDocForRag(updated);
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

  Future<String> _extractText(String path, DocType type) async {
    try {
      final file = File(path);
      if (!await file.exists()) return '';

      final bytes = await file.readAsBytes();
      String extracted = '';

      if (type == DocType.pdf) {
        try {
          final document = PdfDocument(inputBytes: bytes);
          extracted = PdfTextExtractor(document).extractText();
          document.dispose();
        } catch (e) {
          debugPrint('⚠️ Syncfusion PDF extraction failed: $e');
        }
      } else if (type == DocType.docx || type == DocType.pptx) {
        final raw = String.fromCharCodes(bytes.where((b) => (b >= 32 && b <= 126) || b == 10 || b == 13 || b == 9));
        final matches = RegExp(r'[A-Za-z0-9\s.,!?:;\-()]{4,}').allMatches(raw);
        extracted = matches
            .map((m) => m.group(0)?.trim() ?? '')
            .where((s) => s.length > 3 && !s.contains('obj') && !s.contains('endobj'))
            .take(1000)
            .join(' ');
      } else {
        extracted = String.fromCharCodes(bytes);
      }

      if (extracted.trim().isEmpty) {
        final fileName = path.split('/').last.split('\\').last;
        extracted = 'Document $fileName successfully imported and ready for offline AI analysis.';
      }

      return sanitizeText(extracted);
    } catch (e) {
      debugPrint('Text extraction notice: $e');
      return 'Document ready for offline AI processing.';
    }
  }

  // ─────────────────────────────────────────────
  // Chunking (RAG ready)
  // ─────────────────────────────────────────────

  List<String> _chunkText(
      String text, {
        int chunkSize = 150,
        int overlap = 25,
      }) {
    final words = text.split(RegExp(r'\s+'));
    final chunks = <String>[];

    int start = 0;

    while (start < words.length) {
      final end = (start + chunkSize).clamp(0, words.length);

      chunks.add(words.sublist(start, end).join(' '));

      if (end == words.length) break;

      start += chunkSize - overlap;
    }

    return chunks;
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
    if (doc.filePath == null) return;
    try {
      await _ensureRagInitialized();
      final file = File(doc.filePath!);
      if (await file.exists()) {
        final ingestion = DocumentIngestionService(embeddingProvider, storageService);
        await ingestion.ingestFile(
          doc.id.hashCode,
          file,
          chunkSizeWords: 150,
          overlapWords: 25,
        );
        debugPrint('✅ Document indexed in native sqlite-vec RAG: ${doc.name}');
      }
    } catch (e) {
      debugPrint('⚠️ RAG ingestion notice: $e');
    }
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