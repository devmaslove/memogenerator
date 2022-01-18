import 'dart:io';

import 'package:flutter/material.dart';
import 'package:memogenerator/presentation/create_meme/create_meme_bloc.dart';
import 'package:memogenerator/presentation/create_meme/font_settings_bottom_sheet.dart';
import 'package:memogenerator/presentation/create_meme/meme_text_on_canvas.dart';
import 'package:memogenerator/presentation/create_meme/models/meme_text.dart';
import 'package:memogenerator/presentation/create_meme/models/meme_text_with_offset.dart';
import 'package:memogenerator/presentation/create_meme/models/meme_text_with_selection.dart';
import 'package:memogenerator/presentation/widgets/app_button.dart';
import 'package:memogenerator/resources/app_colors.dart';
import 'package:provider/provider.dart';
import 'package:screenshot/screenshot.dart';

class CreateMemePage extends StatefulWidget {
  final String? id;
  final String? selectedMemePath;

  const CreateMemePage({
    Key? key,
    this.id,
    this.selectedMemePath,
  }) : super(key: key);

  @override
  _CreateMemePageState createState() => _CreateMemePageState();
}

class _CreateMemePageState extends State<CreateMemePage> {
  late CreateMemeBloc bloc;

  @override
  void initState() {
    super.initState();
    bloc = CreateMemeBloc(
      id: widget.id,
      selectedMemePath: widget.selectedMemePath,
    );
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
          resizeToAvoidBottomInset: false,
          appBar: AppBar(
            backgroundColor: AppColors.lemon,
            foregroundColor: AppColors.darkGrey,
            title: const Text("Создаём мем"),
            bottom: const EditTextBar(),
            actions: [
              GestureDetector(
                onTap: () => bloc.shareMeme(),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Icon(
                    Icons.share,
                    color: AppColors.darkGrey,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => bloc.saveMeme(),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Icon(
                    Icons.save,
                    color: AppColors.darkGrey,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.white,
          body: const SafeArea(
            child: CreateMemePageContent(),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    bloc.dispose();
    super.dispose();
  }

  Future<bool?> showConfirmationExitDialog(BuildContext context) {
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          actionsPadding: const EdgeInsets.symmetric(horizontal: 16),
          title: const Text("Хотите выйти?"),
          content: const Text("Вы потеряете несохраненные изменения"),
          actions: [
            AppButton(
              onTap: () => Navigator.of(context).pop(false),
              text: "Отмена",
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

class EditTextBar extends StatefulWidget implements PreferredSizeWidget {
  const EditTextBar({Key? key}) : super(key: key);

  @override
  Size get preferredSize => const Size.fromHeight(68);

  @override
  State<EditTextBar> createState() => _EditTextBarState();
}

class _EditTextBarState extends State<EditTextBar> {
  final controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final bloc = Provider.of<CreateMemeBloc>(context, listen: false);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      child: StreamBuilder<MemeText?>(
          stream: bloc.observeSelectedMemText(),
          builder: (context, snapshot) {
            final MemeText? selectedMemeText = snapshot.data;
            if (selectedMemeText?.text != controller.text) {
              final newText = selectedMemeText?.text ?? "";
              controller.text = newText;
              controller.selection =
                  TextSelection.collapsed(offset: newText.length);
            }
            bool isHaveSelectedText = selectedMemeText != null;
            return TextField(
              enabled: isHaveSelectedText,
              cursorColor: AppColors.fuchsia,
              controller: controller,
              onChanged: (text) {
                if (isHaveSelectedText) {
                  bloc.changeMemText(selectedMemeText.id, text);
                }
              },
              onEditingComplete: () => bloc.deselectMemText(),
              decoration: InputDecoration(
                hintText: isHaveSelectedText ? "Ввести текст" : null,
                hintStyle: TextStyle(
                  fontSize: 16,
                  color: AppColors.darkGrey38,
                ),
                filled: true,
                fillColor: isHaveSelectedText
                    ? AppColors.fuchsia16
                    : AppColors.darkGrey6,
                border: UnderlineInputBorder(
                  borderSide: BorderSide(color: AppColors.fuchsia38),
                ),
                disabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: AppColors.darkGrey38),
                ),
                focusedBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: AppColors.fuchsia, width: 2),
                ),
              ),
            );
          }),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}

class CreateMemePageContent extends StatelessWidget {
  const CreateMemePageContent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Expanded(
          flex: 2,
          child: MemeCanvasWidget(),
        ),
        Container(
          color: AppColors.darkGrey,
          height: 1,
        ),
        const Expanded(
          flex: 1,
          child: BottomList(),
        ),
      ],
    );
  }
}

class BottomList extends StatelessWidget {
  const BottomList({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bloc = Provider.of<CreateMemeBloc>(context, listen: false);
    return Container(
      color: Colors.white,
      child: StreamBuilder<List<MemeTextWithSelection>>(
          initialData: const <MemeTextWithSelection>[],
          stream: bloc.observeMemeTextsWithSelection(),
          builder: (context, snapshot) {
            final items = snapshot.hasData
                ? snapshot.data!
                : const <MemeTextWithSelection>[];
            return ListView.separated(
                itemCount: items.length + 1,
                separatorBuilder: (BuildContext context, int index) {
                  if (index == 0) return const SizedBox.shrink();
                  return const BottomSeparator();
                },
                itemBuilder: (BuildContext context, int index) {
                  if (index == 0) {
                    return Padding(
                      padding: const EdgeInsets.all(12),
                      child: Center(
                        child: AppButton(
                          onTap: () => bloc.addNewText(),
                          text: "Добавить текст",
                          color: AppColors.fuchsia,
                          icon: Icons.add,
                        ),
                      ),
                    );
                  }
                  MemeTextWithSelection item = items[index - 1];
                  return BottomMemeText(item: item);
                });
          }),
    );
  }
}

class BottomSeparator extends StatelessWidget {
  const BottomSeparator({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      margin: const EdgeInsets.only(left: 16),
      color: AppColors.darkGrey,
    );
  }
}

class BottomMemeText extends StatelessWidget {
  const BottomMemeText({
    Key? key,
    required this.item,
  }) : super(key: key);

  final MemeTextWithSelection item;

  @override
  Widget build(BuildContext context) {
    final bloc = Provider.of<CreateMemeBloc>(context, listen: false);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => bloc.selectMemText(item.memeText.id),
      child: Container(
        height: 48,
        alignment: Alignment.centerLeft,
        color: item.selected ? AppColors.darkGrey16 : null,
        child: Row(
          children: [
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                item.memeText.text,
                style: const TextStyle(
                  color: AppColors.darkGrey,
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            const SizedBox(width: 4),
            GestureDetector(
              onTap: () {
                showModalBottomSheet(
                    context: context,
                    backgroundColor: Colors.white,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                    ),
                    builder: (context) {
                      return Provider.value(
                        value: bloc,
                        child: FontSettingBottomSheet(memeText: item.memeText),
                      );
                    });
              },
              child: const Padding(
                padding: EdgeInsets.all(8),
                child: Icon(Icons.font_download_outlined),
              ),
            ),
            GestureDetector(
              onTap: () {
                bloc.deleteMemText(item.memeText.id);
              },
              child: const Padding(
                padding: EdgeInsets.all(8),
                child: Icon(Icons.delete_forever_outlined),
              ),
            ),
            const SizedBox(width: 4),
          ],
        ),
      ),
    );
  }
}

class MemeCanvasWidget extends StatelessWidget {
  const MemeCanvasWidget({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bloc = Provider.of<CreateMemeBloc>(context, listen: false);
    return Container(
      padding: const EdgeInsets.all(8),
      color: AppColors.darkGrey38,
      alignment: Alignment.topCenter,
      child: AspectRatio(
        aspectRatio: 1.0,
        child: GestureDetector(
          onTap: () => bloc.deselectMemText(),
          child: StreamBuilder<ScreenshotController>(
            stream: bloc.observeScreenshotController(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox.shrink();
              return Screenshot(
                controller: snapshot.requireData,
                child: Stack(
                  children: const [
                    BackgroundImage(),
                    MemeTexts(),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class MemeTexts extends StatelessWidget {
  const MemeTexts({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bloc = Provider.of<CreateMemeBloc>(context, listen: false);
    return StreamBuilder<List<MemeTextWithOffset>>(
      initialData: const [],
      stream: bloc.observeMemeTextWhitOffsets(),
      builder: (context, snapshot) {
        final memeTextsWithOffsets =
            snapshot.hasData ? snapshot.data! : const <MemeTextWithOffset>[];
        return LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            return Stack(
                children: memeTextsWithOffsets.map((memeTextWithOffset) {
              return DraggableMemeText(
                key: ValueKey(memeTextWithOffset.memeText.id),
                memeTextWithOffset: memeTextWithOffset,
                parentConstraints: constraints,
              );
            }).toList());
          },
        );
      },
    );
  }
}

class BackgroundImage extends StatelessWidget {
  const BackgroundImage({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bloc = Provider.of<CreateMemeBloc>(context, listen: false);
    return StreamBuilder<String?>(
        stream: bloc.observeMemePath(),
        builder: (context, snapshot) {
          final path = snapshot.data;
          if (path == null) {
            return Container(
              color: Colors.white,
            );
          }
          return Image.file(File(path));
        });
  }
}

class DraggableMemeText extends StatefulWidget {
  final MemeTextWithOffset memeTextWithOffset;
  final BoxConstraints parentConstraints;

  const DraggableMemeText({
    Key? key,
    required this.memeTextWithOffset,
    required this.parentConstraints,
  }) : super(key: key);

  @override
  State<DraggableMemeText> createState() => _DraggableMemeTextState();
}

class _DraggableMemeTextState extends State<DraggableMemeText> {
  late double top;
  late double left;
  static const double _padding = 8;

  @override
  void initState() {
    super.initState();
    top = widget.memeTextWithOffset.offset?.dy ??
        widget.parentConstraints.maxHeight / 2;
    left = widget.memeTextWithOffset.offset?.dx ??
        widget.parentConstraints.maxWidth / 3;
    //
    if (widget.memeTextWithOffset.offset == null) {
      WidgetsBinding.instance?.addPostFrameCallback((timeStamp) {
        final bloc = Provider.of<CreateMemeBloc>(context, listen: false);
        bloc.changeMemeTextOffset(
          widget.memeTextWithOffset.memeText.id,
          Offset(left, top),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bloc = Provider.of<CreateMemeBloc>(context, listen: false);
    return Positioned(
      top: top,
      left: left,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanUpdate: (details) {
          bloc.selectMemText(widget.memeTextWithOffset.memeText.id);
          setState(() {
            left = calculateLeft(details);
            top = calculateTop(details);
            bloc.changeMemeTextOffset(
              widget.memeTextWithOffset.memeText.id,
              Offset(left, top),
            );
          });
        },
        onTap: () => bloc.selectMemText(widget.memeTextWithOffset.memeText.id),
        child: StreamBuilder<MemeText?>(
            stream: bloc.observeSelectedMemText(),
            builder: (context, snapshot) {
              final selected =
                  widget.memeTextWithOffset.memeText.id == snapshot.data?.id;
              return MemeTextOnCanvas(
                text: widget.memeTextWithOffset.memeText.text,
                parentConstraints: widget.parentConstraints,
                padding: _padding,
                selected: selected,
                fontSize: widget.memeTextWithOffset.memeText.fontSize,
                color: widget.memeTextWithOffset.memeText.color,
              );
            }),
      ),
    );
  }

  double calculateTop(DragUpdateDetails details) {
    final rawTop = top + details.delta.dy;
    if (rawTop < 0) return 0;
    if (rawTop > widget.parentConstraints.maxHeight - _padding * 2 - 24) {
      return widget.parentConstraints.maxHeight - _padding * 2 - 24;
    }
    return rawTop;
  }

  double calculateLeft(DragUpdateDetails details) {
    final rawLeft = left + details.delta.dx;
    if (rawLeft < 0) return 0;
    if (rawLeft > widget.parentConstraints.maxWidth - _padding * 2 - 24) {
      return widget.parentConstraints.maxWidth - _padding * 2 - 24;
    }
    return rawLeft;
  }
}
