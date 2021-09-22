import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:quizappuic/app/appLocalization.dart';
import 'package:quizappuic/app/routes.dart';
import 'package:quizappuic/features/auth/authRepository.dart';
import 'package:quizappuic/features/auth/cubits/authCubit.dart';
import 'package:quizappuic/features/battleRoom/battleRoomRepository.dart';
import 'package:quizappuic/features/battleRoom/cubits/battleRoomCubit.dart';
import 'package:quizappuic/features/battleRoom/cubits/multiUserBattleRoomCubit.dart';
import 'package:quizappuic/features/bookmark/bookmarkRepository.dart';
import 'package:quizappuic/features/localization/appLocalizationCubit.dart';
import 'package:quizappuic/features/profileManagement/cubits/userDetailsCubit.dart';
import 'package:quizappuic/features/bookmark/cubits/bookmarkCubit.dart';
import 'package:quizappuic/features/settings/settingsCubit.dart';
import 'package:quizappuic/features/profileManagement/profileManagementRepository.dart';
import 'package:quizappuic/features/settings/settingsLocalDataSource.dart';
import 'package:quizappuic/features/settings/settingsRepository.dart';
import 'package:quizappuic/features/systemConfig/cubits/systemConfigCubit.dart';
import 'package:quizappuic/features/systemConfig/systemConfigRepository.dart';
import 'package:quizappuic/ui/styles/theme/appTheme.dart';
import 'package:quizappuic/ui/styles/theme/themeCubit.dart';
import 'package:quizappuic/utils/constants.dart';
import 'package:quizappuic/utils/uiUtils.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';

Future<Widget> initializeApp() async {
  WidgetsFlutterBinding.ensureInitialized();
  MobileAds.instance.initialize();

  if (!kIsWeb) {
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarBrightness: Brightness.dark,
        statusBarIconBrightness: Brightness.dark));

    await Firebase.initializeApp();
    FirebaseFirestore.instance.settings = Settings(persistenceEnabled: false);
    if (defaultTargetPlatform == TargetPlatform.android) {
      InAppPurchaseAndroidPlatformAddition.enablePendingPurchases();
    }
  }

  await Hive.initFlutter();
  await Hive.openBox(
      authBox); //auth box for storing all authentication related details
  await Hive.openBox(
      settingsBox); //settings box for storing all settings details
  await Hive.openBox(
      userdetailsBox); //userDetails box for storing all userDetails details

  return MyApp();
}

class GlobalScrollBehavior extends ScrollBehavior {
  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return BouncingScrollPhysics();
  }
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    precacheImage(AssetImage(UiUtils.getImagePath("splash_logo.png")), context);
    precacheImage(AssetImage(UiUtils.getImagePath("map_finded.png")), context);
    precacheImage(AssetImage(UiUtils.getImagePath("map_finding.png")), context);

    return MultiBlocProvider(
      //providing global providers
      providers: [
        //Creating cubit/bloc that will be use in whole app or
        //will be use in multiple screens
        BlocProvider<ThemeCubit>(create: (_) => ThemeCubit()),
        BlocProvider<SettingsCubit>(
            create: (_) => SettingsCubit(SettingsRepository())),
        BlocProvider<AuthCubit>(create: (_) => AuthCubit(AuthRepository())),
        BlocProvider<AppLocalizationCubit>(
            create: (_) => AppLocalizationCubit(SettingsLocalDataSource())),
        BlocProvider<UserDetailsCubit>(
            create: (_) => UserDetailsCubit(ProfileManagementRepository())),
        BlocProvider<BookmarkCubit>(
            create: (_) => BookmarkCubit(BookmarkRepository())),
        //it will be use in multiple dialogs and screen
        BlocProvider<MultiUserBattleRoomCubit>(
            create: (_) => MultiUserBattleRoomCubit(BattleRoomRepository())),

        BlocProvider<BattleRoomCubit>(
            create: (_) => BattleRoomCubit(BattleRoomRepository())),

        //system config
        BlocProvider<SystemConfigCubit>(
            create: (_) => SystemConfigCubit(SystemConfigRepository())),
      ],
      child: Builder(
        builder: (context) {
          //Watching themeCubit means if any change occurs in themeCubit it will rebuild the child
          final currentTheme = context.watch<ThemeCubit>().state.appTheme;
          //

          final currentLanguage =
              context.watch<AppLocalizationCubit>().state.language;

          return MaterialApp(
            builder: (context, widget) {
              return ScrollConfiguration(
                  behavior: GlobalScrollBehavior(), child: widget!);
            },
            locale: currentLanguage,
            theme: appThemeData[currentTheme]!.copyWith(
                textTheme:
                    GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme)),
            debugShowCheckedModeBanner: false,
            localizationsDelegates: [
              AppLocalization.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: supporatedLocales.map((e) => Locale(e)).toList(),
            initialRoute: Routes.splash,
            onGenerateRoute: Routes.onGenerateRouted,
          );
        },
      ),
    );
  }
}
