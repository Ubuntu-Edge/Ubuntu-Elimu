class OfflineContextParams {
  final double temperature;
  final double topP;
  final int topK;
  final int maxTokens;
  final int contextWindow;
  final String? systemPrompt;

  const OfflineContextParams({
    this.temperature = 0.7,
    this.topP = 0.95,
    this.topK = 40,
    this.maxTokens = 512,
    this.contextWindow = 4096,
    this.systemPrompt,
  });

  OfflineContextParams copyWith({
    double? temperature,
    double? topP,
    int? topK,
    int? maxTokens,
    int? contextWindow,
    String? systemPrompt,
  }) {
    return OfflineContextParams(
      temperature: temperature ?? this.temperature,
      topP: topP ?? this.topP,
      topK: topK ?? this.topK,
      maxTokens: maxTokens ?? this.maxTokens,
      contextWindow: contextWindow ?? this.contextWindow,
      systemPrompt: systemPrompt ?? this.systemPrompt,
    );
  }
}
