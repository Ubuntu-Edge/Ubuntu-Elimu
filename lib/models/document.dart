enum DocType { pdf, pptx, docx, image, other }

extension DocTypeExt on DocType {
  String get extension {
    switch (this) {
      case DocType.pdf:   return 'PDF';
      case DocType.pptx:  return 'PPTX';
      case DocType.docx:  return 'DOCX';
      case DocType.image: return 'IMG';
      case DocType.other: return 'FILE';
    }
  }
}

class Document {
  final String id;
  final String name;
  final DocType type;
  final int sizeBytes;
  final DateTime addedAt;
  final int? pageCount;
  final int? flashcardCount;

  const Document({
    required this.id,
    required this.name,
    required this.type,
    required this.sizeBytes,
    required this.addedAt,
    this.pageCount,
    this.flashcardCount,
  });

  String get sizeLabel {
    if (sizeBytes < 1024 * 1024) {
      return '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}