import 'package:flutter/material.dart';
import 'package:quizappuic/app/appLocalization.dart';
import 'package:quizappuic/app/routes.dart';
import 'package:quizappuic/features/quiz/models/quizType.dart';
import 'package:quizappuic/features/systemConfig/cubits/systemConfigCubit.dart';
import 'package:quizappuic/ui/screens/battle/widgets/createRoomDialog.dart';
import 'package:quizappuic/ui/screens/battle/widgets/joinRoomDialog.dart';
import 'package:quizappuic/utils/stringLabels.dart';
import 'package:quizappuic/utils/uiUtils.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class RoomOptionDialog extends StatelessWidget {
  RoomOptionDialog({Key? key}) : super(key: key);

  TextStyle _buildTextStyle(BuildContext context) {
    return TextStyle(
      color: Theme.of(context).primaryColor,
      fontSize: 16.0,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      children: [
        TextButton(
          onPressed: () {
            if (context
                    .read<SystemConfigCubit>()
                    .getIsCategoryEnableForGroupBattle() ==
                "1") {
              Navigator.of(context).pop();
              //go to category page
              Navigator.of(context).pushNamed(Routes.category, arguments: {
                "quizType": QuizTypes.groupPlay,
              });
            } else {
              Navigator.of(context).pop();
              showDialog(
                  context: context,
                  builder: (context) => CreateRoomDialog(
                        categoryId: "",
                      ));
            }
          },
          child: Text(
            AppLocalization.of(context)!.getTranslatedValues(createRoomKey)!,
            style: _buildTextStyle(context),
          ),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            showDialog(
                context: context, builder: (context) => JoinRoomDialog());
          },
          child: Text(
            AppLocalization.of(context)!.getTranslatedValues(joinRoomKey)!,
            style: _buildTextStyle(context),
          ),
        )
      ],
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(UiUtils.dailogRadius)),
    );
  }
}
