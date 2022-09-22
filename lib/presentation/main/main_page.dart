import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:memogenerator/presentation/create_meme/create_meme_page.dart';
import 'package:memogenerator/presentation/easter_egg/easter_egg_page.dart';
import 'package:memogenerator/presentation/main/main_bloc.dart';
import 'package:memogenerator/presentation/main/models/meme_thumbnail.dart';
import 'package:memogenerator/presentation/main/models/template_full.dart';
import 'package:memogenerator/presentation/widgets/app_button.dart';
import 'package:memogenerator/resources/app_colors.dart';
import 'package:provider/provider.dart';

class MainPage extends StatefulWidget {
  const MainPage({Key? key}) : super(key: key);

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage>
    with SingleTickerProviderStateMixin {
  late MainBloc bloc;
  late TabController tabController;
  int currentIndex = 0;

  @override
  void initState() {
    super.initState();
    bloc = MainBloc();
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
    return Provider.value(
      value: bloc,
      child: WillPopScope(
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
      ),
    );
  }

  @override
  void dispose() {
    bloc.dispose();
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
    final bloc = Provider.of<MainBloc>(context, listen: false);
    return FloatingActionButton.extended(
      onPressed: () async {
        final navigator = Navigator.of(context);
        final selectedMemePath = await bloc.selectMeme();
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
    final bloc = Provider.of<MainBloc>(context, listen: false);
    return FloatingActionButton.extended(
      onPressed: () async {
        await bloc.selectMeme();
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
    final bloc = Provider.of<MainBloc>(context, listen: false);
    return StreamBuilder<List<MemeThumbnail>>(
      stream: bloc.observeMemes(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }
        final items = snapshot.requireData;
        return GridView.extent(
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          maxCrossAxisExtent: 180,
          children: items.map((item) {
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
    final bloc = Provider.of<MainBloc>(context, listen: false);
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
                bloc.deleteMeme(memeThumbnail.memeId);
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
    final bloc = Provider.of<MainBloc>(context, listen: false);
    return StreamBuilder<List<TemplateFull>>(
      stream: bloc.observeTemplates(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }
        final templates = snapshot.requireData;
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
    final bloc = Provider.of<MainBloc>(context, listen: false);
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
                bloc.deleteTemplate(template.id);
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
