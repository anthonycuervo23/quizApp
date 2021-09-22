import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quizappuic/app/routes.dart';
import 'package:quizappuic/features/battleRoom/cubits/battleRoomCubit.dart';
import 'package:quizappuic/features/localization/appLocalizationCubit.dart';
import 'package:quizappuic/features/quiz/models/question.dart';
import 'package:quizappuic/features/quiz/models/quizType.dart';
import 'package:quizappuic/features/systemConfig/cubits/systemConfigCubit.dart';

import 'package:quizappuic/ui/widgets/errorMessageDialog.dart';
import 'package:quizappuic/utils/constants.dart';
import 'package:intl/intl.dart';

class UiUtils {
  static double questionContainerHeightPercentage = 0.725;
  static double quizTypeMaxHeightPercentage = 0.275;
  static double quizTypeMinHeightPercentage = 0.185;

  static double profileHeightBreakPointResultScreen = 355.0;

  static double bottomMenuPercentage = 0.075;

  static double dailogHeightPercentage = 0.65;
  static double dailogWidthPercentage = 0.85;

  static double dailogBlurSigma = 6.0;
  static double dailogRadius = 40.0;
  static double appBarHeightPercentage = 0.16;

  static String buildGuessTheWordQuestionAnswer(List<String> submittedAnswer) {
    String answer = "";
    submittedAnswer.forEach((element) {
      if (element.isNotEmpty) {
        answer = answer + element;
      }
    });
    return answer;
  }

  static void setSnackbar(String msg, BuildContext context, bool showAction,
      {Function? onPressedAction, Duration? duration}) {
    ScaffoldMessenger.of(context).showSnackBar(new SnackBar(
      content: new Text(msg,
          textAlign: showAction ? TextAlign.start : TextAlign.center,
          style: TextStyle(
              color: Theme.of(context).backgroundColor,
              fontWeight: FontWeight.bold,
              fontSize: 16.0)),
      behavior: SnackBarBehavior.fixed,
      duration: duration ?? Duration(seconds: 2),
      backgroundColor: Theme.of(context).primaryColor,
      action: showAction
          ? SnackBarAction(
              label: "Retry",
              onPressed: onPressedAction as void Function(),
              textColor: Theme.of(context).backgroundColor,
            )
          : null,
      elevation: 2.0,
    ));
  }

  static void errorMessageDialog(BuildContext context, String? errorMessage) {
    showDialog(
        context: context,
        builder: (_) => ErrorMessageDialog(errorMessage: errorMessage));
  }

  static String getImagePath(String imageName) {
    return "assets/images/$imageName";
  }

  static String getprofileImagePath(String imageName) {
    return "assets/images/profile/$imageName";
  }

  static BoxShadow buildBoxShadow(
      {Offset? offset, double? blurRadius, Color? color}) {
    return BoxShadow(
      color: color ?? Colors.black.withOpacity(0.1),
      blurRadius: blurRadius ?? 10.0,
      offset: offset ?? Offset(5.0, 5.0),
    );
  }

  static BoxShadow buildAppbarShadow() {
    return buildBoxShadow(
        blurRadius: 5.0,
        color: Colors.black.withOpacity(0.3),
        offset: Offset.zero);
  }

  static LinearGradient buildLinerGradient(
      List<Color> colors, Alignment begin, Alignment end) {
    return LinearGradient(colors: colors, begin: begin, end: end);
  }

  static String getCurrentQuestionLanguageId(BuildContext context) {
    final currentLanguage = context.read<AppLocalizationCubit>().state.language;
    if (context.read<SystemConfigCubit>().getLanguageMode() == "1") {
      final supporatedLanguage =
          context.read<SystemConfigCubit>().getSupportedLanguages();
      return supporatedLanguage[supporatedLanguage.indexWhere((element) =>
              element.languageCode == currentLanguage.languageCode)]
          .id;
    }
    return defaultQuestionLanguageId;
  }

  static String formatNumber(int number) {
    return NumberFormat.compact().format(number).toLowerCase();
  }

  //This method will determine how much coins will user get after
  //completing the quiz
  static int coinsBasedOnWinPercentage(double percentage, QuizTypes quizType) {
    //if percentage is more than maxCoinsWinningPercentage then user will earn maxWinningCoins
    //
    //if percentage is less than maxCoinsWinningPercentage
    //coin value will deduct from maxWinning coins
    //earned coins = (maxWinningCoins - ((maxCoinsWinningPercentage - percentage)/ 10))

    //For example: if percentage is 70 then user will
    //earn 3 coins if maxWinningCoins is 4

    int earnedCoins = 0;
    if (percentage >= maxCoinsWinningPercentage) {
      earnedCoins = quizType == QuizTypes.guessTheWord
          ? guessTheWordMaxWinningCoins
          : maxWinningCoins;
    } else {
      int maxCoins = quizType == QuizTypes.guessTheWord
          ? guessTheWordMaxWinningCoins
          : maxWinningCoins;

      earnedCoins =
          (maxCoins - ((maxCoinsWinningPercentage - percentage) / 10)).toInt();
    }
    if (earnedCoins < 0) {
      print(earnedCoins);
      earnedCoins = 0;
    }
    return earnedCoins;
  }

