import 'package:equatable/equatable.dart';
import 'package:memogenerator/data/models/text_with_position.dart';
import 'package:json_annotation/json_annotation.dart';

part 'meme.g.dart';

@JsonSerializable()
class Meme extends Equatable {
  final String id;
  final List<TextWithPosition> texts;

  Meme({
    required this.id,
    required this.texts,
  });

  factory Meme.fromJson(final Map<String, dynamic> json) =>
      _$MemeFromJson(json);

  Map<String, dynamic> toJson() => _$MemeToJson(this);

  @override
  List<Object?> get props => [id, texts];
}
