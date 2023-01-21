import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:swcap/config/api_urls.dart';
import 'package:swcap/model/global/global_model.dart';
import 'package:swcap/model/kite/kite_script_model.dart';
import 'package:swcap/model/kite/kite_watch_list_model.dart';

class KiteApi {
  static Future<KiteScriptDataModel> getScriptData(
      scriptName, scriptType) async {
    KiteScriptDataModel thisResponse = KiteScriptDataModel();
    final client = http.Client();

    try {
      final response = await client.get(Uri.parse(ApiUrl.getScriptDataApiUrl +
          "?script_name=" +
          scriptName +
          "&script_type=" +
          scriptType));

      if (response.statusCode == 200) {
        if (jsonDecode(response.body)['status']) {
          thisResponse = kiteScriptDataModelFromJson(response.body);
        } else {
          thisResponse = KiteScriptDataModel(status: false, data: null);
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

  static Future<KiteWatchLIstModel> getWatchLists(userID) async {
    final client = http.Client();
    KiteWatchLIstModel thisResponse = KiteWatchLIstModel();
    try {
      final response = await client
          .get(Uri.parse(ApiUrl.getWatchListApiUrl + "?user_id=" + userID));
      if (response.statusCode == 200) {
        if (jsonDecode(response.body)['status']) {
          thisResponse = kiteWatchLIstModelFromJson(response.body);
        } else {
          thisResponse = KiteWatchLIstModel(status: false, data: []);
        }

        return thisResponse;
      } else {
        print("Wrong Status Code : ${response.statusCode}");
      }
    } catch (e) {
      print(e);
    } finally {
      client.close();
    }
    return thisResponse;
  }

  static Future<GlobalModel> addWatchList(
      scriptName, scriptToken, scriptType, scriptCategory, userID) async {
    final client = http.Client();

    GlobalModel thisResponse = GlobalModel();

    try {
      final response =
          await client.post(Uri.parse(ApiUrl.addWatchListApiUrl), body: {
        "script_name": scriptName,
        "script_type": scriptType,
        "script_token": scriptToken,
        "script_category": scriptCategory,
        "user_id": userID
      });

      if (response.statusCode == 200) {
        if (jsonDecode(response.body)['status']) {
          thisResponse = globalModelFromJson(response.body);
        } else {
          thisResponse = GlobalModel(status: false, data: "");
        }

        return thisResponse;
      } else {
        print("Wrong status : ${response.statusCode} ");
      }
    } catch (e) {
      print(e);
    } finally {
      client.close();
    }

    return thisResponse;
  }

  static Future<GlobalModel> removeWatchList(watchListID, userID) async {
    final client = http.Client();
    GlobalModel thisResponse = GlobalModel();

    try {
      final response = await client.get(Uri.parse(ApiUrl.removeWatchlistApiUrl +
          "?watchlist_script_token=$watchListID&client_id=$userID"));

      if (response.statusCode == 200) {
        if (jsonDecode(response.body)['status']) {
          thisResponse = globalModelFromJson(response.body);
        } else {
          thisResponse = GlobalModel(status: false, data: false);
        }

        return thisResponse;
      } else {
        print(response.statusCode);
      }
    } catch (e) {
      print(e);
    } finally {
      client.close();
    }

    return thisResponse;
  }
}
