import 'dart:async';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:memogenerator/data/models/meme.dart';
import 'package:memogenerator/data/models/position.dart';
import 'package:memogenerator/data/models/text_with_position.dart';
import 'package:memogenerator/data/repositories/memes_repository.dart';
import 'package:memogenerator/domain/interactors/save_meme_interactor.dart';
import 'package:memogenerator/domain/interactors/screenshot_interactor.dart';
import 'package:memogenerator/presentation/create_meme/font_settings_bottom_sheet.dart';
import 'package:memogenerator/presentation/create_meme/meme_text_on_canvas.dart';
import 'package:memogenerator/presentation/create_meme/models/meme_text.dart';
import 'package:memogenerator/presentation/create_meme/models/meme_text_offset.dart';
import 'package:memogenerator/presentation/create_meme/models/meme_text_with_offset.dart';
import 'package:memogenerator/presentation/create_meme/models/meme_text_with_selection.dart';
import 'package:memogenerator/presentation/widgets/app_button.dart';
import 'package:memogenerator/resources/app_colors.dart';
import 'package:path_provider/path_provider.dart';
import 'package:reactive_store/reactive_store.dart';
import 'package:rxdart/rxdart.dart';
import 'package:screenshot/screenshot.dart';
import 'package:uuid/uuid.dart';

class CreateMemePageStore extends RStore {
  static const _subscribeIdLoadMemeFromRepository = 1;
  static const _subscribeShareMeme = 2;

  final memeTextsSubject = BehaviorSubject<List<MemeText>>.seeded(<MemeText>[]);
  final selectedMemeTextSubject = BehaviorSubject<MemeText?>.seeded(null);
  final memeTextOffsetsSubject =
      BehaviorSubject<List<MemeTextOffset>>.seeded(<MemeTextOffset>[]);
  final newMemeTextOffsetSubject =
      BehaviorSubject<MemeTextOffset?>.seeded(null);
  final screenshotControllerSubject =
      BehaviorSubject<ScreenshotController>.seeded(ScreenshotController());

  StreamSubscription<MemeTextOffset?>? newMemeTextOffsetSubscription;
  StreamSubscription<bool>? saveMemeSubscription;

  final String _id;
  bool _changed = true;
  String memePath;

  CreateMemePageStore({
    final String? id,
    final String? selectedMemePath,
  })  : _id = id ?? const Uuid().v4(),
        memePath = selectedMemePath ?? '' {
    if (kDebugMode) {
      print('Got id: $id, memePath: $selectedMemePath');
    }
    _subscribeToNewMemeTextOffset();
    if (id != null) {
      // загружаем данные из сторы
      _loadMemeFromRepository();
    }
  }

  void _loadMemeFromRepository() {
    listenFuture<Meme?>(
      MemesRepository.getInstance().getItemById(_id),
      id: _subscribeIdLoadMemeFromRepository,
      onData: (meme) {
        if (meme != null) {
          final memeText = meme.texts
              .map(
                (textWithPosition) =>
                    MemeText.createFromTextWithPosition(textWithPosition),
              )
              .toList();
          final memeTextOffsets = meme.texts
              .map(
                (textWithPosition) => MemeTextOffset(
                  id: textWithPosition.id,
                  offset: Offset(
                    textWithPosition.position.left,
                    textWithPosition.position.top,
                  ),
                ),
              )
              .toList();
          memeTextsSubject.add(memeText);
          memeTextOffsetsSubject.add(memeTextOffsets);
          if (meme.memePath != null) {
            getApplicationDocumentsDirectory().then((docsDirectory) {
              final onlyImageName =
                  meme.memePath!.split(Platform.pathSeparator).last;
              final fullImagePath =
                  "${docsDirectory.absolute.path}${Platform.pathSeparator}${SaveMemeInteractor.memesPathName}${Platform.pathSeparator}$onlyImageName";
              setStore(() => memePath = fullImagePath);
            });
          }
          _changed = false;
        }
      },
      onError: (error, stackTrace) {
        if (kDebugMode) {
          print("Error in _loadMemeFromRepository: $error, $stackTrace");
        }
      },
    );
  }

  bool isNeedSave() => _changed;

  void changeFontSettings(
    final String textId,
    final Color color,
    final double fontSize,
    final FontWeight fontWeight,
  ) {
    final copiedList = [...memeTextsSubject.value];
    int index = copiedList.indexWhere((memeText) => memeText.id == textId);
    if (index != -1) {
      final oldMemeText = copiedList[index];
      copiedList.removeAt(index);
      copiedList.insert(
        index,
        oldMemeText.copyWithChangedFontSettings(
          color,
          fontSize,
          fontWeight,
        ),
      );
      memeTextsSubject.add(copiedList);
      _changed = true;
    }
  }

