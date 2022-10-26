import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:memogenerator/data/models/meme.dart';
import 'package:memogenerator/data/models/template.dart';
import 'package:memogenerator/data/repositories/memes_repository.dart';
import 'package:memogenerator/data/repositories/templates_repository.dart';
import 'package:memogenerator/domain/interactors/pick_image_interactor.dart';
import 'package:memogenerator/domain/interactors/save_template_interactor.dart';
import 'package:memogenerator/presentation/create_meme/create_meme_page.dart';
import 'package:memogenerator/presentation/easter_egg/easter_egg_page.dart';
import 'package:memogenerator/presentation/main/models/meme_thumbnail.dart';
import 'package:memogenerator/presentation/main/models/template_full.dart';
import 'package:memogenerator/presentation/widgets/app_button.dart';
import 'package:memogenerator/resources/app_colors.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:reactive_store/reactive_store.dart';

class MainPageStore extends RStore {
  String newMemeImagePath = '';

  List<MemeThumbnail> get memesThumbnails => compose<List<MemeThumbnail>>(
        keyName: 'memesThumbnails',
        watch: () => [_docsDirAbsolutePath, _memes],
        getValue: () {
          if (_docsDirAbsolutePath.isEmpty || _memes.isEmpty) return [];
          return _memes.map(
            (meme) {
              final fullImagePath = path.join(
                _docsDirAbsolutePath,
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

  List<TemplateFull> get templatesThumbnails =>
      composeConverter2<Directory, List<Template>, List<TemplateFull>>(
        futureA: getApplicationDocumentsDirectory(),
        streamB: TemplatesRepository.getInstance().observeItems(),
        getValue: (docsDir, templates) {
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
        initialValue: const [],
        keyName: 'templatesThumbnails',
      );

  String get _docsDirAbsolutePath => composeConverter<Directory, String>(
        future: getApplicationDocumentsDirectory(),
        initialValue: '',
        getValue: (docsDir) => docsDir.absolute.path,
        keyName: '_docsDirAbsolutePath',
      );

  List<Meme> get _memes => composeStream<List<Meme>>(
        stream: MemesRepository.getInstance().observeItems(),
        initialData: const [],
        keyName: '_memes',
      );

  void addMeme() => _pickMemeImage(true);

  void addTemplate() => _pickMemeImage(false);

  void _pickMemeImage(bool savePath) {
    listenFuture<String?>(
      PickImageInteractor.getInstance().pickImage(),
      onData: (imagePath) {
        if (imagePath != null) {
          SaveTemplateInteractor.getInstance().saveTemplate(
            imagePath: imagePath,
          );
        }
        final newImagePath = imagePath ?? '';
        if (savePath && newImagePath != newMemeImagePath) {
          setStore(
            () => newMemeImagePath = newImagePath,
          );
        }
      },
    );
  }

  void deleteTemplate(final String templateId) {
    TemplatesRepository.getInstance().removeFromItemsById(templateId);
  }

  void deleteMeme(final String memeId) {
    MemesRepository.getInstance().removeFromItemsById(memeId);
  }

  @override
  MainPage get widget => super.widget as MainPage;

  static MainPageStore of(BuildContext context) {
    return RStoreWidget.store<MainPageStore>(context);
  }
}

class MainPage extends RStoreWidget<MainPageStore> {
  const MainPage({
    super.key,
  });

  @override
  Widget build(BuildContext context, MainPageStore store) {
    return const MainPageContent();
  }

  @override
  MainPageStore createRStore() => MainPageStore();
}

class MainPageContent extends StatefulWidget {
  const MainPageContent({Key? key}) : super(key: key);

  @override
  State<MainPageContent> createState() => _MainPageState();
}

class _MainPageState extends State<MainPageContent>
    with SingleTickerProviderStateMixin {
  late TabController tabController;
  int currentIndex = 0;

  @override
  void initState() {
    super.initState();
    tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: currentIndex,
    );
    tabController.addListener(() {
      if (currentIndex != tabController.index) {
        setState(() => currentIndex = tabController.index);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        final goBack = await showConfirmationExitDialog(context);
        return goBack ?? false;
      },
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          backgroundColor: AppColors.lemon,
          foregroundColor: AppColors.darkGrey,
          title: GestureDetector(
            onLongPress: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const EasterEggPage(),
                ),
              );
            },
            child: Text(
              "Мемогенератор",
              style: GoogleFonts.seymourOne(fontSize: 24),
            ),
          ),
          bottom: TabBar(
            controller: tabController,
            indicatorWeight: 3,
            indicatorColor: AppColors.fuchsia,
            labelColor: AppColors.darkGrey,
            labelStyle: const TextStyle(fontSize: 14),
            tabs: [
              Tab(text: "Созданные".toUpperCase()),
              Tab(text: "Шаблоны".toUpperCase()),
            ],
          ),
        ),
        floatingActionButton: AnimatedSwitcher(
          duration: tabController.animationDuration,
          child: currentIndex == 0
              ? const CreateMemeFab()
              : const CreateTemplateFab(),
          layoutBuilder: (currentChild, previousChildren) {
            return Stack(
              alignment: Alignment.centerRight,
              children: [
                ...previousChildren,
                if (currentChild != null) currentChild,
              ],
            );
          },
        ),
        backgroundColor: Colors.white,
        body: TabBarView(
          controller: tabController,
          children: const [
            SafeArea(child: CreatedMemesGrid()),
            SafeArea(child: TemplatesGrid()),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    tabController.dispose();
    super.dispose();
  }

  Future<bool?> showConfirmationExitDialog(BuildContext context) {
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          actionsPadding: const EdgeInsets.symmetric(horizontal: 16),
          title: const Text("Точно хотите выйти?"),
          content: const Text("Мемы сами себя не сделают"),
          actions: [
            AppButton(
              onTap: () => Navigator.of(context).pop(false),
              text: "Остаться",
              color: AppColors.darkGrey,
            ),
            AppButton(
              onTap: () => Navigator.of(context).pop(true),
              text: "Выйти",
              color: AppColors.fuchsia,
            ),
          ],
        );
      },
    );
  }
}

class CreateMemeFab extends StatelessWidget {
  const CreateMemeFab({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final store = MainPageStore.of(context);
    return RStoreStringListener<MainPageStore>(
      store: store,
      watch: (store) => store.newMemeImagePath,
      onNotEmpty: (context, imagePath) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => CreateMemePage(
              selectedMemePath: imagePath,
            ),
          ),
        );
      },
      reset: (store) => store.newMemeImagePath = '',
      child: FloatingActionButton.extended(
        onPressed: () => store.addMeme(),
        backgroundColor: AppColors.fuchsia,
        label: const Text("Мем"),
        icon: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class CreateTemplateFab extends StatelessWidget {
  const CreateTemplateFab({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final store = MainPageStore.of(context);
    return FloatingActionButton.extended(
      onPressed: () => store.addTemplate(),
      backgroundColor: AppColors.fuchsia,
      label: const Text("Шаблон"),
      icon: const Icon(Icons.add, color: Colors.white),
    );
  }
}

class CreatedMemesGrid extends StatelessWidget {
  const CreatedMemesGrid({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return RStoreValueBuilder<MainPageStore, List<MemeThumbnail>>(
      watch: (store) => store.memesThumbnails,
      builder: (context, memes) {
        return GridView.extent(
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          maxCrossAxisExtent: 180,
          children: memes.map((item) {
            return MemeGridItem(memeThumbnail: item);
          }).toList(),
        );
      },
    );
  }
}

class MemeGridItem extends StatelessWidget {
  const MemeGridItem({
    Key? key,
    required this.memeThumbnail,
  }) : super(key: key);

  final MemeThumbnail memeThumbnail;

  @override
  Widget build(BuildContext context) {
    final store = MainPageStore.of(context);
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => CreateMemePage(id: memeThumbnail.memeId),
        ),
      ),
      child: Stack(
        children: [
          Container(
            alignment: Alignment.centerLeft,
            decoration: BoxDecoration(
              border: Border.all(
                color: AppColors.darkGrey,
                width: 1,
              ),
            ),
            child: Image.file(
              File(memeThumbnail.fullImageUrl),
              errorBuilder: (context, error, stackTrace) =>
                  Text(memeThumbnail.memeId),
            ),
          ),
          Align(
            alignment: Alignment.bottomRight,
            child: GestureDetector(
              onTap: () async {
                final delete = await showConfirmationDeleteDialog(context);
                if (delete == null || delete == false) return;
                store.deleteMeme(memeThumbnail.memeId);
              },
              child: Container(
                margin: const EdgeInsets.all(4),
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.darkGrey38,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.delete_outline,
                  size: 24,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<bool?> showConfirmationDeleteDialog(BuildContext context) {
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          actionsPadding: const EdgeInsets.symmetric(horizontal: 16),
          title: const Text("Удалить мем?"),
          content: const Text("Выбранный мем будет удалён навсегда"),
          actions: [
            AppButton(
              onTap: () => Navigator.of(context).pop(false),
              text: "Отмена",
              color: AppColors.darkGrey,
            ),
            AppButton(
              onTap: () => Navigator.of(context).pop(true),
              text: "Удалить",
              color: AppColors.fuchsia,
            ),
          ],
        );
      },
    );
  }
}

class TemplatesGrid extends StatelessWidget {
  const TemplatesGrid({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return RStoreValueBuilder<MainPageStore, List<TemplateFull>>(
      watch: (store) => store.templatesThumbnails,
      builder: (context, templates) {
        return GridView.extent(
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          maxCrossAxisExtent: 180,
          children: templates.map((template) {
            return TemplateGridItem(template: template);
          }).toList(),
        );
      },
    );
  }
}

class TemplateGridItem extends StatelessWidget {
  const TemplateGridItem({
    Key? key,
    required this.template,
  }) : super(key: key);

  final TemplateFull template;

  @override
  Widget build(BuildContext context) {
    final store = MainPageStore.of(context);
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => CreateMemePage(
              selectedMemePath: template.fullImagePath,
            ),
          ),
        );
      },
      child: Stack(
        children: [
          Container(
            alignment: Alignment.centerLeft,
            decoration: BoxDecoration(
              border: Border.all(
                color: AppColors.darkGrey,
                width: 1,
              ),
            ),
            child: Image.file(
              File(template.fullImagePath),
              errorBuilder: (context, error, stackTrace) => Text(template.id),
            ),
          ),
          Align(
            alignment: Alignment.bottomRight,
            child: GestureDetector(
              onTap: () async {
                final delete = await showConfirmationDeleteDialog(context);
                if (delete == null || delete == false) return;
                store.deleteTemplate(template.id);
              },
              child: Container(
                margin: const EdgeInsets.all(4),
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.darkGrey38,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.delete_outline,
                  size: 24,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<bool?> showConfirmationDeleteDialog(BuildContext context) {
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          actionsPadding: const EdgeInsets.symmetric(horizontal: 16),
          title: const Text("Удалить шаблон?"),
          content: const Text("Выбранный шаблон будет удалён навсегда"),
          actions: [
            AppButton(
              onTap: () => Navigator.of(context).pop(false),
              text: "Отмена",
              color: AppColors.darkGrey,
            ),
            AppButton(
              onTap: () => Navigator.of(context).pop(true),
              text: "Удалить",
              color: AppColors.fuchsia,
            ),
          ],
        );
      },
    );
  }
}
