import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

/// Lightweight on-device HTTP server for serving student web projects.
/// Runs on 127.0.0.1 (localhost) and allows live in-app preview and
/// native Chrome browser launching with zero internet connection.
class LocalCodeServer {
  static final LocalCodeServer _instance = LocalCodeServer._internal();
  static LocalCodeServer get instance => _instance;
  LocalCodeServer._internal();

  HttpServer? _server;
  int _port = 8080;
  String _currentHtml = _defaultStarterHtml;
  
  final StreamController<String> _errorStreamController =
      StreamController<String>.broadcast();

  Stream<String> get errorStream => _errorStreamController.stream;
  int get port => _port;
  bool get isRunning => _server != null;
  String get serverUrl => 'http://127.0.0.1:$_port';

  /// Starts the local HTTP server.
  Future<int> start({int preferredPort = 8080}) async {
    if (_server != null) return _port;

    try {
      _server = await HttpServer.bind(
        InternetAddress.anyIPv4,
        preferredPort,
        shared: true,
      );
      _port = _server!.port;
    } catch (e) {
      // Fallback to random available port if preferred is in use
      _server = await HttpServer.bind(InternetAddress.anyIPv4, 0);
      _port = _server!.port;
    }

    _server!.listen(_handleRequest);
    debugPrint('🚀 [LocalCodeServer] Started on http://127.0.0.1:$_port');
    return _port;
  }

  /// Updates the active HTML/CSS/JS project buffer.
  void updateCode(String htmlContent) {
    _currentHtml = htmlContent;
  }

  /// Serves requests for project files and captures runtime JS errors.
  void _handleRequest(HttpRequest request) async {
    // Add CORS headers for local tablet debugging
    request.response.headers.add('Access-Control-Allow-Origin', '*');
    request.response.headers.add('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
    request.response.headers.add('Access-Control-Allow-Headers', '*');

    if (request.method == 'OPTIONS') {
      request.response.statusCode = HttpStatus.ok;
      await request.response.close();
      return;
    }

    final path = request.uri.path;

    // Endpoint for telemetry/error logging from the browser
    if (path == '/__elimu_error' && request.method == 'POST') {
      try {
        final body = await utf8.decoder.bind(request).join();
        final errorJson = jsonDecode(body);
        final errorMessage = errorJson['message'] ?? 'Unknown script error';
        final line = errorJson['line'] ?? '?';
        final col = errorJson['col'] ?? '?';
        final fullLog = 'Line $line:$col - $errorMessage';
        debugPrint('⚠️ [Browser Error Intercepted] $fullLog');
        _errorStreamController.add(fullLog);
      } catch (_) {}
      request.response.statusCode = HttpStatus.ok;
      await request.response.close();
      return;
    }

    // Default route serves the project HTML injected with error listener
    request.response.headers.contentType = ContentType.html;
    final injectedHtml = _injectErrorInterceptor(_currentHtml);
    request.response.write(injectedHtml);
    await request.response.close();
  }

  /// Injects a lightweight offline JS script to catch uncaught errors and log them.
  String _injectErrorInterceptor(String html) {
    const errorInterceptorScript = '''
<script>
  (function() {
    window.onerror = function(message, source, lineno, colno, error) {
      try {
        fetch('/__elimu_error', {
          method: 'POST',
          headers: {'Content-Type': 'application/json'},
          body: JSON.stringify({
            message: message,
            line: lineno,
            col: colno,
            stack: error ? error.stack : ''
          })
        });
      } catch(e) {}
      return false;
    };
    console.error = (function(orig) {
      return function() {
        orig.apply(console, arguments);
        try {
          var msg = Array.from(arguments).map(function(arg) {
            return typeof arg === 'object' ? JSON.stringify(arg) : arg;
          }).join(' ');
          fetch('/__elimu_error', {
            method: 'POST',
            headers: {'Content-Type': 'application/json'},
            body: JSON.stringify({ message: msg, line: 'console', col: 0 })
          });
        } catch(e) {}
      };
    })(console.error);
  })();
</script>
''';

    if (html.contains('</head>')) {
      return html.replaceFirst('</head>', '$errorInterceptorScript</head>');
    } else if (html.contains('<body>')) {
      return html.replaceFirst('<body>', '<body>$errorInterceptorScript');
    } else {
      return '$errorInterceptorScript\n$html';
    }
  }

  /// Opens the live project in native Chrome or default browser on the device.
  Future<bool> openInChrome() async {
    if (_server == null) {
      await start();
    }
    final uri = Uri.parse('http://127.0.0.1:$_port');
    try {
      return await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
    } catch (e) {
      debugPrint('❌ Failed to launch Chrome: $e');
      return false;
    }
  }

  /// Stops the local server.
  Future<void> stop() async {
    await _server?.close(force: true);
    _server = null;
    debugPrint('🛑 [LocalCodeServer] Stopped');
  }

  static const String _defaultStarterHtml = '''<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Ubuntu-Elimu CodeLab</title>
  <style>
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
      margin: 0;
      padding: 24px;
      background: linear-gradient(135deg, #0F172A 0%, #1E1B4B 100%);
      color: #F8FAFC;
      min-height: 100vh;
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
      text-align: center;
    }
    .card {
      background: rgba(255, 255, 255, 0.08);
      backdrop-filter: blur(12px);
      border: 1px solid rgba(255, 255, 255, 0.15);
      border-radius: 20px;
      padding: 32px;
      max-width: 480px;
      box-shadow: 0 20px 40px rgba(0,0,0,0.4);
    }
    h1 {
      font-size: 28px;
      margin-bottom: 12px;
      background: linear-gradient(90deg, #38BDF8, #818CF8);
      -webkit-background-clip: text;
      -webkit-text-fill-color: transparent;
    }
    p {
      color: #94A3B8;
      font-size: 15px;
      line-height: 1.6;
    }
    button {
      margin-top: 20px;
      padding: 12px 24px;
      font-size: 15px;
      font-weight: 600;
      color: white;
      background: #4F46E5;
      border: none;
      border-radius: 12px;
      cursor: pointer;
      transition: all 0.2s ease;
    }
    button:hover {
      background: #6366F1;
      transform: translateY(-2px);
    }
  </style>
</head>
<body>
  <div class="card">
    <h1>Ubuntu-Elimu CodeLab 🚀</h1>
    <p>Welcome to your on-device STEM sandbox! Edit the code on the left and tap <b>Run</b> or <b>View in Chrome</b> to see changes instantly.</p>
    <button onclick="greet()">Click to Test Interactivity</button>
    <p id="output" style="margin-top: 16px; color: #34D399; font-weight: 600;"></p>
  </div>

  <script>
    function greet() {
      document.getElementById('output').innerText = 'Karibu! Your offline code is running smoothly 🎉';
    }
  </script>
</body>
</html>''';
}
