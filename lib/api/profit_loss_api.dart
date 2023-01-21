import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:swcap/config/api_urls.dart';
import 'package:swcap/model/profit_loss/profit_loss_model.dart';

class ProfitLossApi {


  Future<ProfitLossModel> getProfitLoss(client_id) async {

    final client = http.Client();
    ProfitLossModel thisResponse = ProfitLossModel(status: false);

    try {

      final response = await client.get(Uri.parse(ApiUrl.getProfitLossApiUrl + '?client_id='+client_id));

      if(response.statusCode == 200){

        if(jsonDecode(response.body)['status']){
          thisResponse = profitLossModelFromJson(response.body);
        }

        return thisResponse;

      }else{
        print("Wrong Status Code : ${response.statusCode} ");
      }
      
    } catch (e) {
      print(e);
    }finally{
      client.close();
    }

    return thisResponse;

  }

}