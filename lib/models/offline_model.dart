class OfflineModel {
  final String id;
  final String name;
  final String description;
  final String downloadUrl;
  final int sizeBytes;
  final String filename;
  final bool isDownloaded;

  const OfflineModel({
    required this.id,
    required this.name,
    required this.description,
    required this.downloadUrl,
    required this.sizeBytes,
    required this.filename,
    this.isDownloaded = false,
  });

  OfflineModel copyWith({bool? isDownloaded}) {
    return OfflineModel(
      id: id,
      name: name,
      description: description,
      downloadUrl: downloadUrl,
      sizeBytes: sizeBytes,
      filename: filename,
      isDownloaded: isDownloaded ?? this.isDownloaded,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'downloadUrl': downloadUrl,
      'sizeBytes': sizeBytes,
      'filename': filename,
      'isDownloaded': isDownloaded,
    };
  }

  factory OfflineModel.fromMap(Map<String, dynamic> map) {
    return OfflineModel(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      downloadUrl: map['downloadUrl'],
      sizeBytes: map['sizeBytes'],
      filename: map['filename'],
      isDownloaded: map['isDownloaded'] ?? false,
    );
  }
}
