import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';
import 'package:uuid/uuid.dart';
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

  Stream<List<MemTextWithSelection>> observeMemeTextsWithSelection() {
    return Rx.combineLatest2<List<MemeText>, MemeText?,
        List<MemTextWithSelection>>(
      observeMemeTexts(),
      observeSelectedMemText(),
      (memTexts, selectedMem) => memTexts
          .map(
            (memeText) => MemTextWithSelection(
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

class MemeText {
  final String id;
  final String text;

  MemeText({
    required this.id,
    required this.text,
  });

  factory MemeText.create() => MemeText(id: Uuid().v4(), text: "");

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MemeText &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          text == other.text;

  @override
  int get hashCode => id.hashCode ^ text.hashCode;

  @override
  String toString() {
    return 'MemeText{id: $id, text: $text}';
  }
}

class MemTextWithSelection {
  final MemeText memeText;
  final bool selected;

  MemTextWithSelection({
    required this.memeText,
    required this.selected,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MemTextWithSelection &&
          runtimeType == other.runtimeType &&
          memeText == other.memeText &&
          selected == other.selected;

  @override
  int get hashCode => memeText.hashCode ^ selected.hashCode;

  @override
  String toString() {
    return 'MemTextWithSelection{memeText: $memeText, selected: $selected}';
  }
}
