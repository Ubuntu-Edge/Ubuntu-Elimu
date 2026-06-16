import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_pdftext/flutter_pdftext.dart';
import 'package:docx_to_text/docx_to_text.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/document.dart';

class DocumentProvider with ChangeNotifier {
  List<Document> _documents = [];
  String _searchQuery = '';
  String _selectedCategory = 'all';
  bool _isLoading = false;
  String? _error;

  late Box _documentBox;

  // ─── Getters ───────────────────────────────────────────────

  bool get isLoading => _isLoading;
  String? get error => _error;
  String get searchQuery => _searchQuery;
  String get selectedCategory => _selectedCategory;

  List<Document> get documents {
    return _documents.where((doc) {
      final matchesSearch =
      doc.name.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesCategory = _selectedCategory == 'all' ||
          doc.type.extension.toLowerCase() == _selectedCategory.toLowerCase();
      return matchesSearch && matchesCategory;
    }).toList();
  }

  List<Document> get recentUploads {
    final sorted = List<Document>.from(_documents);
    sorted.sort((a, b) => b.addedAt.compareTo(a.addedAt));
    return sorted.take(3).toList();
  }

  // ─── Init — load persisted documents from Hive ─────────────

  Future<void> init() async {
    _documentBox = await Hive.openBox('documents');
    _loadFromHive();
  }

  void _loadFromHive() {
    final stored = _documentBox.values.toList();
    _documents = stored.map((e) => Document.fromMap(Map<String, dynamic>.from(e))).toList();
    notifyListeners();
  }

  // ─── Pick and Upload a Real File ───────────────────────────

  Future<void> pickAndUploadDocument() async {
    _error = null;

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'docx'],
      withData: false,
      withReadStream: false,
    );

    if (result == null || result.files.isEmpty) return;

    final pickedFile = result.files.first;
    if (pickedFile.path == null) return;

    final sourceFile = File(pickedFile.path!);
    final extension = pickedFile.extension?.toLowerCase() ?? '';

    // Determine type
    DocType? type;
    if (extension == 'pdf') type = DocType.pdf;
    if (extension == 'docx') type = DocType.docx;
    if (type == null) {
      _error = 'Unsupported file type';
      notifyListeners();
      return;
    }

    // Copy file to app storage so it persists
    final appDir = await getApplicationDocumentsDirectory();
    final savedPath = '${appDir.path}/${pickedFile.name}';
    await sourceFile.copy(savedPath);

    // Create document entry
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

    // Extract text in background
    await _extractAndChunk(doc);
  }

  // ─── Text Extraction ────────────────────────────────────────

  Future<void> _extractAndChunk(Document doc) async {
    if (doc.filePath == null) return;

    _setLoading(true);

    try {
      String rawText = '';

      if (doc.type == DocType.pdf) {
        rawText = await _extractPdf(doc.filePath!);
      } else if (doc.type == DocType.docx) {
        rawText = await _extractDocx(doc.filePath!);
      }

      if (rawText.isEmpty) {
        _error = 'Could not extract text from ${doc.name}';
        _setLoading(false);
        return;
      }

      final chunks = _chunkText(rawText);

      // Update the document with extracted data
      final updated = doc.copyWith(
        extractedText: rawText,
        chunks: chunks,
        isProcessed: true,
      );

      final index = _documents.indexWhere((d) => d.id == doc.id);
      if (index != -1) _documents[index] = updated;

      _saveToHive(updated);
    } catch (e) {
      _error = 'Extraction failed: $e';
    }

    _setLoading(false);
  }

  Future<String> _extractPdf(String path) async {
    try {
      final text = await FlutterPdfText.getPDFtext(path);
      return text.trim();
    } catch (e) {
      return '';
    }
  }

  Future<String> _extractDocx(String path) async {
    try {
      final bytes = await File(path).readAsBytes();
      final text = docxToText(bytes);
      return text.trim();
    } catch (e) {
      return '';
    }
  }

  // ─── Chunking ───────────────────────────────────────────────
  // Splits text into ~500 word segments with 50 word overlap
  // Overlap ensures context is not lost at chunk boundaries

  List<String> _chunkText(String text, {int chunkSize = 500, int overlap = 50}) {
    final words = text.split(RegExp(r'\s+'));
    final chunks = <String>[];

    int start = 0;
    while (start < words.length) {
      final end = (start + chunkSize).clamp(0, words.length);
      chunks.add(words.sublist(start, end).join(' '));
      if (end == words.length) break;
      start += chunkSize - overlap; // slide with overlap
    }

    return chunks;
  }

  // ─── Retrieval — find most relevant chunks for a query ──────
  // Simple keyword match for now — good enough for offline RAG

  List<String> getRelevantChunks(String docId, String query, {int topK = 3}) {
    final doc = _documents.firstWhere(
          (d) => d.id == docId,
      orElse: () => throw Exception('Document not found'),
    );

    if (doc.chunks.isEmpty) return [];

    final queryWords = query.toLowerCase().split(RegExp(r'\s+'));

    // Score each chunk by how many query words it contains
    final scored = doc.chunks.map((chunk) {
      final lower = chunk.toLowerCase();
      final score = queryWords.where((w) => lower.contains(w)).length;
      return MapEntry(chunk, score);
    }).toList();

    scored.sort((a, b) => b.value.compareTo(a.value));

    return scored.take(topK).map((e) => e.key).toList();
  }

  // ─── Persistence ────────────────────────────────────────────

  void _saveToHive(Document doc) {
    _documentBox.put(doc.id, doc.toMap());
  }

  void removeDocument(String id) {
    _documents.removeWhere((doc) => doc.id == id);
    _documentBox.delete(id);
    notifyListeners();
  }

  // ─── Filters ────────────────────────────────────────────────

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
}