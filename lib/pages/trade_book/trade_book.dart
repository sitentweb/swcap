import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:horizontal_data_table/horizontal_data_table.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socket_io_client/socket_io_client.dart';
import 'package:swcap/api/kite_api.dart';
import 'package:swcap/api/kite_connect_api.dart';
import 'package:swcap/api/trade_book_api.dart';
import 'package:swcap/config/app_config.dart';
import 'package:swcap/model/kite/kite_script_model.dart';
import 'package:swcap/model/trade_book/trade_book_model.dart';
import 'package:swcap/notifier/tick_notifier.dart';
import 'package:swcap/pages/trade_book/add_trade_book.dart';

class TradeBook extends StatefulWidget {
  const TradeBook({Key key}) : super(key: key);

  @override
  _TradeBookState createState() => _TradeBookState();
}

class _TradeBookState extends State<TradeBook> {

  Future<TradeBookModel> _tradeBookModel;
  StreamController<List> tradeController = StreamController();
  String userID;
  Socket socket;
  List _scripts = [];
  List subscribeToken = [];
  int user;

  @override
  void initState() {
    // TODO: implement initState
    _getUserData();
    super.initState();
  }

    _getUserData() async {

    SharedPreferences pref = await SharedPreferences.getInstance();

    setState(() {
      userID = pref.getString("userID");
    });

    _socketSetup();

    // socket.emit('subscribe' , {
    //   "token" : [779521]
    // });

    // socket.on("receiveticks" , (data) {
    //   print(data);
    // });

    _fetchTradeBooks();

  }

  _socketSetup() async {
    socket = io('https://remarkablehr.in:8443' , <String, dynamic>{
        'transports' : ['websocket'],
        'autoConnect' : false
    });

    socket.connect();
  }


  _fetchTradeBooks() async {

    final tradebook =  TradeBookApi.fetchTradeBook(userID);

    setState(() {
      _tradeBookModel = tradebook;
    });
    // _socketSetup();

  }

  getData(TradeBookModel tradeBookModel) async {

    tradeBookModel.data.forEach((tradeBook) {
        
      // final response = await KiteApi


    });

    final response = await KiteApi.getWatchLists(userID);

    if(response.status){
      response.data.forEach((element) {
        _scripts.add({
            "script_name" : element.watchlistScriptName,
            "script_token" : element.watchlistScriptToken
          });
        setState(() {

        });
      });

      _scripts.forEach((element) {
        subscribeToken.add(int.parse(element['script_token']));
      });

        // _scriptStream.add(_scripts);
      

      socket.emit('subscribe' , {
        "token" : subscribeToken
      });

      // _socketSetup();

    }else{
      print("No Watchlist Found");
    }

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
       appBar: AppBar(
         title: Text("TradeBook", style: GoogleFonts.poppins(
           color: Colors.white,
           fontSize: 16
         ),),
         centerTitle: true,
         actions: [
           InkWell(
             onTap: () {
               Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => TradeBook(),));
             },
             child: Container(
               padding: EdgeInsets.all(8),
               child: Icon(Icons.sync , color: Colors.white,),
             ),
           )
         ],
       ),
      // floatingActionButton: FloatingActionButton(
      //   onPressed: () {
      //       Navigator.push(context, MaterialPageRoute(builder: (context) => AddTrade(userID: userID)));
      //   },
      //   child: Icon(Icons.add),
      // ),
      body: Container(
        width: double.infinity,
        child: Container(                  
                  child: Column(
                    children:[
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                        color: Colors.grey[800]
                      ),
                        child: Row(children: [
                          Container(
                      alignment: Alignment.centerLeft,
                      width: 120,
                      child: Text("Script"),
                    ),
                    Container(
                      alignment: Alignment.centerLeft,
                      width: 100,
                      child: Text("Current Price"),
                    ),
                    Container(
                      alignment: Alignment.centerLeft,
                      width: 100,
                      child: Text("Trade Price"),
                    ),
                    Container(
                      alignment: Alignment.centerLeft,
                      width: 100,
                      child: Text("Buy/Sell"),
                    ),
                    Container(
                      alignment: Alignment.centerLeft,
                      width: 100,
                      child: Text("Quantity"),
                    ),
                    Container(
                      alignment: Alignment.centerLeft,
                      width: 100,
                      child: Text("Category"),
                    ),

                    Container(
                      alignment: Alignment.centerLeft,
                      width: 100,
                      child: Text("Trade Time"),
                    ),
                        ],)
                      ),
                      Expanded(child: Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black
                        ),
                        child: FutureBuilder<TradeBookModel>(
                          future: _tradeBookModel,
                          builder: (context, snapshot) {
                            if(snapshot.hasData){

                              print(snapshot.data);

                              if(snapshot.data.status){



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

                                  var lastPrice;
                                  StreamController _scriptStream = StreamController();


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

                                  return Container(
                                    padding: EdgeInsets.symmetric(vertical: 10),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 120,
                                          child: Text("${data.scriptName}"),
                                        ),
                                        Container(
                                          width: 100,
                                          child: StreamBuilder(
                                            stream: _scriptStream.stream,
                                            builder: (context, snapshot) {
                                              if(snapshot.hasData){
                                                return Text("${snapshot.data['data']['last_price'].toString()}");
                                              }else if(snapshot.hasError){
                                                return Text("Error!" , style: TextStyle(
                                                  color: Colors.red
                                                ), );
                                              }else{
                                                return Text("Loading Data");
                                              }
                                            },
                                          )
                                          ),
                                        Container(
                                          width: 100,
                                          child: Text("${data.price}")
                                        ),
                                        Container(
                                          width: 100,
                                          child: Text("${data.buySell}" , style: TextStyle(
                                            color: data.buySell == "Buy" ? Colors.green : Colors.red
                                          ) )
                                        ),
                                        Container(
                                          width: 100,
                                          child: Text("${data.quantity}")
                                        ),
                                        Container(
                                          width: 100,
                                          child: Text("${data.tradeCategory}")
                                        ),
                                        Container(
                                          width: 100,
                                          child: Text("${data.tradeTime}")
                                        ),
                                        
                                      ],
                                    ),
                                  );
                                },
                                );

                              }else{
                                return Center(child: Text("No Trade Book Here"),);
                              }

                              
                            }else if(snapshot.hasError){
                              return Container(
                                child: Text("Error!"),
                              );
                            }else{
                              return Container(
                                child: Center(child: CircularProgressIndicator(),)
                              );
                            }
                          },
                        )
                      )
                      ,)
                    ]
                  ),
                  )
      ),
    );
  }

}
