import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quizappuic/app/appLocalization.dart';
import 'package:quizappuic/app/routes.dart';
import 'package:quizappuic/features/quiz/cubits/comprehensionCubit.dart';
import 'package:quizappuic/features/quiz/models/quizType.dart';
import 'package:quizappuic/features/quiz/quizRepository.dart';

import 'package:quizappuic/ui/widgets/circularProgressContainner.dart';
import 'package:quizappuic/ui/widgets/customBackButton.dart';
import 'package:quizappuic/ui/widgets/errorContainer.dart';
import 'package:quizappuic/ui/widgets/pageBackgroundGradientContainer.dart';
import 'package:quizappuic/utils/errorMessageKeys.dart';

class FunAndLearnTitleScreen extends StatefulWidget {
  final QuizTypes? quizType;

  const FunAndLearnTitleScreen({Key? key, this.quizType}) : super(key: key);
  @override
  _FunAndLearnTitleScreen createState() => _FunAndLearnTitleScreen();
  static Route<dynamic> route(RouteSettings routeSettings) {
    Map? arguments = routeSettings.arguments as Map?;
    return CupertinoPageRoute(
        builder: (_) => MultiBlocProvider(
              providers: [
                BlocProvider<ComprehensionCubit>(
                  create: (_) => ComprehensionCubit(QuizRepository()),
                ),
              ],
              child: FunAndLearnTitleScreen(
                quizType: arguments!['quizType'] as QuizTypes?,
              ),
            ));
  }
}

class _FunAndLearnTitleScreen extends State<FunAndLearnTitleScreen> {
  @override
  void initState() {
    Future.delayed(Duration.zero, () {
      context.read<ComprehensionCubit>().getComprehension();
    });
    super.initState();
  }

  Widget _buildBackButton() {
    return Align(
      alignment: AlignmentDirectional.topStart,
      child: Padding(
        padding: EdgeInsetsDirectional.only(top: 15.0, start: 20),
        child: CustomBackButton(
          iconColor: Theme.of(context).primaryColor,
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).size.height * (0.085),
        ),
        child: BlocConsumer<ComprehensionCubit, ComprehensionState>(
            bloc: context.read<ComprehensionCubit>(),
            listener: (context, state) {},
            builder: (context, state) {
              if (state is ComprehensionProgress ||
                  state is ComprehensionInitial) {
                return Center(
                  child: CircularProgressContainer(
                    useWhiteLoader: false,
                  ),
                );
              }
              if (state is ComprehensionFailure) {
                return ErrorContainer(
                  errorMessage: AppLocalization.of(context)!
                      .getTranslatedValues(
                          convertErrorCodeToLanguageKey(state.errorMessage)),
                  onTapRetry: () {
                    context.read<ComprehensionCubit>().getComprehension();
                  },
                  showErrorImage: true,
                );
              }
              final questions =
                  (state as ComprehensionSuccess).getComprehension;
              return ListView.builder(
                  shrinkWrap: true,
                  padding: EdgeInsets.only(bottom: 15.0),
                  itemCount: questions.length,
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () {
                        Navigator.of(context)
                            .pushNamed(Routes.funAndLearn, arguments: {
                          "detail": questions[index].detail,
                          "id": questions[index].id,
                          "quizType": widget.quizType
                        });
                      },
                      child: Card(
                        margin: EdgeInsets.symmetric(
                          horizontal: 20.0,
                          vertical: 10.0,
                        ),
                        color: Theme.of(context).primaryColor,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20)),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Spacer(),
                            Text(
                              questions[index].title!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 20.0,
                                color: Theme.of(context).backgroundColor,
                              ),
                            ),
                            Spacer(),
                            Container(
                              height: 90,
                              width: 100,
                              padding: EdgeInsets.all(5),
                              child: Card(
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20)),
                                child: Center(
                                    child: Text(
                                  "${questions[index].noOfQue}\n" +
                                      AppLocalization.of(context)!
                                          .getTranslatedValues("questionLbl")!,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      color: Theme.of(context).primaryColor,
                                      height: 1.0),
                                )),
                              ),
                            )
                          ],
                        ),
                      ),
                    );
                  });
            }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Padding(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top,
      ),
      child: Stack(
        children: [
          PageBackgroundGradientContainer(),
          _buildBackButton(),
          _buildTitle()
        ],
      ),
    ));
  }
}
