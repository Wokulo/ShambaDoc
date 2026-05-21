import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:flutter/services.dart';
import 'disease_model.dart';

class TFLiteService {
  static final TFLiteService _instance = TFLiteService._internal();
  factory TFLiteService() => _instance;
  TFLiteService._internal();

  Interpreter? _interpreter;
  List<String> _labels = [];
  bool _isInitialized = false;

  static const int inputSize = 224;
  static const int numClasses = 26;
  static const String modelPath = 'assets/models/plant_disease.tflite';
  static const String labelPath = 'assets/models/labels.txt';

  Future<void> init() async {
    if (_isInitialized) return;
    try {
      _interpreter = await Interpreter.fromAsset(modelPath);
      final labelData = await rootBundle.loadString(labelPath);
      _labels = labelData.split('\n').where((l) => l.isNotEmpty).toList();
      _isInitialized = true;
      print('TFLite model loaded: ${_labels.length} classes');
    } catch (e) {
      print('Error initializing TFLite: $e');
      rethrow;
    }
  }

  Future<DiseaseModel> predict(File imageFile) async {
    if (!_isInitialized) await init();
    if (_interpreter == null) throw Exception('Model not loaded');

    final imageData = await imageFile.readAsBytes();
    var image = img.decodeImage(imageData);
    if (image == null) throw Exception('Could not decode image');

    image = img.copyResize(image, width: inputSize, height: inputSize);

    var input = List.generate(1, (i) => List.generate(inputSize, (y) => List.generate(inputSize, (x) {
      final pixel = image!.getPixel(x, y);
      return [pixel.r / 255.0, pixel.g / 255.0, pixel.b / 255.0];
    })));

    var output = List.generate(1, (i) => List<double>.filled(numClasses, 0.0));
    _interpreter!.run(input, output);

    final scores = output[0];
    final maxIndex = scores.indexOf(scores.reduce((a, b) => a > b ? a : b));
    final confidence = scores[maxIndex];
    final label = maxIndex < _labels.length ? _labels[maxIndex] : 'Unknown';

    return _parseLabel(label, confidence);
  }

  DiseaseModel _parseLabel(String label, double confidence) {
    final parts = label.split('___');
    final cropType = parts.isNotEmpty ? parts[0] : 'Unknown';
    final diseaseName = parts.length > 1 ? parts[1].replaceAll('_', ' ') : 'Healthy';

    return DiseaseModel(
      name: diseaseName,
      cropType: cropType,
      confidence: confidence,
      description: _getDescription(diseaseName, cropType),
      treatment: _getTreatment(diseaseName),
      dosage: _getDosage(diseaseName),
      isOrganic: _isOrganicTreatment(diseaseName),
      severity: _estimateSeverity(diseaseName, confidence),
    );
  }

  String _getDescription(String disease, String crop) {
    return 'Detected $disease on $crop. Review treatment recommendations below.';
  }

  String _getTreatment(String disease) {
    if (disease.toLowerCase().contains('healthy')) {
      return 'Crop appears healthy. Continue standard agronomic practices.';
    }
    final treatments = {
      'early blight': 'Apply Mancozeb or Copper-based fungicide. Remove infected leaves.',
      'late blight': 'Apply Ridomil or Metalaxyl immediately. Ensure field drainage.',
      'leaf spot': 'Apply Dithane M-45. Practice crop rotation.',
      'mosaic virus': 'Uproot and burn infected plants. Control aphids. Use certified seeds.',
      'bacterial wilt': 'Uproot infected plants. Solarize soil. Use resistant varieties.',
    };
    for (final key in treatments.keys) {
      if (disease.toLowerCase().contains(key)) return treatments[key]!;
    }
    return 'Consult your nearest agro-dealer or extension officer for specific treatment.';
  }

  String _getDosage(String disease) {
    if (disease.toLowerCase().contains('healthy')) return 'N/A';
    return '50g per 20L knapsack sprayer (follow manufacturer label)';
  }

  bool _isOrganicTreatment(String disease) {
    return disease.toLowerCase().contains('healthy') || disease.toLowerCase().contains('mild');
  }

  String _estimateSeverity(String disease, double confidence) {
    final normalized = disease.toLowerCase();
    if (normalized.contains('healthy')) return 'early';
    if (confidence < 0.40) return 'moderate';
    if (normalized.contains('late blight') ||
        normalized.contains('wilt') ||
        normalized.contains('virus')) {
      return 'severe';
    }
    if (normalized.contains('spot') || normalized.contains('early blight')) {
      return 'moderate';
    }
    return 'moderate';
  }

  void dispose() {
    _interpreter?.close();
    _isInitialized = false;
  }
}
