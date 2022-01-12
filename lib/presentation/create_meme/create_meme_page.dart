import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:memogenerator/presentation/create_meme/create_meme_bloc.dart';
import 'package:memogenerator/presentation/create_meme/models/meme_text.dart';
import 'package:memogenerator/presentation/create_meme/models/meme_text_with_offset.dart';
import 'package:memogenerator/presentation/create_meme/models/meme_text_with_selection.dart';
import 'package:memogenerator/resources/app_colors.dart';
import 'package:provider/provider.dart';

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
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          backgroundColor: AppColors.lemon,
          foregroundColor: AppColors.darkGrey,
          title: const Text("Создаём мем"),
          bottom: const EditTextBar(),
          actions: [
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
    );
  }

  @override
  void dispose() {
    bloc.dispose();
    super.dispose();
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
                    return const Padding(
                      padding: EdgeInsets.all(12),
                      child: AddNewMemeTextButton(),
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
        padding: const EdgeInsets.symmetric(horizontal: 16),
        height: 48,
        alignment: Alignment.centerLeft,
        color: item.selected ? AppColors.darkGrey16 : null,
        child: Text(
          item.memeText.text,
          style: const TextStyle(
            color: AppColors.darkGrey,
            fontSize: 16,
            fontWeight: FontWeight.w400,
          ),
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
          child: Stack(
            children: [
              StreamBuilder<String?>(
                  stream: bloc.observeMemePath(),
                  builder: (context, snapshot) {
                    final path = snapshot.data;
                    if (path == null) {
                      return Container(
                        color: Colors.white,
                      );
                    }
                    return Image.file(File(path));
                  }),
              StreamBuilder<List<MemeTextWithOffset>>(
                initialData: const [],
                stream: bloc.observeMemeTextWhitOffsets(),
                builder: (context, snapshot) {
                  final memeTextsWithOffsets = snapshot.hasData
                      ? snapshot.data!
                      : const <MemeTextWithOffset>[];
                  return LayoutBuilder(
                    builder:
                        (BuildContext context, BoxConstraints constraints) {
                      return Stack(
                          children:
                              memeTextsWithOffsets.map((memeTextWithOffset) {
                        return DraggableMemeText(
                          memeTextWithOffset: memeTextWithOffset,
                          parentConstraints: constraints,
                        );
                      }).toList());
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
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
          widget.memeTextWithOffset.id,
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
          bloc.selectMemText(widget.memeTextWithOffset.id);
          setState(() {
            left = calculateLeft(details);
            top = calculateTop(details);
            bloc.changeMemeTextOffset(
                widget.memeTextWithOffset.id, Offset(left, top));
          });
        },
        onTap: () => bloc.selectMemText(widget.memeTextWithOffset.id),
        child: StreamBuilder<MemeText?>(
            stream: bloc.observeSelectedMemText(),
            builder: (context, snapshot) {
              final selected =
                  widget.memeTextWithOffset.id == snapshot.data?.id;
              return MemeTextOnCanvas(
                text: widget.memeTextWithOffset.text,
                parentConstraints: widget.parentConstraints,
                padding: _padding,
                selected: selected,
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

class MemeTextOnCanvas extends StatelessWidget {
  const MemeTextOnCanvas({
    Key? key,
    required this.text,
    required this.parentConstraints,
    required this.padding,
    required this.selected,
  }) : super(key: key);

  final String text;
  final BoxConstraints parentConstraints;
  final double padding;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxWidth: parentConstraints.maxWidth,
        maxHeight: parentConstraints.maxHeight,
      ),
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: selected ? AppColors.darkGrey16 : null,
        border: Border.all(
            color: selected ? AppColors.fuchsia : Colors.transparent),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 24,
          color: Colors.black,
          height: 1.0,
        ),
      ),
    );
  }
}

class AddNewMemeTextButton extends StatelessWidget {
  const AddNewMemeTextButton({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bloc = Provider.of<CreateMemeBloc>(context, listen: false);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => bloc.addNewText(),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(4),
          // color: Colors.green,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.add, size: 24, color: AppColors.fuchsia),
              const SizedBox(width: 8),
              Text(
                "Добавить текст".toUpperCase(),
                style: GoogleFonts.roboto(
                  color: AppColors.fuchsia,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
