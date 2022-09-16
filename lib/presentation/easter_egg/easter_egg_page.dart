import 'package:flutter/material.dart';
import 'package:memogenerator/resources/app_colors.dart';
import 'package:memogenerator/resources/app_images.dart';

class EasterEggPage extends StatelessWidget {
  const EasterEggPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.lemon,
        foregroundColor: AppColors.darkGrey,
      ),
      body: const RocketAnimationBody(),
    );
  }
}

class RocketAnimationBody extends StatefulWidget {
  const RocketAnimationBody({Key? key}) : super(key: key);

  @override
  State<RocketAnimationBody> createState() => _RocketAnimationBodyState();
}

class _RocketAnimationBodyState extends State<RocketAnimationBody> {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return DecoratedBox(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage(AppImages.starsPattern),
              repeat: ImageRepeat.repeat,
            ),
          ),
          child: Stack(
            children: [
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  width: double.infinity,
                  height: 100,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.elliptical(constraints.maxWidth, 200),
                    ),
                    color: Colors.green[700],
                  ),
                ),
              ),
              Align(
                alignment: const Alignment(0, 0.9),
                child: Image.asset(
                  AppImages.rocketWithoutFire,
                  height: 200,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
