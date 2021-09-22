import 'dart:convert';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_login_facebook/flutter_login_facebook.dart';
import 'package:quizappuic/features/auth/auhtException.dart';
import 'package:quizappuic/features/auth/cubits/authCubit.dart';
import 'package:quizappuic/utils/apiBodyParameterLabels.dart';
import 'package:quizappuic/utils/apiUtils.dart';
import 'package:quizappuic/utils/constants.dart';
import 'package:quizappuic/utils/errorMessageKeys.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class AuthRemoteDataSource {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final fb = FacebookLogin();
  /*
  data part of addUser response
  {id: 11, firebase_id: G1thaSiA43WYx29dOXmUd6jqUWS2, name: RAHUL HIRANI,
  email: rahulhiraniphotoshop@gmail.com, mobile: , type: gmail,
  profile: https://lh3.googleusercontent.com/a/AATXAJyzUAfJwUFTV3yE6tM9KdevDnX2rcM8vm3GKHFz=s96-c, fcm_id: eU3Pq3lKSvChPKZPRXyTUq:APA91bFLf408jQFZxjWq6iG8Kz5ouUEGLecgQX-WQOghVPEjjgnAUzl1zkNg9CHPRAPyU9YbpGzw5qPKarFt7edWJ9iQ_tBo8VKWhIgfrOLtfimcL78b4MzkLCWsw9iPL-2jFGQKDU3S,
  coins: 0, refer_code: , friends_code: , ip_address: , status: 1, date_registered: 2021-06-07 15:27:59}
  */

  //to addUser
  Future<dynamic> addUser(
      {String? firebaseId,
      String? type,
      String? name,
      String? profile,
      String? mobile,
      String? email,
      String? referCode,
      String? friendCode}) async {
    try {
      String fcmToken = await getFCMToken();
      //body of post request
      final body = {
        accessValueKey: accessValue,
        firebaseIdKey: firebaseId,
        typeKey: type,
        nameKey: name,
        emailKey: email ?? "",
        profileKey: profile ?? "",
        mobileKey: mobile ?? "",
        fcmIdKey: fcmToken,
        friendCodeKey: friendCode ?? ""
      };

      final response = await http.post(Uri.parse(addUserUrl),
          body: body, headers: ApiUtils.getHeaders());
      final responseJson = jsonDecode(response.body);
      print(responseJson);

      if (responseJson['error']) {
        throw AuthException(errorMessageCode: responseJson['message']);
      }
      return responseJson['data'];
    } on SocketException catch (_) {
      throw AuthException(errorMessageCode: noInternetCode);
    } on AuthException catch (e) {
      throw AuthException(errorMessageCode: e.toString());
    } catch (e) {
      //print(e.toString());
      throw AuthException(errorMessageCode: defaultErrorMessageCode);
    }
  }

  Future<bool> isUserExist(String firebaseId) async {
    try {
      final body = {
        accessValueKey: accessValue,
        firebaseIdKey: firebaseId,
      };
      final response = await http.post(Uri.parse(getUserDetailsByIdUrl),
          body: body, headers: ApiUtils.getHeaders());
      final responseJson = jsonDecode(response.body);

      if (responseJson['error']) {
        //if user does not exist means
        if (responseJson['message'] == "102") {
          return false;
        }
        throw AuthException(errorMessageCode: responseJson['message']);
      }

      return true;
    } on SocketException catch (_) {
      throw AuthException(errorMessageCode: noInternetCode);
    } on AuthException catch (e) {
      throw AuthException(errorMessageCode: e.toString());
    } catch (e) {
      throw AuthException(errorMessageCode: defaultErrorMessageCode);
    }
  }

  //SignIn user will accept AuthProvider (enum)
  Future<Map<String, dynamic>> signInUser(AuthProvider authProvider,
      {String? email, String? password}) async {
    //user creadential contains information of signin user and is user new or not
    Map<String, dynamic> result = {};

    try {
      if (authProvider == AuthProvider.gmail) {
        UserCredential userCredential = await signInWithGoogle();
        result['user'] = userCredential.user!;
        result['isNewUser'] = userCredential.additionalUserInfo!.isNewUser;
      } else if (authProvider == AuthProvider.fb) {
        final faceBookAuthResult = await signInWithFacebook();
        if (faceBookAuthResult != null) {
          result['user'] = faceBookAuthResult.user!;
          result['isNewUser'] =
              faceBookAuthResult.additionalUserInfo!.isNewUser;
        } else {
          throw AuthException(errorMessageCode: defaultErrorMessageCode);
        }
      } else if (authProvider == AuthProvider.email) {
        UserCredential userCredential =
            await signInWithEmailAndPassword(email!, password!);
        result['user'] = userCredential.user!;
        result['isNewUser'] = userCredential.additionalUserInfo!.isNewUser;
      } else if (authProvider == AuthProvider.apple) {
        UserCredential userCredential = await signInWithApple();
        result['user'] = userCredential.user!;
        result['isNewUser'] = userCredential.additionalUserInfo!.isNewUser;
      }
      return result;
    } on SocketException catch (_) {
      throw AuthException(errorMessageCode: noInternetCode);
    }
    //firebase auht errors
    on FirebaseAuthException catch (e) {
      print(e.toString());
      throw AuthException(errorMessageCode: firebaseErrorCodeToNumber(e.code));
    } on AuthException catch (e) {
      print(e.toString());
      throw AuthException(errorMessageCode: e.toString());
    } catch (e) {
      print(e.toString());
      throw AuthException(errorMessageCode: defaultErrorMessageCode);
    }
  }

  //signIn using google account
  Future<UserCredential> signInWithGoogle() async {
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      throw AuthException(errorMessageCode: defaultErrorMessageCode);
    }
    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

    final AuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    final UserCredential userCredential =
        await _firebaseAuth.signInWithCredential(credential);

    return userCredential;
  }

  Future<UserCredential?> signInWithFacebook() async {
    final res = await fb.logIn(permissions: [
      FacebookPermission.publicProfile,
      FacebookPermission.email,
    ]);

// Check result status
    switch (res.status) {
      case FacebookLoginStatus.success:

        // Send access token to server for validation and auth
        final FacebookAccessToken? accessToken = res.accessToken;
        AuthCredential authCredential =
            FacebookAuthProvider.credential(accessToken!.token);
        final UserCredential userCredential =
            await _firebaseAuth.signInWithCredential(authCredential);
        return userCredential;
      case FacebookLoginStatus.cancel:
        // User cancel log in
        break;

      case FacebookLoginStatus.error:
        // Log in failed

        break;
    }
  }

