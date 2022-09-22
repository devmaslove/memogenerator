import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:memogenerator/data/models/meme.dart';
import 'package:memogenerator/data/models/template.dart';
import 'package:memogenerator/data/repositories/memes_repository.dart';
import 'package:memogenerator/data/repositories/templates_repository.dart';
import 'package:memogenerator/domain/interactors/save_template_interactor.dart';
import 'package:memogenerator/presentation/main/models/meme_thumbnail.dart';
import 'package:memogenerator/presentation/main/models/template_full.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:rxdart/rxdart.dart';

class MainBloc {
  Stream<List<MemeThumbnail>> observeMemes() =>
      Rx.combineLatest2<List<Meme>, Directory, List<MemeThumbnail>>(
        MemesRepository.getInstance().observeItems(),
        getApplicationDocumentsDirectory().asStream(),
        (memes, docsDir) {
          return memes.map(
            (meme) {
              final fullImagePath = path.join(
                docsDir.absolute.path,
                '${meme.id}.png',
              );
              return MemeThumbnail(
                memeId: meme.id,
                fullImageUrl: fullImagePath,
              );
            },
          ).toList();
        },
      );

  Stream<List<TemplateFull>> observeTemplates() =>
      Rx.combineLatest2<List<Template>, Directory, List<TemplateFull>>(
        TemplatesRepository.getInstance().observeItems(),
        getApplicationDocumentsDirectory().asStream(),
        (templates, docsDir) {
          return templates.map(
            (template) {
              final fullImagePath = path.join(
                docsDir.absolute.path,
                SaveTemplateInteractor.templatesPathName,
                template.imageUrl,
              );
              return TemplateFull(
                id: template.id,
                fullImagePath: fullImagePath,
              );
            },
          ).toList();
        },
      );

  Future<String?> selectMeme() async {
    if (defaultTargetPlatform == TargetPlatform.macOS) {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
      );
      final imagePath = result?.files.single.path;
      if (imagePath != null) {
        await SaveTemplateInteractor.getInstance().saveTemplate(
          imagePath: imagePath,
        );
      }
      return imagePath;
    }
    final xFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    final imagePath = xFile?.path;
    if (imagePath != null) {
      await SaveTemplateInteractor.getInstance().saveTemplate(
        imagePath: imagePath,
      );
    }
    return imagePath;
  }

  void deleteTemplate(final String templateId) {
    TemplatesRepository.getInstance().removeFromItemsById(templateId);
  }

  void deleteMeme(final String memeId) {
    MemesRepository.getInstance().removeFromItemsById(memeId);
  }

  void dispose() {}
}
