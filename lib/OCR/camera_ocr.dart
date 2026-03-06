import 'dart:io';
import 'dart:ui' as ui;
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart'; // สำหรับ debugPrint
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'ocr_camera_frame.dart';
import 'ocr_image_cropper.dart';
import 'ocr_result_page.dart';
import 'ocr_text_service.dart';
import 'tutorial_dialog.dart';
import '../Model/medicine_model.dart';

class CameraOcrPage extends StatefulWidget {
  final MedicineDraft draft;
  final int profileId;
  final bool isEdit;
  final MedicineItem? initialItem;

  const CameraOcrPage({
    super.key,
    required this.draft,
    required this.profileId,
    this.isEdit = false,
    this.initialItem,
  });

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      TutorialDialog.show(context);
    });
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

  // ---------- validation ----------
  void _showValidationDialog(String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color.fromARGB(255, 234, 244, 255), Colors.white],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20.0),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF5A81BB).withOpacity(0.15),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  color: Color(0xFF5A81BB),
                  size: 48,
                ),
                const SizedBox(height: 16),
                const Text(
                  'แจ้งเตือน',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2B4C7E),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF5A81BB),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5A81BB),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24.0),
                      ),
                    ),
                    child: const Text(
                      'ตกลง',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<File?> _validateOcrImage(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final sizeInBytes = bytes.length;
      final sizeInMB = sizeInBytes / (1024 * 1024);
      final extension = file.path.split('.').last.toLowerCase();

      final ui.Image image = await decodeImageFromList(bytes);
      final width = image.width;
      final height = image.height;
      image.dispose();

      debugPrint('----------------------------------------');
      debugPrint('DEBUG OCR IMAGE INFO:');
      debugPrint('Resolution: $width x $height');
      debugPrint('File Size: $sizeInBytes bytes');
      debugPrint('File Size (MB): ${sizeInMB.toStringAsFixed(2)} MB');
      debugPrint('Extension: $extension');
      debugPrint('----------------------------------------');

      if (extension != 'jpg' && extension != 'jpeg' && extension != 'png') {
        _showValidationDialog(
            'ระบบรองรับเฉพาะไฟล์รูปภาพ JPG, JPEG, และ PNG เท่านั้น');
        return null;
      }

      final minDim = width < height ? width : height;
      final maxDim = width > height ? width : height;
      if (minDim < 720 || maxDim < 1280) {
        _showValidationDialog(
            'ความละเอียดภาพไม่เพียงพอ ต้องการความละเอียดตั้งแต่ 1280x720 ขึ้นไป');
        return null;
      }

      if (sizeInMB > 3.0) {
        debugPrint('File size exceeds 3MB, attempting to compress...');
        final targetPath =
            file.path.replaceFirst(RegExp(r'\.[a-zA-Z]+$'), '_compressed.jpg');
        XFile? result = await FlutterImageCompress.compressAndGetFile(
          file.absolute.path,
          targetPath,
          quality: 80,
        );

        if (result != null) {
          final newFile = File(result.path);
          final newBytes = await newFile.readAsBytes();
          final newSizeInMB = newBytes.length / (1024 * 1024);
          debugPrint('----------------------------------------');
          debugPrint('DEBUG OCR IMAGE COMPRESSED:');
          debugPrint('New File Size: ${newBytes.length} bytes');
          debugPrint(
              'New File Size (MB): ${newSizeInMB.toStringAsFixed(2)} MB');
          debugPrint('----------------------------------------');

          if (newSizeInMB > 3.0) {
            _showValidationDialog(
                'ขนาดไฟล์เกิน 3 MB ไม่สามารถลดขนาดให้ต่ำกว่ากำหนดได้');
            return null;
          }
          return newFile;
        } else {
          _showValidationDialog('ขนาดไฟล์เกิน 3 MB ไม่สามารถลดขนาดได้');
          return null;
        }
      }

      return file;
    } catch (e) {
      debugPrint('Image validation error: $e');
      _showValidationDialog('เกิดข้อผิดพลาดในการตรวจสอบไฟล์รูปภาพ');
      return null;
    }
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

    // 1) Validate Image Before processing
    final validFile = await _validateOcrImage(imageFile);
    if (validFile == null) {
      _log('processImage cancelled due to validation failure (source=$source)');
      return;
    }
    imageFile = validFile;

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
          builder: (_) => OcrSuccessPage(
            imageFile: croppedImage,
            recognizedText: extractedText,
            draft: widget.draft,
            profileId: widget.profileId,
            isEdit: widget.isEdit,
            initialItem: widget.initialItem,
          ),
        ),
      );
      if (result is MedicineItem) {
        if (!mounted) return;
        Navigator.pop(context, result);
        return;
      }
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
      backgroundColor: const Color(0xFFF0F6FF),
      appBar: AppBar(
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color.fromARGB(255, 234, 244, 255),
                Color.fromARGB(255, 193, 222, 255)
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded,
              color: Color(0xFF5A81BB)),
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
                color: Color(0xFF2B4C7E),
              ),
            ),
            SizedBox(height: 2),
            Text(
              '> สแกนชื่อของยา',
              style: TextStyle(fontSize: 16, color: Color(0xFF5A81BB)),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline, color: Color(0xFF5A81BB)),
            onPressed: () => TutorialDialog.show(context, forceShow: true),
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
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2B4C7E)),
              ),
            ),
            const SizedBox(height: 1),
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
