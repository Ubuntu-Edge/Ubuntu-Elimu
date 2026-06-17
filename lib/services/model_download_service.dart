import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import '../models/offline_model.dart';

class ModelDownloadService {
  final Dio _dio = Dio();
  CancelToken? _cancelToken;

  Future<void> downloadModel({
    required OfflineModel model,
    required Function(double progress) onProgress,
    required Function(String filePath) onSuccess,
    required Function(String error) onError,
  }) async {
    try {
      final appDir = await getApplicationSupportDirectory();
      final modelsDir = Directory('${appDir.path}/models');
      
      if (!await modelsDir.exists()) {
        await modelsDir.create(recursive: true);
      }

      final savePath = '${modelsDir.path}/${model.filename}';
      _cancelToken = CancelToken();

      await _dio.download(
        model.downloadUrl,
        savePath,
        cancelToken: _cancelToken,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            onProgress(received / total);
          }
        },
      );

      onSuccess(savePath);
    } catch (e) {
      if (CancelToken.isCancel(e as DioException)) {
        onError('Download cancelled');
      } else {
        onError('Download failed: $e');
      }
    }
  }

  void cancelDownload() {
    _cancelToken?.cancel();
  }

  Future<bool> checkModelExists(String filename) async {
    final appDir = await getApplicationSupportDirectory();
    final file = File('${appDir.path}/models/$filename');
    return await file.exists();
  }

  Future<void> deleteModel(String filename) async {
    final appDir = await getApplicationSupportDirectory();
    final file = File('${appDir.path}/models/$filename');
    if (await file.exists()) {
      await file.delete();
    }
  }
}
