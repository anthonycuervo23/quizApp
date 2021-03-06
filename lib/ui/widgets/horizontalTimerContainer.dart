import 'package:flutter/material.dart';
import 'package:quizappuic/ui/styles/colors.dart';

class HorizontalTimerContainer extends StatelessWidget {
  final AnimationController timerAnimationController;

  HorizontalTimerContainer({Key? key, required this.timerAnimationController})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          color: Theme.of(context).backgroundColor,
          height: 10.0,
          width: MediaQuery.of(context).size.width,
        ),
        AnimatedBuilder(
          animation: timerAnimationController,
          builder: (context, child) {
            return Container(
              color: pageBackgroundColor,
              height: 10.0,
              width: MediaQuery.of(context).size.width *
                  timerAnimationController.value,
            );
          },
        ),
      ],
    );
  }
}
