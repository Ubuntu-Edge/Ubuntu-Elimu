import 'dart:async';
import 'dart:isolate';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:archive/archive.dart';
import 'package:xml/xml.dart';

import '../models/document.dart';

/// Isolated background task for document processing
/// This prevents OOM crashes on the main UI thread
class DocumentProcessingIsolate {
  static Future<String> extractTextInIsolate(
      String filePath, DocType type) async {
    final receivePort = ReceivePort();

    try {
      await Isolate.spawn(
        _extractTextEntryPoint,
        receivePort.sendPort,
        debugName: 'document_extraction_isolate',
      );

      final sendPort = await receivePort.first as SendPort;
      final responsePort = ReceivePort();

      sendPort.send({
        'path': filePath,
        'type': type.toString(),
        'responsePort': responsePort.sendPort,
      });

      // Wait for result with timeout (prevent hanging)
      final result = await responsePort.first.timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw TimeoutException('PDF extraction exceeded 30s'),
      );

      receivePort.close();
      responsePort.close();

      if (result is String) {
        return result; // Success
      } else if (result is Exception) {
        throw result;
      } else {
        throw Exception('Unknown error in isolate: $result');
      }
    } catch (e) {
      debugPrint('❌ Text extraction isolate failed: $e');
      receivePort.close();
      rethrow;
    }
  }

  /// Entry point for the isolate - must be a top-level function
  static void _extractTextEntryPoint(SendPort parentPort) {
    final port = ReceivePort();
    parentPort.send(port.sendPort);

    port.listen((dynamic message) async {
      try {
        if (message is Map<String, dynamic>) {
          final filePath = message['path'] as String;
          final typeStr = message['type'] as String;
          final responsePort = message['responsePort'] as SendPort;

          final type = typeStr == 'DocType.pdf' ? DocType.pdf : DocType.docx;
          final text = await _extractTextSync(filePath, type);

          responsePort.send(text);
        }
      } catch (e, stackTrace) {
        debugPrint('Error in isolate: $e\n$stackTrace');
        final responsePort = message?['responsePort'] as SendPort?;
        responsePort?.send(Exception('$e'));
      }
    });
  }

  /// Synchronous text extraction (runs in background isolate)
  static Future<String> _extractTextSync(String path, DocType type) async {
    try {
      if (type == DocType.pdf) {
        final bytes = await File(path).readAsBytes();

        // Create document in isolate (not on main thread)
        final document = PdfDocument(inputBytes: bytes);
        final extractor = PdfTextExtractor(document);
        final text = extractor.extractText();

        document.dispose();
        debugPrint('✅ [Isolate] Extracted PDF text (${text.length} chars)');
        return text;
      } else if (type == DocType.docx) {
        final bytes = await File(path).readAsBytes();
        final archive = ZipDecoder().decodeBytes(bytes);
        final wordFile = archive.findFile('word/document.xml');

        if (wordFile == null) return '';

        final xmlString = utf8.decode(wordFile.content as List<int>);
        final xmlDoc = XmlDocument.parse(xmlString);
        final text = xmlDoc.descendants
            .whereType<XmlElement>()
            .where((e) => e.name.local == 't')
            .map((e) => e.innerText)
            .join(' ');

        debugPrint('✅ [Isolate] Extracted DOCX text (${text.length} chars)');
        return text;
      }

      return '';
    } catch (e) {
      debugPrint('❌ [Isolate] Text extraction failed: $e');
      rethrow;
    }
  }

  /// Text chunking in isolate (for large documents)
  static Future<List<String>> chunkTextInIsolate(
    String text, {
    int chunkSize = 500,
    int overlap = 50,
  }) async {
    final receivePort = ReceivePort();

    try {
      await Isolate.spawn(
        _chunkTextEntryPoint,
        receivePort.sendPort,
        debugName: 'text_chunking_isolate',
      );

      final sendPort = await receivePort.first as SendPort;
      final responsePort = ReceivePort();

      sendPort.send({
        'text': text,
        'chunkSize': chunkSize,
        'overlap': overlap,
        'responsePort': responsePort.sendPort,
      });

      final result = await responsePort.first.timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw TimeoutException('Text chunking exceeded 15s'),
      );

      receivePort.close();
      responsePort.close();

      if (result is List<String>) {
        return result;
      } else if (result is Exception) {
        throw result;
      }
      throw Exception('Unknown error: $result');
    } catch (e) {
      debugPrint('❌ Chunking isolate failed: $e');
      receivePort.close();
      rethrow;
    }
  }

  static void _chunkTextEntryPoint(SendPort parentPort) {
    final port = ReceivePort();
    parentPort.send(port.sendPort);

    port.listen((dynamic message) async {
      try {
        if (message is Map<String, dynamic>) {
          final text = message['text'] as String;
          final chunkSize = message['chunkSize'] as int;
          final overlap = message['overlap'] as int;
          final responsePort = message['responsePort'] as SendPort;

          final chunks = _chunkTextSync(
            text,
            chunkSize: chunkSize,
            overlap: overlap,
          );
          responsePort.send(chunks);
        }
      } catch (e) {
        final responsePort = message?['responsePort'] as SendPort?;
        responsePort?.send(Exception('$e'));
      }
    });
  }

  static List<String> _chunkTextSync(
    String text, {
    required int chunkSize,
    required int overlap,
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

    debugPrint('✅ [Isolate] Chunked text into ${chunks.length} chunks');
    return chunks;
  }
}
