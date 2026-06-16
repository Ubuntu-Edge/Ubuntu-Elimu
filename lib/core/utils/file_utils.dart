import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import '../theme/colors.dart';

class FileUtils {
  static Color getIconBg(String type) {
    switch (type.toLowerCase()) {
      case 'pdf':
        return UEColors.pdfBg;
      case 'pptx':
        return UEColors.pptxBg;
      case 'docx':
        return UEColors.docxBg;
      default:
        return UEColors.iconBg;
    }
  }

  static Color getIconFg(String type) {
    switch (type.toLowerCase()) {
      case 'pdf':
        return UEColors.pdfFg;
      case 'pptx':
        return UEColors.pptxFg;
      case 'docx':
        return UEColors.docxFg;
      default:
        return UEColors.accent;
    }
  }

  static IconData getIcon(String type) {
    switch (type.toLowerCase()) {
      case 'pdf':
        return TablerIcons.file_type_pdf;
      case 'pptx':
        return TablerIcons.presentation;
      case 'docx':
        return TablerIcons.file_text;
      case 'zip':
        return TablerIcons.zip;
      case 'audio':
      case 'mp3':
        return TablerIcons.headphones;
      default:
        return TablerIcons.file;
    }
  }

  static String formatBytes(int bytes, {int decimals = 1}) {
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB", "TB"];
    double doubleBytes = bytes.toDouble();
    int suffixIndex = 0;
    while (doubleBytes >= 1024 && suffixIndex < suffixes.length - 1) {
      doubleBytes /= 1024;
      suffixIndex++;
    }
    return '${doubleBytes.toStringAsFixed(decimals)} ${suffixes[suffixIndex]}';
  }
}
