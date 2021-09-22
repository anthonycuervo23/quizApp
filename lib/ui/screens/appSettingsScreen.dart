import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quizappuic/app/appLocalization.dart';
import 'package:quizappuic/features/systemConfig/cubits/appSettingsCubit.dart';
import 'package:quizappuic/features/systemConfig/systemConfigRepository.dart';
import 'package:quizappuic/ui/widgets/circularProgressContainner.dart';
import 'package:quizappuic/ui/widgets/errorContainer.dart';
import 'package:quizappuic/ui/widgets/roundedAppbar.dart';

import 'package:quizappuic/utils/errorMessageKeys.dart';
import 'package:quizappuic/utils/stringLabels.dart';
import 'package:quizappuic/utils/uiUtils.dart';

import 'package:webview_flutter/webview_flutter.dart';

class AppSettingsScreen extends StatefulWidget {
  final String title;
  AppSettingsScreen({Key? key, required this.title}) : super(key: key);

  static Route<AppSettingsScreen> route(RouteSettings routeSettings) {
    return CupertinoPageRoute(
        builder: (_) => BlocProvider<AppSettingsCubit>(
              create: (_) => AppSettingsCubit(
                SystemConfigRepository(),
              ),
              child:
                  AppSettingsScreen(title: routeSettings.arguments as String),
            ));
  }

  @override
  _AppSettingsScreenState createState() => _AppSettingsScreenState();
}

//about_us / privacy_policy / terms_conditions / contact_us / instructions
class _AppSettingsScreenState extends State<AppSettingsScreen> {
  late WebViewController webViewController;

  String getType() {
    if (widget.title == aboutUs) {
      return "about_us";
    }
    if (widget.title == privacyPolicy) {
      return "privacy_policy";
    }
    if (widget.title == termsAndConditions) {
      return "terms_conditions";
    }
    if (widget.title == contactUs) {
      return "contact_us";
    }
    if (widget.title == howToPlayLbl) {
      return "instructions";
    }

    print(widget.title);
    return "";
  }

  @override
  void initState() {
    getAppSetting();
    super.initState();
  }

  void getAppSetting() {
    Future.delayed(Duration.zero, () {
      context.read<AppSettingsCubit>().getAppSetting(getType());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).backgroundColor,
      body: Stack(
        children: [
          //PageBackgroundGradientContainer(),
          Align(
              alignment: Alignment.topCenter,
              child: RoundedAppbar(
                title: AppLocalization.of(context)!
                    .getTranslatedValues(widget.title)!,
              )),
          BlocBuilder<AppSettingsCubit, AppSettingsState>(
            bloc: context.read<AppSettingsCubit>(),
            builder: (context, state) {
              if (state is AppSettingsFetchInProgress ||
                  state is AppSettingsIntial) {
                return Center(
                  child: CircularProgressContainer(useWhiteLoader: false),
                );
              }
              if (state is AppSettingsFetchFailure) {
                return Center(
                  child: ErrorContainer(
                    errorMessage: AppLocalization.of(context)!
                        .getTranslatedValues(
                            convertErrorCodeToLanguageKey(state.errorCode))!,
                    onTapRetry: () {
                      getAppSetting();
                    },
                    showErrorImage: true,
                    errorMessageColor: Theme.of(context).primaryColor,
                  ),
                );
              }
              return Padding(
                  padding: EdgeInsets.only(
                    top: (MediaQuery.of(context).size.height *
                            (UiUtils.appBarHeightPercentage)) +
                        15.0,
                  ),
                  child: WebView(
                    javascriptMode: JavascriptMode.unrestricted,
                    initialUrl: Uri.dataFromString(
                            (state as AppSettingsFetchSuccess).settingsData,
                            mimeType: 'text/html',
                            encoding: Encoding.getByName('utf-8'))
                        .toString(),
                  )
                  //
                  // initialUrl: Uri.dataFromString((state as AppSettingsFetchSuccess).settingsData, mimeType: 'text/html', encoding: Encoding.getByName('utf-8')).toString(),
                  );
            },
          )
        ],
      ),
    );
  }
}
