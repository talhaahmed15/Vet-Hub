import 'package:image_picker/image_picker.dart';

class ImageService {
  ImageService({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  Future<String?> pickImageFromGallery() async {
    final file = await _picker.pickImage(source: ImageSource.gallery);
    return file?.path;
  }
}
