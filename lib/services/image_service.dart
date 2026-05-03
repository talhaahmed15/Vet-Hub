import 'dart:developer';

import 'package:image_picker/image_picker.dart';

class ImageService {
  ImageService({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  Future<String?> pickImageFromGallery() async {
    log('Picking image from gallery');
    final file = await _picker.pickImage(source: ImageSource.gallery);
    final path = file?.path;
    log(path == null ? 'No image selected' : 'Image selected: $path');
    return path;
  }
}
