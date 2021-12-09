import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:memogenerator/blocs/create_meme_bloc.dart';
import 'package:memogenerator/resources/app_colors.dart';
import 'package:provider/provider.dart';

class CreateMemePage extends StatefulWidget {
  CreateMemePage({Key? key}) : super(key: key);

  @override
  _CreateMemePageState createState() => _CreateMemePageState();
}

class _CreateMemePageState extends State<CreateMemePage> {
  late CreateMemeBloc bloc;

  @override
  void initState() {
    super.initState();
    bloc = CreateMemeBloc();
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
          title: Text("Создаём мем"),
          bottom: EditTextBar(),
        ),
        backgroundColor: Colors.white,
        body: SafeArea(
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
            return TextField(
              enabled: selectedMemeText != null,
              controller: controller,
              onChanged: (text) {
                if (selectedMemeText != null) {
                  bloc.changeMemText(selectedMemeText.id, text);
                }
              },
              onEditingComplete: () => bloc.deselectMemText(),
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.darkGrey6,
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
        Expanded(
          flex: 1,
          child: Container(
            color: Colors.white,
            child: ListView(
              children: const [
                SizedBox(height: 12),
                AddNewMemeTextButton(),
              ],
            ),
          ),
        ),
      ],
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
          behavior: HitTestBehavior.opaque,
          onTap: () => bloc.deselectMemText(),
          child: Container(
            color: Colors.white,
            child: StreamBuilder<List<MemeText>>(
              initialData: const <MemeText>[],
              stream: bloc.observeMemeTexts(),
              builder: (context, snapshot) {
                final memeTexts =
                    snapshot.hasData ? snapshot.data! : const <MemeText>[];
                return LayoutBuilder(
                  builder: (BuildContext context, BoxConstraints constraints) {
                    return Stack(
                        children: memeTexts.map((memeText) {
                      return DraggableMemeText(
                        memeText: memeText,
                        parentConstraints: constraints,
                      );
                    }).toList());
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class DraggableMemeText extends StatefulWidget {
  final MemeText memeText;
  final BoxConstraints parentConstraints;

  const DraggableMemeText({
    Key? key,
    required this.memeText,
    required this.parentConstraints,
  }) : super(key: key);

  @override
  State<DraggableMemeText> createState() => _DraggableMemeTextState();
}

class _DraggableMemeTextState extends State<DraggableMemeText> {
  double top = 0;
  double left = 0;
  static const double _padding = 8;

  @override
  Widget build(BuildContext context) {
    final bloc = Provider.of<CreateMemeBloc>(context, listen: false);
    return Positioned(
      top: top,
      left: left,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanUpdate: (details) {
          setState(() {
            left = calculateLeft(details);
            top = calculateTop(details);
            bloc.selectMemText(widget.memeText.id);
          });
        },
        onTap: () => bloc.selectMemText(widget.memeText.id),
        child: Container(
          constraints: BoxConstraints(
            maxWidth: widget.parentConstraints.maxWidth,
            maxHeight: widget.parentConstraints.maxHeight,
          ),
          padding: const EdgeInsets.all(_padding),
          // color: AppColors.darkGrey6,
          child: Text(
            widget.memeText.text,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              color: Colors.black,
              height: 1.0,
            ),
          ),
        ),
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
      return widget.parentConstraints.maxWidth - _padding * 2 -24;
    }
    return rawLeft;
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
