import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:swcap/config/api_urls.dart';
import 'package:swcap/model/global/global_model.dart';
import 'package:swcap/model/user/user_model.dart';

class UserApi {
  static Future<GlobalModel> updateUser(userID, userData) async {
    final client = http.Client();
    GlobalModel thisResponse = GlobalModel();

    try {
      final response = await client.post(Uri.parse(ApiUrl.updateUserApiUrl),
          body: {"user_id": userID, "user_data": userData});

      if (response.statusCode == 200) {
        if (jsonDecode(response.body)['status']) {
          thisResponse = globalModelFromJson(response.body);
        } else {
          thisResponse = GlobalModel(
            status: false,
            data: false,
          );
        }

        return thisResponse;
      } else {
        print("Wrong Status Code : ${response.statusCode} ");
      }
    } catch (e) {
      print(e);
    } finally {
      client.close();
    }

    return thisResponse;
  }

  static Future<UserModel> fetchUser(userID) async {
    final client = http.Client();
    UserModel thisResponse = UserModel(status: false);

    try {
      final response = await client
          .get(Uri.parse(ApiUrl.fetchUserApiUrl + "?user_id=" + userID));

      if (response.statusCode == 200) {
        print(jsonDecode(response.body));

        if (jsonDecode(response.body)['status']) {
          thisResponse = userModelFromJson(response.body);
        } else {
          thisResponse = UserModel(status: false, data: null);
        }

        return thisResponse;
      } else {
        print("Wrong Status Code = ${response.statusCode}");
      }
    } catch (e) {
      print(e);
    } finally {
      client.close();
    }

    return thisResponse;
  }

  static Future<GlobalModel> sendPayoutRequest(payOutData) async {
    final client = http.Client();
    GlobalModel thisResponse = GlobalModel();

    try {
      final response = await client.post(
          Uri.parse(ApiUrl.addPayoutRequestApiUrl),
          body: {"payout_data": payOutData});

      if (response.statusCode == 200) {
        if (jsonDecode(response.body)['status']) {
          thisResponse = globalModelFromJson(response.body);
        } else {
          thisResponse = GlobalModel(status: false, data: false);
        }

        return thisResponse;
      } else {
        print("Wrong status code : ${response.statusCode}");
      }
    } catch (e) {
      print(e);
    } finally {
      client.close();
    }

    return thisResponse;
  }
}
