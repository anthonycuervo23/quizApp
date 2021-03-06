import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quizappuic/features/profileManagement/profileManagementRepository.dart';

@immutable
abstract class UpdateScoreAndCoinsState {}

class UpdateScoreAndCoinsInitial extends UpdateScoreAndCoinsState {}

class UpdateScoreAndCoinsInProgress extends UpdateScoreAndCoinsState {}

class UpdateScoreAndCoinsSuccess extends UpdateScoreAndCoinsState {
  final String? score;
  final String? coins;
  UpdateScoreAndCoinsSuccess({this.coins, this.score});
}

class UpdateScoreAndCoinsFailure extends UpdateScoreAndCoinsState {
  final String errorMessage;
  UpdateScoreAndCoinsFailure(this.errorMessage);
}

class UpdateScoreAndCoinsCubit extends Cubit<UpdateScoreAndCoinsState> {
  final ProfileManagementRepository _profileManagementRepository;
  UpdateScoreAndCoinsCubit(this._profileManagementRepository)
      : super(UpdateScoreAndCoinsInitial());

  void updateCoins(String? userId, int? coins, bool addCoin) async {
    emit(UpdateScoreAndCoinsInProgress());

    _profileManagementRepository
        .updateConins(userId: userId, coins: coins, addCoin: addCoin)
        .then(
          (result) => emit(UpdateScoreAndCoinsSuccess(
              coins: result['coins'], score: result['score'])),
        )
        .catchError((e) {
      emit(UpdateScoreAndCoinsFailure(e.toString()));
    });
  }

  void updateScore(String? userId, int? score) async {
    emit(UpdateScoreAndCoinsInProgress());
    _profileManagementRepository
        .updateScore(userId: userId, score: score)
        .then(
          (result) => UpdateScoreAndCoinsSuccess(
              coins: result['coins'], score: result['score']),
        )
        .catchError((e) {
      emit(UpdateScoreAndCoinsFailure(e.toString()));
    });
  }

  void updateCoinsAndScore(
      String? userId, int? score, bool addCoin, int coins) async {
    emit(UpdateScoreAndCoinsInProgress());

    _profileManagementRepository
        .updateConinsAndScore(
            userId: userId, coins: coins, addCoin: addCoin, score: score)
        .then(
          (result) => emit(UpdateScoreAndCoinsSuccess(
              coins: result['coins'], score: result['score'])),
        )
        .catchError((e) {
      emit(UpdateScoreAndCoinsFailure(e.toString()));
    });
  }
}