  void shareMeme() {
    listenFuture<void>(
      ScreenshotInteractor.getInstance()
          .shareScreenshot(screenshotControllerSubject.value),
      id: _subscribeShareMeme,
      onData: (_) {},
      onError: (error, stackTrace) {
        if (kDebugMode) {
          print("Error in shareMemeSubscription: $error, $stackTrace");
        }
      },
    );
  }

  void saveMeme() {
    final memeTexts = memeTextsSubject.value;
    final memeTextsOffsets = memeTextOffsetsSubject.value;
    final texts = memeTexts.map((memeText) {
      final memeTextPosition = memeTextsOffsets.firstWhereOrNull(
          (memeTextsOffset) => memeTextsOffset.id == memeText.id);
      final position = Position(
        top: memeTextPosition?.offset.dy ?? 0,
        left: memeTextPosition?.offset.dx ?? 0,
      );
      return TextWithPosition(
        id: memeText.id,
        text: memeText.text,
        position: position,
        fontSize: memeText.fontSize,
        fontWeight: memeText.fontWeight,
        color: memeText.color,
      );
    }).toList();
    saveMemeSubscription?.cancel();
    saveMemeSubscription = SaveMemeInteractor.getInstance()
        .saveMeme(
          id: _id,
          screenshotController: screenshotControllerSubject.value,
          textWithPositions: texts,
          imagePath: memePath,
        )
        .asStream()
        .listen(
      (saved) {
        _changed = false;
        if (kDebugMode) {
          print("Meme saved: $saved");
        }
      },
      onError: (error, stackTrace) {
        if (kDebugMode) {
          print("Error in saveMemeSubscription: $error, $stackTrace");
        }
      },
    );
  }

  void _subscribeToNewMemeTextOffset() {
    newMemeTextOffsetSubscription = newMemeTextOffsetSubject
        .debounceTime(const Duration(milliseconds: 300))
        .listen(
      (value) {
        if (value != null) _changeMemeTextOffsetInternal(value);
      },
      onError: (error, stackTrace) {
        if (kDebugMode) {
          print("Error in newMemeTextOffsetSubscription: $error, $stackTrace");
        }
      },
    );
  }

  void changeMemeTextOffset(final String id, final Offset offset) {
    newMemeTextOffsetSubject.add(MemeTextOffset(id: id, offset: offset));
    _changed = true;
  }

  void _changeMemeTextOffsetInternal(final MemeTextOffset newMemeTextOffset) {
    final copiedMemeTextOffset = [...memeTextOffsetsSubject.value];
    final currentMemeTextOffset = copiedMemeTextOffset.firstWhereOrNull(
        (memeTextOffset) => memeTextOffset.id == newMemeTextOffset.id);
    if (currentMemeTextOffset != null) {
      copiedMemeTextOffset.remove(currentMemeTextOffset);
    }
    copiedMemeTextOffset.add(newMemeTextOffset);
    memeTextOffsetsSubject.add(copiedMemeTextOffset);
  }

  void addNewText() {
    final newMemeText = MemeText.create();
    memeTextsSubject.add([...memeTextsSubject.value, newMemeText]);
    selectedMemeTextSubject.add(newMemeText);
    _changed = true;
  }

  void changeMemText(final String id, final String text) {
    final copiedList = [...memeTextsSubject.value];
    int index = copiedList.indexWhere((memeText) => memeText.id == id);
    if (index != -1) {
      final oldMemeText = copiedList[index];
      copiedList.removeAt(index);
      copiedList.insert(
        index,
        oldMemeText.copyWithChangedText(text),
      );
      memeTextsSubject.add(copiedList);
      _changed = true;
    }
  }

  void deleteMemeText(final String textId) {
    final copiedList = [...memeTextsSubject.value];
    int index = copiedList.indexWhere((memeText) => memeText.id == textId);
    if (index != -1) {
      if (selectedMemeTextSubject.value != null &&
          selectedMemeTextSubject.value!.id == textId) {
        deselectMemText();
      }
      copiedList.removeAt(index);
      memeTextsSubject.add(copiedList);
      _changed = true;
    }
  }

  void selectMemText(final String id) {
    final foundMemText =
        memeTextsSubject.value.firstWhereOrNull((element) => element.id == id);
    selectedMemeTextSubject.add(foundMemText);
  }

  void deselectMemText() {
    selectedMemeTextSubject.add(null);
  }

