import 'package:flutter/material.dart';
import 'package:denizen_ai/denizen_ai.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:provider/provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../providers/offline_model_provider.dart';

class ModelRegistryScreen extends StatefulWidget {
  const ModelRegistryScreen({super.key});

  @override
  State<ModelRegistryScreen> createState() => _ModelRegistryScreenState();
}

class _ModelRegistryScreenState extends State<ModelRegistryScreen> {
  final DenizenAI _denizen = DenizenAI();
  final List<OfflineModel> _availableModels = DefaultOfflineModels.getMedicalModels();

  String? _downloadingModelId;
  double _downloadProgress = 0.0;
  String _statusText = '';
  final Set<String> _downloadedModelIds = {};
  int _availableRamMB = -1;

  @override
  void initState() {
    super.initState();
    _checkDownloadedModels();
    _loadRamInfo();
  }

  Future<void> _loadRamInfo() async {
    try {
      if (Platform.isAndroid) {
        final memInfo = await File('/proc/meminfo').readAsString();
        final match = RegExp(r'MemAvailable:\s+(\d+)').firstMatch(memInfo);
        if (match != null && mounted) {
          setState(() => _availableRamMB = int.parse(match.group(1)!) ~/ 1024);
        }
      }
    } catch (_) {}
  }

  Future<void> _checkDownloadedModels() async {
    final Set<String> downloaded = {};
    for (final model in _availableModels) {
      try {
        if (await _denizen.models.isDownloaded(model.id)) {
          downloaded.add(model.id);
        }
      } catch (_) {}
    }
    if (mounted) {
      setState(() {
        _downloadedModelIds.clear();
        _downloadedModelIds.addAll(downloaded);
      });
    }
  }

