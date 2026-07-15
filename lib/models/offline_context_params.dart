/// Parameters for initializing llama.cpp context
class OfflineContextParams {
  final int nCtx; // Context window size
  final int nThreads; // CPU threads
  final int nBatch; // Batch size
  final int nGpuLayers; // GPU acceleration layers
  final bool useMmap; // Memory mapping
  final bool useMlock; // Memory locking

  const OfflineContextParams({
    this.nCtx = 1024, // Reduced from 2048 for better mobile compatibility
    this.nThreads = 2, // Reduced from 4 for low-end devices
    this.nBatch = 256, // Reduced from 512
    this.nGpuLayers = 0, // Default to 0 for CPU-only
    this.useMmap = true,
    this.useMlock = false,
  });

  /// Create a copy with modified fields
  OfflineContextParams copyWith({
    int? nCtx,
    int? nThreads,
    int? nBatch,
    int? nGpuLayers,
    bool? useMmap,
    bool? useMlock,
  }) {
    return OfflineContextParams(
      nCtx: nCtx ?? this.nCtx,
      nThreads: nThreads ?? this.nThreads,
      nBatch: nBatch ?? this.nBatch,
      nGpuLayers: nGpuLayers ?? this.nGpuLayers,
      useMmap: useMmap ?? this.useMmap,
      useMlock: useMlock ?? this.useMlock,
    );
  }

  /// High-end device configuration (6GB+ RAM)
  static const OfflineContextParams highEnd = OfflineContextParams(
    nCtx: 2048,
    nThreads: 4,
    nBatch: 512,
    nGpuLayers: 99,
  );

  /// Mid-range device configuration (3-6GB RAM)
  static const OfflineContextParams midRange = OfflineContextParams(
    nCtx: 1536,
    nThreads: 3,
    nBatch: 256,
    nGpuLayers: 20,
  );

  /// Low-end device configuration (<3GB RAM) - OPTIMIZED FOR 2GB DEVICES
  static const OfflineContextParams lowEnd = OfflineContextParams(
    nCtx: 512, // Very conservative for 2GB devices
    nThreads: 2,
    nBatch: 128,
    nGpuLayers: 0,
  );

  /// Convert to JSON
  Map<String, dynamic> toJson() => {
        'nCtx': nCtx,
        'nThreads': nThreads,
        'nBatch': nBatch,
        'nGpuLayers': nGpuLayers,
        'useMmap': useMmap,
        'useMlock': useMlock,
      };

  /// Create from JSON
  factory OfflineContextParams.fromJson(Map<String, dynamic> json) {
    return OfflineContextParams(
      nCtx: json['nCtx'] as int? ?? 2048,
      nThreads: json['nThreads'] as int? ?? 4,
      nBatch: json['nBatch'] as int? ?? 512,
      nGpuLayers: json['nGpuLayers'] as int? ?? 0,
      useMmap: json['useMmap'] as bool? ?? true,
      useMlock: json['useMlock'] as bool? ?? false,
    );
  }

  @override
  String toString() =>
      'OfflineContextParams(ctx: $nCtx, threads: $nThreads, batch: $nBatch, gpu: $nGpuLayers)';
}
