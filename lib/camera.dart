import 'dart:async';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:iot_camera_sensor_app/communication.dart';
import 'package:iot_camera_sensor_app/image_converter.dart';
import 'package:iot_camera_sensor_app/prova_immagine.dart';

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
  bool checkingImageRequest = false;
  
  @override
  void initState() {
    super.initState();
    _initializeCamera();

    myTimer = Timer.periodic(
      const Duration(milliseconds: 300), 
      (timer) async{
        if(!checkingImageRequest && _isCameraInitialized){
          checkingImageRequest = true;
          imageRequestPending = await WebServer.isImageRequestPending();
          checkingImageRequest = false;
          
        }
      }
    );
  }

  Future<void> _initializeCamera() async {
    cameras = await availableCameras();
    if (cameras!.isNotEmpty) {
      _controller = CameraController(cameras![0], ResolutionPreset.high);
      await _controller!.initialize();
      if (mounted) {
        _isCameraInitialized = true;
        _controller!.setFocusPoint(Offset(0.5, 0.5));
        
        _controller!.startImageStream((image) async{
          if(imageRequestPending){
            imageRequestPending = false;
            
            Uint8List? newImage = await convertYUV420ToJPEG(image);

            print("Sending new image");
            WebServer.sendImage(newImage);     

            setState(() {
              cameraImage = newImage;
            });    
          }
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
      body: _isCameraInitialized && cameraImage!=null
          // ? CameraPreview(_controller!)
          ? Image.memory(cameraImage!)
          : Center(child: CircularProgressIndicator()),
    );
  }
}
