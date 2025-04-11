import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:image/image.dart' as img;

Future<Uint8List> resizeImageFromXFile(XFile imageFile, int targetWidth, int targetHeight) async {
  // Leggi il file come Uint8List.
  Uint8List imageBytes = await imageFile.readAsBytes();

  // Decodifica i byte dell'immagine.
  img.Image? decodedImage = img.decodeImage(imageBytes);

  if (decodedImage == null) {
    throw Exception('Failed to decode image.');
  }

  // Ridimensiona l'immagine.
  img.Image resizedImage = img.copyResize(decodedImage, width: targetWidth, height: targetHeight);

  // Ricodifica l'immagine ridimensionata in formato Uint8List.
  Uint8List resizedBytes = Uint8List.fromList(img.encodePng(resizedImage));

  return resizedBytes;
}


