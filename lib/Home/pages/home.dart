import 'package:flutter/material.dart';
import '../../OCR/camera_ocr.dart';

class homePage extends StatefulWidget {
  const homePage({super.key});

  @override
  State<homePage> createState() => _homePage();
}

class _homePage extends State<homePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(),
        body: ConstrainedBox(
          constraints: const BoxConstraints.expand(),
          child: Center(
            child: IconButton(
              icon: const Icon(Icons.camera_alt),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CameraOcr(),
                ),
              ),
            ),
          ),
        ));
  }
}
