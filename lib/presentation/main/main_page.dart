import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:memogenerator/data/models/meme.dart';
import 'package:memogenerator/data/models/template.dart';
import 'package:memogenerator/data/repositories/memes_repository.dart';
import 'package:memogenerator/data/repositories/templates_repository.dart';
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
  String _docsDirAbsolutePath = '';
  List<Meme> _memes = [];
  List<Template> _templates = [];

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

  List<TemplateFull> get templatesThumbnails => compose<List<TemplateFull>>(
        keyName: 'templatesThumbnails',
        watch: () => [_docsDirAbsolutePath, _templates],
        getValue: () {
          if (_docsDirAbsolutePath.isEmpty || _templates.isEmpty) return [];
          return _templates.map(
            (template) {
              final fullImagePath = path.join(
                _docsDirAbsolutePath,
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

  void initStore() {
    listenFuture<Directory>(
      getApplicationDocumentsDirectory(),
      id: 0,
      onData: (docsDir) => setStore(
        () => _docsDirAbsolutePath = docsDir.absolute.path,
      ),
    );
    listenStream<List<Meme>>(
      MemesRepository.getInstance().observeItems(),
      id: 1,
      onData: (memes) => setStore(
        () => _memes = [...memes],
      ),
    );
    listenStream<List<Template>>(
      TemplatesRepository.getInstance().observeItems(),
      id: 2,
      onData: (templates) => setStore(
        () => _templates = [...templates],
      ),
    );
  }

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
  MainPageStore createRStore() => MainPageStore()..initStore();
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
    return FloatingActionButton.extended(
      onPressed: () async {
        final navigator = Navigator.of(context);
        final selectedMemePath = await store.selectMeme();
        if (selectedMemePath == null) return;
        navigator.push(
          MaterialPageRoute(
            builder: (_) => CreateMemePage(
              selectedMemePath: selectedMemePath,
            ),
          ),
        );
      },
      backgroundColor: AppColors.fuchsia,
      label: const Text("Мем"),
      icon: const Icon(Icons.add, color: Colors.white),
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
      onPressed: () async {
        final navigator = Navigator.of(context);
        final selectedMemePath = await store.selectMeme();
        if (selectedMemePath == null) return;
        navigator.push(
          MaterialPageRoute(
            builder: (_) => CreateMemePage(
              selectedMemePath: selectedMemePath,
            ),
          ),
        );
      },
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
    return RStoreContextValueBuilder<MainPageStore, List<MemeThumbnail>>(
      watch: (store) => store.memesThumbnails,
      builder: (context, memes, _) {
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
    return RStoreContextValueBuilder<MainPageStore, List<TemplateFull>>(
      watch: (store) => store.templatesThumbnails,
      builder: (context, templates, _) {
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
