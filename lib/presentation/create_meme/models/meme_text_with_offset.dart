import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';

class MemeTextWithOffset extends Equatable {
  final String id;
  final String text;
  final Offset? offset;

  MemeTextWithOffset({
    required this.id,
    required this.text,
    required this.offset,
  });

  @override
  List<Object?> get props => [id, text, offset];
}
