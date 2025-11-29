class HistoryModel {
  String imageBase64;
  String prediction;
  DateTime timestamp;

  HistoryModel({
    required this.imageBase64,
    required this.prediction,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'image_base64': imageBase64,
      'prediction': prediction,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
