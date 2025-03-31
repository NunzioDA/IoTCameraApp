import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

Future<Uint8List?> cameraImageToUint8List(CameraImage cameraImage) async{
  try {
    if (cameraImage.format.group == ImageFormatGroup.yuv420 || cameraImage.format.group == ImageFormatGroup.nv21) {
      img.Image? image = _convertYUV420(cameraImage); // Oppure _convertNV21, se necessario
      if (image != null) {
        return await optimize(Uint8List.fromList(img.encodeJpg(image)), image.width, image.height);
      }
    } else if (cameraImage.format.group == ImageFormatGroup.jpeg) {
      return await optimize(cameraImage.planes[0].bytes, cameraImage.planes[0].width!, cameraImage.planes[0].height!);
    }
  } catch (e) {
    print("Errore nella conversione CameraImage: $e");
  }
  return null;
}

img.Image? _convertYUV420(CameraImage cameraImage) {
  // Implementazione della conversione YUV420 come mostrato in precedenza
  try {
    final planeData = cameraImage.planes.map((plane) => plane.bytes).toList();

    final yPlane = planeData[0];
    final uPlane = planeData[1];
    final vPlane = planeData[2];

    final width = cameraImage.width;
    final height = cameraImage.height;

    final img.Image imgYuv420 = img.Image(width: width, height: height);

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final uvIndex = (x / 2).floor() + (y / 2).floor() * (width / 2);
        final index = y * width + x;

        final yp = yPlane[index];
        final up = uPlane[uvIndex.toInt()];
        final vp = vPlane[uvIndex.toInt()];

        final r = (yp + 1.370705 * (vp - 128)).round().clamp(0, 255);
        final g = (yp - 0.698001 * (vp - 128) - 0.337633 * (up - 128)).round().clamp(0, 255);
        final b = (yp + 1.732446 * (up - 128)).round().clamp(0, 255);

        imgYuv420.setPixelRgba(x, y, r, g, b, 255);
      }
    }
    return imgYuv420;
  } catch (e) {
    print("ERROR: " + e.toString());
  }
  return null;
}

Future<Uint8List?> optimize(Uint8List bytes, int width, int height, [int maxWidthHeigth = 211]) async {

    int maxDimension = max(width, height);
    Uint8List? optimized;

    if(maxDimension > maxWidthHeigth)
    {

      ImageProvider provider = Image.memory(bytes).image;
      ResizeImage resized = ResizeImage(
        provider, 
        height: maxDimension == height? maxWidthHeigth : null,  
        width: maxDimension == width? maxWidthHeigth : null,
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
    }
    
    return optimized;
  }