/*  Future<UserCredential?> signInWithFacebook() async {
    final res = await FacebookAuth.instance.login(permissions: ['email', 'publicProfile']);
     print("/////////////////////////////////////////////"+res.message.toString());
// Check result status
    switch (res.status) {
      case LoginStatus.success:
        final AccessToken? accessToken = res.accessToken;
        print("0000000000000000000000000000000000000000000000000000000$accessToken");
        AuthCredential authCredential = FacebookAuthProvider.credential(accessToken!.token);
        final UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(authCredential);
        print("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!$userCredential");
        return userCredential;
      case LoginStatus.cancelled:
       print("in cancel.........................................................");
        break;
      case LoginStatus.failed:
        print("in fail..........................................................");
        break;
      case LoginStatus.operationInProgress:
        print("in process......................................................");
        break;
    }
  }*/

  signInWithApple() async {
    final credential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
    );
    return credential;
  }

  Future<UserCredential> signInWithEmailAndPassword(
      String email, String password) async {
    //sign in using email
    UserCredential userCredential = await _firebaseAuth
        .signInWithEmailAndPassword(email: email, password: password);
    if (userCredential.user!.emailVerified) {
      return userCredential;
    } else {
      throw AuthException(errorMessageCode: "135");
    }
  }

  Future<void> resetPassword(String email) async {
    await _firebaseAuth.sendPasswordResetEmail(email: email);
  }

  static Future<String> getFCMToken() async {
    try {
      return await FirebaseMessaging.instance.getToken() ?? "";
    } catch (e) {
      return "";
    }
  }

  //create user account
  Future<void> signUpUser(String email, String password) async {
    try {
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
          email: email, password: password);
      //verify email address
      await userCredential.user!.sendEmailVerification();
    } on FirebaseAuthException catch (e) {
      throw AuthException(errorMessageCode: firebaseErrorCodeToNumber(e.code));
    } on SocketException catch (_) {
      throw AuthException(errorMessageCode: noInternetCode);
    } catch (e) {
      throw AuthException(errorMessageCode: defaultErrorMessageCode);
    }
  }

  Future<void> signOut(AuthProvider? authProvider) async {
    _firebaseAuth.signOut();
    if (authProvider == AuthProvider.gmail) {
      _googleSignIn.signOut();
    }
  }
}
