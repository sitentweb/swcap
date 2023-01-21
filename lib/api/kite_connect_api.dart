import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:swcap/config/api_urls.dart';
import 'package:swcap/model/kite/kite_connect_api_model.dart';

class KiteConnectApi {

  static Future<KiteConnectApiModel> getKiteApi() async {

    final client = http.Client();
    KiteConnectApiModel thisResponse = KiteConnectApiModel();

    try {
      
      final response = await client.get(Uri.parse(ApiUrl.getKiteConnectApiUrl));

      if(response.statusCode  == 200){

        if(jsonDecode(response.body)['status']){

          thisResponse = kiteConnectApiModelFromJson(response.body);

        }else{
          thisResponse = KiteConnectApiModel(
            status: false,
            data: null
          );
        }

        return thisResponse;

      }else{
        print("Response failed with : ${response.statusCode} ");
      }

    } catch (e) {
      print(e);
    } finally {
      client.close();
    }

    return thisResponse;

  }

}