  static void vibrate() {
    HapticFeedback.heavyImpact();
    HapticFeedback.vibrate();
  }

  static int determineBattleCorrectAnswerPoints(
      double animationControllerValue) {
    double secondsTakenToAnswer =
        (questionDurationInSeconds * animationControllerValue);

    print("Took ${secondsTakenToAnswer}s to give the answer");

    //improve points system here if needed
    if (secondsTakenToAnswer <= 2) {
      return correctAnswerPointsForBattle + 10;
    } else if (secondsTakenToAnswer <= 4) {
      return correctAnswerPointsForBattle + 5;
    }
    return correctAnswerPointsForBattle;
  }

  //navigate to battle screen
  static void navigateToOneVSOneBattleScreen(BuildContext context) {
    //reset state of battle room to initial
    context.read<BattleRoomCubit>().emit(BattleRoomInitial());
    if (context.read<SystemConfigCubit>().getIsCategoryEnableForBattle() ==
        "1") {
      //go to category page
      Navigator.of(context)
          .pushNamed(Routes.category, arguments: QuizTypes.battle);
    } else {
      Navigator.of(context)
          .pushNamed(Routes.battleRoomFindOpponent, arguments: "")
          .then((value) {
        //need to delete room if user exit the process in between of finding opponent
        //or instantly press exit button
        Future.delayed(Duration(milliseconds: 3000)).then((value) {
          //In battleRoomFindOpponent screen
          //we are calling pushReplacement method so it will trigger this
          //callback so we need to check if state is not battleUserFound then
          //and then we need to call deleteBattleRoom

          //when user press the backbutton and choose to exit the game and
          //process of creating room(in firebase) is still running
          //then state of battleRoomCubit will not be battleRoomUserFound
          //deleteRoom call execute
          if (context.read<BattleRoomCubit>().state is! BattleRoomUserFound) {
            context.read<BattleRoomCubit>().deleteBattleRoom();
          }
        });
      });
    }
  }

  //will be in use while playing screen
  //this method will be in use to display color based on user's answer
  static Color getOptionBackgroundColor(Question question, BuildContext context,
      String? optionId, String? showCorrectAnswerMode) {
    if (question.attempted) {
      if (showCorrectAnswerMode == "0") {
        return Theme.of(context).primaryColor.withOpacity(0.65);
      }

      // if given answer is correct
      if (question.submittedAnswerId == question.correctAnswerOptionId) {
        //if given option is same as answer
        if (question.submittedAnswerId == optionId) {
          return Colors.greenAccent;
        }
        //color will not change for other options
        return Theme.of(context).colorScheme.secondary;
      } else {
        //option id is same as given answer then change color to red
        if (question.submittedAnswerId == optionId) {
          return Colors.redAccent;
        }
        //if given option id is correct as same answer then change color to green
        else if (question.correctAnswerOptionId == optionId) {
          return Colors.greenAccent;
        }
        //do not change color
        return Theme.of(context).colorScheme.secondary;
      }
    }
    return Theme.of(context).colorScheme.secondary;
  }

  //will be in use while playing  quiz screen
  //this method will be in use to display color based on user's answer
  static Color getOptionTextColor(Question question, BuildContext context,
      String? optionId, String? showCorrectAnswerMode) {
    if (question.attempted) {
      if (showCorrectAnswerMode == "0") {
        return Theme.of(context).scaffoldBackgroundColor;
      }

      // if given answer is correct
      if (question.submittedAnswerId == question.correctAnswerOptionId) {
        //if given option is same as answer
        if (question.submittedAnswerId == optionId) {
          return Theme.of(context).scaffoldBackgroundColor;
        }
        //color will not change for other options
        return Theme.of(context).scaffoldBackgroundColor;
      } else {
        //option id is same as given answer then change color to red
        if (question.submittedAnswerId == optionId) {
          return Theme.of(context).scaffoldBackgroundColor;
        }
        //if given option id is correct as same answer then change color to green
        else if (question.correctAnswerOptionId == optionId) {
          return Theme.of(context).scaffoldBackgroundColor;
        }
        //do not change color
        return Theme.of(context).scaffoldBackgroundColor;
      }
    }
    return Theme.of(context).scaffoldBackgroundColor;
  }
}
