import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:swcap/config/api_urls.dart';
import 'package:swcap/model/margin/script_margin_model.dart';
import 'package:swcap/model/margin/span_margin_model.dart';

class SpanMarginApi {
  Future<SpanMarginModel> fetchSpanMargin() async {
    final client = http.Client();
    SpanMarginModel thisResponse = SpanMarginModel();

    try {
      final response = await client.get(Uri.parse(ApiUrl.getSpanMarginApiUrl));

      if (response.statusCode == 200) {
        if (jsonDecode(response.body)['status']) {
          thisResponse = spanMarginModelFromJson(response.body);

          return thisResponse;
        } else {
          thisResponse = SpanMarginModel(status: false, data: []);
        }

        return thisResponse;
      } else {
        print(" Response Status Code Error : ${response.statusCode} ");
      }
    } catch (e) {
      print(e);
    } finally {
      client.close();
    }

    return thisResponse;
  }

  Future<ScriptMarginModel> fetchMargin(String scriptName) async {
    ScriptMarginModel thisResponse = ScriptMarginModel(status: false);
    final client = http.Client();

    try {
      final response = await client.get(Uri.parse(
          "${ApiUrl.fetchScriptMarginApiUrl}?script_name=$scriptName"));

      if (response.statusCode == 200) {
        if (jsonDecode(response.body)['status']) {
          thisResponse = scriptMarginModelFromJson(response.body);
        } else {
          thisResponse = ScriptMarginModel(status: false);
        }

        return thisResponse;
      } else {
        print(response.statusCode);
        thisResponse = ScriptMarginModel(status: false);
      }
    } catch (e) {
      print(e);
    } finally {
      client.close();
    }

    return thisResponse;
  }
}
