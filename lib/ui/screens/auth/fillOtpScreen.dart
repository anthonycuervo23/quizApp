import 'dart:async';
import 'dart:ui';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quizappuic/app/appLocalization.dart';
import 'package:quizappuic/app/routes.dart';
import 'package:quizappuic/features/auth/authRepository.dart';
import 'package:quizappuic/features/auth/cubits/authCubit.dart';
import 'package:quizappuic/features/auth/cubits/signInCubit.dart';
import 'package:quizappuic/features/profileManagement/cubits/userDetailsCubit.dart';
import 'package:quizappuic/ui/screens/auth/widgets/termsAndCondition.dart';
import 'package:quizappuic/ui/widgets/circularProgressContainner.dart';
import 'package:quizappuic/ui/widgets/pageBackgroundGradientContainer.dart';
import 'package:quizappuic/utils/stringLabels.dart';
import 'package:quizappuic/utils/uiUtils.dart';
import 'package:lottie/lottie.dart';
import 'package:sms_autofill/sms_autofill.dart';

class FillOtpScreen extends StatefulWidget {
  final String? mobileNumber, countryCode, name;

  const FillOtpScreen(
      {Key? key, this.mobileNumber, this.countryCode, this.name})
      : super(key: key);
  @override
  _FillOtpScreen createState() => _FillOtpScreen();
}

class _FillOtpScreen extends State<FillOtpScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  String mobile = "", _verificationId = "", otp = "", signature = "";
  bool _isClickable = false,
      isCodeSent = false,
      isloading = false,
      isErrorOtp = false;
  TextEditingController otpController = TextEditingController();
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  late AnimationController buttonController;
  late Timer _timer;
  int _start = 60;

  bool hasError = false;
  String currentText = "";
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  final formKey = GlobalKey<FormState>();

  void startTimer() {
    const oneSec = const Duration(seconds: 1);
    _timer = new Timer.periodic(
      oneSec,
      (Timer timer) {
        if (_start == 0) {
          setState(() {
            _isClickable = true;
            timer.cancel();
          });
        } else {
          setState(() {
            _start--;
          });
        }
      },
    );
  }

  bool otpMobile(String value) {
    if (value.trim().isEmpty) {
      setState(() {
        isErrorOtp = true;
      });
      return false;
    }
    return false;
  }

