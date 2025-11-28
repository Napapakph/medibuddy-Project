import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

class CameraOcr extends StatefulWidget {
  const CameraOcr({super.key});

  @override
  State<CameraOcr> createState() => _CameraOcrState();
}

class _CameraOcrState extends State<CameraOcr> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CAMERA'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints.expand(),
          child: TextButton.icon(
              onPressed: () async {
                final cameras = await availableCameras();
                final firstCamera = cameras.first;

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TakePictureScreen(camera: firstCamera),
                  ),
                );
              },
              label: const Text('Open camera')),
        ),
      ),
    );
  }
}

// ----------------------------------------------------------
// 👇 คลาสนี้ต้องอยู่นอก class ด้านบน ไม่ใช่ซ้อนข้างใน
// ----------------------------------------------------------

class TakePictureScreen extends StatefulWidget {
  const TakePictureScreen({
    super.key,
    required this.camera,
  });

  final CameraDescription camera;

  @override
  TakePictureScreenState createState() => TakePictureScreenState();
}

class TakePictureScreenState extends State<TakePictureScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;

  @override
  void initState() {
    super.initState();

    _controller = CameraController(
      widget.camera,
      ResolutionPreset.medium,
    );

    _initializeControllerFuture = _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _initializeControllerFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return CameraPreview(_controller);
        } else {
          return const Center(child: CircularProgressIndicator());
        }
      },
    );
  }
}
