import 'dart:convert';
import 'dart:developer';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';

class ImageService {
  ImageService({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  Future<String?> pickImageFromGallery() async {
    log('Picking image from gallery');
    final file = await _picker.pickImage(source: ImageSource.gallery);
    if (file == null) {
      log('No image selected');
      return null;
    }

    if (kIsWeb) {
      final bytes = await file.readAsBytes();
      final name = file.name;
      final ext = name.contains('.') ? name.split('.').last.toLowerCase() : '';
      final mime = ext == 'png' ? 'image/png' : 'image/jpeg';
      final dataUri = 'data:$mime;name=$name;base64,${base64Encode(bytes)}';
      log('Image selected (web data URI): $name');
      return dataUri;
    }

    final path = file.path;
    log('Image selected: $path');
    return path;
  }
}
