import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart'; // สำหรับ debugPrint
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'ocr_camera_frame.dart';
import 'ocr_image_cropper.dart';
import 'ocr_result_page.dart';
import 'ocr_text_service.dart';

class CameraOcrPage extends StatefulWidget {
  const CameraOcrPage({super.key});

  @override
  State<CameraOcrPage> createState() => _CameraOcrPageState();
}

class _CameraOcrPageState extends State<CameraOcrPage> {
  final ImagePicker _imagePicker = ImagePicker();
  final OcrImageCropper _imageCropper = const OcrImageCropper();
  final OcrTextService _ocrTextService = OcrTextService();

  CameraController? _cameraController;
  Future<void>? _initializeControllerFuture;

  bool _isProcessing = false;
  File? _capturedPhoto;

  CameraLensDirection _lensDirection = CameraLensDirection.back;

  // ---------- debug helpers ----------
  int _tapSeq = 0;

  void _log(String msg) {
    // ให้ log อ่านง่ายและค้นหาได้จาก console
    debugPrint('[CameraOcrPage] $msg');
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // ---------- lifecycle ----------
  @override
  void initState() {
    super.initState();
    _log('initState()');
    _initCamera(_lensDirection);
  }

  @override
  void dispose() {
    _log('dispose()');
    _ocrTextService.dispose();
    _cameraController?.dispose();
    super.dispose();
  }

  // ---------- camera init ----------
  Future<void> _initCamera(CameraLensDirection direction) async {
    _log('initCamera(direction=$direction) start');

    setState(() {
      _isProcessing = false;
    });

    final old = _cameraController;
    _cameraController = null;
    _initializeControllerFuture = null;
    await old?.dispose();

    try {
      final cameras = await availableCameras();
      if (!mounted) return;

      CameraDescription? selected;

      for (final c in cameras) {
        if (c.lensDirection == direction) {
          selected = c;
          break;
        }
      }

      selected ??= cameras.isNotEmpty ? cameras.first : null;

      if (selected == null) {
        _log('No camera found');
        _snack('ไม่พบกล้องในอุปกรณ์');
        return;
      }

      final controller = CameraController(
        selected,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      _cameraController = controller;

      // ✅📸 ใส่ debug ว่า init สำเร็จ/ล้มเหลว
      _initializeControllerFuture = controller.initialize().then((_) {
        _log(
            'camera initialize DONE (isInitialized=${controller.value.isInitialized})');
        if (mounted) {
          setState(() {});
        }
      }).catchError((e, st) {
        _log('camera initialize ERROR: $e');
        throw e;
      });

      setState(() {});
      _log('initCamera() end -> controller set');
    } catch (e) {
      _log('initCamera() exception: $e');
      if (!mounted) return;
      _snack('เปิดกล้องไม่สำเร็จ: $e');
    }
  }

  // ---------- helper: preview ----------
  Widget _buildCameraPreview() {
    final controller = _cameraController;
    final initFuture = _initializeControllerFuture;

    if (controller == null || initFuture == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return FutureBuilder<void>(
      future: initFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text('Init กล้องล้มเหลว: ${snapshot.error}'),
          );
        }

        if (snapshot.connectionState == ConnectionState.done) {
          return LayoutBuilder(
            builder: (context, constraints) {
              final frameWidth = constraints.maxWidth;
              final frameHeight = constraints.maxHeight;

              final previewAspect = controller.value.aspectRatio;
              final frameAspect = frameWidth / frameHeight;

              double width;
              double height;

              if (previewAspect > frameAspect) {
                height = frameHeight;
                width = height * previewAspect;
              } else {
                width = frameWidth;
                height = width / previewAspect;
              }

              return Center(
                child: SizedBox(
                  width: width,
                  height: height,
                  child: CameraPreview(controller),
                ),
              );
            },
          );
        }

        return const Center(child: CircularProgressIndicator());
      },
    );
  }

  // ---------- actions ----------
  Future<void> _pickFromGallery() async {
    if (_isProcessing) {
      _log('pickFromGallery blocked: isProcessing=true');
      return;
    }

    _log('pickFromGallery start');
    final XFile? picked = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
    );

    if (!mounted) return;
    if (picked == null) {
      _log('pickFromGallery cancelled');
      return;
    }

