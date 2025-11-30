class HistoryModel {
  String userId;
  String imageBase64;
  String prediction;
  DateTime timestamp;

  HistoryModel({
    required this.userId,
    required this.imageBase64,
    required this.prediction,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      "userId": userId,
      'image_base64': imageBase64,
      'prediction': prediction,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
