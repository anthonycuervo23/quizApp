import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:quizappuic/app/appLocalization.dart';
import 'package:quizappuic/features/battleRoom/models/battleRoom.dart';
import 'package:quizappuic/features/quiz/cubits/setContestLeaderboardCubit.dart';
import 'package:quizappuic/features/quiz/models/guessTheWordQuestion.dart';
import 'package:quizappuic/features/quiz/models/userBattleRoomDetails.dart';
import 'package:quizappuic/features/statistic/cubits/updateStatisticCubit.dart';
import 'package:quizappuic/features/statistic/statisticRepository.dart';
import 'package:quizappuic/ui/widgets/circularImageContainer.dart';
import 'package:quizappuic/ui/widgets/pageBackgroundGradientContainer.dart';
import 'package:quizappuic/utils/constants.dart';
import 'package:quizappuic/utils/errorMessageKeys.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:path_provider/path_provider.dart';

import 'package:quizappuic/app/routes.dart';
import 'package:quizappuic/features/profileManagement/cubits/updateScoreAndCoinsCubit.dart';
import 'package:quizappuic/features/profileManagement/cubits/userDetailsCubit.dart';
import 'package:quizappuic/features/profileManagement/profileManagementRepository.dart';
import 'package:quizappuic/features/quiz/cubits/updateLevelCubit.dart';
import 'package:quizappuic/features/quiz/models/question.dart';
import 'package:quizappuic/features/quiz/models/quizType.dart';
import 'package:quizappuic/features/quiz/quizRepository.dart';
import 'package:quizappuic/ui/screens/quiz/widgets/radialResultContainer.dart';

import 'package:quizappuic/ui/widgets/customRoundedButton.dart';
import 'package:quizappuic/utils/uiUtils.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';

class ResultScreen extends StatefulWidget {
  final QuizTypes?
      quizType; //to show different kind of result data for different quiz type
  final int?
      numberOfPlayer; //to show different kind of resut data for number of player
  final int?
      myPoints; // will be in use when quiz is not tyoe of battle and live battle
  final List<Question>? questions; //to see reivew answers
  final BattleRoom? battleRoom; //will be in use for battle
  final String? contestId;
  final String? comprehensionId; //will be use to set contest leaderboard
  final List<GuessTheWordQuestion>?
      guessTheWordQuestions; //questions when quiz type is guessTheWord

  //if quizType is quizZone then it will be in use
  //to determine to show next level button
  //it will be in use if quizType is quizZone
  final String? subcategoryMaxLevel;
  //to determine if we need to update level or not
  //it will be in use if quizType is quizZone
  final int? unlockedLevel;

  ResultScreen(
      {Key? key,
      this.numberOfPlayer,
      this.myPoints,
      this.battleRoom,
      this.questions,
      this.unlockedLevel,
      this.quizType,
      this.subcategoryMaxLevel,
      this.contestId,
      this.comprehensionId,
      this.guessTheWordQuestions})
      : super(key: key);

  static Route<dynamic> route(RouteSettings routeSettings) {
    Map arguments = routeSettings.arguments as Map;
    //keys of map are numberOfPlayer,quizType,questions (required)
    //if quizType is not battle and liveBattle need to pass following arguments
    //myPoints
    //if quizType is quizZone then need to pass following agruments
    //subcategoryMaxLevel, unlockedLevel
    //if quizType is battle and liveBattle then need to pass following agruments
    //battleRoom
    return CupertinoPageRoute(
        builder: (_) => MultiBlocProvider(
              providers: [
                //to update unlocked level for given subcategory
                BlocProvider<UpdateLevelCubit>(
                  create: (_) => UpdateLevelCubit(QuizRepository()),
                ),
                //to update user score and coins
                BlocProvider<UpdateScoreAndCoinsCubit>(
                  create: (_) =>
                      UpdateScoreAndCoinsCubit(ProfileManagementRepository()),
                ),
                //to update statistic
                BlocProvider<UpdateStatisticCubit>(
                  create: (_) => UpdateStatisticCubit(StatisticRepository()),
                ),
                //set ContestLeaderBoard
                BlocProvider<SetContestLeaderboardCubit>(
                  create: (_) => SetContestLeaderboardCubit(QuizRepository()),
                ),
              ],
              child: ResultScreen(
                  myPoints: arguments['myPoints'],
                  numberOfPlayer: arguments['numberOfPlayer'],
                  questions: arguments['questions'],
                  battleRoom: arguments['battleRoom'],
                  quizType: arguments['quizType'],
                  subcategoryMaxLevel: arguments['subcategoryMaxLevel'],
                  unlockedLevel: arguments['unlockedLevel'],
                  guessTheWordQuestions: arguments['guessTheWordQuestions'], //
                  contestId: arguments["contestId"]),
            ));
  }

