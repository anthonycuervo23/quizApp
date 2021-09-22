import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quizappuic/features/statistic/statisticRepository.dart';

@immutable
abstract class UpdateStatisticState {}

class UpdateStatisticInitial extends UpdateStatisticState {}

class UpdateStatisticFetchInProgress extends UpdateStatisticState {}

class UpdateStatisticFetchSuccess extends UpdateStatisticState {
  UpdateStatisticFetchSuccess();
}

class UpdateStatisticFetchFailure extends UpdateStatisticState {
  final String errorMessageCode;
  UpdateStatisticFetchFailure(this.errorMessageCode);
}

class UpdateStatisticCubit extends Cubit<UpdateStatisticState> {
  final StatisticRepository _statisticRepository;
  UpdateStatisticCubit(this._statisticRepository)
      : super(UpdateStatisticInitial());

  void updateStatistic(
      {String? userId,
      int? answeredQuestion,
      int? correctAnswers,
      double? winPercentage,
      String? categoryId}) async {
    emit(UpdateStatisticFetchInProgress());
    try {
      await _statisticRepository.updateStatistic(
        answeredQuestion: answeredQuestion,
        categoryId: categoryId,
        correctAnswers: correctAnswers,
        userId: userId,
        winPercentage: winPercentage,
      );
      emit(UpdateStatisticFetchSuccess());
    } catch (e) {
      emit(UpdateStatisticFetchFailure(e.toString()));
    }
  }
}
