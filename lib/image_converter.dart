import 'dart:async';
import 'dart:typed_data';
import 'dart:ui';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;


// This function is used to convert a YUV420T to a Jpeg image
Future<Uint8List> convertYUV420ToJPEG(CameraImage image) async{
  img.Image imgData = convertYUV420ToRGB(image); 
  Uint8List jpgimage = Uint8List.fromList(img.encodeJpg(imgData, quality: 100)); 
  return (await optimize(jpgimage, imgData.width, imgData.height, 0.1))!;
}

// This function is used to convert a YUV420T image to a RGB
img.Image convertYUV420ToRGB(CameraImage image) {
  final int width = image.width;
  final int height = image.height;

  final img.Image imgData = img.Image(width: width, height: height);

  final Uint8List yPlane = image.planes[0].bytes;
  final Uint8List uPlane = image.planes[1].bytes;
  final Uint8List vPlane = image.planes[2].bytes;

  final int uvRowStride = image.planes[1].bytesPerRow;
  final int uvPixelStride = image.planes[1].bytesPerPixel ?? 1;

  for (int y = 0; y < height; y++) {
    for (int x = 0; x < width; x++) {
      final int yIndex = y * width + x;
      final int uvIndex = ((y ~/ 2) * uvRowStride) + (x ~/ 2) * uvPixelStride;

      final int yValue = yPlane[yIndex] & 0xFF;
      final int uValue = uPlane[uvIndex] & 0xFF;
      final int vValue = vPlane[uvIndex] & 0xFF;

      final int r = (yValue + 1.370705 * (vValue - 128)).clamp(0, 255).toInt();
      final int g = (yValue - 0.698001 * (vValue - 128) - 0.337633 * (uValue - 128)).clamp(0, 255).toInt();
      final int b = (yValue + 1.732446 * (uValue - 128)).clamp(0, 255).toInt();

      imgData.setPixelRgb(x, y, r, g, b);
    }
  }

  return imgData;
}

// This function is used to optimize the image
// by changing its quality and dimensions
Future<Uint8List?> optimize(Uint8List bytes, int width, int height, [double quality = 0.6]) async {
  Uint8List? optimized;

  ImageProvider provider = Image.memory(bytes).image;
  ResizeImage resized = ResizeImage(
    provider, 
    height: (height * quality).toInt(), 
    width: (width * quality).toInt()
  );
  final Completer<Uint8List?> completer = Completer<Uint8List?>();

  resized.resolve(ImageConfiguration.empty).addListener(
    ImageStreamListener((imageInfo, synchronousCall) async{              
      final bytes = await imageInfo.image.toByteData(format: ImageByteFormat.png);
      if (!completer.isCompleted) {
        completer.complete(bytes?.buffer.asUint8List());
      }
    })
  );

  optimized = await completer.future;
  
  return optimized;
}