  @override
  _ResultScreenState createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  final ScreenshotController screenshotController = ScreenshotController();

  late bool _isWinner;
  int _earnedCoins = 0;
  String? _winnerId;
  /* AdmobBannerSize? bannerSize;
  late AdmobInterstitial interstitialAd;*/

  void decideWinnerForBattle() {
    if (widget.numberOfPlayer == 2) {
      String winnerId = "";
      if (widget.battleRoom!.user1!.points ==
          widget.battleRoom!.user2!.points) {
        _isWinner = true;
        _winnerId = "";
        //updateCoinsForBattleWinner(battleWinnerCoins ~/ 2);
      } else {
        if (widget.battleRoom!.user1!.points >
            widget.battleRoom!.user2!.points) {
          winnerId = widget.battleRoom!.user1!.uid;
        } else {
          winnerId = widget.battleRoom!.user2!.uid;
        }
        Future.delayed(Duration.zero, () {
          if (context.read<UserDetailsCubit>().getUserId() == winnerId) {
            _isWinner = true;
            //updateCoinsForBattleWinner(battleWinnerCoins);
          } else {
            _isWinner = false;
          }
          _winnerId = winnerId;
          setState(() {});
        });
      }
    }
  }

  void updateCoinsForBattleWinner(int earnedCoins) {
    Future.delayed(Duration.zero, () {
      //
      context.read<UpdateScoreAndCoinsCubit>().updateCoins(
          context.read<UserDetailsCubit>().getUserId(), earnedCoins, true);
      context.read<UserDetailsCubit>().updateCoins(
            addCoin: true,
            coins: earnedCoins,
          );
    });
  }

  //AddMob ads Ids
  String? getRewardBasedVideoAdUnitId() {
    if (Platform.isIOS) {
      return videoIosId;
    } else if (Platform.isAndroid) {
      return videoAndroidId;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    if (widget.quizType == QuizTypes.battle) {
      decideWinnerForBattle();
    } else {
      if (winPercentage() >= winPercentageBreakPoint) {
        _isWinner = true;
      } else {
        _isWinner = false;
      }
      earnCoinsBasedOnWinPercentage();
      updateResultDetails();
      setContestLeaderboard();
    }
    /*bannerSize = AdmobBannerSize.BANNER;
    interstitialAd = AdmobInterstitial(
      adUnitId: getRewardBasedVideoAdUnitId()!,
      listener: (AdmobAdEvent event, Map<String, dynamic>? args) {
        if (event == AdmobAdEvent.closed) {
          interstitialAd.load();
        }
      },
    );
    interstitialAd.load();*/
    _createInterstitialAd();
  }

  void _createInterstitialAd() {
    InterstitialAd.load(
        adUnitId: getRewardBasedVideoAdUnitId()!,
        request: AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (InterstitialAd ad) {
            interstitialAd = ad;
            print('$ad loaded');
          },
          onAdFailedToLoad: (LoadAdError error) {
            print('InterstitialAd failed to load: $error.');
            _createInterstitialAd();
          },
        ));
  }

