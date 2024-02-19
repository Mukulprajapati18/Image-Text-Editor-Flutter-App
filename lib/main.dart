import 'package:flutter/material.dart';
import 'image_editor_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Image Text Editor',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: ImageEditorScreen(),
    );
  }
}
