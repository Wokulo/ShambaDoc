import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shambadoc/ai/tflite_service.dart';
import 'package:shambadoc/ai/disease_model.dart';

class ScanController extends ChangeNotifier {
  final TFLiteService _aiService = TFLiteService();
  final ImagePicker _picker = ImagePicker();

  bool isLoading = false;
  String? errorMessage;
  DiseaseModel? result;
  File? selectedImage;

  Future<void> pickFromGallery() async {
    final XFile? picked = await _picker.pickImage(source: ImageSource.gallery, maxWidth: 1024);
    if (picked != null) {
      selectedImage = File(picked.path);
      notifyListeners();
      await _runInference();
    }
  }

  Future<void> captureFromCamera() async {
    final XFile? captured = await _picker.pickImage(source: ImageSource.camera, maxWidth: 1024);
    if (captured != null) {
      selectedImage = File(captured.path);
      notifyListeners();
      await _runInference();
    }
  }

  Future<void> _runInference() async {
    if (selectedImage == null) return;
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      await _aiService.init();
      result = await _aiService.predict(selectedImage!);
    } catch (e) {
      errorMessage = 'Failed to analyze image: $e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void reset() {
    result = null;
    selectedImage = null;
    errorMessage = null;
    isLoading = false;
    notifyListeners();
  }
}
