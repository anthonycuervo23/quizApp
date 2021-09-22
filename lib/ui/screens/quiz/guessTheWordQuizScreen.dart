import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quizappuic/app/appLocalization.dart';
import 'package:quizappuic/app/routes.dart';
import 'package:quizappuic/features/quiz/cubits/guessTheWordQuizCubit.dart';

import 'package:quizappuic/features/quiz/models/quizType.dart';
import 'package:quizappuic/features/quiz/quizRepository.dart';
import 'package:quizappuic/ui/screens/quiz/widgets/guessTheWordQuestionContainer.dart';

import 'package:quizappuic/ui/widgets/circularProgressContainner.dart';
import 'package:quizappuic/ui/widgets/customRoundedButton.dart';
import 'package:quizappuic/ui/widgets/errorContainer.dart';
import 'package:quizappuic/ui/widgets/exitGameDailog.dart';
import 'package:quizappuic/ui/widgets/horizontalTimerContainer.dart';
import 'package:quizappuic/ui/widgets/pageBackgroundGradientContainer.dart';
import 'package:quizappuic/ui/widgets/questionsContainer.dart';
import 'package:quizappuic/ui/widgets/quizPlayAreaBackgroundContainer.dart';
import 'package:quizappuic/utils/constants.dart';
import 'package:quizappuic/utils/errorMessageKeys.dart';
import 'package:quizappuic/utils/uiUtils.dart';

class GuessTheWordQuizScreen extends StatefulWidget {
  GuessTheWordQuizScreen({Key? key}) : super(key: key);

  @override
  _GuessTheWordQuizScreenState createState() => _GuessTheWordQuizScreenState();

  static Route<dynamic> route(RouteSettings routeSettings) {
    return CupertinoPageRoute(
        builder: (context) => MultiBlocProvider(
              providers: [
                BlocProvider<GuessTheWordQuizCubit>(
                    create: (_) => GuessTheWordQuizCubit(QuizRepository()))
              ],
              child: GuessTheWordQuizScreen(),
            ));
  }
}