//to get time to display in text widget
  String getTime() {
    String secondsAsString = _start < 10 ? "0$_start" : _start.toString();
    return "$secondsAsString";
  }

  static Future<bool> checkNet() async {
    bool check = false;
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.mobile) {
      check = true;
    } else if (connectivityResult == ConnectivityResult.wifi) {
      check = true;
    }
    return check;
  }

  @override
  void initState() {
    super.initState();
    getSingature();
    _onVerifyCode();
    startTimer();
    Future.delayed(Duration(seconds: 60)).then((_) {
      _isClickable = true;
    });
    buttonController = new AnimationController(
        duration: new Duration(milliseconds: 2000), vsync: this);
  }

  @override
  void dispose() {
    super.dispose();
    _timer.cancel();
    SmsAutoFill().unregisterListener();
    buttonController.dispose();
  }

  Future<void> getSingature() async {
    SmsAutoFill().getAppSignature.then((sign) {
      setState(() {
        signature = sign;
      });
    });
    await SmsAutoFill().listenForCode;
  }

  Future<void> checkNetworkOtpResend() async {
    bool checkInternet = await checkNet();
    if (checkInternet) {
      if (_isClickable) {
        _onVerifyCode();
      } else {
        UiUtils.setSnackbar(
            AppLocalization.of(context)!.getTranslatedValues('resendSnackBar')!,
            context,
            false);
      }
    } else {
      setState(() {
        checkInternet = false;
      });
      Future.delayed(Duration(seconds: 60)).then((_) async {
        bool checkInternet = await checkNet();
        if (checkInternet) {
          if (_isClickable)
            _onVerifyCode();
          else {
            UiUtils.setSnackbar(
                AppLocalization.of(context)!
                    .getTranslatedValues("resendSnackBar")!,
                context,
                false);
          }
        } else {
          await buttonController.reverse();
          UiUtils.setSnackbar(
              AppLocalization.of(context)!
                  .getTranslatedValues("noInterNetSnackBar")!,
              context,
              false);
        }
      });
    }
  }

  void _onVerifyCode() async {
    setState(() {
      isCodeSent = true;
    });
    final PhoneVerificationCompleted verificationCompleted =
        (AuthCredential phoneAuthCredential) {
      _firebaseAuth
          .signInWithCredential(phoneAuthCredential)
          .then((UserCredential value) {
        User? user = value.user;
        if (user != null) {
        } else {}
      }).catchError((error) {});
    };
    final PhoneVerificationFailed verificationFailed =
        (FirebaseAuthException authException) {
      setState(() {
        UiUtils.setSnackbar(
            AppLocalization.of(context)!.getTranslatedValues("otpNotMatch")!,
            context,
            false);
      });
    };
    final PhoneCodeSent codeSent =
        (String verificationId, [int? forceResendingToken]) async {
      if (mounted) {
        setState(() {
          _verificationId = verificationId;
        });
      }
    };
    final PhoneCodeAutoRetrievalTimeout codeAutoRetrievalTimeout =
        (String verificationId) {
      _verificationId = verificationId;
      if (mounted) {
        setState(() {
          _isClickable = true;
          _verificationId = verificationId;
        });
      }
    };
    await _firebaseAuth.verifyPhoneNumber(
        phoneNumber: "+${widget.countryCode}${widget.mobileNumber}",
        timeout: const Duration(seconds: 60),
        verificationCompleted: verificationCompleted,
        verificationFailed: verificationFailed,
        codeSent: codeSent,
        codeAutoRetrievalTimeout: codeAutoRetrievalTimeout);
  }

  void _onFormSubmitted() async {
    String code = otp.trim();
    if (code.length == 6) {
      setState(() {
        isloading = true;
      });
      AuthCredential _authCredential = PhoneAuthProvider.credential(
          verificationId: _verificationId, smsCode: code);
      _firebaseAuth
          .signInWithCredential(_authCredential)
          .then((UserCredential value) async {
        String? uid = value.user!.uid;
        String email = value.user!.email ?? "";
        String name = widget.name.toString();
        String profile = value.user!.photoURL ?? "";
        //update auth
        context.read<AuthCubit>().updateAuthDetails(
            authProvider: AuthProvider.mobile,
            authStatus: true,
            firebaseId: uid,
            isNewUser: false);

        if (value.additionalUserInfo!.isNewUser) {
          print("in if..........................................");
          context
              .read<AuthCubit>()
              .authRepository
              .addUserData(
                  firebaseId: uid,
                  type: "mobile",
                  name: name,
                  profile: profile,
                  mobile: widget.countryCode! + widget.mobileNumber!,
                  email: email,
                  friendCode: "",
                  referCode: "")
              .then((value) {
            if (mounted) {
              context.read<UserDetailsCubit>().fetchUserDetails(uid);
              Navigator.of(context)
                  .pushReplacementNamed(Routes.selectProfile, arguments: true);
              setState(() {
                isloading = false;
              });
            }
          });
        } else {
          print("in else...........................................");
          context.read<UserDetailsCubit>().fetchUserDetails(uid);
          Navigator.of(context)
              .pushReplacementNamed(Routes.home, arguments: false);
        }
        if (value.user != null) {
          await buttonController.reverse();
        } else {
          await buttonController.reverse();
        }
      }).catchError((error) async {
        if (mounted) {
          UiUtils.setSnackbar(error.toString(), context, false);
          await buttonController.reverse();
        }
      });
    } else {}
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SignInCubit>(
        create: (_) => SignInCubit(AuthRepository()),
        child: Builder(
            builder: (context) => Scaffold(
                resizeToAvoidBottomInset: true,
                body: Stack(
                  children: <Widget>[
                    Stack(
                      children: <Widget>[
                        PageBackgroundGradientContainer(),
                        SingleChildScrollView(
                          child: showForm(),
                        )
                      ],
                    ),
                  ],
                ))));
  }

  Widget showForm() {
    return Form(
      key: _formKey,
      child: Padding(
        padding: EdgeInsetsDirectional.only(
            start: MediaQuery.of(context).size.width * .05,
            end: MediaQuery.of(context).size.width * .08),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              SizedBox(
                height: MediaQuery.of(context).size.height * .07,
              ),
              otpLabel(),
              SizedBox(
                height: MediaQuery.of(context).size.height * .03,
              ),
              showTopImage(),
              showText(),
              numberText(),
              SizedBox(
                height: MediaQuery.of(context).size.height * .01,
              ),
              showPin(),
              SizedBox(
                height: MediaQuery.of(context).size.height * .08,
              ),
              resendText(),
              showVerify(),
              TermsAndCondition()
            ],
          ),
        ),
      ),
    );
  }

  Widget otpLabel() {
    return Text(
      AppLocalization.of(context)!.getTranslatedValues('otpVerificationLbl')!,
      textAlign: TextAlign.center,
      style: TextStyle(
          color: Theme.of(context).primaryColor,
          fontSize: 22,
          fontWeight: FontWeight.bold),
    );
  }

  Widget showTopImage() {
    return Container(
      transformAlignment: Alignment.topCenter,
      child: Lottie.asset("assets/animations/login.json",
          height: MediaQuery.of(context).size.height * .25,
          width: MediaQuery.of(context).size.width * 3),
    );
  }

  Widget showText() {
    return Container(
        alignment: AlignmentDirectional.topStart,
        padding: EdgeInsetsDirectional.only(
          top: MediaQuery.of(context).size.height * .03,
          start: 25,
        ),
        child: Text(
          AppLocalization.of(context)!.getTranslatedValues('otpSendLbl')!,
          style: TextStyle(
              color: Theme.of(context).primaryColor,
              fontWeight: FontWeight.bold,
              fontSize: 20),
        ));
  }

  Widget numberText() {
    return Container(
        alignment: Alignment.topLeft,
        padding: EdgeInsetsDirectional.only(
          start: 25,
        ),
        child: Text(
          "+" + widget.countryCode! + " " + widget.mobileNumber!,
          style: TextStyle(color: Theme.of(context).primaryColor, fontSize: 14),
        ));
  }

  Widget showPin() {
    return Padding(
        padding: EdgeInsetsDirectional.only(
          start: MediaQuery.of(context).size.width * .05,
          end: MediaQuery.of(context).size.width * .05,
        ),
        child: PinFieldAutoFill(
            controller: otpController,
            codeLength: 6,
            decoration: BoxLooseDecoration(
                errorText: isErrorOtp
                    ? AppLocalization.of(context)!.getTranslatedValues(enterOtp)
                    : null,
                strokeColorBuilder:
                    FixedColorBuilder(Theme.of(context).backgroundColor),
                bgColorBuilder:
                    FixedColorBuilder(Theme.of(context).backgroundColor),
                gapSpace: 5,
                textStyle: Theme.of(context).textTheme.headline4!.merge(
                    TextStyle(
                        color: Theme.of(context).colorScheme.secondary,
                        fontSize: 14))),
            currentCode: otp,
            onCodeChanged: (String? code) {
              isErrorOtp = otpController.text.isEmpty;
              otp = code!;
              isloading = false;
            },
            onCodeSubmitted: (String code) {
              otp = code;
            }));
  }

  Widget showVerify() {
    return Container(
        padding: EdgeInsets.symmetric(
            horizontal: MediaQuery.of(context).size.width * .07,
            vertical: MediaQuery.of(context).size.height * .04),
        width: MediaQuery.of(context).size.width,
        child: isloading
            ? Center(
                child: CircularProgressContainer(
                  useWhiteLoader: false,
                  heightAndWidth: 50,
                ),
              )
            : CupertinoButton(
                borderRadius: BorderRadius.circular(15),
                child: Text(
                  AppLocalization.of(context)!
                      .getTranslatedValues('submitBtn')!,
                  style: TextStyle(
                      color: Theme.of(context).backgroundColor,
                      fontSize: 20,
                      fontWeight: FontWeight.bold),
                ),
                color: Theme.of(context).primaryColor,
                onPressed: () {
                  if (otpController.text.isEmpty) {
                    otpMobile(otpController.text);
                  } else {
                    _onFormSubmitted();
                  }
                },
              ));
  }

  Widget resendText() {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            AppLocalization.of(context)!.getTranslatedValues('resetLbl')! +
                "00:" +
                getTime() +
                " ",
            style: TextStyle(
                fontSize: 10,
                color: Theme.of(context).primaryColor,
                fontWeight: FontWeight.normal),
          ),
          _isClickable == true
              ? CupertinoButton(
                  onPressed: () async {
                    setState(() {
                      isloading = false;
                    });
                    await buttonController.reverse();
                    checkNetworkOtpResend();
                  },
                  padding: EdgeInsets.all(0),
                  child: Text(
                    AppLocalization.of(context)!
                        .getTranslatedValues("resendBtn")!,
                    style: TextStyle(
                        fontSize: 10,
                        color: Theme.of(context).primaryColor,
                        decoration: TextDecoration.underline,
                        fontWeight: FontWeight.normal),
                  ),
                )
              : Container(),
        ],
      ),
    );
  }
}
