import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppButton extends StatelessWidget {
  final VoidCallback onTap;
  final String text;
  final IconData? icon;
  final Color color;

  const AppButton({
    Key? key,
    required this.onTap,
    required this.text,
    this.icon,
    required this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(4),
          // color: Colors.green,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon!=null) Icon(icon, size: 24, color: color),
              if (icon!=null) const SizedBox(width: 8),
              Text(
                text.toUpperCase(),
                style: GoogleFonts.roboto(
                  color: color,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
