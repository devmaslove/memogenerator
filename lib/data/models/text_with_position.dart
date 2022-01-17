import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';
import 'package:memogenerator/data/models/position.dart';
import 'package:json_annotation/json_annotation.dart';

part 'text_with_position.g.dart';

@JsonSerializable()
class TextWithPosition extends Equatable {
  final String id;
  final String text;
  final Position position;
  final double? fontSize;
  @JsonKey(toJson: colorToJson, fromJson: colorFromJson)
  final Color? color;
  @JsonKey(toJson: fontWeightToJson, fromJson: fontWeightFromJson)
  final FontWeight? fontWeight;

  const TextWithPosition({
    required this.id,
    required this.text,
    required this.position,
    required this.fontSize,
    required this.fontWeight,
    required this.color,
  });

  factory TextWithPosition.fromJson(final Map<String, dynamic> json) =>
      _$TextWithPositionFromJson(json);

  Map<String, dynamic> toJson() => _$TextWithPositionToJson(this);

  @override
  List<Object?> get props => [id, text, position, fontSize, fontWeight, color];
}

String? colorToJson(final Color? color) {
  return color?.value.toRadixString(16);
}

Color? colorFromJson(final String? colorString) {
  if (colorString == null) return null;
  final intColor = int.tryParse(colorString, radix: 16);
  return intColor != null ? Color(intColor) : null;
}

int? fontWeightToJson(final FontWeight? fontWeight) {
  return fontWeight?.index;
}

FontWeight? fontWeightFromJson(final int? fontWeightIndex) {
  if (fontWeightIndex == null ||
      fontWeightIndex < 0 ||
      fontWeightIndex >= FontWeight.values.length) {
    return null;
  }
  return FontWeight.values[fontWeightIndex];
}