  Stream<List<MemeText>> observeMemeTexts() =>
      memeTextsSubject.distinct((prev, next) => listEquals(prev, next));

  Stream<List<MemeTextWithOffset>> observeMemeTextWhitOffsets() =>
      Rx.combineLatest2<List<MemeText>, List<MemeTextOffset>,
              List<MemeTextWithOffset>>(
          observeMemeTexts(), memeTextOffsetsSubject.distinct(),
          (memeTexts, memeTextsOffsets) {
        return memeTexts.map((memeText) {
          final memeTextsOffset = memeTextsOffsets
              .firstWhereOrNull((element) => element.id == memeText.id);
          return MemeTextWithOffset(
              memeText: memeText, offset: memeTextsOffset?.offset);
        }).toList();
      }).distinct((prev, next) => listEquals(prev, next));

  Stream<MemeText?> observeSelectedMemText() =>
      selectedMemeTextSubject.distinct();

  Stream<ScreenshotController> observeScreenshotController() =>
      screenshotControllerSubject.distinct();

  Stream<List<MemeTextWithSelection>> observeMemeTextsWithSelection() {
    return Rx.combineLatest2<List<MemeText>, MemeText?,
        List<MemeTextWithSelection>>(
      observeMemeTexts(),
      observeSelectedMemText(),
      (memTexts, selectedMem) => memTexts
          .map(
            (memeText) => MemeTextWithSelection(
              memeText: memeText,
              selected: memeText.id == selectedMem?.id,
            ),
          )
          .toList(),
    );
  }

  @override
  void dispose() {
    super.dispose();
    memeTextsSubject.close();
    selectedMemeTextSubject.close();
    memeTextOffsetsSubject.close();
    newMemeTextOffsetSubject.close();
    screenshotControllerSubject.close();

    newMemeTextOffsetSubscription?.cancel();
    saveMemeSubscription?.cancel();
  }

  @override
  CreateMemePage get widget => super.widget as CreateMemePage;

  static CreateMemePageStore of(BuildContext context) {
    return RStoreWidget.store<CreateMemePageStore>(context);
  }
}

class CreateMemePage extends RStoreWidget<CreateMemePageStore> {
  final String? id;
  final String? selectedMemePath;

  const CreateMemePage({
    super.key,
    this.id,
    this.selectedMemePath,
  });

