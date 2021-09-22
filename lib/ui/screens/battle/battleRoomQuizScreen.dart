import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quizappuic/app/appLocalization.dart';
import 'package:quizappuic/app/routes.dart';
import 'package:quizappuic/features/battleRoom/cubits/opponentMessageCubit.dart';
import 'package:quizappuic/features/bookmark/bookmarkRepository.dart';
import 'package:quizappuic/features/bookmark/cubits/bookmarkCubit.dart';
import 'package:quizappuic/features/bookmark/cubits/updateBookmarkCubit.dart';
import 'package:quizappuic/features/battleRoom/cubits/battleRoomCubit.dart';
import 'package:quizappuic/features/profileManagement/cubits/userDetailsCubit.dart';
import 'package:quizappuic/features/quiz/models/question.dart';
import 'package:quizappuic/features/quiz/models/quizType.dart';
import 'package:quizappuic/features/quiz/models/userBattleRoomDetails.dart';
import 'package:quizappuic/ui/widgets/bookmarkButton.dart';
import 'package:quizappuic/ui/widgets/exitGameDailog.dart';
import 'package:quizappuic/ui/widgets/pageBackgroundGradientContainer.dart';

import 'package:quizappuic/ui/widgets/questionsContainer.dart';
import 'package:quizappuic/ui/widgets/quizPlayAreaBackgroundContainer.dart';
import 'package:quizappuic/ui/widgets/userDetailsWithTimerContainer.dart';
import 'package:quizappuic/utils/constants.dart';
import 'package:quizappuic/utils/uiUtils.dart';

class BattleRoomQuizScreen extends StatefulWidget {
  BattleRoomQuizScreen({Key? key}) : super(key: key);

  static Route<dynamic> route(RouteSettings routeSettings) {
    return CupertinoPageRoute(
        builder: (_) => MultiBlocProvider(providers: [
              BlocProvider<UpdateBookmarkCubit>(
                  create: (context) =>
                      UpdateBookmarkCubit(BookmarkRepository())),
            ], child: BattleRoomQuizScreen()));
  }

  @override
  _BattleRoomQuizScreenState createState() => _BattleRoomQuizScreenState();
}

