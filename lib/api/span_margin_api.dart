import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:swcap/config/api_urls.dart';
import 'package:swcap/model/margin/span_margin_model.dart';

class SpanMarginApi {


  Future<SpanMarginModel> fetchSpanMargin() async {

    final client = http.Client();
    SpanMarginModel thisResponse = SpanMarginModel();

    try {
      final response = await client.get(Uri.parse(ApiUrl.getSpanMarginApiUrl));

    if(response.statusCode == 200 ){

      if(jsonDecode(response.body)['status']){

        thisResponse = spanMarginModelFromJson(response.body);

        return thisResponse;

      }else{
        thisResponse = SpanMarginModel(
          status: false,
          data: []
        );
      }

      return thisResponse;

    }else{
      print(" Response Status Code Error : ${response.statusCode} ");
    }

    } catch (e) {
      print(e);
    } finally {
      client.close();
    }

    return thisResponse;

  }

}