import 'package:flutter/material.dart';

class WidgetUtils {
  static AppBar createAppBar(String title) {
    return AppBar(
      title: Text(title),
      elevation: 1,
    );
  }
}