class _BattleRoomQuizScreenState extends State<BattleRoomQuizScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController timerAnimationController = AnimationController(
      vsync: this, duration: Duration(seconds: questionDurationInSeconds))
    ..addStatusListener(currentUserTimerAnimationStatusListener)
    ..forward();
  late AnimationController opponentUserTimerAnimationController =
      AnimationController(
          vsync: this, duration: Duration(seconds: questionDurationInSeconds))
        ..forward();

  //to animate the question container
  late AnimationController questionAnimationController;
  late AnimationController questionContentAnimationController;
  //to slide the question container from right to left
  late Animation<double> questionSlideAnimation;
  //to scale up the second question
  late Animation<double> questionScaleUpAnimation;
  //to scale down the second question
  late Animation<double> questionScaleDownAnimation;
  //to slude the question content from right to left
  late Animation<double> questionContentAnimation;
  late int currentQuestionIndex = 0;

  //if user left the by pressing home button or lock screen
  //this will be true
  bool showYouLeftQuiz = false;

  //to track if setting dialog is open
  bool isSettingDialogOpen = false;

  final double bottomPadding = 15;

  @override
  void initState() {
    initializeAnimation();
    questionContentAnimationController.forward();
    WidgetsBinding.instance!.addObserver(this);
    super.initState();
  }

  @override
  void dispose() {
    timerAnimationController
        .removeStatusListener(currentUserTimerAnimationStatusListener);
    timerAnimationController.dispose();
    opponentUserTimerAnimationController.dispose();
    questionAnimationController.dispose();
    questionContentAnimationController.dispose();
    WidgetsBinding.instance!.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    //delete battle room
    if (state == AppLifecycleState.paused) {
      //delete battle room
      context.read<BattleRoomCubit>().deleteBattleRoom();
    }
    //show you left the game
    if (state == AppLifecycleState.resumed) {
      // came back to Foreground
      setState(() {
        showYouLeftQuiz = true;
      });
      timerAnimationController.stop();
      opponentUserTimerAnimationController.stop();
    }
  }

  //
  void initializeAnimation() {
    questionAnimationController =
        AnimationController(vsync: this, duration: Duration(milliseconds: 500));
    questionContentAnimationController =
        AnimationController(vsync: this, duration: Duration(milliseconds: 250));

    questionSlideAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
            parent: questionAnimationController, curve: Curves.easeInOut));
    questionScaleUpAnimation = Tween<double>(begin: 0.0, end: 0.1).animate(
        CurvedAnimation(
            parent: questionAnimationController,
            curve: Interval(0.0, 0.5, curve: Curves.easeInQuad)));
    questionScaleDownAnimation = Tween<double>(begin: 0.0, end: 0.05).animate(
        CurvedAnimation(
            parent: questionAnimationController,
            curve: Interval(0.5, 1.0, curve: Curves.easeOutQuad)));
    questionContentAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
            parent: questionContentAnimationController,
            curve: Curves.easeInQuad));
  }

  void toggleSettingDialog() {
    isSettingDialogOpen = !isSettingDialogOpen;
  }

  //listener for current user timer
  void currentUserTimerAnimationStatusListener(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      print("User has left the question so submit answer as -1");
      submitAnswer("-1");
    }
  }

  void updateSubmittedAnswerForBookmark(Question question) {
    if (context.read<BookmarkCubit>().hasQuestionBookmarked(question.id)) {
      context.read<BookmarkCubit>().updateSubmittedAnswerId(question);
    }
  }

  //to submit the answer
  void submitAnswer(String submittedAnswer) async {
    timerAnimationController.stop();

    //submitted answer will be id of the answerOption
    final battleRoomCubit = context.read<BattleRoomCubit>();
    if (!battleRoomCubit.getQuestions()[currentQuestionIndex].attempted) {
      //update answer locally
      context.read<BattleRoomCubit>().updateQuestionAnswer(
          battleRoomCubit.getQuestions()[currentQuestionIndex].id,
          submittedAnswer);
      updateSubmittedAnswerForBookmark(
          battleRoomCubit.getQuestions()[currentQuestionIndex]);

      //need to give the delay so user can see the correct answer or incorrect
      await Future.delayed(Duration(seconds: inBetweenQuestionTimeInSeconds));
      //update answer and current points in database

      battleRoomCubit.submitAnswer(
        context.read<UserDetailsCubit>().getUserId(),
        submittedAnswer,
        battleRoomCubit
                .getQuestions()[currentQuestionIndex]
                .correctAnswerOptionId ==
            submittedAnswer,
        UiUtils.determineBattleCorrectAnswerPoints(
            timerAnimationController.value), //
      );
    }
  }

  //if user has submitted the answer for current question
  bool hasSubmittedAnswerForCurrentQuestion() {
    return context
        .read<BattleRoomCubit>()
        .getQuestions()[currentQuestionIndex]
        .attempted;
  }

  //next question
  void changeQuestion() {
    questionAnimationController.forward(from: 0.0).then((value) {
      //need to dispose the animation controllers
      questionAnimationController.dispose();
      questionContentAnimationController.dispose();
      //initializeAnimation again
      setState(() {
        initializeAnimation();
        currentQuestionIndex++;
      });
      //load content(options, image etc) of question
      questionContentAnimationController.forward();
    });
  }

  //for changing ui and other trigger other actions based on realtime changes that occured in game
  void battleRoomListener(BuildContext context, BattleRoomState state,
      BattleRoomCubit battleRoomCubit) {
    if (state is BattleRoomUserFound) {
      UserBattleRoomDetails opponentUserDetails = battleRoomCubit
          .getOpponentUserDetails(context.read<UserDetailsCubit>().getUserId());
      UserBattleRoomDetails currentUserDetails = battleRoomCubit
          .getCurrentUserDetails(context.read<UserDetailsCubit>().getUserId());

      //if user has left the game
      if (state.hasLeft) {
        timerAnimationController.stop();
        opponentUserTimerAnimationController.stop();
      } else {
        //check if opponent user has submitted the answer
        if (opponentUserDetails.answers.length == (currentQuestionIndex + 1)) {
          opponentUserTimerAnimationController.stop();
        }
        //if both users submitted the answer then change question
        if (state.battleRoom.user1!.answers.length ==
            state.battleRoom.user2!.answers.length) {
          //
          //if user has not submitted the answers for all questions then move to next question
          //
          if (state.battleRoom.user1!.answers.length !=
              state.questions.length) {
            //
            //since submitting answer locally will change the cubit state
            //to avoid calling changeQuestion() called twice
            //need to add this condition
            //
            if (!state.questions[currentUserDetails.answers.length].attempted) {
              //stop any timer
              timerAnimationController.stop();
              opponentUserTimerAnimationController.stop();
              //change the question
              changeQuestion();
              //run timer again
              timerAnimationController.forward(from: 0.0);
              opponentUserTimerAnimationController.forward(from: 0.0);
            }
          }
          //else move to result screen
          else {
            //stop timers if any running
            timerAnimationController.stop();
            opponentUserTimerAnimationController.stop();

            //delete messages by current user
            deleteMessages(battleRoomCubit);
            //delete room
            battleRoomCubit.deleteBattleRoom();
            //navigate to result
            if (isSettingDialogOpen) {
              Navigator.of(context).pop();
            }
            Navigator.of(context).pushReplacementNamed(
              Routes.result,
              arguments: {
                "questions": state.questions,
                "battleRoom": state.battleRoom,
                "numberOfPlayer": 2,
                "quizType": QuizTypes.battle,
              },
            );
          }
        }
      }
    }
  }

  Widget _buildCurrentUserDetailsContainer() {
    BattleRoomCubit battleRoomCubit = context.read<BattleRoomCubit>();
    return PositionedDirectional(
        bottom: bottomPadding,
        start: 10,
        child: BlocBuilder<BattleRoomCubit, BattleRoomState>(
          bloc: battleRoomCubit,
          builder: (context, state) {
            if (state is BattleRoomUserFound) {
              UserBattleRoomDetails curretUserDetails =
                  battleRoomCubit.getCurrentUserDetails(
                      context.read<UserDetailsCubit>().getUserId());
              //it contains correct answer by respective user and user name
              return UserDetailsWithTimerContainer(
                points: curretUserDetails.points.toString(),
                isCurrentUser: true,
                name: curretUserDetails.name,
                timerAnimationController: timerAnimationController,
                profileUrl: curretUserDetails.profileUrl,
              );
            }
            return Container();
          },
        ));
  }

  Widget _buildOpponentUserDetailsContainer() {
    BattleRoomCubit battleRoomCubit = context.read<BattleRoomCubit>();
    return PositionedDirectional(
        bottom: bottomPadding,
        end: 10,
        child: BlocBuilder<BattleRoomCubit, BattleRoomState>(
          bloc: battleRoomCubit,
          builder: (context, state) {
            if (state is BattleRoomUserFound) {
              UserBattleRoomDetails opponentUserDetails =
                  battleRoomCubit.getOpponentUserDetails(
                      context.read<UserDetailsCubit>().getUserId());
              //it contains correct answer by respective user and user name
              return UserDetailsWithTimerContainer(
                points: opponentUserDetails.points.toString(),
                isCurrentUser: false,
                name: opponentUserDetails.name,
                timerAnimationController: opponentUserTimerAnimationController,
                profileUrl: opponentUserDetails.profileUrl,
              );
            }
            return Container();
          },
        ));
  }

  //if opponent user has left the game this dialog will be shown
  Widget _buildYouWonGameDailog(BattleRoomCubit battleRoomCubit) {
    return showYouLeftQuiz
        ? Container()
        : BlocBuilder<BattleRoomCubit, BattleRoomState>(
            bloc: battleRoomCubit,
            builder: (context, state) {
              if (state is BattleRoomUserFound) {
                //show you won game only opponent user has left the game
                if (state.hasLeft &&
                    battleRoomCubit
                            .getCurrentUserDetails(
                                context.read<UserDetailsCubit>().getUserId())
                            .answers
                            .length !=
                        state.questions.length) {
                  return Container(
                    alignment: Alignment.center,
                    color: Theme.of(context).backgroundColor.withOpacity(0.1),
                    width: MediaQuery.of(context).size.width,
                    height: MediaQuery.of(context).size.height,
                    child: AlertDialog(
                      title: Text(
                        AppLocalization.of(context)!
                            .getTranslatedValues('youWonLbl')!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                      content: Text(
                        AppLocalization.of(context)!
                            .getTranslatedValues('opponentLeftLbl')!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                      actions: [
                        CupertinoButton(
                            child: Text(
                              AppLocalization.of(context)!
                                  .getTranslatedValues('okayLbl')!,
                              style: TextStyle(
                                  color: Theme.of(context).primaryColor),
                            ),
                            onPressed: () {
                              deleteMessages(battleRoomCubit);
                              Navigator.of(context).pop();
                            }),
                      ],
                    ),
                  );
                }
              }
              return Container();
            },
          );
  }

  //if currentUser has left the game
  Widget _buildCurrentUserLeftTheGame() {
    return showYouLeftQuiz
        ? Container(
            color: Theme.of(context).backgroundColor.withOpacity(0.12),
            child: Center(
              child: AlertDialog(
                content: Text(
                  AppLocalization.of(context)!
                      .getTranslatedValues('youLeftLbl')!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ),
                actions: [
                  CupertinoButton(
                      child: Text(
                        AppLocalization.of(context)!
                            .getTranslatedValues('okayLbl')!,
                        style: TextStyle(color: Theme.of(context).primaryColor),
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                      })
                ],
              ),
            ),
          )
        : Container();
  }

  Widget _buildBookmarkButton(BattleRoomCubit battleRoomCubit) {
    return BlocBuilder<BattleRoomCubit, BattleRoomState>(
      bloc: battleRoomCubit,
      builder: (context, state) {
        if (state is BattleRoomUserFound)
          return BookmarkButton(
            question: state.questions[currentQuestionIndex],
          );
        return Container();
      },
    );
  }

  void deleteMessages(BattleRoomCubit battleRoomCubit) {
    //to delete messages by given user
    //context.read<MessageCubit>().deleteMessages(battleRoomCubit.getRoomId(), context.read<UserDetailsCubit>().getUserId());
  }

  @override
  Widget build(BuildContext context) {
    final battleRoomCubit = context.read<BattleRoomCubit>();
    return WillPopScope(
      onWillPop: () {
        //if user left the game
        if (showYouLeftQuiz) {
          return Future.value(true);
        }
        //show warning
        showDialog(
            context: context,
            builder: (context) {
              return ExitGameDailog(
                onTapYes: () {
                  //
                  timerAnimationController.stop();
                  opponentUserTimerAnimationController.stop();
                  //delete messages
                  deleteMessages(battleRoomCubit);
                  //delete battle room
                  battleRoomCubit.deleteBattleRoom();
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                },
              );
            });
        return Future.value(false);
      },
      child: Scaffold(
        body: MultiBlocListener(
          listeners: [
            BlocListener<BattleRoomCubit, BattleRoomState>(
              bloc: battleRoomCubit,
              listener: (context, state) {
                //since this listener will be call everytime if any changes occurred
                //in battleRoomCubit
                battleRoomListener(context, state, battleRoomCubit);
              },
            ),
          ],
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              PageBackgroundGradientContainer(),
              Align(
                alignment: Alignment.topCenter,
                child: QuizPlayAreaBackgroundContainer(
                  heightPercentage: 0.875,
                ),
              ),
              Align(
                alignment: Alignment.topCenter,
                child: QuestionsContainer(
                  toggleSettingDialog: toggleSettingDialog,
                  showAnswerCorrectness: true,
                  lifeLines: {},
                  bookmarkButton: _buildBookmarkButton(battleRoomCubit),
                  guessTheWordQuestionContainerKeys: [],
                  guessTheWordQuestions: [],
                  hasSubmittedAnswerForCurrentQuestion:
                      hasSubmittedAnswerForCurrentQuestion,
                  questions: battleRoomCubit.getQuestions(),
                  submitAnswer: submitAnswer,
                  questionContentAnimation: questionContentAnimation,
                  questionScaleDownAnimation: questionScaleDownAnimation,
                  questionScaleUpAnimation: questionScaleUpAnimation,
                  questionSlideAnimation: questionSlideAnimation,
                  currentQuestionIndex: currentQuestionIndex,
                  questionAnimationController: questionAnimationController,
                  questionContentAnimationController:
                      questionContentAnimationController,
                ),
              ),
              _buildCurrentUserDetailsContainer(),
              _buildOpponentUserDetailsContainer(),
              _buildYouWonGameDailog(battleRoomCubit),
              _buildCurrentUserLeftTheGame(),
            ],
          ),
        ),
      ),
    );
  }
}
