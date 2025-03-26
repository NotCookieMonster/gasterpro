import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ImageService {
  static final ImageService _instance = ImageService._internal();

  factory ImageService() {
    return _instance;
  }

  ImageService._internal();

  // Process and store image, returning a path or base64 string depending on platform
  Future<String?> processPickedImage(XFile? pickedFile) async {
    if (pickedFile == null) return null;

    if (kIsWeb) {
      // For web, convert to base64
      final bytes = await pickedFile.readAsBytes();
      return 'data:image/jpeg;base64,${base64Encode(bytes)}';
    } else {
      // For mobile, return the file path
      return pickedFile.path;
    }
  }

  // Display image based on the stored value and current platform
  Widget displayImage(String? imageData, {double? width, double? height, BoxFit fit = BoxFit.cover}) {
    if (imageData == null) {
      return _placeholderImage(width, height);
    }

    if (imageData.startsWith('data:image')) {
      // Handle base64 image (used on web)
      try {
        final base64Data = imageData.split(',')[1];
        return Image.memory(
          base64Decode(base64Data),
          width: width,
          height: height,
          fit: fit,
        );
      } catch (e) {
        print('Error displaying base64 image: $e');
        return _placeholderImage(width, height);
      }
    } else {
      // Handle file path (used on mobile)
      if (kIsWeb) {
        // If we're on web but got a file path (which shouldn't happen if properly implemented)
        return _placeholderImage(width, height);
      }
      
      final file = File(imageData);
      if (file.existsSync()) {
        return Image.file(
          file,
          width: width,
          height: height,
          fit: fit,
        );
      } else {
        return _placeholderImage(width, height);
      }
    }
  }

  // Create a placeholder image
  Widget _placeholderImage(double? width, double? height) {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[300],
      child: const Icon(
        Icons.restaurant,
        size: 50,
        color: Colors.grey,
      ),
    );
  }
}