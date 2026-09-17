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
import 'widgets/custom_model_picker_dialog.dart';

class ModelRegistryScreen extends StatefulWidget {
  const ModelRegistryScreen({super.key});

  @override
  State<ModelRegistryScreen> createState() => _ModelRegistryScreenState();
}

class _ModelRegistryScreenState extends State<ModelRegistryScreen> {
  final DenizenAI _denizen = DenizenAI();
  final List<OfflineModel> _availableModels = [
    DefaultOfflineModels.getUltraLightVisionModel(),
    ...DefaultOfflineModels.getEducationModels(),
    DefaultOfflineModels.getInspectionVisionModel(),
  ];

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
    final provider = Provider.of<OfflineModelProvider>(context, listen: false);

    try {
      if (Platform.isAndroid && await Permission.notification.isDenied) {
        await Permission.notification.request();
      }

      // Delegate entirely to the provider — it manages all state
      await provider.setActiveModel(model);

      if (!mounted) return;
      await _checkDownloadedModels();
      if (!mounted) return;

      if (provider.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Model action failed: ${provider.error}'),
            backgroundColor: UEColors.pdfFg,
          ),
        );
      } else {
        _showSuccessDialog(model);
      }
    } catch (e) {
      await _checkDownloadedModels();
      if (mounted) {
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

  void _showSuccessDialog(OfflineModel model) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
        decoration: const BoxDecoration(
          color: UEColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: UEColors.greenBg,
                shape: BoxShape.circle,
                border: Border.all(color: UEColors.green.withValues(alpha: 0.4), width: 2),
              ),
              child: const Icon(TablerIcons.circle_check_filled, color: UEColors.green, size: 36),
            ),
            const SizedBox(height: 16),
            Text(
              'Model Ready!',
              style: UETypography.spaceGrotesk(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: UEColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${model.name} has been downloaded and loaded into the on-device AI engine.',
              textAlign: TextAlign.center,
              style: UETypography.inter(
                fontSize: 13,
                color: UEColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${model.sizeMB.toStringAsFixed(0)} MB · ${model.quantization ?? "Q4_K_M"} · ${model.author}',
              style: UETypography.inter(
                fontSize: 11,
                color: UEColors.textMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: UEColors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pop(context); // Go back to the previous screen
                },
                child: Text(
                  'Start Using AI',
                  style: UETypography.inter(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
        ? 'Free device memory: $availableMB MB (${availableMB >= 700 ? "Good" : availableMB >= 400 ? "Low" : "Critical"})'
        : 'Engine Memory: Auto-Managed by On-Device AI Runtime';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 0.5),
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
    final modelProvider = context.watch<OfflineModelProvider>();
    final loadedModelId = _denizen.engine.loadedModel?.id;
    final downloadingModelId = modelProvider.downloadingModelId;
    final statusText = modelProvider.downloadStatusText;
    final downloadProgress = modelProvider.downloadProgressFraction;

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
        actions: [
          IconButton(
            tooltip: 'Load Custom GGUF',
            icon: const Icon(TablerIcons.file_import, color: UEColors.accent),
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => CustomModelPickerDialog(
                  onModelSelected: _checkDownloadedModels,
                ),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildRamBar(_availableRamMB),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: UEColors.accent.withValues(alpha: 0.08),
              border: Border.all(color: UEColors.accent.withValues(alpha: 0.3), width: 0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(TablerIcons.info_circle, color: UEColors.accent, size: 24),
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
          if (statusText.isNotEmpty) ...[
            Text(
              statusText,
              style: UETypography.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: downloadingModelId != null ? UEColors.accent : UEColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            if (downloadingModelId != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: downloadProgress > 0 ? downloadProgress : null,
                  backgroundColor: UEColors.iconBg,
                  color: UEColors.accent,
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: 16),
            ],
          ],
          OutlinedButton.icon(
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => CustomModelPickerDialog(
                  onModelSelected: _checkDownloadedModels,
                ),
              );
            },
            icon: const Icon(TablerIcons.folder_open, size: 16, color: UEColors.accent),
            label: Text(
              'Load Custom GGUF from Device Storage',
              style: UETypography.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: UEColors.accent,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: UEColors.border),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 16),
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
            final isDownloadingThis = downloadingModelId == model.id;
            final isDownloadedOnDisk = _downloadedModelIds.contains(model.id);
            final requiredRamMB = (model.sizeMB * 2.5).ceil();

            final String categoryBadge = model.isVision
                ? '👁️ MULTIMODAL VISION'
                : model.id.contains('0.5b')
                    ? '⚡ ULTRA-LIGHTWEIGHT'
                    : model.id.contains('gemma') || model.id.contains('1b') || model.id.contains('1.5b')
                        ? '🎯 RAG & REASONING'
                        : '🧠 HIGH-END EDGE';

            final Color badgeColor = model.isVision
                ? UEColors.indigo
                : model.id.contains('0.5b')
                    ? UEColors.accent
                    : model.id.contains('gemma') || model.id.contains('1b') || model.id.contains('1.5b')
                        ? const Color(0xFF059669)
                        : const Color(0xFF8B5CF6);

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: UEColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isCurrentlyLoaded ? UEColors.green.withValues(alpha: 0.6) : UEColors.border,
                  width: isCurrentlyLoaded ? 1.5 : 0.5,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: badgeColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: badgeColor.withValues(alpha: 0.4), width: 0.5),
                        ),
                        child: Text(
                          categoryBadge,
                          style: UETypography.inter(fontSize: 9, fontWeight: FontWeight.w700, color: badgeColor),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
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
                    '${model.author} · ${model.quantization ?? "Q4_K_M"} · needs ~$requiredRamMB MB RAM',
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
                          const Icon(TablerIcons.check, size: 16, color: UEColors.green),
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
                              onPressed: downloadingModelId != null ? null : () => _downloadAndLoadModel(model),
                            ),
                          ),
                        ),
                        if (isDownloadedOnDisk) ...[
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () async {
                              final provider = Provider.of<OfflineModelProvider>(context, listen: false);
                              await provider.deleteModel(model);
                              await _checkDownloadedModels();
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
