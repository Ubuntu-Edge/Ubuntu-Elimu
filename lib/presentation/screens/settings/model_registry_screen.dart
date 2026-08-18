import 'package:flutter/material.dart';
import 'package:denizen_ai/denizen_ai.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:provider/provider.dart';
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

  Future<void> _downloadAndLoadModel(OfflineModel model) async {
    setState(() {
      _downloadingModelId = model.id;
      _downloadProgress = 0.0;
      _statusText = 'Preparing download for ${model.name}...';
    });

    try {
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

      if (mounted) {
        setState(() {
          _downloadingModelId = null;
          _statusText = '✅ ${model.name} loaded into neural memory!';
        });

        // Sync provider so other screens know
        final provider = Provider.of<OfflineModelProvider>(context, listen: false);
        await provider.initialize();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ ${model.name} successfully activated for on-device AI!'),
            backgroundColor: UEColors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _downloadingModelId = null;
          _statusText = 'Download error: $e';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Download failed: $e'),
            backgroundColor: UEColors.pdfFg,
          ),
        );
      }
    }
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
                    'Download any GGUF model below. Once downloaded, it runs 100% locally on your phone without internet.',
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
                    '${model.author} · ${model.quantization ?? "Q4_K_M"}',
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
                    SizedBox(
                      width: double.infinity,
                      height: 38,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: UEColors.accent,
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
                            : const Icon(TablerIcons.download, size: 16),
                        label: Text(
                          isDownloadingThis ? 'DOWNLOADING & LOADING...' : 'DOWNLOAD & LOAD ENGINE',
                          style: UETypography.inter(fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                        onPressed: _downloadingModelId != null ? null : () => _downloadAndLoadModel(model),
                      ),
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