  InterstitialAd? interstitialAd;
  void _showInterstitialAd() {
    if (interstitialAd == null) {
      print('Warning: attempt to show interstitial before loaded');
      return;
    }
    interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (InterstitialAd ad) =>
          print('ad onAdShowedFullScreenContent'),
      onAdDismissedFullScreenContent: (InterstitialAd ad) {
        print('$ad onAdDismissedFullScreenContent');
        ad.dispose();
        _createInterstitialAd();
      },
      onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
        print('$ad onAdFailedToShowFullScreenContent: $error');
        ad.dispose();
        _createInterstitialAd();
      },
    );
    interstitialAd!.show();
    interstitialAd = null;
  }

  void setContestLeaderboard() {
    if (widget.quizType == QuizTypes.contest) {
      context.read<SetContestLeaderboardCubit>().setContestLeaderboard(
          userId: context.read<UserDetailsCubit>().getUserId(),
          questionAttended: attemptedQuestion(),
          correctAns: correctAnswer(),
          contestId: widget.contestId,
          score: widget.myPoints);
    }
  }

  //
  void updateResultDetails() {
    Future.delayed(Duration.zero, () {
      //we need to update score and coins only for some type of quiz
      if (widget.quizType == QuizTypes.quizZone ||
          widget.quizType == QuizTypes.dailyQuiz ||
          widget.quizType == QuizTypes.guessTheWord ||
          widget.quizType == QuizTypes.trueAndFalse ||
          widget.quizType == QuizTypes.funAndLearn) {
/*
        //update statistic for given user
        context.read<UpdateStatisticCubit>().updateStatistic(
          answeredQuestion: attemptedQuestion(),
          categoryId: widget.questions!.first.categoryId,
          correctAnswers: correctAnswer(),
          userId: context.read<UserDetailsCubit>().getUserId(),
          winPercentage: winPercentage(),
        );*/
        //if percentage is more than 30 then update socre and coins
        if (_isWinner) {
          //update score and coins for user
          context.read<UpdateScoreAndCoinsCubit>().updateCoinsAndScore(
              context.read<UserDetailsCubit>().getUserId(),
              widget.myPoints ?? 0,
              true,
              _earnedCoins);
          //update score locally and database
          context
              .read<UserDetailsCubit>()
              .updateCoins(addCoin: true, coins: _earnedCoins);
          context.read<UserDetailsCubit>().updateScore(widget.myPoints);

          //if quizType is quizZone we need to update unlocked level
          if (widget.quizType == QuizTypes.quizZone) {
            //if this level is not last level then update level
            if (widget.subcategoryMaxLevel != widget.questions!.first.level) {
              //if given level is same as unlocked level then update level
              if (int.parse(widget.questions!.first.level!) ==
                  widget.unlockedLevel) {
                int updatedLevel =
                    int.parse(widget.questions!.first.level!) + 1;
                //update level
                context.read<UpdateLevelCubit>().updateLevel(
                    context.read<UserDetailsCubit>().getUserId(),
                    widget.questions!.first.categoryId,
                    widget.questions!.first.subcategoryId,
                    updatedLevel.toString());
              }
            }
          }
        } else {
          //update only score
          context.read<UpdateScoreAndCoinsCubit>().updateScore(
              context.read<UserDetailsCubit>().getUserId(), widget.myPoints);
          context.read<UserDetailsCubit>().updateScore(widget.myPoints);
        }
      }
    });
  }

  void earnCoinsBasedOnWinPercentage() {
    if (_isWinner) {
      double percentage = winPercentage();
      _earnedCoins =
          UiUtils.coinsBasedOnWinPercentage(percentage, widget.quizType!);
    }
  }

  int correctAnswer() {
    int correctAnswer = 0;
    if (widget.quizType == QuizTypes.guessTheWord) {
      for (var question in widget.guessTheWordQuestions!) {
        if (question.answer ==
            UiUtils.buildGuessTheWordQuestionAnswer(question.submittedAnswer)) {
          correctAnswer++;
        }
      }
    } else {
      for (var question in widget.questions!) {
        if (question.correctAnswerOptionId == question.submittedAnswerId) {
          correctAnswer++;
        }
      }
    }
    return correctAnswer;
  }

  int attemptedQuestion() {
    int attemptedQuestion = 0;
    if (widget.quizType == QuizTypes.guessTheWord) {
      //
      for (var question in widget.guessTheWordQuestions!) {
        if (question.hasAnswered) {
          attemptedQuestion++;
        }
      }
    } else {
      //
      for (var question in widget.questions!) {
        if (question.attempted) {
          attemptedQuestion++;
        }
      }
    }
    return attemptedQuestion;
  }

  double winPercentage() {
    if (widget.quizType == QuizTypes.guessTheWord) {
      return (correctAnswer() * 100.0) / widget.guessTheWordQuestions!.length;
    } else {
      return (correctAnswer() * 100.0) / widget.questions!.length;
    }
  }

  bool showCoinsAndScore() {
    if (widget.quizType == QuizTypes.selfChallenge ||
        widget.quizType == QuizTypes.contest) {
      return false;
    }

    return true;
  }

  int totalQuestions() {
    if (widget.quizType == QuizTypes.guessTheWord) {
      return widget.guessTheWordQuestions!.length;
    }
    return widget.questions!.length;
  }

  Widget _buildGreetingMessage(String title, String message) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          height: 15.0,
        ),
        Container(
          alignment: Alignment.center,
          child: Text(
            "$message",
            style: TextStyle(
                fontSize: 19.0, color: Theme.of(context).backgroundColor),
          ),
        ),
        SizedBox(
          height: 5.0,
        ),
        Container(
          alignment: Alignment.center,
          child: Text("$title",
              style: TextStyle(
                fontSize: 25.0 * MediaQuery.of(context).textScaleFactor * 1.25,
                color: Theme.of(context).backgroundColor,
              )),
        )
      ],
    );
  }

  Widget _buildResultDataWithIconContainer(
      String title, String icon, EdgeInsetsGeometry margin) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
          color: Theme.of(context).backgroundColor,
          borderRadius: BorderRadius.circular(10.0)),
      width: MediaQuery.of(context).size.width * (0.2125),
      height: 30.0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset(UiUtils.getImagePath(icon),
              color: Theme.of(context).colorScheme.secondary),
          SizedBox(
            width: 5,
          ),
          Text(
            title,
            style: TextStyle(color: Theme.of(context).colorScheme.secondary),
          ),
        ],
      ),
      alignment: Alignment.center,
    );
  }

  Widget _buildIndividualResultContainer(String userProfileUrl) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Align(
          alignment: Alignment.center,
          child: SvgPicture.asset(
            _isWinner
                ? UiUtils.getImagePath("celebration_win.svg")
                : UiUtils.getImagePath("celebration_loss.svg"),
          ),
        ),
        Align(
          alignment: Alignment.topCenter,
          child: LayoutBuilder(
            builder: (context, constraints) {
              double verticalSpacePercentage = 0.0;
              double profileRadiusPercentage = 0.0;
              if (constraints.maxHeight <
                  UiUtils.profileHeightBreakPointResultScreen) {
                verticalSpacePercentage = 0.015;
                profileRadiusPercentage = 0.35; //test in
              } else {
                verticalSpacePercentage = 0.035;
                profileRadiusPercentage = 0.375;
              }
              return Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  _isWinner
                      ? _buildGreetingMessage(
                          AppLocalization.of(context)!
                              .getTranslatedValues("victoryLbl")!,
                          AppLocalization.of(context)!
                              .getTranslatedValues("congratulationsLbl")!)
                      : _buildGreetingMessage(
                          AppLocalization.of(context)!
                              .getTranslatedValues("defeatLbl")!,
                          AppLocalization.of(context)!
                              .getTranslatedValues("betterNextLbl")!),
                  SizedBox(
                    height: constraints.maxHeight * verticalSpacePercentage,
                  ),
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Center(
                        child: Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .primaryColor
                                  .withOpacity(0.5),
                              shape: BoxShape.circle,
                            ),
                            height: constraints.maxHeight *
                                profileRadiusPercentage),
                      ),
                      Center(
                        child: Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor,
                              shape: BoxShape.circle,
                            ),
                            height: constraints.maxHeight *
                                (profileRadiusPercentage - 0.025)),
                      ),
                      Center(
                        child: CircularImageContainer(
                            imagePath: userProfileUrl,
                            height: constraints.maxHeight *
                                (profileRadiusPercentage - 0.05),
                            width: constraints.maxWidth *
                                (profileRadiusPercentage - 0.05 + 0.15)),
                      ),
                    ],
                  ),
                  Text(
                    _isWinner
                        ? AppLocalization.of(context)!
                            .getTranslatedValues("winnerLbl")!
                        : AppLocalization.of(context)!
                            .getTranslatedValues("youLossLbl")!,
                    style: TextStyle(
                      fontSize:
                          25.0 * MediaQuery.of(context).textScaleFactor * (1.1),
                      fontWeight: FontWeight.w400,
                      color: Theme.of(context)
                          .backgroundColor, //Theme.of(context).backgroundColor,
                    ),
                  )
                ],
              );
            },
          ),
        ),

        //incorrect answer
        Align(
          alignment: AlignmentDirectional.bottomStart,
          child: _buildResultDataWithIconContainer(
              "${totalQuestions() - correctAnswer()}/${totalQuestions()}",
              "wrong.svg",
              EdgeInsetsDirectional.only(
                  start: 15.0, bottom: showCoinsAndScore() ? 20.0 : 30.0)),
        ),
        //correct answer
        showCoinsAndScore()
            ? Align(
                alignment: AlignmentDirectional.bottomStart,
                child: _buildResultDataWithIconContainer(
                    "${correctAnswer()}/${totalQuestions()}",
                    "correct.svg",
                    EdgeInsetsDirectional.only(start: 15.0, bottom: 60.0)),
              )
            : Align(
                alignment: Alignment.bottomRight,
                child: _buildResultDataWithIconContainer(
                    "${correctAnswer()}/${totalQuestions()}",
                    "correct.svg",
                    EdgeInsetsDirectional.only(end: 15.0, bottom: 30.0)),
              ),

        //points
        showCoinsAndScore()
            ? Align(
                alignment: AlignmentDirectional.bottomEnd,
                child: _buildResultDataWithIconContainer(
                    "${widget.myPoints}",
                    "score.svg",
                    EdgeInsetsDirectional.only(end: 15.0, bottom: 60.0)),
              )
            : Container(),

        //earned coins
        showCoinsAndScore()
            ? Align(
                alignment: AlignmentDirectional.bottomEnd,
                child: _buildResultDataWithIconContainer(
                    "$_earnedCoins",
                    "earnedCoin.svg",
                    EdgeInsetsDirectional.only(end: 15.0, bottom: 20.0)),
              )
            : Container(),

        //build radils percentage container
        Align(
          alignment: Alignment.bottomCenter,
          child: LayoutBuilder(builder: (context, constraints) {
            double radialSizePercentage = 0.0;
            if (constraints.maxHeight <
                UiUtils.profileHeightBreakPointResultScreen) {
              radialSizePercentage = 0.4;
            } else {
              radialSizePercentage = 0.325;
            }
            return Transform.translate(
              offset: Offset(0.0, 15.0), //
              child: RadialPercentageResultContainer(
                circleColor: Theme.of(context).colorScheme.secondary,
                arcColor: Theme.of(context).backgroundColor,
                arcStrokeWidth: 10.0,
                circleStrokeWidth: 10.0,
                radiusPercentage: 0.25,
                percentage: winPercentage(),
                size: Size(
                    constraints.maxHeight * radialSizePercentage,
                    constraints.maxHeight *
                        radialSizePercentage), //150.0 , 150.0
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildBattleResultDetails() {
    UserBattleRoomDetails? winnerDetails =
        widget.battleRoom!.user1!.uid == _winnerId
            ? widget.battleRoom!.user1
            : widget.battleRoom!.user2;
    UserBattleRoomDetails? looserDetails =
        widget.battleRoom!.user1!.uid != _winnerId
            ? widget.battleRoom!.user1
            : widget.battleRoom!.user2;

    return _winnerId == null
        ? Container()
        : LayoutBuilder(
            builder: (context, constraints) {
              double profileRadiusPercentage = 0.0;
              double looserProfileRadiusPercentage = 0.0;
              double verticalSpacePercentage = 0.0;
              double translateOffsetdy = 0.0;
              double nameAndProfileSizedBoxHeight = 0.0;
              if (constraints.maxHeight <
                  UiUtils.profileHeightBreakPointResultScreen) {
                profileRadiusPercentage = _winnerId!.isEmpty ? 0.165 : 0.18;
                verticalSpacePercentage = _winnerId!.isEmpty ? 0.035 : 0.03;
                looserProfileRadiusPercentage =
                    _winnerId!.isEmpty ? profileRadiusPercentage : 0.127;
                translateOffsetdy = -15.0;
                nameAndProfileSizedBoxHeight = 5.0;
              } else {
                profileRadiusPercentage = _winnerId!.isEmpty ? 0.15 : 0.17;
                verticalSpacePercentage = _winnerId!.isEmpty ? 0.075 : 0.05;
                looserProfileRadiusPercentage =
                    _winnerId!.isEmpty ? profileRadiusPercentage : 0.11;
                translateOffsetdy = 25.0;
                nameAndProfileSizedBoxHeight = 10.0;
              }

              return Column(
                children: [
                  _winnerId!.isEmpty
                      ? _buildGreetingMessage(
                          AppLocalization.of(context)!
                              .getTranslatedValues("matchDrawLbl")!,
                          AppLocalization.of(context)!
                              .getTranslatedValues("congratulationsLbl")!)
                      : _isWinner
                          ? _buildGreetingMessage(
                              AppLocalization.of(context)!
                                  .getTranslatedValues("victoryLbl")!,
                              AppLocalization.of(context)!
                                  .getTranslatedValues("congratulationsLbl")!)
                          : _buildGreetingMessage(
                              AppLocalization.of(context)!
                                  .getTranslatedValues("defeatLbl")!,
                              AppLocalization.of(context)!
                                  .getTranslatedValues("betterNextLbl")!),
                  SizedBox(
                    height: constraints.maxHeight * verticalSpacePercentage,
                  ),
                  _winnerId!.isEmpty
                      ? Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20.0),
                          child: Row(
                            children: [
                              Column(
                                children: [
                                  Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          Center(
                                            child: CircleAvatar(
                                              radius: constraints.maxHeight *
                                                  (profileRadiusPercentage),
                                              backgroundImage:
                                                  CachedNetworkImageProvider(
                                                      widget.battleRoom!.user1!
                                                          .profileUrl),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  SizedBox(
                                    height: nameAndProfileSizedBoxHeight,
                                  ),
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                        vertical: 4.0, horizontal: 5.0),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).backgroundColor,
                                      borderRadius: BorderRadius.circular(5.0),
                                    ),
                                    width: constraints.maxWidth * (0.3),
                                    child: Text(
                                      "${widget.battleRoom!.user1!.name}",
                                      style: TextStyle(
                                          color:
                                              Theme.of(context).primaryColor),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  SizedBox(
                                    height: 4,
                                  ),
                                  Container(
                                    width: constraints.maxWidth * (0.3),
                                    padding: EdgeInsets.only(left: 10),
                                    child: Text(
                                      AppLocalization.of(context)!
                                          .getTranslatedValues("winnerLbl")!,
                                      style: TextStyle(
                                          color: Theme.of(context)
                                              .backgroundColor),
                                    ),
                                  ),
                                ],
                              ),
                              Spacer(),
                              Column(
                                children: [
                                  Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      Center(
                                        child: CircleAvatar(
                                          radius: constraints.maxHeight *
                                              (profileRadiusPercentage),
                                          backgroundImage:
                                              CachedNetworkImageProvider(widget
                                                  .battleRoom!
                                                  .user2!
                                                  .profileUrl),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(
                                    height: nameAndProfileSizedBoxHeight,
                                  ),
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                        vertical: 4.0, horizontal: 5.0),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).backgroundColor,
                                      borderRadius: BorderRadius.circular(5.0),
                                    ),
                                    width: constraints.maxWidth * (0.3),
                                    child: Text(
                                      "${widget.battleRoom!.user2!.name}",
                                      style: TextStyle(
                                          color:
                                              Theme.of(context).primaryColor),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  SizedBox(
                                    height: 4,
                                  ),
                                  Container(
                                    width: constraints.maxWidth * (0.3),
                                    padding: EdgeInsets.only(left: 10),
                                    child: Text(
                                      AppLocalization.of(context)!
                                          .getTranslatedValues("winnerLbl")!,
                                      style: TextStyle(
                                          color: Theme.of(context)
                                              .backgroundColor),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        )
                      : Row(
                          children: [
                            SizedBox(
                              width: 20.0,
                            ),
                            Column(
                              children: [
                                Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Center(
                                      child: CircleAvatar(
                                        radius: constraints.maxHeight *
                                            (profileRadiusPercentage),
                                        backgroundImage:
                                            CachedNetworkImageProvider(
                                                winnerDetails!.profileUrl),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(
                                  height: nameAndProfileSizedBoxHeight,
                                ),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                      vertical: 4.0, horizontal: 5.0),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).backgroundColor,
                                    borderRadius: BorderRadius.circular(5.0),
                                  ),
                                  width: constraints.maxWidth * (0.3),
                                  child: Text(
                                    "${winnerDetails.name}",
                                    style: TextStyle(
                                      color: Theme.of(context).primaryColor,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                SizedBox(
                                  height: 4,
                                ),
                                Container(
                                  width: constraints.maxWidth * (0.3),
                                  padding:
                                      EdgeInsetsDirectional.only(start: 10),
                                  child: Text(
                                    AppLocalization.of(context)!
                                        .getTranslatedValues("winnerLbl")!,
                                    style: TextStyle(
                                        color:
                                            Theme.of(context).backgroundColor),
                                  ),
                                ),
                              ],
                            ),
                            Spacer(),
                            Transform.translate(
                              offset: Offset(0.0, translateOffsetdy),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      Center(
                                        child: CircleAvatar(
                                          radius: constraints.maxHeight *
                                              (looserProfileRadiusPercentage),
                                          backgroundImage:
                                              CachedNetworkImageProvider(
                                                  looserDetails!.profileUrl),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(
                                    height: nameAndProfileSizedBoxHeight,
                                  ),
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                        vertical: 4.0, horizontal: 5.0),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(5.0),
                                      color: Theme.of(context).backgroundColor,
                                    ),
                                    width: constraints.maxWidth * (0.3),
                                    child: Text(
                                      "${looserDetails.name}",
                                      textAlign: TextAlign.center,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                          color:
                                              Theme.of(context).primaryColor),
                                    ),
                                  ),
                                  SizedBox(
                                    height: 2.0,
                                  ),
                                  Container(
                                    width: constraints.maxWidth * (0.3),
                                    padding:
                                        EdgeInsetsDirectional.only(start: 10),
                                    child: Text(
                                      AppLocalization.of(context)!
                                          .getTranslatedValues("looserLbl")!,
                                      style: TextStyle(
                                          color: Theme.of(context)
                                              .backgroundColor),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(
                              width: 20.0,
                            ),
                          ],
                        ),
                  Spacer(),
                  Container(
                    padding: EdgeInsets.symmetric(
                        vertical: constraints.maxHeight <
                                UiUtils.profileHeightBreakPointResultScreen
                            ? 7.5
                            : 15.0),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Theme.of(context).backgroundColor,
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                    width: constraints.maxWidth * (0.8),
                    child: Text(
                      "${winnerDetails!.points}:${looserDetails!.points}",
                      style: TextStyle(
                          fontSize: 17.5,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).primaryColor),
                    ),
                  ),
                  SizedBox(
                    height: constraints.maxHeight <
                            UiUtils.profileHeightBreakPointResultScreen
                        ? 10.0
                        : 20.0,
                  ),
                ],
              );
            },
          );
  }

  Widget _buildResultDetails(BuildContext context) {
    final userProfileUrl =
        context.read<UserDetailsCubit>().getUserProfile().profileUrl ?? "";

    //build results for 1 user
    if (widget.numberOfPlayer == 1) {
      return _buildIndividualResultContainer(userProfileUrl);
    }
    if (widget.numberOfPlayer == 2) {
      return _buildBattleResultDetails();
    }
    return Container();
  }

  Widget _buildResultContainer(BuildContext context) {
    return Screenshot(
      controller: screenshotController,
      child: Container(
        height: MediaQuery.of(context).size.height * (0.575),
        width: MediaQuery.of(context).size.width * (0.85),
        decoration: BoxDecoration(
          boxShadow: [UiUtils.buildBoxShadow()],
          color: Theme.of(context).primaryColor,
          borderRadius: BorderRadius.circular(20.0),
        ),
        child: _buildResultDetails(context),
      ),
    );
  }

  Widget _buildButton(
      String buttonTitle, Function onTap, BuildContext context) {
    return CustomRoundedButton(
      widthPercentage: 0.85,
      backgroundColor: Theme.of(context).primaryColor,
      buttonTitle: buttonTitle,
      radius: 7.5,
      elevation: 5.0,
      showBorder: false,
      fontWeight: FontWeight.bold,
      height: 50.0,
      titleColor: Theme.of(context).backgroundColor,
      onTap: onTap,
      textSize: 17.0,
    );
  }

  //paly again button will be build different for every quizType
  Widget _buildPlayAgainButton() {
    if (widget.quizType == QuizTypes.selfChallenge) {
      return Container();
    } else if (widget.quizType == QuizTypes.guessTheWord) {
      if (_isWinner) {
        return Container();
      }
      return _buildButton(
          AppLocalization.of(context)!.getTranslatedValues("playAgainBtn")!,
          () {
        Navigator.of(context).pushReplacementNamed(Routes.guessTheWord);
      }, context);
    } else if (widget.quizType == QuizTypes.funAndLearn) {
      return Container();
    } else if (widget.quizType == QuizTypes.quizZone) {
      //if user is winner
      if (_isWinner) {
        //we need to check if currentLevel is last level or not
        int maxLevel = int.parse(widget.subcategoryMaxLevel!);
        int currentLevel = int.parse(widget.questions!.first.level!);
        if (maxLevel == currentLevel) {
          return Container();
        }
        return _buildButton(
            AppLocalization.of(context)!.getTranslatedValues("nextLevelBtn")!,
            () {
          //if given level is same as unlocked level then we need to update level
          //else do not update level
          int? unlockedLevel =
              int.parse(widget.questions!.first.level!) == widget.unlockedLevel
                  ? (widget.unlockedLevel! + 1)
                  : widget.unlockedLevel;
          //play quiz for next level
          Navigator.of(context).pushReplacementNamed(Routes.quiz, arguments: {
            "numberOfPlayer": widget.numberOfPlayer,
            "quizType": widget.quizType,
            //if subcategory id is empty for question means we need to fetch quesitons by it's category
            "categoryId": widget.questions!.first.subcategoryId == "0"
                ? widget.questions!.first.categoryId
                : "",
            "subcategoryId": widget.questions!.first.subcategoryId == "0"
                ? ""
                : widget.questions!.first.subcategoryId,
            "level": (currentLevel + 1).toString(), //increase level
            "subcategoryMaxLevel": widget.subcategoryMaxLevel,
            "unlockedLevel": unlockedLevel,
          });
        }, context);
      }
      //if user failed to complete this level
      return _buildButton(
          AppLocalization.of(context)!.getTranslatedValues("playAgainBtn")!,
          () {
        //to play this level again (for quizZone quizType)
        Navigator.of(context).pushReplacementNamed(Routes.quiz, arguments: {
          "numberOfPlayer": widget.numberOfPlayer,
          "quizType": widget.quizType,
          //if subcategory id is empty for question means we need to fetch quesitons by it's category
          "categoryId": widget.questions!.first.subcategoryId == "0"
              ? widget.questions!.first.categoryId
              : "",
          "subcategoryId": widget.questions!.first.subcategoryId == "0"
              ? ""
              : widget.questions!.first.subcategoryId,
          "level": widget.questions!.first.level,
          "unlockedLevel": widget.unlockedLevel,
          "subcategoryMaxLevel": widget.subcategoryMaxLevel,
        });
      }, context);
    }

    return Container();
  }

  Widget _buildShareYourScoreButton() {
    return _buildButton(
        AppLocalization.of(context)!.getTranslatedValues("shareScoreBtn")!,
        () async {
      try {
        //capturing image
        final image = await screenshotController.capture();
        //root directory path
        final directory = (await getApplicationDocumentsDirectory()).path;

        String fileName = DateTime.now().microsecondsSinceEpoch.toString();
        //create file with given path
        File file = await File("$directory/$fileName.png").create();
        //write as bytes
        await file.writeAsBytes(image!.buffer.asUint8List());

        await Share.shareFiles(
          [file.path],
          text: AppLocalization.of(context)!.getTranslatedValues("myScoreLbl")!,
        );
      } catch (e) {
        UiUtils.setSnackbar(
            AppLocalization.of(context)!.getTranslatedValues(
                convertErrorCodeToLanguageKey(defaultErrorMessageCode))!,
            context,
            false);
      }
    }, context);
  }

  Widget _buildResultButtons(BuildContext context) {
    double betweenButoonSpace = 15.0;
    if (widget.quizType == QuizTypes.battle) {
      return Column(
        children: [
          SizedBox(
            height: betweenButoonSpace,
          ),
          _buildButton(
              AppLocalization.of(context)!.getTranslatedValues("reviewAnsBtn")!,
              () {
            Navigator.of(context).pushNamed(Routes.reviewAnswers, arguments: {
              "questions": widget.quizType == QuizTypes.guessTheWord
                  ? List<Question>.from([])
                  : widget.questions,
              "guessTheWordQuestions": widget.quizType == QuizTypes.guessTheWord
                  ? widget.guessTheWordQuestions
                  : List<GuessTheWordQuestion>.from([]),
            });
          }, context),
          SizedBox(
            height: betweenButoonSpace,
          ),
          _buildShareYourScoreButton(),
          SizedBox(
            height: betweenButoonSpace,
          ),
          _buildButton(
              AppLocalization.of(context)!
                  .getTranslatedValues("anotherOpponentBtn")!, () {
            UiUtils.navigateToOneVSOneBattleScreen(context);
          }, context),
          SizedBox(
            height: betweenButoonSpace,
          ),
          _buildButton(
              AppLocalization.of(context)!.getTranslatedValues("homeBtn")!, () {
            //interstitialAd.show();
            _showInterstitialAd();
            Navigator.of(context).popUntil((route) => route.isFirst);
          }, context),
        ],
      );
    }

    return Column(
      children: [
        _buildPlayAgainButton(),
        SizedBox(
          height: betweenButoonSpace,
        ),
        _buildButton(
            AppLocalization.of(context)!.getTranslatedValues("reviewAnsBtn")!,
            () {
          Navigator.of(context).pushNamed(Routes.reviewAnswers, arguments: {
            "questions": widget.quizType == QuizTypes.guessTheWord
                ? List<Question>.from([])
                : widget.questions,
            "guessTheWordQuestions": widget.quizType == QuizTypes.guessTheWord
                ? widget.guessTheWordQuestions
                : List<GuessTheWordQuestion>.from([]),
          });
        }, context),
        SizedBox(
          height: betweenButoonSpace,
        ),
        _buildShareYourScoreButton(),
        SizedBox(
          height: betweenButoonSpace,
        ),
        _buildButton(
            AppLocalization.of(context)!.getTranslatedValues("homeBtn")!, () {
          //interstitialAd.show();
          _showInterstitialAd();

          Navigator.of(context).popUntil((route) => route.isFirst);
        }, context),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: () {
          _showInterstitialAd();
          //interstitialAd.show();
          Navigator.pop(context);
          return Future.value(false);
        },
        child: Scaffold(
          body: Stack(
            children: [
              PageBackgroundGradientContainer(),
              SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      height: 50.0,
                    ),
                    Center(child: _buildResultContainer(context)),
                    SizedBox(
                      height: 30.0,
                    ),
                    _buildResultButtons(context),
                    SizedBox(
                      height: 50.0,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ));
  }
}
