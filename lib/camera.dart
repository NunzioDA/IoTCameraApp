import 'dart:async';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:iot_camera_sensor_app/communication.dart';
import 'package:iot_camera_sensor_app/image_converter.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  CameraScreenState createState() => CameraScreenState();
}

class CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  List<CameraDescription>? cameras;
  bool _isCameraInitialized = false;
  Uint8List? cameraImage;
  late Timer myTimer;

  bool imageRequestPending = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();

    myTimer = Timer.periodic(
      const Duration(seconds: 5), 
      (timer) async{
        imageRequestPending = await WebServer.isImageRequestPending();
      }
    );
  }

  Future<void> _initializeCamera() async {
    cameras = await availableCameras();
    if (cameras!.isNotEmpty) {
      _controller = CameraController(cameras![0], ResolutionPreset.high);
      await _controller!.initialize();
      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
          _controller!.startImageStream((image) async{
            if(imageRequestPending){
              imageRequestPending = false;
              Uint8List? newImage = await cameraImageToUint8List(image);
              if(newImage != null)
              {
                print("sending image");
                WebServer.sendImage(newImage);
              }
            }
          });
        });
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    myTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Fotocamera")),
      body: _isCameraInitialized
          ? CameraPreview(_controller!)
          : Center(child: CircularProgressIndicator()),
    );
  }
}
