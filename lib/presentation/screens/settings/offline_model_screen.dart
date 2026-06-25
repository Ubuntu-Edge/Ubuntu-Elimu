import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../models/offline_model.dart';
import '../../../providers/offline_model_provider.dart';
import '../../../services/model_download_service.dart';

class OfflineModelScreen extends StatefulWidget {
  const OfflineModelScreen({super.key});

  @override
  State<OfflineModelScreen> createState() => _OfflineModelScreenState();
}

class _OfflineModelScreenState extends State<OfflineModelScreen> {
  int _usedStorageMB = 0;

  @override
  void initState() {
    super.initState();
    _loadStorageInfo();
  }

  Future<void> _loadStorageInfo() async {
    final used = await ModelDownloadService.instance.getModelsDirectorySize();
    if (mounted) setState(() => _usedStorageMB = (used / (1024 * 1024)).round());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: UEColors.bgPrimary,
      appBar: AppBar(
        backgroundColor: UEColors.bgPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(TablerIcons.arrow_left, color: UEColors.textMuted, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Offline Models', style: UETypography.h3),
        centerTitle: true,
      ),
      body: Consumer<OfflineModelProvider>(
        builder: (context, provider, _) {
          final models = provider.models;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildStorageBar(),
              const SizedBox(height: 20),
              Text(
                'AVAILABLE MODELS',
                style: UETypography.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: UEColors.textMuted,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 12),
              ...models.map((m) => _ModelCard(
                model: m,
                isActive: provider.activeModel?.id == m.id,
                isLoading: provider.isContextLoading &&
                    provider.activeModel?.id == m.id,
                onDownload: () => provider.startDownload(m),
                onActivate: () => provider.setActiveModel(m),
                onDelete: () => _confirmDelete(context, provider, m),
              )),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStorageBar() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: UEColors.surface,
        border: Border.all(color: UEColors.border, width: 0.5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(TablerIcons.database, color: UEColors.accent, size: 18),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Models Storage',
                  style: UETypography.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: UEColors.textPrimary)),
              const SizedBox(height: 2),
              Text('$_usedStorageMB MB used',
                  style: UETypography.inter(
                      fontSize: 11, color: UEColors.textMuted)),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, OfflineModelProvider provider, OfflineModel model) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: UEColors.surface,
        title: Text('Delete ${model.name}?',
            style: UETypography.h3),
        content: Text(
          'The model file will be removed from your device. You can re-download it anytime.',
          style: UETypography.inter(fontSize: 13, color: UEColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel',
                style: UETypography.inter(color: UEColors.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete',
                style: UETypography.inter(color: UEColors.pdfFg)),
          ),
        ],
      ),
    );
    if (confirmed == true) await provider.deleteModel(model);
  }
}

class _ModelCard extends StatelessWidget {
  final OfflineModel model;
  final bool isActive;
  final bool isLoading;
  final VoidCallback onDownload;
  final VoidCallback onActivate;
  final VoidCallback onDelete;

  const _ModelCard({
    required this.model,
    required this.isActive,
    required this.isLoading,
    required this.onDownload,
    required this.onActivate,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: UEColors.surface,
        border: Border.all(
          color: isActive ? UEColors.accent : UEColors.border,
          width: isActive ? 1 : 0.5,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(model.name,
                            style: UETypography.spaceGrotesk(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: UEColors.textPrimary)),
                        if (model.tags.contains('recommended')) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: UEColors.accent.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text('RECOMMENDED',
                                style: UETypography.inter(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
                                    color: UEColors.accent)),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(model.description,
                        style: UETypography.inter(
                            fontSize: 11, color: UEColors.textMuted)),
                  ],
                ),
              ),
              if (isActive)
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: UEColors.accent.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('ACTIVE',
                      style: UETypography.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: UEColors.accent)),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _chip('${(model.size / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB'),
              const SizedBox(width: 8),
              _chip(model.quantization),
              const SizedBox(width: 8),
              _chip('${model.contextSize ~/ 1000}k ctx'),
            ],
          ),
          const SizedBox(height: 14),
          if (model.isDownloaded && model.downloadProgress >= 1.0)
            _buildDownloadedActions()
          else if (model.downloadProgress > 0 && model.downloadProgress < 1.0)
            _buildProgressBar()
          else
            _buildDownloadButton(),
        ],
      ),
    );
  }

  Widget _chip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: UEColors.iconBg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label,
          style: UETypography.inter(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: UEColors.textSecondary)),
    );
  }

  Widget _buildDownloadButton() {
    return GestureDetector(
      onTap: onDownload,
      child: Container(
        height: 38,
        width: double.infinity,
        decoration: BoxDecoration(
          color: UEColors.accent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(TablerIcons.download, color: Colors.white, size: 16),
            const SizedBox(width: 8),
            Text('Download',
                style: UETypography.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white)),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    final pct = (model.downloadProgress * 100).toInt();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Downloading...',
                style: UETypography.inter(
                    fontSize: 11, color: UEColors.textMuted)),
            Text('$pct%',
                style: UETypography.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: UEColors.accent)),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: model.downloadProgress,
            backgroundColor: UEColors.iconBg,
            color: UEColors.accent,
            minHeight: 6,
          ),
        ),
      ],
    );
  }

  Widget _buildDownloadedActions() {
    return Row(
      children: [
        if (!isActive)
          Expanded(
            child: GestureDetector(
              onTap: isLoading ? null : onActivate,
              child: Container(
                height: 38,
                decoration: BoxDecoration(
                  color: UEColors.accent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: isLoading
                      ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2),
                  )
                      : Text('Load Model',
                      style: UETypography.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white)),
                ),
              ),
            ),
          )
        else
          Expanded(
            child: Container(
              height: 38,
              decoration: BoxDecoration(
                color: UEColors.accent.withOpacity(0.1),
                border: Border.all(color: UEColors.accent, width: 0.5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(TablerIcons.check, color: UEColors.accent, size: 14),
                  const SizedBox(width: 6),
                  Text('Loaded & Ready',
                      style: UETypography.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: UEColors.accent)),
                ],
              ),
            ),
          ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: onDelete,
          child: Container(
            height: 38,
            width: 38,
            decoration: BoxDecoration(
              color: UEColors.pdfBg,
              border: Border.all(color: UEColors.pdfFg.withOpacity(0.3)),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(TablerIcons.trash, color: UEColors.pdfFg, size: 16),
          ),
        ),
      ],
    );
  }
}