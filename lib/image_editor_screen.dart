import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

class ImageEditorScreen extends StatefulWidget {
  @override
  _ImageEditorScreenState createState() => _ImageEditorScreenState();
}

class _ImageEditorScreenState extends State<ImageEditorScreen> {
  Uint8List? _imageBytes;
  List<TextInfo> _textInfoList = []; // List to store text information
  String _text = '';
  double _textSize = 20;
  String _selectedFont = 'Roboto';
  Color _textColor = Colors.black; // Initial text color
  Offset _textPosition = Offset(0, 0); // Initial text position

  Future<void> _getImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final imageBytes = await pickedFile.readAsBytes();
      setState(() {
        _imageBytes = imageBytes;
      });
    }
  }

  Future<void> _addTextToImage() async {
    if (_imageBytes == null || _text.isEmpty) {
      return;
    }

    // Convert the image bytes to an Image object
    final image = await decodeImageFromList(_imageBytes!);
    final imageWidth = image.width.toDouble();
    final imageHeight = image.height.toDouble();

    // Prepare the text style
    final style = TextStyle(
      color: _textColor,
      fontSize: _textSize,
      fontFamily: _selectedFont,
    );

    // Configure text properties
    final textSpan = TextSpan(
      text: _text,
      style: style,
    );

    // Create a TextPainter to measure the size of the text
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout(minWidth: 0, maxWidth: double.infinity);

    // Calculate the position to center the text on the image
    final x = (imageWidth - textPainter.width) / 2 + _textPosition.dx;
    final y = (imageHeight - textPainter.height) / 2 + _textPosition.dy;

    // Draw the text onto the image
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawImage(image, Offset.zero, Paint()); // Draw the original image
    textPainter.paint(canvas, Offset(x, y)); // Draw the text

    // Convert the canvas to an image
    final newImage = await recorder
        .endRecording()
        .toImage(imageWidth.toInt(), imageHeight.toInt());
    final byteData = await newImage.toByteData(format: ui.ImageByteFormat.png);
    if (byteData != null) {
      setState(() {
        _imageBytes = byteData.buffer.asUint8List();
      });
    }
  }

  void _changeTextColor(Color color) {
    setState(() {
      _textColor = color;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Image Text Editor'),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Stack(
                alignment: Alignment.center,
                children: [
                  _imageBytes == null
                      ? Text('No image selected.')
                      : Image.memory(
                          _imageBytes!,
                          width: 300,
                          height: 300,
                          fit: BoxFit.cover,
                        ),
                  if (_imageBytes != null)
                    ..._textInfoList.map((textInfo) {
                      return GestureDetector(
                        onPanUpdate: (details) {
                          setState(() {
                            _textInfoList[_textInfoList.indexOf(textInfo)]
                                .position += details.delta;
                          });
                        },
                        child: CustomPaint(
                          size: Size(300, 300),
                          painter: _TextPainter(textInfo),
                        ),
                      );
                    }).toList(),
                ],
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _getImage,
                child: Text('Select Image'),
              ),
              SizedBox(height: 20),
              TextFormField(
                decoration: InputDecoration(labelText: 'Enter Text'),
                onChanged: (value) {
                  setState(() {
                    _text = value;
                  });
                },
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Font: '),
                  DropdownButton<String>(
  value: _selectedFont,
  onChanged: (value) {
    print("Selected font: $value"); // Print selected font
    setState(() {
      _selectedFont = value!;
    });
  },
  items: GoogleFonts.asMap().keys.map<DropdownMenuItem<String>>((font) {
    return DropdownMenuItem<String>(
      value: font,
      child: Text(font),
    );
  }).toList(),
),


                ],
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Text Size: '),
                  Slider(
                    value: _textSize,
                    min: 10,
                    max: 50,
                    onChanged: (value) {
                      setState(() {
                        _textSize = value;
                      });
                    },
                  ),
                ],
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Text Color: '),
                  IconButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: Text('Pick a color'),
                            content: SingleChildScrollView(
                              child: ColorPicker(
                                pickerColor: _textColor,
                                onColorChanged: _changeTextColor,
                                showLabel: true,
                                pickerAreaHeightPercent: 0.8,
                              ),
                            ),
                            actions: <Widget>[
                              TextButton(
                                child: Text('OK'),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                              ),
                            ],
                          );
                        },
                      );
                    },
                    icon: Icon(Icons.color_lens),
                  ),
                ],
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (_imageBytes != null && _text.isNotEmpty) {
                    setState(() {
                      _textInfoList.add(TextInfo(
                        text: _text,
                        position:
                            Offset(0, 0), // Initial position, adjust as needed
                        color: _textColor,
                        fontSize: _textSize,
                        fontFamily: _selectedFont,
                      ));
                      _text = ''; // Clear the text field after adding text
                    });
                  }
                },
                child: Text('Add Text'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TextInfo {
  final String text;
  Offset position;
  final Color color;
  final double fontSize;
  final String fontFamily;

  TextInfo({
    required this.text,
    required this.position,
    required this.color,
    required this.fontSize,
    required this.fontFamily,
  });
}

class _TextPainter extends CustomPainter {
  final TextInfo textInfo;

  _TextPainter(this.textInfo);

  @override
  void paint(Canvas canvas, Size size) {
    // Calculate the boundaries of the image
    final double maxWidth = size.width;
    final double maxHeight = size.height;

    // Calculate the position of the text
    final double textWidth = textInfo.fontSize * textInfo.text.length;
    final double textHeight = textInfo.fontSize;
    double x = textInfo.position.dx;
    double y = textInfo.position.dy;

    // Adjust the text position if it exceeds the image boundaries
    if (x < 0) {
      x = 0;
    } else if (x + textWidth > maxWidth) {
      x = maxWidth - textWidth;
    }
    if (y < 0) {
      y = 0;
    } else if (y + textHeight > maxHeight) {
      y = maxHeight - textHeight;
    }

    // Paint the text
    final textStyle = TextStyle(
      color: textInfo.color,
      fontSize: textInfo.fontSize,
      fontFamily: textInfo.fontFamily,
    );
    final textSpan = TextSpan(
      text: textInfo.text,
      style: textStyle,
    );
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(x, y));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}





