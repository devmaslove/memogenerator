import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:memogenerator/data/models/meme.dart';
import 'package:memogenerator/data/models/position.dart';
import 'package:memogenerator/data/models/text_with_position.dart';
import 'package:memogenerator/data/repositories/memes_repository.dart';
import 'package:memogenerator/domain/interactors/save_meme_interactor.dart';
import 'package:memogenerator/presentation/create_meme/models/meme_text.dart';
import 'package:memogenerator/presentation/create_meme/models/meme_text_offset.dart';
import 'package:memogenerator/presentation/create_meme/models/meme_text_with_offset.dart';
import 'package:memogenerator/presentation/create_meme/models/meme_text_with_selection.dart';
import 'package:rxdart/rxdart.dart';
import 'package:collection/collection.dart';
import 'package:uuid/uuid.dart';

class CreateMemeBloc {
  final memeTextsSubject = BehaviorSubject<List<MemeText>>.seeded(<MemeText>[]);
  final selectedMemeTextSubject = BehaviorSubject<MemeText?>.seeded(null);
  final memeTextOffsetsSubject =
      BehaviorSubject<List<MemeTextOffset>>.seeded(<MemeTextOffset>[]);
  final newMemeTextOffsetSubject =
      BehaviorSubject<MemeTextOffset?>.seeded(null);
  final memePathSubject = BehaviorSubject<String?>.seeded(null);

  StreamSubscription<MemeTextOffset?>? newMemeTextOffsetSubscription;
  StreamSubscription<bool>? saveMemeSubscription;
  StreamSubscription<Meme?>? existentMemeSubscription;

  final String id;

  CreateMemeBloc({
    final String? id,
    final String? selectedMemePath,
  }) : this.id = id ?? Uuid().v4() {
    print('Got id: ${this.id}');
    memePathSubject.add(selectedMemePath);
    _subscribeToNewMemeTextOffset();
    _subscribeToExistentMeme();
  }

  void _subscribeToExistentMeme() {
    existentMemeSubscription =
        MemesRepository.getInstance().getMeme(id).asStream().listen(
      (meme) {
        if (meme != null) {
          final memeText = meme.texts
              .map(
                (textWithPosition) => MemeText(
                  id: textWithPosition.id,
                  text: textWithPosition.text,
                ),
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
          memePathSubject.add(meme.memePath);
        }
      },
      onError: (error, stackTrace) =>
          print("Error in existentMemeSubscription: $error, $stackTrace"),
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
      );
    }).toList();
    saveMemeSubscription?.cancel();
    saveMemeSubscription = SaveMemeInteractor.getInstance()
        .saveMeme(
          id: id,
          textWithPositions: texts,
          imagePath: memePathSubject.value,
        )
        .asStream()
        .listen(
      (saved) {
        print("Meme saved: $saved");
      },
      onError: (error, stackTrace) =>
          print("Error in saveMemeSubscription: $error, $stackTrace"),
    );
  }

  void _subscribeToNewMemeTextOffset() {
    newMemeTextOffsetSubscription = newMemeTextOffsetSubject
        .debounceTime(const Duration(milliseconds: 300))
        .listen(
      (value) {
        if (value != null) _changeMemeTextOffsetInternal(value);
      },
      onError: (error, stackTrace) =>
          print("Error in newMemeTextOffsetSubscription: $error, $stackTrace"),
    );
  }

  void changeMemeTextOffset(final String id, final Offset offset) {
    newMemeTextOffsetSubject.add(MemeTextOffset(id: id, offset: offset));
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

  Stream<String?> observeMemePath() => memePathSubject.distinct();

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
              id: memeText.id,
              text: memeText.text,
              offset: memeTextsOffset?.offset);
        }).toList();
      }).distinct((prev, next) => listEquals(prev, next));

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
    memeTextOffsetsSubject.close();
    newMemeTextOffsetSubject.close();
    memePathSubject.close();

    newMemeTextOffsetSubscription?.cancel();
    saveMemeSubscription?.cancel();
    existentMemeSubscription?.cancel();
  }
}
