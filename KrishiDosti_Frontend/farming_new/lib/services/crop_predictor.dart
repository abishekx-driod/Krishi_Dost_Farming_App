import 'package:tflite_flutter/tflite_flutter.dart';

class CropPredictor {
  late Interpreter interpreter;
  bool isLoaded = false;

  /// ✅ Your real crop labels (19 classes)
  final List<String> labels = [
    "banana",
    "barley",
    "brinjal",
    "cauliflower",
    "cotton",
    "ground_nuts",
    "guava",
    "jackfruit",
    "maize",
    "mango",
    "millets",
    "oil_seeds",
    "paddy",
    "potato",
    "pulses",
    "sugarcane",
    "tobacco",
    "tomato",
    "wheat"
  ];

  /// Load TFLite Model
  Future<void> load() async {
    try {
      interpreter =
          await Interpreter.fromAsset("assets/models/crop_model.tflite");

      print("📌 Model Input Shape: ${interpreter.getInputTensor(0).shape}");
      print("📌 Model Output Shape: ${interpreter.getOutputTensor(0).shape}");
      print("📌 Model Loaded Successfully");

      isLoaded = true;
    } catch (e) {
      print("❌ Error loading crop model: $e");
      isLoaded = false;
    }
  }

  /// Predict raw output from model
  Map<String, dynamic> predictRaw(List<double> input) {
    if (!isLoaded) {
      return {"crop": "Model not loaded", "probability": 0.0};
    }

    if (input.length != 28) {
      print("❌ Expected 28 input values, got ${input.length}");
      return {"crop": "Invalid input length", "probability": 0.0};
    }

    /// 👉 MODEL OUTPUT IS [1, 19] → 19 classes
    final output = List.filled(19, 0.0).reshape([1, 19]);

    try {
      interpreter.run([input], output);
    } catch (e) {
      print("❌ Error running interpreter: $e");
      return {"crop": "Prediction failed", "probability": 0.0};
    }

    /// Extract probabilities
    List<double> probs = List<double>.from(output[0]);

    /// Get index of highest probability
    int maxIndex = 0;
    double maxValue = probs[0];

    for (int i = 1; i < probs.length; i++) {
      if (probs[i] > maxValue) {
        maxValue = probs[i];
        maxIndex = i;
      }
    }

    return {
      "crop": labels[maxIndex],     // 🟢 Actual crop name
      "probability": maxValue,      // Confidence value
    };
  }
}
