import 'package:flutter/foundation.dart';
import 'package:memogenerator/presentation/create_meme/models/meme_text.dart';
import 'package:memogenerator/presentation/create_meme/models/meme_text_with_selection.dart';
import 'package:rxdart/rxdart.dart';
import 'package:collection/collection.dart';

class CreateMemeBloc {
  final memeTextsSubject = BehaviorSubject<List<MemeText>>.seeded(<MemeText>[]);
  final selectedMemeTextSubject = BehaviorSubject<MemeText?>.seeded(null);

  void addNewText() {
    final newMemeText = MemeText.create();
    memeTextsSubject.add([...memeTextsSubject.value, newMemeText]);
    selectedMemeTextSubject.add(newMemeText);
  }

  void changeMemText(final String id, final String text) {
    final copiedList = [...memeTextsSubject.value];
    int index = copiedList.indexWhere((memeText) => memeText.id == id);
    if (index != -1) {
      copiedList.removeAt(index);
      copiedList.insert(index, MemeText(id: id, text: text));
      memeTextsSubject.add(copiedList);
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

  Stream<MemeText?> observeSelectedMemText() =>
      selectedMemeTextSubject.distinct();

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

  void dispose() {
    memeTextsSubject.close();
    selectedMemeTextSubject.close();
  }
}
