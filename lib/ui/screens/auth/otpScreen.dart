import 'package:country_code_picker/country_code_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quizappuic/app/appLocalization.dart';

import 'package:quizappuic/features/auth/authRepository.dart';
import 'package:quizappuic/features/auth/cubits/signInCubit.dart';
import 'package:quizappuic/ui/screens/auth/fillOtpScreen.dart';
import 'package:quizappuic/ui/screens/auth/widgets/termsAndCondition.dart';
import 'package:quizappuic/ui/widgets/pageBackgroundGradientContainer.dart';
import 'package:lottie/lottie.dart';

class OtpScreen extends StatefulWidget {
  @override
  _OtpScreen createState() => _OtpScreen();
}

class _OtpScreen extends State<OtpScreen> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController phoneController = TextEditingController();
  bool iserrorNumber = false, isErrorName = false;
  String? countrycode, countryName;
  // mobile number verify
  RegExp regExp = new RegExp(r'(^(?:[+0]9)?[0-9]{10,12}$)');
  bool validateMobile(String value) {
    String pattern = r'(^(?:[+0]9)?[0-9]{10,12}$)';
    RegExp regExp = new RegExp(pattern);
    if (value.trim().isEmpty ||
        value.trim().length < 9 ||
        value.trim().length > 14) {
      setState(() {
        iserrorNumber = true;
      });
      return false;
    } else if (!regExp.hasMatch(value)) {
      setState(() {
        iserrorNumber = true;
      });
      return false;
    }
    setState(() {
      iserrorNumber = false;
    });
    return true;
  }

  //check textfield empty for name
  bool validateName(String name) {
    if (name.isEmpty) {
      setState(() {
        isErrorName = true;
      });
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SignInCubit>(
        create: (_) => SignInCubit(AuthRepository()),
        child: Builder(
            builder: (context) => Scaffold(
                  body: Stack(
                    children: <Widget>[
                      PageBackgroundGradientContainer(),
                      SingleChildScrollView(
                        child: showForm(),
                      )
                    ],
                  ),
                )));
  }

  Widget showForm() {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsetsDirectional.only(
              start: MediaQuery.of(context).size.width * .05,
              end: MediaQuery.of(context).size.width * .08),
          child: Column(
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
              receiveText(),
              SizedBox(
                height: MediaQuery.of(context).size.height * .02,
              ),
              showMobileNumber(),
              SizedBox(
                height: MediaQuery.of(context).size.height * .08,
              ),
              showVerify(),
              TermsAndCondition(),
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
          AppLocalization.of(context)!.getTranslatedValues('enterNumberLbl')!,
          style: TextStyle(
              color: Theme.of(context).primaryColor,
              fontWeight: FontWeight.bold,
              fontSize: 22),
        ));
  }

  Widget receiveText() {
    return Container(
        alignment: Alignment.topLeft,
        padding: EdgeInsetsDirectional.only(
          start: 25,
        ),
        child: Text(
          AppLocalization.of(context)!.getTranslatedValues('receiveOtpLbl')!,
          style: TextStyle(color: Theme.of(context).primaryColor, fontSize: 14),
        ));
  }

  Widget showMobileNumber() {
    return Padding(
      padding: EdgeInsetsDirectional.only(start: 25),
      child: TextFormField(
        controller: phoneController,
        keyboardType: TextInputType.number,
        onChanged: (value) {
          iserrorNumber = phoneController.text.isEmpty;
          iserrorNumber = phoneController.text.length < 9 ||
              phoneController.text.length > 14;
        },
        style: TextStyle(
          color: Theme.of(context).colorScheme.secondary,
        ),
        decoration: InputDecoration(
          fillColor: Theme.of(context).backgroundColor,
          filled: true,
          prefixIcon: Container(
              width: MediaQuery.of(context).size.width * .28,
              child: CountryCodePicker(
                  padding: EdgeInsets.zero,
                  flagDecoration:
                      BoxDecoration(borderRadius: BorderRadius.circular(5)),
                  showDropDownButton: true,
                  searchDecoration: InputDecoration(
                    hintText: AppLocalization.of(context)!
                        .getTranslatedValues("countryLbl"),
                    hintStyle: TextStyle(
                        color: Theme.of(context).colorScheme.secondary),
                    fillColor: Theme.of(context).colorScheme.secondary,
                  ),
                  showOnlyCountryWhenClosed: false,
                  hideMainText: true,
                  initialSelection: 'ES',
                  flagWidth: 25,
                  dialogSize: Size(MediaQuery.of(context).size.width * .8,
                      MediaQuery.of(context).size.height * .8),
                  // alignLeft: true,
                  textStyle: TextStyle(
                      color: Theme.of(context).colorScheme.secondary,
                      fontWeight: FontWeight.bold),
                  onChanged: (CountryCode countryCode) {
                    countrycode = countryCode.toString().replaceFirst("+", "");
                    countryName = countryCode.name;
                  },
                  onInit: (code) {
                    countrycode = code.toString().replaceFirst("+", "");
                  })),
          errorText: iserrorNumber
              ? AppLocalization.of(context)!.getTranslatedValues("validMobMsg")
              : null,
          hintText: "+34 999-999-999",
          hintStyle: TextStyle(
              color: Theme.of(context).colorScheme.secondary.withOpacity(0.6)),
          labelStyle: TextStyle(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.secondary,
          ),
          contentPadding: EdgeInsets.all(15),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
            borderSide: BorderSide.none,
          ),
          enabledBorder: UnderlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
            borderSide:
                new BorderSide(color: Theme.of(context).backgroundColor),
          ),
        ),
      ),
    );
  }

  Widget showVerify() {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: MediaQuery.of(context).size.width * .07,
          vertical: MediaQuery.of(context).size.height * .04),
      width: MediaQuery.of(context).size.width,
      child: CupertinoButton(
        borderRadius: BorderRadius.circular(15),
        child: Text(
          AppLocalization.of(context)!.getTranslatedValues("requestOtpLbl")!,
          style: TextStyle(
              color: Theme.of(context).backgroundColor,
              fontSize: 20,
              fontWeight: FontWeight.bold),
        ),
        color: Theme.of(context).primaryColor,
        onPressed: () {
          if (phoneController.text.isEmpty ||
              phoneController.text.length < 9 ||
              phoneController.text.length > 14) {
            validateMobile(phoneController.text);
          } else {
            Navigator.pushReplacement(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, anim1, anim2) => FillOtpScreen(
                      mobileNumber: phoneController.text,
                      countryCode: countrycode,
                      name: ""),
                ));
          }
        },
      ),
    );
  }
}
