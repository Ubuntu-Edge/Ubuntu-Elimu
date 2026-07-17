import 'package:flutter/material.dart';
import '../../services/ai_service.dart';

class AIServiceScreen extends StatefulWidget {
  const AIServiceScreen({super.key});

  @override
  State<AIServiceScreen> createState() => _AIServiceScreenState();
}

class _AIServiceScreenState extends State<AIServiceScreen> {
  bool _isModelLoaded = false;
  String _modelInfo = 'Checking service status...';

  @override
  void initState() {
    super.initState();
    _getServiceStatus();
  }

  Future<void> _getServiceStatus() async {
    if (!mounted) return;
    // In online mode, we can treat 'loadModel' as a health check.
    try {
      await AIService.instance.loadModel(); 
      if (!mounted) return;
      setState(() {
        _isModelLoaded = AIService.instance.isLoaded;
        _modelInfo = AIService.instance.getModelInfo();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _modelInfo = 'Error contacting AI service: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Service Status'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              margin: const EdgeInsets.only(bottom: 20),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Service Status:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(
                      _modelInfo,
                      style: TextStyle(
                        fontSize: 16,
                        color: _isModelLoaded ? Colors.green : Colors.red,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _isModelLoaded
                        ? const Text('The online AI service is ready.')
                        : const Text('Could not connect to the online AI service.'),
                  ],
                ),
              ),
            ),
            // The button that navigated to AIChatScreen without a patient has been removed
            // to resolve the build error.
          ],
        ), 
      ),
    );
  }
}
