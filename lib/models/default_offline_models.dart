import 'offline_model.dart';

class DefaultOfflineModels {
  static const List<OfflineModel> availableModels = [
    OfflineModel(
      id: 'phi-3-mini-lite',
      name: 'Phi-3 Mini (Lite)',
      description: 'Small, fast, and efficient. Perfect for most mobile devices.',
      downloadUrl: 'https://huggingface.co/microsoft/Phi-3-mini-4k-instruct-gguf/resolve/main/Phi-3-mini-4k-instruct-q4_k_m.gguf',
      sizeBytes: 2300000000, // ~2.3 GB
      filename: 'phi-3-mini-q4.gguf',
    ),
    OfflineModel(
      id: 'llama-3-8b-power',
      name: 'Llama-3 8B (Power)',
      description: 'Higher reasoning capabilities. Requires newer hardware.',
      downloadUrl: 'https://huggingface.co/QuantFactory/Meta-Llama-3-8B-Instruct-GGUF/resolve/main/Meta-Llama-3-8B-Instruct.Q4_K_M.gguf',
      sizeBytes: 4900000000, // ~4.9 GB
      filename: 'llama-3-8b-q4.gguf',
    ),
  ];
}
