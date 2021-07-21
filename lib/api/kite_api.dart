import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:swcap/config/api_urls.dart';
import 'package:swcap/model/kite/kite_script_model.dart';
import 'package:swcap/model/kite/kite_watch_list_model.dart';

class KiteApi {


  static Future<KiteScriptDataModel> getScriptData(scriptName) async {
    KiteScriptDataModel thisResponse = KiteScriptDataModel();
    final client = http.Client();

    try{
      
      final response = await client.get(Uri.parse(ApiUrl.getScriptDataApiUrl+"?script_name="+scriptName));

      if(response.statusCode == 200){

        if(jsonDecode(response.body)['status']){

          thisResponse = kiteScriptDataModelFromJson(response.body);

        }else{
          thisResponse = KiteScriptDataModel(
            status: false,
            data: null
          );
        }

        return thisResponse;

      }else{
        print("Wrong Status Code : ${response.statusCode} ");
      }
      
    }catch(e){
      print(e);
    }finally{
      client.close();
    }

    return thisResponse;

  }
  
  static Future<KiteWatchLIstModel> getWatchLists() async {
    final client = http.Client();
    KiteWatchLIstModel thisResponse = KiteWatchLIstModel();
    try{
      
      final response = await client.get(Uri.parse(ApiUrl.getWatchListApiUrl));

      if(response.statusCode == 200){

        if(jsonDecode(response.body)['status']){

          thisResponse = kiteWatchLIstModelFromJson(response.body);

        }else{
          thisResponse = KiteWatchLIstModel(
            status: false,
            data: []
          );
        }

        return thisResponse;

      }else{
        print("Wrong Status Code : ${response.statusCode}");
      }
      
    }catch(e){
      print(e);
    }finally{
      client.close();
    }
    return thisResponse;
  }

}