import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socket_io_client/socket_io_client.dart';
import 'package:swcap/api/kite_api.dart';
import 'package:swcap/api/order_book_api.dart';
import 'package:swcap/model/kite/kite_script_model.dart';
import 'package:swcap/model/order_book/fetch_order_book.dart';

class OrderBook extends StatefulWidget {
  const OrderBook({Key key}) : super(key: key);

  @override
  _OrderBookState createState() => _OrderBookState();
}

class _OrderBookState extends State<OrderBook> {
  Future<OrderBookModel> _orderBookModel;
  String userID;
  Socket socket;

  @override
  void initState() {
    // TODO: implement initState
    _getUserData();
    super.initState();
  }

  _socketSetup() async {
    socket = io('https://remarkablehr.in:8443', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false
    });

    socket.connect();
  }

  _getUserData() async {
    SharedPreferences pref = await SharedPreferences.getInstance();

    setState(() {
      userID = pref.getString("userID");
    });

    _socketSetup();
    _fetchTradeBooks();
  }

  _fetchTradeBooks() async {
    final orderbook = OrderBookApi.fetchOrderBook(userID);

    setState(() {
      _orderBookModel = orderbook;
    });
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "OrderBook",
          style: GoogleFonts.poppins(color: Colors.white, fontSize: 16),
        ),
        elevation: 0,
        centerTitle: true,
        actions: [
          InkWell(
            onTap: () {
              Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => OrderBook(),
                  ));
            },
            child: Container(
              padding: EdgeInsets.all(8),
              child: Icon(
                Icons.sync,
                color: Colors.white,
              ),
            ),
          )
        ],
      ),
      body: Container(
          width: double.infinity,
          child: Container(
            child: Column(children: [
              Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.grey[800]),
                  child: Row(
                    children: [
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
                    ],
                  )),
              Expanded(
                child: Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.black),
                    child: FutureBuilder<OrderBookModel>(
                      future: _orderBookModel,
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          print(snapshot.data);

                          if (snapshot.data.status) {
                            return ListView.builder(
                              itemCount: snapshot.data.data.length,
                              itemBuilder: (context, index) {
                                var data = snapshot.data.data[index];

                                Future<KiteScriptDataModel> kiteScriptDataModel;
                                KiteScriptDataModel _kiteScript;

                                if (data.tradeCategory == "CASH") {
                                  kiteScriptDataModel = KiteApi.getScriptData(
                                      data.scriptName, "NSE");
                                } else if (data.tradeCategory == "FUTURE" ||
                                    data.tradeCategory == "OPTION") {
                                  kiteScriptDataModel = KiteApi.getScriptData(
                                      data.scriptName, "NFO");
                                }

                                kiteScriptDataModel.then((script) {
                                  print(script.data.instrumentToken);

                                  _kiteScript = script;

                                  socket.emit('subscribe', {
                                    "token": [script.data.instrumentToken]
                                  });
                                });

                                var lastPrice;
                                StreamController _scriptStream =
                                    StreamController();

                                socket.on('receiveticks', (ticks) {
                                  print(ticks);

                                  ticks['tick'].forEach((tick) {
                                    if (_kiteScript.data.instrumentToken ==
                                        int.parse(tick['instrument_token']
                                            .toString())) {
                                      _scriptStream.add({
                                        "data": tick,
                                        "token":
                                            tick['instrument_token'].toString()
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
                                              if (snapshot.hasData) {
                                                if (snapshot.data['data']
                                                        ['last_price'] <=
                                                    data.price) {
                                                  print('Trade Executed');
                                                }
                                                return Text(
                                                    "${snapshot.data['data']['last_price'].toString()}");
                                              } else if (snapshot.hasError) {
                                                return Text(
                                                  "Error!",
                                                  style: TextStyle(
                                                      color: Colors.red),
                                                );
                                              } else {
                                                return Text("Loading Data");
                                              }
                                            },
                                          )),
                                      Container(
                                          width: 100,
                                          child: Text("${data.price}")),
                                      Container(
                                          width: 100,
                                          child: Text("${data.buySell}",
                                              style: TextStyle(
                                                  color: data.buySell == "Buy"
                                                      ? Colors.green
                                                      : Colors.red))),
                                      Container(
                                          width: 100,
                                          child: Text("${data.quantity}")),
                                      Container(
                                          width: 100,
                                          child: Text("${data.tradeCategory}")),
                                      Container(
                                          width: 100,
                                          child: Text("${data.tradeTime}")),
                                    ],
                                  ),
                                );
                              },
                            );
                          } else {
                            return Center(
                              child: Text("No Trade Book Here"),
                            );
                          }
                        } else if (snapshot.hasError) {
                          return Container(
                            child: Text("Error!"),
                          );
                        } else {
                          return Container(
                              child: Center(
                            child: CircularProgressIndicator(),
                          ));
                        }
                      },
                    )),
              )
            ]),
          )),
    );
  }
}
