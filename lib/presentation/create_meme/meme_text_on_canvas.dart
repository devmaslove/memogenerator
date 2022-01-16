import 'package:flutter/material.dart';
import 'package:memogenerator/resources/app_colors.dart';

class MemeTextOnCanvas extends StatelessWidget {
  const MemeTextOnCanvas({
    Key? key,
    required this.text,
    required this.parentConstraints,
    required this.padding,
    required this.selected,
    required this.fontSize,
    required this.color,
  }) : super(key: key);

  final String text;
  final BoxConstraints parentConstraints;
  final double padding;
  final bool selected;
  final double fontSize;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxWidth: parentConstraints.maxWidth,
        maxHeight: parentConstraints.maxHeight,
      ),
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: selected ? AppColors.darkGrey16 : null,
        border: Border.all(
            color: selected ? AppColors.fuchsia : Colors.transparent),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: fontSize,
          color: color,
          height: 1.0,
        ),
      ),
    );
  }
}
