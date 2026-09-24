import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/typography.dart';
import '../../../../services/local_code_server.dart';

class CodeLabPreviewPane extends StatefulWidget {
  final VoidCallback onOpenInChrome;
  final VoidCallback onRefresh;
  final VoidCallback? onToggleFullscreen;
  final bool isFullscreen;

  const CodeLabPreviewPane({
    super.key,
    required this.onOpenInChrome,
    required this.onRefresh,
    this.onToggleFullscreen,
    this.isFullscreen = false,
  });

  @override
  State<CodeLabPreviewPane> createState() => CodeLabPreviewPaneState();
}

class CodeLabPreviewPaneState extends State<CodeLabPreviewPane> {
  WebViewController? _webViewController;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  Future<void> _initWebView() async {
    try {
      final server = LocalCodeServer.instance;
      final url = server.serverUrl;

      final controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(const Color(0xFF0F172A))
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageStarted: (_) => setState(() => _isLoading = true),
            onPageFinished: (_) => setState(() => _isLoading = false),
            onWebResourceError: (error) {
              setState(() {
                _isLoading = false;
                _errorMessage = error.description;
              });
            },
          ),
        );

      await controller.loadRequest(Uri.parse(url));
      setState(() {
        _webViewController = controller;
        _errorMessage = null;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  /// Reloads the WebView with the latest code from the local server
  void reload() {
    final server = LocalCodeServer.instance;
    _webViewController?.loadRequest(Uri.parse(server.serverUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: UEColors.bgPrimary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: UEColors.border, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Preview Top Bar
          _buildPreviewBar(),
          // Web View Content
          Expanded(
            child: Stack(
              children: [
                if (_webViewController != null && _errorMessage == null)
                  WebViewWidget(controller: _webViewController!)
                else if (_errorMessage != null)
                  _buildErrorState()
                else
                  const Center(
                    child: CircularProgressIndicator(color: UEColors.accent),
                  ),

                if (_isLoading && _errorMessage == null)
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: const LinearProgressIndicator(
                      color: UEColors.accent,
                      backgroundColor: Colors.transparent,
                      minHeight: 2,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: const BoxDecoration(
        color: UEColors.surface,
        border: Border(bottom: BorderSide(color: UEColors.border, width: 0.5)),
      ),
      child: Row(
        children: [
          // Browser mockup dots
          Row(
            children: [
              _circle(const Color(0xFFF87171)),
              const SizedBox(width: 6),
              _circle(const Color(0xFFFBBF24)),
              const SizedBox(width: 6),
              _circle(const Color(0xFF34D399)),
            ],
          ),
          const SizedBox(width: 14),
          // URL Bar indicator
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: UEColors.bgPrimary,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: UEColors.border, width: 0.5),
              ),
              child: Row(
                children: [
                  const Icon(TablerIcons.lock, size: 12, color: UEColors.green),
                  const SizedBox(width: 6),
                  Text(
                    'http://127.0.0.1:${LocalCodeServer.instance.port}',
                    style: UETypography.inter(
                      fontSize: 11,
                      color: UEColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Refresh Button
          IconButton(
            icon: const Icon(TablerIcons.refresh, size: 18, color: UEColors.textSecondary),
            tooltip: 'Reload Sandbox',
            onPressed: () {
              widget.onRefresh();
              reload();
            },
          ),
          // Launch Chrome button
          InkWell(
            onTap: widget.onOpenInChrome,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.4)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(TablerIcons.brand_chrome, size: 16, color: Color(0xFF38BDF8)),
                  const SizedBox(width: 6),
                  Text(
                    'Open in Chrome',
                    style: UETypography.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF38BDF8),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (widget.onToggleFullscreen != null) ...[
            const SizedBox(width: 4),
            IconButton(
              icon: Icon(
                widget.isFullscreen ? TablerIcons.minimize : TablerIcons.maximize,
                size: 18,
                color: UEColors.textSecondary,
              ),
              onPressed: widget.onToggleFullscreen,
            ),
          ],
        ],
      ),
    );
  }

  Widget _circle(Color color) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(TablerIcons.alert_triangle, size: 40, color: UEColors.pdfFg),
            const SizedBox(height: 12),
            Text(
              'Preview Loading Notice',
              style: UETypography.spaceGrotesk(fontSize: 16, fontWeight: FontWeight.w600, color: UEColors.textPrimary),
            ),
            const SizedBox(height: 6),
            Text(
              _errorMessage ?? 'Make sure the local server is running.',
              textAlign: TextAlign.center,
              style: UETypography.inter(fontSize: 12, color: UEColors.textMuted),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: UEColors.accent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                _initWebView();
              },
              icon: const Icon(TablerIcons.refresh, size: 16),
              label: const Text('Retry Preview'),
            ),
          ],
        ),
      ),
    );
  }
}
