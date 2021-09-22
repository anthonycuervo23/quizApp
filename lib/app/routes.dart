import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:quizappuic/ui/screens/appSettingsScreen.dart';
import 'package:quizappuic/ui/screens/auth/signInScreen.dart';
import 'package:quizappuic/ui/screens/auth/signUpScreen.dart';
import 'package:quizappuic/ui/screens/battle/battleRoomFindOpponentScreen.dart';
import 'package:quizappuic/ui/screens/bookmarkScreen.dart';
import 'package:quizappuic/ui/screens/coinStoreScreen.dart';
import 'package:quizappuic/ui/screens/home/homeScreen.dart';
import 'package:quizappuic/ui/screens/introSliderScreen.dart';
import 'package:quizappuic/ui/screens/leaderBoardScreen.dart';
import 'package:quizappuic/ui/screens/notificationScreen.dart';
import 'package:quizappuic/ui/screens/profile/profileScreen.dart';
import 'package:quizappuic/ui/screens/battle/battleRoomQuizScreen.dart';

import 'package:quizappuic/ui/screens/quiz/bookmarkQuizScreen.dart';
import 'package:quizappuic/ui/screens/quiz/categoryScreen.dart';
import 'package:quizappuic/ui/screens/quiz/contestLeaderboardScreen.dart';
import 'package:quizappuic/ui/screens/quiz/contestScreen.dart';
import 'package:quizappuic/ui/screens/quiz/funAndLearnScreen.dart';
import 'package:quizappuic/ui/screens/quiz/funAndLearnTitleScreen.dart';
import 'package:quizappuic/ui/screens/quiz/guessTheWordQuizScreen.dart';
import 'package:quizappuic/ui/screens/battle/multiUserBattleRoomQuizScreen.dart';
import 'package:quizappuic/ui/screens/battle/multiUserBattleRoomResultScreen.dart';
import 'package:quizappuic/ui/screens/quiz/levelsScreen.dart';
import 'package:quizappuic/ui/screens/quiz/reviewAnswersScreen.dart';
import 'package:quizappuic/ui/screens/quiz/selfChallengeQuestionsScreen.dart';
import 'package:quizappuic/ui/screens/quiz/selfChallengeScreen.dart';

import 'package:quizappuic/ui/screens/quiz/subCategoryAndLevelScreen.dart';
import 'package:quizappuic/ui/screens/quiz/quizScreen.dart';
import 'package:quizappuic/ui/screens/quiz/resultScreen.dart';

import 'package:quizappuic/ui/screens/referAndEarnScreen.dart';
import 'package:quizappuic/ui/screens/rewardsScreen.dart';
import 'package:quizappuic/ui/screens/profile/selectProfilePictureScreen.dart';

import 'package:quizappuic/ui/screens/splashScreen.dart';
import 'package:quizappuic/ui/screens/statisticScreen.dart';

class Routes {
  static const home = "/";
  static const login = "login";
  static const splash = 'splash';
  static const signUp = "signUp";
  static const introSlider = "introSlider";
  static const selectProfile = "selectProfile";
  static const quiz = "/quiz";
  static const subcategoryAndLevel = "/subcategoryAndLevel";
  static const statistics = "/statistics";
  static const referAndEarn = "/referAndEarn";
  static const notification = "/notification";
  static const bookmark = "/bookmark";
  static const bookmarkQuiz = "/bookmarkQuiz";
  static const coinStore = "/coinStore";
  static const rewards = "/rewards";
  static const result = "/result";
  static const selectRoom = "/selectRoom";
  static const category = "/category";
  static const profile = "/profile";
  static const editProfile = "/editProfile";
  static const leaderBoard = "/leaderBoard";
  static const reviewAnswers = "/reviewAnswers";
  static const selfChallenge = "/selfChallenge";
  static const selfChallengeQuestions = "/selfChallengeQuestions";
  static const battleRoomQuiz = "/battleRoomQuiz";
  static const battleRoomFindOpponent = "/battleRoomFindOpponent";

  static const logOut = "/logOut";
  static const trueFalse = "/trueFalse";
  static const multiUserBattleRoomQuiz = "/multiUserBattleRoomQuiz";
  static const multiUserBattleRoomQuizResult = "/multiUserBattleRoomQuizResult";

  static const contest = "/contest";
  static const contestLeaderboard = "/contestLeaderboard";
  static const funAndLearnTitle = "/funAndLearnTitle";
  static const funAndLearn = "funAndLearn";
  static const guessTheWord = "/guessTheWord";
  static const appSettings = "/appSettings";
  static const levels = "/levels";

  static Route<dynamic> onGenerateRouted(RouteSettings routeSettings) {
    switch (routeSettings.name) {
      case splash:
        return CupertinoPageRoute(builder: (context) => SplashScreen());
      case home:
        return HomeScreen.route(routeSettings);
      case introSlider:
        return CupertinoPageRoute(builder: (context) => IntroSliderScreen());
      case login:
        return CupertinoPageRoute(builder: (context) => SignInScreen());
      case signUp:
        return CupertinoPageRoute(builder: (context) => SignUpScreen());

      case subcategoryAndLevel:
        return SubCategoryAndLevelScreen.route(routeSettings);
      case selectProfile:
        return SelectProfilePictureScreen.route(routeSettings);
      case quiz:
        return QuizScreen.route(routeSettings);

      case coinStore:
        return CoinStoreScreen.route(routeSettings);
      case rewards:
        return CupertinoPageRoute(builder: (_) => RewardsScreen());
      case statistics:
        return StatisticScreen.route(routeSettings);
      case referAndEarn:
        return CupertinoPageRoute(builder: (_) => ReferAndEarnScreen());
      case result:
        return ResultScreen.route(routeSettings);
      case profile:
        return ProfileScreen.route(routeSettings);
      case reviewAnswers:
        return ReviewAnswersScreen.route(routeSettings);
      case selfChallenge:
        return SelfChallengeScreen.route(routeSettings);
      case selfChallengeQuestions:
        return SelfChallengeQuestionsScreen.route(routeSettings);
      case category:
        return CategoryScreen.route(routeSettings);
      case leaderBoard:
        return LeaderBoardScreen.route(routeSettings);
      case bookmark:
        return CupertinoPageRoute(builder: (context) => BookmarkScreen());
      case bookmarkQuiz:
        return BookmarkQuizScreen.route(routeSettings);
      case battleRoomQuiz:
        return BattleRoomQuizScreen.route(routeSettings);

      case notification:
        return NotificationScreen.route(routeSettings);
      /*case trueFalse:
        return TrueFalseScreen.route(routeSettings);*/
      case funAndLearnTitle:
        return FunAndLearnTitleScreen.route(routeSettings);
      case funAndLearn:
        return FunAndLearnScreen.route(routeSettings);
      case multiUserBattleRoomQuiz:
        return MultiUserBattleRoomQuizScreen.route(routeSettings);
      case contest:
        return ContestScreen.route(routeSettings);

      case guessTheWord:
        return GuessTheWordQuizScreen.route(routeSettings);

      case multiUserBattleRoomQuizResult:
        return MultiUserBattleRoomResultScreen.route(routeSettings);

      case contestLeaderboard:
        return ContestLeaderBoardScreen.route(routeSettings);

      case battleRoomFindOpponent:
        return BattleRoomFindOpponentScreen.route(routeSettings);

      case appSettings:
        return AppSettingsScreen.route(routeSettings);

      case levels:
        return LevelsScreen.route(routeSettings);

      default:
        return CupertinoPageRoute(builder: (context) => Scaffold());
    }
  }
}