  Future<void> _downloadAndLoadModel(OfflineModel model) async {
    setState(() {
      _downloadingModelId = model.id;
      _downloadProgress = 0.0;
      _statusText = 'Preparing model for ${model.name}...';
    });

    try {
      if (Platform.isAndroid && await Permission.notification.isDenied) {
        await Permission.notification.request();
      }
      await WakelockPlus.enable();

      if (_denizen.isModelLoaded) {
        await _denizen.engine.unloadModel();
      }

      await _denizen.models.load(
        model.id,
        onProgress: (progress) {
          if (mounted) {
            setState(() {
              _downloadProgress = progress.progress.clamp(0.0, 1.0);
              _statusText =
                  'Downloading: ${(progress.bytesDownloaded / (1024 * 1024)).toStringAsFixed(1)} MB / ${(progress.totalBytes / (1024 * 1024)).toStringAsFixed(1)} MB (${progress.percent.toStringAsFixed(1)}%)';
            });
          }
        },
      );

      await _checkDownloadedModels();

      if (mounted) {
        setState(() {
          _downloadingModelId = null;
          _statusText = '✅ ${model.name} loaded into neural memory!';
        });

        final provider = Provider.of<OfflineModelProvider>(context, listen: false);
        await provider.initialize();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ ${model.name} successfully activated for live on-device AI!'),
            backgroundColor: UEColors.green,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      await _checkDownloadedModels();
      if (mounted) {
        setState(() {
          _downloadingModelId = null;
          _statusText = 'Error: $e';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Model action failed: $e'),
            backgroundColor: UEColors.pdfFg,
          ),
        );
      }
    } finally {
      try {
        await WakelockPlus.disable();
      } catch (_) {}
    }
  }

  Widget _buildRamBar(int availableMB) {
    final hasRamReading = availableMB > 0;
    final color = !hasRamReading
        ? UEColors.accent
        : availableMB >= 700
            ? UEColors.green
            : availableMB >= 400
                ? const Color(0xFFE6A817)
                : UEColors.pdfFg;
    final text = hasRamReading
        ? 'Free device memory: ${availableMB} MB (${availableMB >= 700 ? "Good" : availableMB >= 400 ? "Low" : "Critical"})'
        : 'Engine Memory: Auto-Managed by On-Device AI Runtime';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        border: Border.all(color: color.withOpacity(0.3), width: 0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(TablerIcons.cpu, size: 14, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: UETypography.inter(fontSize: 11, color: color, fontWeight: FontWeight.w600),
            ),
          ),
          GestureDetector(
            onTap: _loadRamInfo,
            child: Icon(TablerIcons.refresh, size: 13, color: color),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loadedModelId = _denizen.engine.loadedModel?.id;

    return Scaffold(
      backgroundColor: UEColors.bg,
      appBar: AppBar(
        backgroundColor: UEColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(TablerIcons.chevron_left, color: UEColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Model Registry',
          style: UETypography.spaceGrotesk(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: UEColors.textPrimary,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildRamBar(_availableRamMB),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: UEColors.accent.withOpacity(0.08),
              border: Border.all(color: UEColors.accent.withOpacity(0.3), width: 0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(TablerIcons.info_circle, color: UEColors.accent, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Select any compact GGUF neural model below to activate 100% offline AI inference on your device.',
                    style: UETypography.inter(fontSize: 12, color: UEColors.textPrimary, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (_statusText.isNotEmpty) ...[
            Text(
              _statusText,
              style: UETypography.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _downloadingModelId != null ? UEColors.accent : UEColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            if (_downloadingModelId != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: _downloadProgress > 0 ? _downloadProgress : null,
                  backgroundColor: UEColors.iconBg,
                  color: UEColors.accent,
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: 16),
            ],
          ],
          Text(
            'AVAILABLE OFFLINE MODELS',
            style: UETypography.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: UEColors.textMuted,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 12),
          ..._availableModels.map((model) {
            final isCurrentlyLoaded = loadedModelId == model.id;
            final isDownloadingThis = _downloadingModelId == model.id;
            final isDownloadedOnDisk = _downloadedModelIds.contains(model.id);
            final requiredRamMB = (model.sizeMB * 2.5).ceil();

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: UEColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isCurrentlyLoaded ? UEColors.green.withOpacity(0.6) : UEColors.border,
                  width: isCurrentlyLoaded ? 1.5 : 0.5,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        isCurrentlyLoaded ? TablerIcons.circle_check : TablerIcons.cpu,
                        color: isCurrentlyLoaded ? UEColors.green : UEColors.accent,
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          model.name,
                          style: UETypography.spaceGrotesk(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: UEColors.textPrimary,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: UEColors.iconBg,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${model.sizeMB.toStringAsFixed(0)} MB',
                          style: UETypography.inter(fontSize: 11, fontWeight: FontWeight.w600, color: UEColors.textMuted),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${model.author} · ${model.quantization ?? "Q4_K_M"} · needs ~${requiredRamMB} MB RAM',
                    style: UETypography.inter(fontSize: 11, color: UEColors.textMuted),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    model.description ?? 'Optimized compact model for edge inference.',
                    style: UETypography.inter(fontSize: 12, color: UEColors.textSecondary, height: 1.4),
                  ),
                  const SizedBox(height: 14),
                  if (isCurrentlyLoaded) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: UEColors.greenBg,
                        border: Border.all(color: UEColors.greenBorder, width: 0.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(TablerIcons.check, size: 16, color: UEColors.green),
                          const SizedBox(width: 6),
                          Text(
                            'ACTIVE ENGINE MODEL',
                            style: UETypography.inter(
                              color: UEColors.green,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 38,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isDownloadedOnDisk ? const Color(0xFF059669) : UEColors.accent,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                elevation: 0,
                              ),
                              icon: isDownloadingThis
                                  ? const SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                    )
                                  : Icon(isDownloadedOnDisk ? TablerIcons.player_play : TablerIcons.download, size: 16),
                              label: Text(
                                isDownloadingThis
                                    ? 'LOADING MODEL...'
                                    : isDownloadedOnDisk
                                        ? 'LOAD INTO ENGINE'
                                        : 'DOWNLOAD & LOAD ENGINE',
                                style: UETypography.inter(fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                              onPressed: _downloadingModelId != null ? null : () => _downloadAndLoadModel(model),
                            ),
                          ),
                        ),
                        if (isDownloadedOnDisk) ...[
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () async {
                              await _denizen.models.deleteModel(model.id);
                              await _checkDownloadedModels();
                              if (context.mounted) {
                                final provider = Provider.of<OfflineModelProvider>(context, listen: false);
                                await provider.initialize();
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                              decoration: BoxDecoration(
                                border: Border.all(color: UEColors.pdfFg, width: 0.5),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Delete',
                                style: UETypography.inter(fontSize: 11, color: UEColors.pdfFg, fontWeight: FontWeight.w500),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
