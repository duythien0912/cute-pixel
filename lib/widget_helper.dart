import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

class WidgetHelper {
  static const platform = MethodChannel('com.thiendevlab.cute_pixel/widget');

  static Future<void> updateWidget(List<List<Color>> pixels) async {
    final pixelData = pixels.map((row) => 
      row.map((color) => '#${color.value.toRadixString(16).substring(2).toUpperCase()}').toList()
    ).toList();
    
    final json = jsonEncode({'pixels': pixelData});
    
    try {
      await platform.invokeMethod('updateWidget', {'pixels': json});
    } catch (e) {
      print('Error updating widget: $e');
    }
  }
}
