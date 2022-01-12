import 'dart:io';

import 'package:memogenerator/data/models/meme.dart';
import 'package:memogenerator/data/models/text_with_position.dart';
import 'package:memogenerator/data/repositories/memes_repository.dart';
import 'package:path_provider/path_provider.dart';
import 'package:collection/collection.dart';

class SaveMemeInteractor {
  static SaveMemeInteractor? _instance;

  factory SaveMemeInteractor.getInstance() =>
      _instance ??= SaveMemeInteractor._internal();

  SaveMemeInteractor._internal();

  Future<String> _createNewFile(final String imagePath) async {
    // создаем директорию с мемами
    final docsPath = await getApplicationDocumentsDirectory();
    final memePath = "${docsPath.absolute.path}${Platform.pathSeparator}memes";
    final memesDirectory = Directory(memePath);
    await memesDirectory.create(recursive: true);
    final currentFiles = memesDirectory.listSync();
    //
    final imageName = _getFileNameByPath(imagePath);
    final oldFileWithSameName = currentFiles.firstWhereOrNull((element) =>
        _getFileNameByPath(element.path) == imageName && element is File);
    final newImagePath = "$memePath${Platform.pathSeparator}$imageName";
    final tempFile = File(imagePath);

    if (oldFileWithSameName == null) {
      await tempFile.copy(newImagePath);
      return newImagePath;
    }

    final oldFileLength = await (oldFileWithSameName as File).length();
    final newFileLength = await tempFile.length();
    if (oldFileLength == newFileLength) return newImagePath;

    final indexOfLastDot = imageName.lastIndexOf(".");
    if (indexOfLastDot == -1) {
      await tempFile.copy(newImagePath);
      return newImagePath;
    }

    final extension = imageName.substring(indexOfLastDot);
    final imageNameWithoutExt = imageName.substring(0, indexOfLastDot);
    final indexOfLastUnderscore = imageNameWithoutExt.lastIndexOf("_");
    if (indexOfLastUnderscore == -1) {
      final correctedNewImagePath =
          "$memePath${Platform.pathSeparator}${imageNameWithoutExt}_1$extension";
      await tempFile.copy(correctedNewImagePath);
      return correctedNewImagePath;
    }
    final suffixNumberString =
        imageNameWithoutExt.substring(indexOfLastUnderscore + 1);
    final suffixNumber = int.tryParse(suffixNumberString);
    if (suffixNumber == null) {
      final correctedNewImagePath =
          "$memePath${Platform.pathSeparator}${imageNameWithoutExt}_1$extension";
      await tempFile.copy(correctedNewImagePath);
      return correctedNewImagePath;
    }
    final imageNameWithoutSuffix =
        imageNameWithoutExt.substring(0, indexOfLastUnderscore);
    final correctedNewImagePath =
        "$memePath${Platform.pathSeparator}${imageNameWithoutSuffix}_${suffixNumber + 1}$extension";
    await tempFile.copy(correctedNewImagePath);
    return correctedNewImagePath;
  }

  Future<String> _createNewFileIfNeed(
    final String imageFileName,
    final int imageFileNum,
    final String imageExt,
    final String memePath,
    final File imageFile,
    final int imageLength,
  ) async {
    final imageName = imageFileNum > 0
        ? "${imageFileName}_$imageFileNum.$imageExt"
        : "$imageFileName.$imageExt";
    final fullImageName = "$memePath${Platform.pathSeparator}$imageName";
    final oldFile = File(fullImageName);
    bool exists = await oldFile.exists();
    if (!exists) {
      await imageFile.copy(fullImageName);
      return fullImageName;
    }
    // проверяем размер - если совпадает то считаем что это
    // такая же картинка
    int oldLength = await oldFile.length();
    if (oldLength == imageLength) return fullImageName;
    // меняем номер и заного проверяем
    return _createNewFileIfNeed(
      imageFileName,
      imageFileNum + 1,
      imageExt,
      memePath,
      imageFile,
      imageLength,
    );
  }

  Future<String> _createNewFile2(final String imagePath) async {
    // создаем директорию с мемами
    final docsPath = await getApplicationDocumentsDirectory();
    final memePath = "${docsPath.absolute.path}${Platform.pathSeparator}memes";
    await Directory(memePath).create(recursive: true);
    // получаем имя файла в нашей дирректории
    String imageName = _getFileNameByPath(imagePath);
    final imageExt = imageName.split(".").last;
    String imageFileName =
        imageName.substring(0, imageName.length - imageExt.length - 1);
    int imageFileNum = 0;
    if (imageFileName.contains(RegExp(r"_\d+$"))) {
      final number = imageFileName.split("_").last;
      imageFileNum = int.tryParse(number) ?? 0;
      if (imageFileNum != 0) {
        imageFileName = imageFileName.substring(
            0, imageFileName.length - number.length - 1);
      }
    }
    imageName = _getFileNameByPath(imagePath);
    print(
        "PARTS OF FILE NAME $imageName IS $imageFileName _ $imageFileNum . $imageExt");
    final imageFile = File(imagePath);
    int imageLength = await imageFile.length();
    return _createNewFileIfNeed(
      imageFileName,
      imageFileNum,
      imageExt,
      memePath,
      imageFile,
      imageLength,
    );
  }

  Future<bool> saveMeme({
    required final String id,
    required final List<TextWithPosition> textWithPositions,
    final String? imagePath,
  }) async {
    if (imagePath == null) {
      final meme = Meme(id: id, texts: textWithPositions);
      return MemesRepository.getInstance().addToMemes(meme);
    } else {
      final newImagePath = await _createNewFile(imagePath);
      final meme = Meme(
        id: id,
        texts: textWithPositions,
        memePath: newImagePath,
      );
      return MemesRepository.getInstance().addToMemes(meme);
    }
  }

  String _getFileNameByPath(String imagePath) =>
      imagePath.split(Platform.pathSeparator).last;
}
