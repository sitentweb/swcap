import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socket_io_client/socket_io_client.dart';
import 'package:swcap/api/kite_api.dart';
import 'package:swcap/api/order_book_api.dart';
import 'package:swcap/api/trade_book_api.dart';
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

  // Function to update the executed trade
  _executeTrade(tradeID, scriptName, lastPrice) async {
    // Update the executed trade in TradeBook
    // Where Order = 0 & Trade = 1

    // Get the response in response variable
    final response = await TradeBookApi.updateTradeBook(
        tradeID, jsonEncode({"trade_in": '1'}));

    // Initialize the SnackBar
    SnackBar snackBar;

    // Check if the status of the response is true or false
    if (response.status) {
      snackBar = SnackBar(
        content: Text("$scriptName is executed at $lastPrice"),
      );
    } else {
      snackBar = SnackBar(content: Text("Something went wrong in $scriptName"));
    }

    // Show the SnackBar according to the response
    ScaffoldMessenger.of(context).showSnackBar(snackBar);

    // Navigate the page on the same page after trade execution
    Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => OrderBook(),
        ));
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
                      Container(
                        alignment: Alignment.centerLeft,
                        width: 100,
                        child: Text("Action"),
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
                                                if (data.buySell == "Buy") {
                                                  if (double.parse(snapshot
                                                          .data['data']
                                                              ['last_price']
                                                          .toString()) <=
                                                      double.parse(data.price
                                                          .toString())) {
                                                    _executeTrade(
                                                        data.tradeBookId,
                                                        data.scriptName,
                                                        snapshot.data['data']
                                                                ['last_price']
                                                            .toString());
                                                  }
                                                } else if (data.buySell ==
                                                    "Sell") {
                                                  if (double.parse(snapshot
                                                          .data['data']
                                                              ['last_price']
                                                          .toString()) >=
                                                      double.parse(data.price
                                                          .toString())) {
                                                    print('Trade Executed');

                                                    // SEND EXECUTED ORDER TO TRADE BOOK

                                                    _executeTrade(
                                                        data.tradeBookId,
                                                        data.scriptName,
                                                        snapshot.data['data']
                                                                ['last_price']
                                                            .toString());
                                                  }
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
                                      Container(
                                          width: 100,
                                          child: Row(
                                            children: [
                                              InkWell(
                                                onTap: () {
                                                  TextEditingController
                                                      _quantityController =
                                                      TextEditingController();
                                                  TextEditingController
                                                      _priceController =
                                                      TextEditingController();
                                                  TextEditingController
                                                      _discloseController =
                                                      TextEditingController();

                                                  _quantityController.text =
                                                      data.quantity;
                                                  _priceController.text =
                                                      data.price;
                                                  _discloseController.text =
                                                      "0";

                                                  showBarModalBottomSheet(
                                                    context: context,
                                                    builder: (context) {
                                                      return StatefulBuilder(
                                                        builder: (context,
                                                            setState) {
                                                          return Container(
                                                            height: MediaQuery.of(
                                                                        context)
                                                                    .size
                                                                    .height *
                                                                0.5,
                                                            color:
                                                                Colors.black87,
                                                            child: Column(
                                                              children: [
                                                                SizedBox(
                                                                  height: 50,
                                                                ),
                                                                Container(
                                                                    alignment:
                                                                        Alignment
                                                                            .center,
                                                                    child: Text(
                                                                      data.scriptName,
                                                                      style: TextStyle(
                                                                          fontSize:
                                                                              18),
                                                                    )),
                                                                Container(
                                                                  padding:
                                                                      EdgeInsets
                                                                          .all(
                                                                              8.0),
                                                                  child: Row(
                                                                    children: [
                                                                      Expanded(
                                                                        child:
                                                                            TextFormField(
                                                                          controller:
                                                                              _quantityController,
                                                                          style:
                                                                              TextStyle(color: Colors.white),
                                                                          decoration:
                                                                              InputDecoration(label: Text("Quantity")),
                                                                        ),
                                                                      ),
                                                                      SizedBox(
                                                                        width:
                                                                            10,
                                                                      ),
                                                                      Expanded(
                                                                        child:
                                                                            TextFormField(
                                                                          controller:
                                                                              _priceController,
                                                                          style:
                                                                              TextStyle(color: Colors.white),
                                                                          decoration:
                                                                              InputDecoration(label: Text("Price")),
                                                                        ),
                                                                      ),
                                                                      SizedBox(
                                                                        width:
                                                                            10,
                                                                      ),
                                                                      Expanded(
                                                                        child:
                                                                            TextFormField(
                                                                          controller:
                                                                              _discloseController,
                                                                          style:
                                                                              TextStyle(color: Colors.white),
                                                                          decoration:
                                                                              InputDecoration(label: Text("Disclose Quantity")),
                                                                        ),
                                                                      )
                                                                    ],
                                                                  ),
                                                                ),
                                                                SizedBox(
                                                                  height: 10,
                                                                ),
                                                                Container(
                                                                  child:
                                                                      MaterialButton(
                                                                    onPressed:
                                                                        () async {
                                                                      var orderData =
                                                                          jsonEncode({
                                                                        "quantity":
                                                                            _quantityController.text,
                                                                        "price":
                                                                            _priceController.text,
                                                                        "trade_disclose_quantity":
                                                                            _discloseController.text
                                                                      });

                                                                      await OrderBookApi.updateOrderBook(
                                                                              userID,
                                                                              data.tradeBookId,
                                                                              orderData)
                                                                          .then((response) {
                                                                        SnackBar
                                                                            snackBar;
                                                                        if (response
                                                                            .status) {
                                                                          snackBar =
                                                                              SnackBar(
                                                                            content:
                                                                                Text("Order Updated Successfully"),
                                                                          );
                                                                        } else {
                                                                          snackBar =
                                                                              SnackBar(content: Text("Order can't updated"));
                                                                        }

                                                                        ScaffoldMessenger.of(context)
                                                                            .showSnackBar(snackBar);

                                                                        Navigator.pop(
                                                                            context);

                                                                        Navigator.pushReplacement(
                                                                            context,
                                                                            MaterialPageRoute(
                                                                              builder: (context) => OrderBook(),
                                                                            ));
                                                                      });
                                                                    },
                                                                    color: Colors
                                                                        .white,
                                                                    child: Text(
                                                                        "Update Order"),
                                                                  ),
                                                                )
                                                              ],
                                                            ),
                                                          );
                                                        },
                                                      );
                                                    },
                                                  );
                                                },
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.all(8.0),
                                                  child: Icon(
                                                    Icons.edit,
                                                    color: Colors.white,
                                                    size: 14,
                                                  ),
                                                ),
                                              ),
                                              InkWell(
                                                onTap: () async {
                                                  await OrderBookApi
                                                          .deleteOrderBook(
                                                              userID,
                                                              data.tradeBookId)
                                                      .then((res) {
                                                    SnackBar snackBar;

                                                    if (res.status) {
                                                      snackBar = SnackBar(
                                                          content: Text(
                                                              "Order Deleted Successfully",
                                                              style: TextStyle(
                                                                  color: Colors
                                                                      .white)));
                                                    } else {
                                                      snackBar = SnackBar(
                                                          content: Text(
                                                        "Something went wrong",
                                                        style: TextStyle(
                                                            color: Colors.red),
                                                      ));
                                                    }

                                                    ScaffoldMessenger.of(
                                                            context)
                                                        .showSnackBar(snackBar);

                                                    Navigator.pushReplacement(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder: (context) =>
                                                              OrderBook(),
                                                        ));
                                                  });
                                                },
                                                child: Padding(
                                                  padding: EdgeInsets.all(8.0),
                                                  child: Icon(
                                                    Icons.cancel,
                                                    color: Colors.red,
                                                    size: 14,
                                                  ),
                                                ),
                                              )
                                            ],
                                          )),
                                    ],
                                  ),
                                );
                              },
                            );
                          } else {
                            return Center(
                              child: Text("No Order Here"),
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
