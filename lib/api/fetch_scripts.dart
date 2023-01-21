import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:swcap/config/api_urls.dart';
import 'package:swcap/model/kite/all_script_model.dart';
import 'package:swcap/model/margin/get_instrument_data.dart';

class FetchScripts {
  Future fetchAllScripts(String apiKey, String accessToken) async {
    final client = http.Client();

    try {
      final response = await client
          .get(Uri.parse("https://api.kite.trade/instruments"), headers: {
        "X-Kite-Version": "3",
        "Authorization": "token $apiKey:$accessToken"
      });

      if (response.statusCode == 200) {
        print(response.body);
        return response.body;
      } else {
        print(response.statusCode);
      }
    } catch (e) {
      print(e);
    } finally {
      print("Done");
      client.close();
    }
  }

  Future<ScriptListModel> fetchScriptFromBackEnd(
      String query, String client_id) async {
    ScriptListModel thisResponse = ScriptListModel(status: false);
    final client = http.Client();

    try {
      final response = await client.get(Uri.parse(
          ApiUrl.fetchSearchScriptApiUrl +
              "?query=" +
              query +
              "&client_id=" +
              client_id));

      if (response.statusCode == 200) {
        if (jsonDecode(response.body)['status']) {
          thisResponse = scriptListModelFromJson(response.body);
        } else {
          thisResponse = ScriptListModel(status: false, data: null);
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

  Future<InstrumentDataModel> fetchInstrumentData(String scriptSymbol) async {
    InstrumentDataModel thisResponse = InstrumentDataModel(status: false);
    final client = http.Client();

    try {
      final response = await client.get(Uri.parse(
          "${ApiUrl.fetchInstrumentDataApiUrl}?script_symbol=$scriptSymbol"));

      if (response.statusCode == 200) {
        if (jsonDecode(response.body)['status']) {
          thisResponse = instrumentDataModelFromJson(response.body);
        } else {
          thisResponse = InstrumentDataModel(status: false, data: Data());
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