    _log('pickFromGallery picked=${picked.path}');
    await _processImage(File(picked.path), source: 'gallery');
  }

  Future<void> _captureFromCamera() async {
    final int seq = ++_tapSeq;
    _log('✅📸 capture tap seq=$seq (processing=$_isProcessing)');

    if (_isProcessing) {
      _log('✅📸 capture blocked seq=$seq: isProcessing=true');
      return;
    }

    final controller = _cameraController;
    final initFuture = _initializeControllerFuture;

    if (controller == null || initFuture == null) {
      _log('✅📸 capture blocked seq=$seq: controller/initFuture null');
      _snack('กล้องยังไม่พร้อม');
      return;
    }

    try {
      // ✅📸 สำคัญ: อย่าตั้ง _isProcessing=true ที่นี่
      // เพราะ _processImage() จะเป็นคนตั้งเอง
      // (ถ้าตั้งที่นี่ _processImage จะโดน if (_isProcessing) return ตัดทิ้ง)
      _log('✅📸 await initFuture seq=$seq...');
      await initFuture;

      if (!mounted) return;

      _log(
          '✅📸 initFuture done seq=$seq, isInitialized=${controller.value.isInitialized}');

      if (!controller.value.isInitialized) {
        _log('✅📸 capture blocked seq=$seq: controller not initialized');
        _snack('กล้องยังไม่พร้อม กรุณาลองใหม่');
        return;
      }

      if (controller.value.isTakingPicture) {
        _log('✅📸 capture blocked seq=$seq: isTakingPicture=true');
        return;
      }

      _log('✅📸 takePicture start seq=$seq...');
      final XFile file = await controller.takePicture();
      if (!mounted) return;

      _log('✅📸 takePicture done seq=$seq -> path=${file.path}');
      final photo = File(file.path);

      setState(() => _capturedPhoto = photo);

      // ✅📸 ส่งต่อไป pipeline
      await _processImage(photo, source: 'camera(seq=$seq)');
    } catch (e) {
      _log('✅📸 capture exception seq=$seq: $e');
      if (!mounted) return;
      _snack('ถ่ายรูปไม่สำเร็จ: $e');
    }
  }

  Future<void> _toggleCamera() async {
    if (_isProcessing) {
      _log('toggleCamera blocked: isProcessing=true');
      return;
    }

    _lensDirection = _lensDirection == CameraLensDirection.back
        ? CameraLensDirection.front
        : CameraLensDirection.back;

    _log('toggleCamera -> $_lensDirection');
    await _initCamera(_lensDirection);
  }

  // ---------- OCR pipeline ----------
  Future<void> _processImage(File imageFile, {required String source}) async {
    // ✅📸 Debug สำคัญ: ถ้าเข้าเงื่อนไขนี้ แปลว่า “ถูกกันไว้” และจะไม่ไปหน้า result
    if (_isProcessing) {
      _log('✅📸 processImage ABORTED (source=$source): isProcessing=true');
      _snack('ถูกกันไว้เพราะกำลังประมวลผลอยู่');
      return;
    }

    _log('processImage start (source=$source, path=${imageFile.path})');
    setState(() => _isProcessing = true);

    try {
      // 1) ตอนนี้ข้าม cropper ไปก่อน
      final File? croppedImage = await _imageCropper.crop(imageFile);
      if (croppedImage == null) {
        _log('processImage crop cancelled (source=$source)');
        return;
      }

      _log('processImage step1 croppedImage=${croppedImage.path}');

      // 2) OCR (ตอนนี้ยัง placeholder)
      String extractedText = '';
      try {
        extractedText = await _ocrTextService.recognize(croppedImage);
        _log('processImage step2 OCR done (len=${extractedText.length})');
      } catch (e) {
        _log('processImage OCR error: $e');
        extractedText = '';
      }

      if (!mounted) return;

      // 3) ไปหน้า result
      _log('✅📸 Navigator.push -> OcrResultPage');
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OcrResultPage(
            imageFile: croppedImage,
            recognizedText: extractedText,
          ),
        ),
      );
      if (result is String && result.trim().isNotEmpty) {
        if (!mounted) return;
        Navigator.pop(context, result.trim());
        return;
      }
      _log('✅📸 Navigator.push returned (back from result page)');
    } catch (e) {
      _log('processImage exception: $e');
      if (!mounted) return;
      _snack('ประมวลผลรูปไม่สำเร็จ: $e');
    } finally {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      _log('processImage end -> isProcessing=false');
    }
  }

  // ---------- UI ----------
  @override
  Widget build(BuildContext context) {
    final controller = _cameraController;

    final bool isCaptureEnabled = controller != null &&
        controller.value.isInitialized &&
        !_isProcessing &&
        !controller.value.isTakingPicture;

    // debug ค่าที่ทำให้ปุ่ม disabled (ดูได้จาก console)
    _log('build: enabled=$isCaptureEnabled '
        'init=${controller?.value.isInitialized} '
        'processing=$_isProcessing '
        'taking=${controller?.value.isTakingPicture}');

    final size = MediaQuery.of(context).size;
    final frameWidth = size.width * 0.86;
    final frameHeight = size.height * 0.68;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1F497D),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
          },
        ),
        centerTitle: true,
        title: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'เพิ่มยา',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 2),
            Text(
              '> สแกนชื่อของยา',
              style: TextStyle(fontSize: 12, color: Colors.white),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 12),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'ถ่ายรูปเพื่อสแกนชื่อยา\nที่ต้องรับประทาน',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Center(
                child: OcrCameraFrame(
                  width: frameWidth,
                  height: frameHeight,
                  isCaptureEnabled: isCaptureEnabled,
                  cameraPreview: _buildCameraPreview(),
                  isProcessing: _isProcessing,
                  onPickFromGallery: _pickFromGallery,
                  onCapture: _captureFromCamera,
                  onToggleCamera: _toggleCamera,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