class _GuessTheWordQuizScreenState extends State<GuessTheWordQuizScreen>
    with TickerProviderStateMixin {
  late AnimationController timerAnimationController = AnimationController(
      vsync: this,
      duration: Duration(seconds: guessTheWordQuestionDurationInSeconds))
    ..addStatusListener(currentUserTimerAnimationStatusListener);

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

  int _currentQuestionIndex = 0;

  //to track if setting dialog is open
  bool isSettingDialogOpen = false;

  late List<GlobalKey<GuessTheWordQuestionContainerState>>
      questionContainerKeys = [];

  @override
  void initState() {
    super.initState();
    initializeAnimation();
    //fetching question for quiz
    _getQuestions();
  }

  void _getQuestions() {
    Future.delayed(Duration.zero, () {
      context
          .read<GuessTheWordQuizCubit>()
          .getQuestion(UiUtils.getCurrentQuestionLanguageId(context));
    });
  }

  @override
  void dispose() {
    timerAnimationController
        .removeStatusListener(currentUserTimerAnimationStatusListener);
    timerAnimationController.dispose();
    questionContentAnimationController.dispose();
    questionAnimationController.dispose();
    super.dispose();
  }

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
      submitAnswer(questionContainerKeys[_currentQuestionIndex]
          .currentState!
          .getSubmittedAnswer());
    }
  }

  void submitAnswer(List<String> submittedAnswer) async {
    print(submittedAnswer);
    timerAnimationController.stop();
    final guessTheWordQuizCubit = context.read<GuessTheWordQuizCubit>();
    //if answer not submitted then submit answer
    if (!guessTheWordQuizCubit
        .getQuestions()[_currentQuestionIndex]
        .hasAnswered) {
      //submitted answer
      guessTheWordQuizCubit.submitAnswer(
          guessTheWordQuizCubit.getQuestions()[_currentQuestionIndex].id,
          submittedAnswer);
      //wait for some seconds
      await Future.delayed(Duration(seconds: inBetweenQuestionTimeInSeconds));
      //if currentQuestion is last then move user to result screen
      if (_currentQuestionIndex ==
          (guessTheWordQuizCubit.getQuestions().length - 1)) {
        if (isSettingDialogOpen) {
          Navigator.of(context).pop();
        }

        Navigator.of(context).pushReplacementNamed(Routes.result, arguments: {
          "myPoints": guessTheWordQuizCubit.getCurrentPoints(),
          "quizType": QuizTypes.guessTheWord,
          "numberOfPlayer": 1,
          "guessTheWordQuestions": guessTheWordQuizCubit.getQuestions(),
        });
      } else {
        //change question
        changeQuestion();
        timerAnimationController.forward(from: 0.0);
      }
    }
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
        _currentQuestionIndex++;
      });
      //load content(options, image etc) of question
      questionContentAnimationController.forward();
    });
  }

  Widget _buildQuesitons(GuessTheWordQuizCubit guessTheWordQuizCubit) {
    return BlocBuilder<GuessTheWordQuizCubit, GuessTheWordQuizState>(
        builder: (context, state) {
      if (state is GuessTheWordQuizIntial ||
          state is GuessTheWordQuizFetchInProgress) {
        return Center(
          child: CircularProgressContainer(
            useWhiteLoader: true,
          ),
        );
      }
      if (state is GuessTheWordQuizFetchSuccess) {
        return Align(
          alignment: Alignment.topCenter,
          child: QuestionsContainer(
            toggleSettingDialog: toggleSettingDialog,
            showAnswerCorrectness: true,
            lifeLines: {},
            bookmarkButton: Container(),
            guessTheWordQuestionContainerKeys: questionContainerKeys,
            topPadding: 30.0,
            guessTheWordQuestions: state.questions,
            hasSubmittedAnswerForCurrentQuestion: () {},
            questions: [],
            submitAnswer: () {},
            questionContentAnimation: questionContentAnimation,
            questionScaleDownAnimation: questionScaleDownAnimation,
            questionScaleUpAnimation: questionScaleUpAnimation,
            questionSlideAnimation: questionSlideAnimation,
            currentQuestionIndex: _currentQuestionIndex,
            questionAnimationController: questionAnimationController,
            questionContentAnimationController:
                questionContentAnimationController,
          ),
        );
      }
      if (state is GuessTheWordQuizFetchFailure) {
        return Center(
          child: ErrorContainer(
              errorMessage: AppLocalization.of(context)?.getTranslatedValues(
                  convertErrorCodeToLanguageKey(state.errorMessage)),
              onTapRetry: () {
                _getQuestions();
              },
              showErrorImage: true),
        );
      }
      return Container();
    });
  }

  Widget _buildSubmitButton(GuessTheWordQuizCubit guessTheWordQuizCubit) {
    return BlocBuilder<GuessTheWordQuizCubit, GuessTheWordQuizState>(
      bloc: guessTheWordQuizCubit,
      builder: (context, state) {
        if (state is GuessTheWordQuizFetchSuccess) {
          return Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: EdgeInsets.only(bottom: 10.0),
              child: CustomRoundedButton(
                widthPercentage: 0.5,
                backgroundColor: Theme.of(context).primaryColor,
                buttonTitle: AppLocalization.of(context)!
                    .getTranslatedValues("submitBtn")!
                    .toUpperCase(),
                elevation: 5.0,
                shadowColor: Colors.black45,
                titleColor: Theme.of(context).backgroundColor,
                fontWeight: FontWeight.bold,
                onTap: () {
                  submitAnswer(questionContainerKeys[_currentQuestionIndex]
                      .currentState!
                      .getSubmittedAnswer());
                },
                radius: 10.0,
                showBorder: false,
                height: 45,
              ),
            ),
          );
        }
        return Container();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final GuessTheWordQuizCubit guessTheWordQuizCubit =
        context.read<GuessTheWordQuizCubit>();
    return WillPopScope(
      onWillPop: () {
        showDialog(context: context, builder: (_) => ExitGameDailog());
        return Future.value(false);
      },
      child: BlocListener<GuessTheWordQuizCubit, GuessTheWordQuizState>(
        bloc: guessTheWordQuizCubit,
        listener: (context, state) {
          if (state is GuessTheWordQuizFetchSuccess) {
            if (_currentQuestionIndex == 0 &&
                !state.questions[_currentQuestionIndex].hasAnswered) {
              state.questions.forEach((element) {
                questionContainerKeys
                    .add(GlobalKey<GuessTheWordQuestionContainerState>());
              });
              //start timer
              timerAnimationController.forward();
              questionContentAnimationController.forward();
            }
          }
        },
        child: Scaffold(
          body: Stack(
            children: [
              PageBackgroundGradientContainer(),
              Align(
                alignment: Alignment.topCenter,
                child: QuizPlayAreaBackgroundContainer(heightPercentage: 0.885),
              ),
              Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: EdgeInsets.only(
                      top: MediaQuery.of(context).padding.top + 7.5),
                  child: HorizontalTimerContainer(
                    timerAnimationController: timerAnimationController,
                  ),
                ),
              ),
              _buildQuesitons(guessTheWordQuizCubit),
              _buildSubmitButton(guessTheWordQuizCubit),
            ],
          ),
        ),
      ),
    );
  }
}
