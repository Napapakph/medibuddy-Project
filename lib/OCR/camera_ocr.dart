import 'dart:io';

import 'package:camera/camera.dart';
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
  // ---------- state fields (ที่คุณเรียกแต่ยังไม่มี) ----------
  final ImagePicker _imagePicker = ImagePicker();

  CameraController? _cameraController;
  Future<void>? _initializeControllerFuture;

  bool _isProcessing = false;

  File? _capturedPhoto;

  CameraLensDirection _lensDirection = CameraLensDirection.back;

  // ---------- lifecycle ----------
  @override
  void initState() {
    super.initState();
    _initCamera(_lensDirection);
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  // ---------- camera init ----------
  Future<void> _initCamera(CameraLensDirection direction) async {
    setState(() {
      _isProcessing = false;
    });

    // ปิด controller เก่าก่อน (กัน memory leak)
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

      // ถ้าไม่เจอ direction ที่ต้องการ ให้ใช้ตัวแรก
      selected ??= cameras.isNotEmpty ? cameras.first : null;

      if (selected == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ไม่พบกล้องในอุปกรณ์')),
        );
        return;
      }

      final controller = CameraController(
        selected,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      _cameraController = controller;
      _initializeControllerFuture = controller.initialize();

      setState(() {});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เปิดกล้องไม่สำเร็จ: $e')),
      );
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

  // ---------- actions (ที่คุณเรียกแต่ยังไม่มี) ----------
  Future<void> _pickFromGallery() async {
    if (_isProcessing) return;

    final XFile? picked = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
    );

    if (!mounted) return;
    if (picked == null) return;

    await _processImage(File(picked.path));
  }

  Future<void> _captureFromCamera() async {
    if (_isProcessing) return;

    final controller = _cameraController;
    final initFuture = _initializeControllerFuture;

    if (controller == null || initFuture == null) return;

    try {
      setState(() => _isProcessing = true);

      await initFuture;
      if (!mounted) return;

      if (controller.value.isTakingPicture) return;

      final XFile file = await controller.takePicture();
      if (!mounted) return;

      final photo = File(file.path);
      setState(() => _capturedPhoto = photo);

      await _processImage(photo);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ถ่ายรูปไม่สำเร็จ: $e')),
      );
    } finally {
      if (!mounted) return;
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _toggleCamera() async {
    if (_isProcessing) return;

    _lensDirection = _lensDirection == CameraLensDirection.back
        ? CameraLensDirection.front
        : CameraLensDirection.back;

    await _initCamera(_lensDirection);
  }

  // ---------- OCR pipeline (โครง) ----------
  Future<void> _processImage(File imageFile) async {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      // ✅ 1) ตอนนี้ข้าม cropper ไปก่อน (กัน error class ไม่เจอ)
      final File finalImage = imageFile;

      // ✅ 2) OCR (fallback-safe)
      String extractedText = '';

      try {
        // ปรับชื่อเมทอดตรงนี้ให้ตรงกับของจริงภายหลัง
        // ตอนนี้ใส่ placeholder ไว้ก่อนให้ผ่าน compile
        // extractedText = await OcrTextService().extractText(finalImage);

        extractedText = ''; // placeholder: ยังไม่ทำ OCR จริง
      } catch (_) {
        extractedText = '';
      }

      if (!mounted) return;

      // ✅ 3) ไปหน้า result โดยส่ง param ตามที่หน้า result ต้องการจริง
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OcrResultPage(
            imageFile: finalImage,
            recognizedText: extractedText,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ประมวลผลรูปไม่สำเร็จ: $e')),
      );
    } finally {
      if (!mounted) return;
      setState(() => _isProcessing = false);
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
              style: TextStyle(
                fontSize: 12,
                color: Colors.white,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: IconButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('วิธีการสแกนชื่อยา')),
                );
              },
              icon: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.7),
                ),
                child: const Center(
                  child: Icon(
                    Icons.question_mark,
                    size: 18,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
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
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
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
