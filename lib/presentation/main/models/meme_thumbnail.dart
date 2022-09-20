import 'package:memogenerator/data/models/meme.dart';

class MemeThumbnail extends Meme {
  final String memeId;
  final String fullImageUrl;

  MemeThumbnail({
    required this.memeId,
    required this.fullImageUrl,
  }) : super(id: '', texts: []);
}
