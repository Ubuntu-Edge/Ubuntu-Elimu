import 'package:flutter/material.dart';
import '../models/document.dart';
import '../core/theme/colors.dart';

class DocumentProvider with ChangeNotifier {
  final List<Document> _documents = [
    Document(
      id: 'doc_1',
      name: 'Biochem Lecture Notes — W4.pdf',
      fileType: 'pdf',
      sizeBytes: 2400000,
      uploadTime: DateTime.now(),
      tag: 'New',
      tagColor: UEColors.accent,
    ),
    Document(
      id: 'doc_2',
      name: 'Thermodynamics Slides.pptx',
      fileType: 'pptx',
      sizeBytes: 8100000,
      uploadTime: DateTime.now().subtract(const Duration(days: 1)),
      tag: '12 cards',
      tagColor: UEColors.pptxFg,
    ),
    Document(
      id: 'doc_3',
      name: 'Research Handbook — APA.docx',
      fileType: 'docx',
      sizeBytes: 1100000,
      uploadTime: DateTime.now().subtract(const Duration(days: 3)),
      tag: 'Active',
      tagColor: UEColors.docxFg,
    ),
  ];

  String _searchQuery = '';
  String _selectedCategory = 'all'; // all, pdf, pptx, docx

  List<Document> get documents {
    return _documents.where((doc) {
      final matchesSearch = doc.name.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesCategory = _selectedCategory == 'all' || doc.fileType.toLowerCase() == _selectedCategory.toLowerCase();
      return matchesSearch && matchesCategory;
    }).toList();
  }

  List<Document> get recentUploads {
    // Return newest uploads first
    final sorted = List<Document>.from(_documents);
    sorted.sort((a, b) => b.uploadTime.compareTo(a.uploadTime));
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

  void uploadDocument(String name, String type, int sizeBytes) {
    final newDoc = Document(
      id: 'doc_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      fileType: type,
      sizeBytes: sizeBytes,
      uploadTime: DateTime.now(),
      tag: 'Added',
      tagColor: UEColors.green,
    );
    _documents.add(newDoc);
    notifyListeners();
  }

  void removeDocument(String id) {
    _documents.removeWhere((doc) => doc.id == id);
    notifyListeners();
  }
}