  @override
  Widget build(BuildContext context, CreateMemePageStore store) {
    return WillPopScope(
      onWillPop: () async {
        if (store.isNeedSave()) {
          final goBack = await showConfirmationExitDialog(context);
          return goBack ?? false;
        }
        return true;
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          backgroundColor: AppColors.lemon,
          foregroundColor: AppColors.darkGrey,
          title: const Text("Создаём мем"),
          bottom: const EditTextBar(),
          actions: [
            AnimatedIconButton(
              onTap: () => store.shareMeme(),
              icon: Icons.share,
            ),
            AnimatedIconButton(
              onTap: () => store.saveMeme(),
              icon: Icons.save,
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
  CreateMemePageStore createRStore() => CreateMemePageStore(
        id: id,
        selectedMemePath: selectedMemePath,
      );

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

class AnimatedIconButton extends StatefulWidget {
  final VoidCallback onTap;
  final IconData icon;

  const AnimatedIconButton({
    Key? key,
    required this.onTap,
    required this.icon,
  }) : super(key: key);

  @override
  State<AnimatedIconButton> createState() => _AnimatedIconButtonState();
}

class _AnimatedIconButtonState extends State<AnimatedIconButton> {
  double scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        setState(() => scale = 1.5);
        widget.onTap();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: AnimatedScale(
          duration: const Duration(milliseconds: 150),
          scale: scale,
          onEnd: () => setState(() => scale = 1.0),
          curve: Curves.bounceInOut,
          child: Icon(
            widget.icon,
            color: AppColors.darkGrey,
            size: 24,
          ),
        ),
      ),
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
    final store = CreateMemePageStore.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      child: StreamBuilder<MemeText?>(
          stream: store.observeSelectedMemText(),
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
                  store.changeMemText(selectedMemeText.id, text);
                }
              },
              onEditingComplete: () => store.deselectMemText(),
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
    final store = CreateMemePageStore.of(context);
    return Container(
      color: Colors.white,
      child: StreamBuilder<List<MemeTextWithSelection>>(
          initialData: const <MemeTextWithSelection>[],
          stream: store.observeMemeTextsWithSelection(),
          builder: (context, snapshot) {
            final items = snapshot.hasData
                ? snapshot.data!
                : const <MemeTextWithSelection>[];
            return ListView.separated(
                itemCount: items.length + 1,
                separatorBuilder: (BuildContext context, int index) {
                  if (index == 0) return const SizedBox.shrink();
                  return Container(
                    height: 1,
                    margin: const EdgeInsets.only(left: 16),
                    color: AppColors.darkGrey,
                  );
                },
                itemBuilder: (BuildContext context, int index) {
                  if (index == 0) {
                    return Padding(
                      padding: const EdgeInsets.all(12),
                      child: Center(
                        child: AppButton(
                          onTap: () => store.addNewText(),
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

class BottomMemeText extends StatelessWidget {
  final MemeTextWithSelection item;

  const BottomMemeText({
    super.key,
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    final store = CreateMemePageStore.of(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => store.selectMemText(item.memeText.id),
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
            BottomMemeTextAction(
              iconData: Icons.font_download_outlined,
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
                      return FontSettingBottomSheet(
                          memeText: item.memeText,
                          onChangeFontSettings: (
                            Color color,
                            double fontSize,
                            FontWeight fontWeight,
                          ) {
                            store.changeFontSettings(
                              item.memeText.id,
                              color,
                              fontSize,
                              fontWeight,
                            );
                          });
                    });
              },
            ),
            BottomMemeTextAction(
              iconData: Icons.delete_forever_outlined,
              onTap: () => store.deleteMemeText(item.memeText.id),
            ),
            const SizedBox(width: 4),
          ],
        ),
      ),
    );
  }
}

class BottomMemeTextAction extends StatelessWidget {
  final IconData iconData;
  final VoidCallback onTap;

  const BottomMemeTextAction({
    super.key,
    required this.iconData,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Icon(iconData),
      ),
    );
  }
}

class MemeCanvasWidget extends StatelessWidget {
  const MemeCanvasWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final store = CreateMemePageStore.of(context);
    return Container(
      padding: const EdgeInsets.all(8),
      color: AppColors.darkGrey38,
      alignment: Alignment.topCenter,
      child: AspectRatio(
        aspectRatio: 1.0,
        child: GestureDetector(
          onTap: () => store.deselectMemText(),
          child: StreamBuilder<ScreenshotController>(
            stream: store.observeScreenshotController(),
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
  const MemeTexts({super.key});

  @override
  Widget build(BuildContext context) {
    final store = CreateMemePageStore.of(context);
    return StreamBuilder<List<MemeTextWithOffset>>(
      initialData: const [],
      stream: store.observeMemeTextWhitOffsets(),
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
              }).toList(),
            );
          },
        );
      },
    );
  }
}

class BackgroundImage extends StatelessWidget {
  const BackgroundImage({super.key});

  @override
  Widget build(BuildContext context) {
    return RStoreContextValueBuilder<CreateMemePageStore, String>(
      watch: (store) => store.memePath,
      builder: (context, path, _) {
        if (path.isEmpty) {
          return Container(
            color: Colors.white,
          );
        }
        return Image.file(File(path));
      },
    );
  }
}

class DraggableMemeText extends StatefulWidget {
  final MemeTextWithOffset memeTextWithOffset;
  final BoxConstraints parentConstraints;

  const DraggableMemeText({
    super.key,
    required this.memeTextWithOffset,
    required this.parentConstraints,
  });

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
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
        final store = CreateMemePageStore.of(context);
        store.changeMemeTextOffset(
          widget.memeTextWithOffset.memeText.id,
          Offset(left, top),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = CreateMemePageStore.of(context);
    return Positioned(
      top: top,
      left: left,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanUpdate: (details) {
          store.selectMemText(widget.memeTextWithOffset.memeText.id);
          setState(() {
            left = calculateLeft(details);
            top = calculateTop(details);
            store.changeMemeTextOffset(
              widget.memeTextWithOffset.memeText.id,
              Offset(left, top),
            );
          });
        },
        onTap: () => store.selectMemText(widget.memeTextWithOffset.memeText.id),
        child: StreamBuilder<MemeText?>(
            stream: store.observeSelectedMemText(),
            builder: (context, snapshot) {
              final selected =
                  widget.memeTextWithOffset.memeText.id == snapshot.data?.id;
              return MemeTextOnCanvas(
                text: widget.memeTextWithOffset.memeText.text,
                parentConstraints: widget.parentConstraints,
                padding: _padding,
                selected: selected,
                fontSize: widget.memeTextWithOffset.memeText.fontSize,
                fontWeight: widget.memeTextWithOffset.memeText.fontWeight,
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
