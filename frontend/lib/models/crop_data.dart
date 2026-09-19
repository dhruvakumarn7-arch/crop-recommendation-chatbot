/// crop_data.dart
/// -------------
/// This file defines the CropInputData class.
/// It stores the user's answers collected by the chatbot (soil, temperature, rainfall, etc.)
/// and converts them into JSON format so we can send them over HTTP to the Flask backend.

class CropInputData {
  String soilType;
  double? temperature;
  double? rainfall;
  double? humidity;
  double? ph;
  String location;
  String season;

  CropInputData({
    this.soilType = '',
    this.temperature,
    this.rainfall,
    this.humidity,
    this.ph,
    this.location = '',
    this.season = '',
  });

  /// Converts the Dart object into a JSON Map to send to the Flask API
  Map<String, dynamic> toJson() {
    return {
      'soil_type': soilType,
      'temperature': temperature,
      'rainfall': rainfall,
      'humidity': humidity,
      'ph': ph,
      'location': location,
      'season': season,
    };
  }

  /// Resets all values so the user can start a new recommendation chat
  void reset() {
    soilType = '';
    temperature = null;
    rainfall = null;
    humidity = null;
    ph = null;
    location = '';
    season = '';
  }
}
