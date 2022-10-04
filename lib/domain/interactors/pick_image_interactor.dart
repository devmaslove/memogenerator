import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

class PickImageInteractor {
  static PickImageInteractor? _instance;
  factory PickImageInteractor.getInstance() =>
      _instance ??= PickImageInteractor._();
  PickImageInteractor._();

  Future<String?> pickImage() async {
    if (defaultTargetPlatform == TargetPlatform.macOS) {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
      );
      return result?.files.single.path;
    }
    final xFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    return xFile?.path;
  }
}
