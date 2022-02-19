import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:memogenerator/data/models/meme.dart';
import 'package:memogenerator/data/models/template.dart';
import 'package:memogenerator/data/repositories/memes_repository.dart';
import 'package:memogenerator/data/repositories/templates_repository.dart';
import 'package:memogenerator/domain/interactors/save_template_interactor.dart';
import 'package:memogenerator/presentation/main/memes_with_docs_path.dart';
import 'package:memogenerator/presentation/main/models/template_full.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:rxdart/rxdart.dart';

class MainBloc {
  Stream<List<Meme>> observeMemes() =>
      MemesRepository.getInstance().observeMemes();

  Stream<MemesWithDocsPath> observeMemesWithPath() =>
      Rx.combineLatest2<List<Meme>, Directory, MemesWithDocsPath>(
        MemesRepository.getInstance().observeMemes(),
        getApplicationDocumentsDirectory().asStream(),
        (memes, docsDir) => MemesWithDocsPath(memes, docsDir.path),
      );

  Stream<List<TemplateFull>> observeTemplates() =>
      Rx.combineLatest2<List<Template>, Directory, List<TemplateFull>>(
        TemplatesRepository.getInstance().observeTemplates(),
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
    final xFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    return xFile?.path;
  }

  void dispose() {}
}
