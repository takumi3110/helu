import 'package:flutter/material.dart';

class WidgetUtils {
  static AppBar createAppBar(String title) {
    return AppBar(
      title: Text(title),
      elevation: 1,
    );
  }

  static Widget sliderRow(String title, Slider child, String result) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [Text(title), Expanded(child: child), Text(result)],
    );
  }
}