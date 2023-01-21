import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socket_io_client/socket_io_client.dart';
import 'package:swcap/api/kite_api.dart';
import 'package:swcap/api/profit_loss_api.dart';
import 'package:swcap/model/kite/kite_script_model.dart';
import 'package:swcap/model/profit_loss/profit_loss_model.dart';

class OpenPositions extends StatefulWidget {
  const OpenPositions({ Key key }) : super(key: key);

  @override
  _OpenPositionsState createState() => _OpenPositionsState();
}

class _OpenPositionsState extends State<OpenPositions> {

  Future<ProfitLossModel> _profitLossModel;
  String userID;
  Socket socket;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getUserData();
  }

  getUserData() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    setState(() {
      userID = pref.getString("userID");
    });

    _profitLossModel = ProfitLossApi().getProfitLoss(userID);
    setState(() {
      
    });

    await _socketSetup();

  }

  _socketSetup() async {
    socket = io('https://remarkablehr.in:8443' , <String, dynamic>{
        'transports' : ['websocket'],
        'autoConnect' : false
    });

    socket.connect();
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        title: Text("Open Positions"),
        centerTitle: true,
        elevation: 0,
      ),
      body: Container(
        padding: EdgeInsets.all(8),
        width: size.width,
        height: size.height,
        child: Column(children: [
          Container(
            height: 30,
            child: Row(
              children: [
                Container(
                  width: 120,
                  child: Text("Script Name" , style: TextStyle(
                    color: Colors.white
                  ),),
                ),
                Container(
                  width: 80,
                  child: Text("CMP" , style: TextStyle(
                    color: Colors.white,
                    fontSize: 10
                  ),)
                ),
                Container(
                  width: 80,
                  child: Text("Buy Quantity" , style: TextStyle(
                    color: Colors.white,
                    fontSize: 10
                  ),),
                ),
                Container(
                  width: 80,
                  child: Text("Buy Value" , style: TextStyle(
                    color: Colors.white,
                    fontSize: 10
                  ),),
                ),
                Container(
                  width: 80,
                  child: Text("Buy Average" , style: TextStyle(
                    color: Colors.white,
                    fontSize: 10
                  ),),
                ),
                Container(
                  width: 80,
                  child: Text("Sell Quantity" , style: TextStyle(
                    color: Colors.white,
                    fontSize: 10
                  ),),
                ),
                Container(
                  width: 80,
                  child: Text("Sell Value" , style: TextStyle(
                    color: Colors.white,
                    fontSize: 10
                  ),),
                ),
                Container(
                  width: 80,
                  child: Text("Sell Average" , style: TextStyle(
                    color: Colors.white,
                    fontSize: 10
                  ),),
                ),
                Container(
                  width: 100,
                  child: Text("Balance Quantity" , style: TextStyle(
                    color: Colors.white,
                    fontSize: 10
                  ),),
                ),
                Expanded(
                  child: Container(
                    width: 80,
                    child: Text("Unrealized Profit" , style: TextStyle(
                      color: Colors.white,
                      fontSize: 10
                    ),),
                  ),
                )
              ],
            ),
          ),
          Expanded(child: Container(
            child: FutureBuilder<ProfitLossModel>(
              future: _profitLossModel,
              builder: (context, snapshot) {
                  if(snapshot.hasData){

                    return ListView.builder(
                      itemCount: snapshot.data.data.length,
                      itemBuilder: (context, index) {
                        var data = snapshot.data.data[index];

                        Future<KiteScriptDataModel> kiteScriptDataModel;
                                  KiteScriptDataModel _kiteScript;

                                  if(data.tradeCategory == "CASH"){

                                    kiteScriptDataModel = KiteApi.getScriptData(data.scriptName, "NSE");

                                  }else if(data.tradeCategory == "FUTURE" || data.tradeCategory == "OPTION"){

                                    kiteScriptDataModel = KiteApi.getScriptData(data.scriptName, "NFO");
                                  }

                                  kiteScriptDataModel.then((script) {

                                    print(script.data.instrumentToken);

                                    _kiteScript = script;

                                    socket.emit('subscribe' , {
                                      "token" : [script.data.instrumentToken]
                                    });
                                  });

                                  StreamController _scriptStream = StreamController();
                                  double lastPrice = 0.0;

                                  socket.on('receiveticks', (ticks) {

                                    print(ticks);

                                     ticks['tick'].forEach((tick) {

                                   if(_kiteScript.data.instrumentToken == int.parse(tick['instrument_token'].toString())){
                                        _scriptStream.add({
                                            "data" : tick,
                                            "token" : tick['instrument_token'].toString()
                                          });
                                      }                                      
                                    });


                                  });

                        return StreamBuilder(
                            stream:  _scriptStream.stream,
                            builder: (context, snapshot) {
                              if(snapshot.hasData){

                                double lastPrice = double.parse(snapshot.data['data']['last_price'].toString());

                                double unRealizedValue = 0;

                                if(double.parse(data.balanceQuantity) > 0){
                                  unRealizedValue = lastPrice - double.parse(data.buyAverage);
                                  unRealizedValue = unRealizedValue * double.parse(data.balanceQuantity);
                                }else{
                                  unRealizedValue = double.parse(data.sellAverage) - lastPrice;
                                  unRealizedValue = unRealizedValue * -double.parse(data.balanceQuantity);
                                }

                                return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Row(
                            children: [
                              Container(
                                width: 120,
                                child: Text("${data.scriptName}"),
                              ),
                              Container(
                                width: 80,
                                child: Text("${snapshot.data['data']['last_price'].toString()}")
                              ),
                              Container(
                                width: 80,
                                child: Text("${data.buyQuantity}" , style: TextStyle(
                                  fontSize: 10
                                ), ),
                              ),
                              Container(
                                width: 80,
                                child: Text("${data.buyValue}" , style: TextStyle(
                                  fontSize: 10
                                ),  ),
                              ),
                              Container(
                                width: 80,
                                child: Text("${data.buyAverage != null ? double.parse(data.buyAverage.toString()).toStringAsFixed(2).toString() : 0}" , style: TextStyle(
                                  fontSize: 10
                                ), ),
                              ),
                              Container(
                                width: 80,
                                child: Text("${data.sellQuantity}", style: TextStyle(
                                  fontSize: 10
                                ), ),
                              ),
                              Container(
                                width: 80,
                                child: Text("${data.sellValue}", style: TextStyle(
                                  fontSize: 10
                                ), ),
                              ),
                              Container(
                                width: 80,
                                child: Text("${data.sellAverage != null ? double.parse(data.sellAverage.toString()).toStringAsFixed(2).toString() : 0}", style: TextStyle(
                                  fontSize: 10
                                ), ),
                              ),
                              Container(
                                alignment: Alignment.center,
                                width: 100,
                                child: Text("${data.balanceQuantity}", style: TextStyle(
                                  fontSize: 10
                                ), ),
                              ),
                              Expanded(
                                child: Container(
                                  alignment: Alignment.centerLeft,
                                  width: 80,
                                  child: Text("${unRealizedValue.toStringAsFixed(2)} ", style: TextStyle(
                                    fontSize: 10
                                  ), ),
                                ),
                              ),
                            ],
                          ),
                        );
                              }else{
                                return Text("Loading ${data.scriptName} Data");
                              }
                            },
                          ); 
                        
                        
                        
                        
                        
                        
                      },
                    );

                  }else if(snapshot.hasError){
                    var snackBar = SnackBar(
                      content: Text("Something went wrong"),
                    );

                    ScaffoldMessenger.of(context).showSnackBar(snackBar);
                    return Container();
                  }else{
                    return Container(child: Center(child: CircularProgressIndicator()));
                  }
              },
            ),
          ),)
        ],),
      )
    );
  }
}