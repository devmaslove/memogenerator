import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:memogenerator/data/models/meme.dart';
import 'package:memogenerator/presentation/main/main_bloc.dart';
import 'package:memogenerator/presentation/create_meme/create_meme_page.dart';
import 'package:memogenerator/presentation/main/memes_with_docs_path.dart';
import 'package:memogenerator/resources/app_colors.dart';
import 'package:provider/provider.dart';

class MainPage extends StatefulWidget {
  MainPage({Key? key}) : super(key: key);

  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  late MainBloc bloc;

  @override
  void initState() {
    super.initState();
    bloc = MainBloc();
  }

  @override
  Widget build(BuildContext context) {
    return Provider.value(
      value: bloc,
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          backgroundColor: AppColors.lemon,
          foregroundColor: AppColors.darkGrey,
          title: Text(
            "Мемогенератор",
            style: GoogleFonts.seymourOne(fontSize: 24),
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () async {
            final selectedMemePath = await bloc.selectMeme();
            if (selectedMemePath == null) return;
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => CreateMemePage(
                  selectedMemePath: selectedMemePath,
                ),
              ),
            );
          },
          backgroundColor: AppColors.fuchsia,
          label: Text("Создать".toUpperCase()),
          icon: Icon(Icons.add, color: Colors.white),
        ),
        backgroundColor: Colors.white,
        body: const SafeArea(
          child: MainPageContent(),
        ),
      ),
    );
  }

  @override
  void dispose() {
    bloc.dispose();
    super.dispose();
  }
}

class MainPageContent extends StatelessWidget {
  const MainPageContent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bloc = Provider.of<MainBloc>(context, listen: false);
    return StreamBuilder<MemesWithDocsPath>(
        stream: bloc.observeMemesWithPath(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const SizedBox.shrink();
          }
          final items = snapshot.requireData.memes;
          final docsPath = snapshot.requireData.docsPath;
          return GridView.extent(
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            maxCrossAxisExtent: 180,
            children: items.map((item) {
              return GridItem(meme: item, docsPath: docsPath);
            }).toList(),
          );
        });
  }
}

class GridItem extends StatelessWidget {
  const GridItem({
    Key? key,
    required this.docsPath,
    required this.meme,
  }) : super(key: key);

  final String docsPath;
  final Meme meme;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => CreateMemePage(id: meme.id),
        ),
      ),
      child: Container(
        alignment: Alignment.centerLeft,
        decoration: BoxDecoration(
          border: Border.all(
            color: AppColors.darkGrey,
            width: 1,
          ),
        ),
        child: Image.file(
          File("$docsPath${Platform.pathSeparator}${meme.id}.png"),
          errorBuilder: (context, error, stackTrace) => Text(meme.id),
        ),
      ),
    );
  }
}
