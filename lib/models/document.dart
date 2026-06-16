import 'package:flutter/material.dart';

class Document {
  final String id;
  final String name;
  final String fileType; // pdf, pptx, docx, etc.
  final int sizeBytes;
  final DateTime uploadTime;
  final String tag;
  final Color tagColor;

  Document({
    required this.id,
    required this.name,
    required this.fileType,
    required this.sizeBytes,
    required this.uploadTime,
    required this.tag,
    required this.tagColor,
  });
}
