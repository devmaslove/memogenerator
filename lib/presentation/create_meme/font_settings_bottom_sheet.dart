import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:memogenerator/presentation/create_meme/meme_text_on_canvas.dart';
import 'package:memogenerator/presentation/create_meme/models/meme_text.dart';
import 'package:memogenerator/resources/app_colors.dart';

class FontSettingsBottomSheet extends StatelessWidget {
  final MemeText memeText;

  const FontSettingsBottomSheet({
    Key? key,
    required this.memeText,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          const SizedBox(height: 8),
          Center(
            child: Container(
              height: 4,
              width: 64,
              decoration: BoxDecoration(
                color: AppColors.darkGrey38,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          MemeTextOnCanvas(
            text: memeText.text,
            parentConstraints: const BoxConstraints.expand(),
            padding: 8,
            selected: true,
          ),
          const SizedBox(height: 48),
          const FontSizeSlider(),
        ],
      ),
    );
  }
}

class FontSizeSlider extends StatefulWidget {
  const FontSizeSlider({
    Key? key,
  }) : super(key: key);

  @override
  State<FontSizeSlider> createState() => _FontSizeSliderState();
}

class _FontSizeSliderState extends State<FontSizeSlider> {
  double fontSize = 20;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(width: 16),
        const Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: Text(
            "Size:",
            style: TextStyle(
              color: AppColors.darkGrey,
              fontSize: 20,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
        Expanded(
          child: SliderTheme(
            data: SliderThemeData(
              activeTrackColor: AppColors.fuchsia,
              inactiveTrackColor: AppColors.fuchsia38,
              valueIndicatorShape: const PaddleSliderValueIndicatorShape(),
              thumbColor: AppColors.fuchsia,
              inactiveTickMarkColor: AppColors.fuchsia,
              valueIndicatorColor: AppColors.fuchsia,
            ),
            child: Slider(
              min: 16,
              max: 32,
              divisions: 10,
              label: fontSize.round().toString(),
              value: fontSize,
              onChanged: (double value) {
                setState(() => fontSize = value);
              },
            ),
          ),
        ),
        const SizedBox(width: 16),
      ],
    );
  }
}
