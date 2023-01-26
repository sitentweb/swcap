import 'dart:convert';
import 'dart:developer';

import 'package:http/http.dart' as http;
import 'package:swcap/config/api_urls.dart';
import 'package:swcap/model/global/global_model.dart';
import 'package:swcap/model/trade_book/trade_book_model.dart';

class TradeBookApi {
  static Future<TradeBookModel> fetchTradeBook(userID) async {
    final client = http.Client();

    TradeBookModel thisResponse = TradeBookModel(status: false);

    try {
      final response = await client
          .get(Uri.parse(ApiUrl.fetchTradeBookApiUrl + "?user_id=" + userID));

      if (response.statusCode == 200) {
        if (jsonDecode(response.body)['status']) {
          thisResponse = tradeBookModelFromJson(response.body);
        } else {
          thisResponse = TradeBookModel(status: false, data: []);
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

  static Future<GlobalModel> createTradeBook(tradeData) async {
    final client = http.Client();

    GlobalModel thisResponse = GlobalModel(status: false);

    try {
      final response = await client.post(Uri.parse(ApiUrl.createTradeBook),
          body: {"tradebook_data": tradeData});

      log(response.body, name: 'CREATE TRADEBOOK');

      if (response.statusCode == 200) {
        if (jsonDecode(response.body)['status']) {
          thisResponse = globalModelFromJson(response.body);
        } else {
          thisResponse = GlobalModel(status: false, data: null);
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

  static Future<GlobalModel> updateTradeBook(tradeID, tradeData) async {
    final client = http.Client();
    GlobalModel thisResponse = GlobalModel();

    try {
      final response = await client.post(
          Uri.parse(ApiUrl.updateTradeBookApiUrl),
          body: {"trade_id": tradeID, "trade_data": tradeData});

      if (response.statusCode == 200) {
        if (jsonDecode(response.body)['status']) {
          thisResponse = globalModelFromJson(response.body);
        } else {
          thisResponse = GlobalModel(status: false, data: false);
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
}
