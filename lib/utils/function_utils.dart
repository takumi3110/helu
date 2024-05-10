import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_recognition_error.dart';

class FunctionUtils {
  static void logEvent(String eventDescription) {
      var eventTime = DateTime.now().toIso8601String();
      debugPrint('$eventTime $eventDescription');
  }
}

