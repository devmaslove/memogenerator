import 'dart:io';

import 'package:memogenerator/data/models/meme.dart';
import 'package:memogenerator/data/models/text_with_position.dart';
import 'package:memogenerator/data/repositories/memes_repository.dart';
import 'package:path_provider/path_provider.dart';

class SaveMemeInteractor {
  static SaveMemeInteractor? _instance;

  factory SaveMemeInteractor.getInstance() =>
      _instance ??= SaveMemeInteractor._internal();

  SaveMemeInteractor._internal();

  Future<bool> saveMeme({
    required final String id,
    required final List<TextWithPosition> textWithPositions,
    final String? imagePath,
  }) async {
    if (imagePath == null) {
      final meme = Meme(id: id, texts: textWithPositions);
      return MemesRepository.getInstance().addToMemes(meme);
    } else {
      // создаем директорию с мемами
      final docsPath = await getApplicationDocumentsDirectory();
      final memePath =
          "${docsPath.absolute.path}${Platform.pathSeparator}memes";
      await Directory(memePath).create(recursive: true);
      // получаем имя файла в нашей дирректории
      String imageName = imagePath.split(Platform.pathSeparator).last;
      final imageExt = imageName.split(".").last;
      String imageFileName =
          imageName.substring(0, imageName.length - imageExt.length - 1);
      int imageFileNum = 0;
      if (imageFileName.contains(RegExp(r"_\d+$"))) {
        final number = imageFileName.split("_").last;
        imageFileName = imageFileName.substring(
            0, imageFileName.length - number.length - 1);
        imageFileNum = int.tryParse(number) ?? 0;
      }
      imageName = imagePath.split(Platform.pathSeparator).last;
      final imageFile = File(imagePath);
      int imageLength = await imageFile.length();
      String fullImageName;
      // проверяем есть ли уже такой
      bool needSave = false;
      do {
        fullImageName = "$memePath${Platform.pathSeparator}$imageName";
        final oldFile = File(fullImageName);
        bool exists = await oldFile.exists();
        if (!exists) {
          needSave = true;
          break;
        }
        int oldLength = await oldFile.length();
        if (oldLength == imageLength) break;
        // меняем имя и заного проверяем
        imageFileNum++;
        imageName = "${imageFileName}_$imageFileNum.$imageExt";
      } while (true);
      if (needSave) {
        print("COPY FILE $imagePath TO $fullImageName");
        final tempFile = File(imagePath);
        await tempFile.copy(fullImageName);
      }
      final meme = Meme(
        id: id,
        texts: textWithPositions,
        memePath: fullImageName,
      );
      return MemesRepository.getInstance().addToMemes(meme);
    }
  }
}
