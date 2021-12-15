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
    }
    else {
      final docsPath = await getApplicationDocumentsDirectory();
      final memePath = "${docsPath.absolute.path}${Platform.pathSeparator}memes";
      await Directory(memePath).create(recursive: true);
      final imageName = imagePath.split(Platform.pathSeparator).last;
      final fullImageName = "$memePath${Platform.pathSeparator}$imageName";
      final tempFile = File(imagePath);
      await tempFile.copy(fullImageName);
      final meme = Meme(id: id, texts: textWithPositions, memePath: fullImageName);
      return MemesRepository.getInstance().addToMemes(meme);
    }
  }
}
