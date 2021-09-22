import 'dart:convert';
import 'dart:io';

import 'package:quizappuic/utils/apiBodyParameterLabels.dart';
import 'package:quizappuic/utils/apiUtils.dart';
import 'package:quizappuic/utils/constants.dart';
import 'package:quizappuic/utils/errorMessageKeys.dart';
import 'package:http/http.dart' as http;

import 'notificationException.dart';

class NotificationRemoteDataSource {
  Future<dynamic> getNotification() async {
    try {
      //body of post request
      final body = {accessValueKey: accessValue};
      final response = await http.post(Uri.parse(getNotificationUrl),
          body: body, headers: ApiUtils.getHeaders());
      final responseJson = jsonDecode(response.body);
      print(responseJson);

      if (responseJson['error']) {
        throw NotificationException(errorMessageCode: responseJson['message']);
      }
      return responseJson["data"];
    } on SocketException catch (_) {
      throw NotificationException(errorMessageCode: noInternetCode);
    } on NotificationException catch (e) {
      throw NotificationException(errorMessageCode: e.toString());
    } catch (e) {
      throw NotificationException(
          errorMessageKey: e.toString(), errorMessageCode: '');
    }
  }
}
