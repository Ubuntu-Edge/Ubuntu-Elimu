import 'package:flutter/material.dart';
import '../models/document.dart';

class DocumentProvider with ChangeNotifier {
  final List<Document> _documents = [
    Document(
      id: 'doc_1',
      name: 'Biochem Lecture Notes — W4.pdf',
      type: DocType.pdf,
      sizeBytes: 2400000,
      addedAt: DateTime.now(),
      pageCount: 24,
      flashcardCount: 18,
    ),
    Document(
      id: 'doc_2',
      name: 'Thermodynamics Slides.pptx',
      type: DocType.pptx,
      sizeBytes: 8100000,
      addedAt: DateTime.now().subtract(const Duration(days: 1)),
      pageCount: 34,
      flashcardCount: 12,
    ),
    Document(
      id: 'doc_3',
      name: 'Research Handbook — APA.docx',
      type: DocType.docx,
      sizeBytes: 1100000,
      addedAt: DateTime.now().subtract(const Duration(days: 3)),
      pageCount: 88,
    ),
  ];

  String _searchQuery = '';
  String _selectedCategory = 'all'; // all, pdf, pptx, docx

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

  String get searchQuery => _searchQuery;
  String get selectedCategory => _selectedCategory;

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setSelectedCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void uploadDocument(String name, DocType type, int sizeBytes) {
    final newDoc = Document(
      id: 'doc_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      type: type,
      sizeBytes: sizeBytes,
      addedAt: DateTime.now(),
    );
    _documents.add(newDoc);
    notifyListeners();
  }

  void removeDocument(String id) {
    _documents.removeWhere((doc) => doc.id == id);
    notifyListeners();
  }
}
