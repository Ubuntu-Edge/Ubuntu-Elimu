import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:archive/archive.dart';
import 'package:xml/xml.dart';

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
          doc.type.name.toLowerCase() == _selectedCategory.toLowerCase();

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
    } catch (e) {
      _error = 'Processing failed: $e';
    }

    _setLoading(false);
  }

  // ─────────────────────────────────────────────
  // TEXT EXTRACTION (SYNCFUSION & XML)
  // ─────────────────────────────────────────────

  Future<String> _extractText(String path, DocType type) async {
    try {
      if (type == DocType.pdf) {
        final bytes = await File(path).readAsBytes();
        final document = PdfDocument(inputBytes: bytes);
        final extractor = PdfTextExtractor(document);
        final text = extractor.extractText();
        document.dispose();
        debugPrint('✅ Extracted ${text.length} chars from PDF');
        return text;
      }

      if (type == DocType.docx) {
        // DOCX extraction requires xml parsing inside the open zip archive
        final bytes = await File(path).readAsBytes();
        final archive = ZipDecoder().decodeBytes(bytes);
        final wordFile = archive.findFile('word/document.xml');
        if (wordFile == null) return '';

        final xmlString = utf8.decode(wordFile.content as List<int>);
        final document = XmlDocument.parse(xmlString);
        final text = document.descendants
            .whereType<XmlElement>()
            .where((e) => e.name.local == 't')
            .map((e) => e.innerText)
            .join(' ');

        debugPrint('✅ Extracted ${text.length} chars from DOCX');
        return text;
      }

      return '';
    } catch (e) {
      debugPrint('❌ Text extraction failed: $e');
      return '';
    }
  }

  // ─────────────────────────────────────────────
  // Chunking (RAG ready)
  // ─────────────────────────────────────────────

  List<String> _chunkText(
      String text, {
        int chunkSize = 500,
        int overlap = 50,
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
  // Retrieval (basic RAG)
  // ─────────────────────────────────────────────

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

    final queryWords = query.toLowerCase().split(RegExp(r'\s+'));

    final scored = doc.chunks.map((chunk) {
      final lower = chunk.toLowerCase();
      final score =
          queryWords.where((w) => lower.contains(w)).length;
      return MapEntry(chunk, score);
    }).toList();

    scored.sort((a, b) => b.value.compareTo(a.value));

    return scored.take(topK).map((e) => e.key).toList();
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