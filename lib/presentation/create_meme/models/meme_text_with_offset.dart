import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';
import 'package:memogenerator/presentation/create_meme/models/meme_text.dart';

class MemeTextWithOffset extends Equatable {
  final MemeText memeText;
  final Offset? offset;

  const MemeTextWithOffset({
    required this.memeText,
    required this.offset,
  });

  @override
  List<Object?> get props => [memeText, offset];
}
