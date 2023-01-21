import 'dart:async';
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socket_io_client/socket_io_client.dart';
import 'package:swcap/api/kite_api.dart';
import 'package:swcap/api/kite_connect_api.dart';
import 'package:swcap/api/trade_book_api.dart';
import 'package:swcap/components/drawer/custom_drawer.dart';
import 'package:swcap/model/global/global_model.dart';
import 'package:swcap/model/kite/kite_script_model.dart';
import 'package:swcap/notifier/tick_notifier.dart';
// import 'package:socket_io_client/socket_io_client.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List _scripts = [];
  String userID;
  String apiKey;
  String accessToken;
  StreamController<List> _streamController = StreamController();
  double oldValue = 0;
  Socket socket;
  int user;
  List subscribeToken = [];
  List scriptData = [];
  SharedPreferences pref;
  bool gotApi = false;

  @override
  void initState() {
    getUser();
    super.initState();
  }

  _fetchKiteApi() async {
    await KiteConnectApi.getKiteApi().then((res) {
      if (res.status) {
        setState(() {
          apiKey = res.data.apiKey;
          accessToken = res.data.accessToken;
        });

        socket.emit("kiteApi",
            {"apiKey": res.data.apiKey, "accessToken": res.data.accessToken});

        //  SharedPreferences pref = await SharedPreferences.getInstance();

        //  pref.setString("kiteApi", res.data.apiKey);
        //  pref.setString("kiteAccessToken", res.data.accessToken);

        socket.on('apiReceived', (data) {
          print("Api Received");

          socket.emit('subscribe', {"token": subscribeToken});
        });

        print(res.data.toJson());
      }
    });
  }

  _socketSetup() async {
    socket = io('https://remarkablehr.in:8443', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false
    });

    socket.connect();
    // user = Random().nextInt(10000);

    // socket.emit('registerMeSwcap' , {
    //   "user" : user
    // });

    // setState(() {});
  }

  getUser() async {
    SharedPreferences pref = await SharedPreferences.getInstance();

    setState(() {
      userID = pref.getString("userID");
    });

    getData();
  }

  getData() async {
    final response = await KiteApi.getWatchLists(userID);

    if (response.status) {
      response.data.forEach((element) {
        _scripts.add({
          "script_id": element.watchlistId,
          "script_name": element.watchlistScriptName,
          "script_token": element.watchlistScriptToken,
          "script_category": element.watchlistScriptCategory
        });

        print(_scripts);

        setState(() {});
      });

      await _socketSetup();
      await _fetchKiteApi();

      _scripts.forEach((element) {
        subscribeToken.add(int.parse(element['script_token']));
      });

      _streamController.add(_scripts);
    } else {
      print("No Watchlist Found");
    }
  }

  _storeOldValue(oldV) {
    oldValue = oldV;
  }

  _createOrder(lastPrice, tradeType, tradeData) async {
    print(tradeData);

    await TradeBookApi.createTradeBook(tradeData).then((value) {
      if (value.status) {
        Navigator.pop(context);
        print("Trade Created");
      } else {
        print("Something went wrong");
      }
    });
  }

  @override
  void dispose() {
    // TODO: implement dispose
    socket.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.black12,
        actions: [
          InkWell(
            onTap: () {
              Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => HomePage(),
                  ));
            },
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Icon(Icons.sync),
            ),
          ),
        ],
      ),
      drawer: CustomDrawer(),
      floatingActionButton: FloatingActionButton(
        mini: true,
        mouseCursor: SystemMouseCursors.click,
        backgroundColor: Colors.black54,
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) {
              TextEditingController _scriptTextController =
                  TextEditingController();
              String scriptCategory = "CASH";

              return StatefulBuilder(
                builder: (context, setState) {
                  return AlertDialog(
                    actions: [
                      Container(
                        height: 50,
                        child: TextField(
                          controller: _scriptTextController,
                          decoration: InputDecoration(
                              labelText: "Script Symbol",
                              labelStyle:
                                  GoogleFonts.poppins(color: Colors.black)),
                        ),
                      ),
                      SizedBox(
                        height: 10,
                      ),
                      Container(
                        height: 50,
                        child: DropdownButton(
                            isExpanded: true,
                            value: scriptCategory,
                            onChanged: (value) {
                              print(value);
                              setState(() {
                                scriptCategory = value;
                              });
                            },
                            items: [
                              DropdownMenuItem(
                                  value: "CASH",
                                  child: Text("CASH",
                                      style: GoogleFonts.poppins(
                                          color: Colors.black))),
                              DropdownMenuItem(
                                  value: "FUTURE",
                                  child: Text("FUTURE",
                                      style: GoogleFonts.poppins(
                                          color: Colors.black))),
                              DropdownMenuItem(
                                  value: "OPTION",
                                  child: Text("OPTION",
                                      style: GoogleFonts.poppins(
                                          color: Colors.black)))
                            ]),
                      ),
                      SizedBox(
                        height: 10,
                      ),
                      MaterialButton(
                        color: Colors.black87,
                        textColor: Colors.white,
                        onPressed: () async {
                          print("Adding Script");

                          KiteScriptDataModel res;

                          if (scriptCategory == "CASH") {
                            res = await KiteApi.getScriptData(
                                _scriptTextController.text, "NSE");
                          } else if (scriptCategory == "FUTURE" ||
                              scriptCategory == "OPTION") {
                            res = await KiteApi.getScriptData(
                                _scriptTextController.text, "NFO");
                          }

                          String token = "";

                          if (res.status) {
                            print(res.data.instrumentToken);

                            setState(() {
                              token = res.data.instrumentToken.toString();
                            });
                          } else {
                            SnackBar snackBar =
                                SnackBar(content: Text("Script not available"));

                            ScaffoldMessenger.of(context)
                                .showSnackBar(snackBar);
                          }

                          print(token);

                          GlobalModel response;

                          if (scriptCategory == "CASH") {
                            response = await KiteApi.addWatchList(
                                _scriptTextController.text,
                                token,
                                "NSE",
                                'CASH',
                                userID);
                          } else if (scriptCategory == "FUTURE" ||
                              scriptCategory == "OPTION") {
                            response = await KiteApi.addWatchList(
                                _scriptTextController.text,
                                token,
                                "NFO",
                                scriptCategory,
                                userID);
                          }

                          if (response.status) {
                            if (_scriptTextController.text.isNotEmpty) {
                              _scripts.add({
                                "script_name": "${_scriptTextController.text}",
                                "script_token": "$token"
                              });

                              _streamController.add(_scripts);

                              setState(() {});

                              socket.emit('subscribe', {
                                "token": [int.parse(token)]
                              });
                            } else {
                              print("Script not added");
                            }

                            Navigator.pop(context);
                          } else {
                            print("script is empty");
                          }
                        },
                        child: Text(
                          "Add",
                          style: GoogleFonts.poppins(),
                        ),
                      )
                    ],
                  );
                },
              );
            },
          );
        },
        child: Icon(Icons.add),
      ),
      body: Container(
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(5),
              decoration: BoxDecoration(color: Colors.grey[800]),
              alignment: Alignment.centerLeft,
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
                  width: 120,
                  child: Text("Today's Market"),
                ),
                Container(
                  alignment: Alignment.centerLeft,
                  width: 100,
                  child: Text("Volume"),
                ),
                Container(
                  alignment: Alignment.centerLeft,
                  width: 100,
                  child: Text("Open"),
                ),
                Container(
                  alignment: Alignment.centerLeft,
                  width: 100,
                  child: Text("Close"),
                ),
                Container(
                  alignment: Alignment.centerLeft,
                  width: 100,
                  child: Text("High"),
                ),
                Container(
                  alignment: Alignment.centerLeft,
                  width: 70,
                  child: Text("Low"),
                ),
                Container(
                  alignment: Alignment.centerLeft,
                  width: 30,
                  child: Icon(
                    Icons.cancel,
                    size: 12,
                    color: Colors.white,
                  ),
                )
              ]),
            ),
            Expanded(
              child: Container(
                padding: EdgeInsets.all(5),
                width: MediaQuery.of(context).size.width,
                child: _scripts.length > 0
                    ? StreamBuilder<List>(
                        stream: _streamController.stream,
                        builder: (context, snapshot) {
                          if (snapshot.hasData) {
                            // print(snapshot.data);

                            return ListView.builder(
                              physics: AlwaysScrollableScrollPhysics(),
                              itemCount: snapshot.data.length,
                              itemBuilder: (context, index) {
                                var script = snapshot.data[index];

                                StreamController _scriptStream =
                                    StreamController();

                                socket.on(
                                    'receiveticks',
                                    (ticks) => {
                                          ticks['tick'].forEach((tick) {
                                            scriptData.add({
                                              "data": tick,
                                              "token": tick['instrument_token']
                                                  .toString()
                                            });

                                            if (tick['instrument_token'] ==
                                                int.parse(
                                                    script['script_token'])) {
                                              // print(tick);
                                              Provider.of<TickNotifier>(context,
                                                      listen: false)
                                                  .storeValue(
                                                      tick['last_price'],
                                                      tick['instrument_token']);

                                              _scriptStream.add({
                                                "data": tick,
                                                "token":
                                                    tick['instrument_token']
                                                        .toString()
                                              });

                                              // print("Token Matched with : ${ data['script_name'] }");
                                            } else {
                                              // print("Script Token not matched ${tick['instrument_token']} : ${data['script_token']}");
                                              // print(last_price);
                                            }
                                          })
                                        });

                                var new_value = "00.00";

                                return Container(
                                  height: 30,
                                  child: Row(
                                    children: [
                                      InkWell(
                                          onTap: () {
                                            String stockName =
                                                script['script_name'];
                                            String stockToken =
                                                script['script_token'];
                                            String stockCategory =
                                                script['script_category']
                                                    .toString();
                                            StreamController _depthStream =
                                                StreamController();
                                            TextEditingController
                                                _instrumentController =
                                                TextEditingController();
                                            TextEditingController
                                                _quantityController =
                                                TextEditingController();
                                            TextEditingController
                                                _priceController =
                                                TextEditingController();
                                            TextEditingController
                                                _stoplossController =
                                                TextEditingController();
                                            TextEditingController
                                                _discloseQuantityController =
                                                TextEditingController();
                                            _instrumentController.text =
                                                stockName;
                                            var lastPrice = "";

                                            dynamic depthProduct = "MIS";
                                            dynamic depthType = "DAY";
                                            dynamic depthValidity = "DAY";
                                            dynamic depthTypeOptions = "MARKET";

                                            // setState(() {
                                            //   _priceController.text = lastPrice;
                                            // });
                                            // if(depthTypeOptions == "MARKET")

                                            socket.on(
                                                "receiveticks",
                                                (ticks) => {
                                                      ticks['tick']
                                                          .forEach((tick) {
                                                        print(tick);
                                                        if (tick[
                                                                'instrument_token'] ==
                                                            int.parse(
                                                                stockToken)) {
                                                          _depthStream.add({
                                                            "data": tick,
                                                            "token": stockToken
                                                          });
                                                        }
                                                      })
                                                    });

                                            showMaterialModalBottomSheet(
                                              context: context,
                                              builder: (context) {
                                                return StatefulBuilder(
                                                  builder: (context, setState) {
                                                    return Container(
                                                        decoration:
                                                            BoxDecoration(
                                                                color: Colors
                                                                    .black),
                                                        height: MediaQuery.of(
                                                                    context)
                                                                .size
                                                                .height *
                                                            0.50,
                                                        child: Container(
                                                          child: Row(
                                                            children: [
                                                              Expanded(
                                                                  child:
                                                                      Container(
                                                                          color: Colors
                                                                              .grey,
                                                                          child:
                                                                              Column(children: [
                                                                            Container(
                                                                                height: 20,
                                                                                color: Colors.black,
                                                                                child: Center(
                                                                                  child: Text("Market Depth ($stockName)"),
                                                                                )),
                                                                            Expanded(
                                                                              child: Container(
                                                                                color: Colors.black87,
                                                                                child: StreamBuilder(
                                                                                  stream: _depthStream.stream,
                                                                                  builder: (context, snapshot) {
                                                                                    if (snapshot.hasData) {
                                                                                      lastPrice = snapshot.data['data']['last_price'].toString();
                                                                                      var depth = snapshot.data['data']['depth'];

                                                                                      return Column(
                                                                                        children: [
                                                                                          Container(
                                                                                            height: 20,
                                                                                            child: Text(
                                                                                              " $stockName : $lastPrice",
                                                                                              style: TextStyle(fontSize: 15),
                                                                                            ),
                                                                                          ),
                                                                                          Expanded(
                                                                                            child: Container(
                                                                                              child: Row(
                                                                                                children: [
                                                                                                  Expanded(
                                                                                                      child: Container(
                                                                                                    padding: EdgeInsets.symmetric(horizontal: 10),
                                                                                                    child: Column(children: [
                                                                                                      Container(
                                                                                                        height: 20,
                                                                                                        child: Center(child: Text("Buy", style: TextStyle(color: Colors.green))),
                                                                                                      ),
                                                                                                      Expanded(
                                                                                                          child: Container(
                                                                                                        child: Column(
                                                                                                          mainAxisAlignment: MainAxisAlignment.start,
                                                                                                          children: [
                                                                                                            Container(),
                                                                                                            Container(
                                                                                                              padding: EdgeInsets.all(0),
                                                                                                              margin: EdgeInsets.all(0),
                                                                                                              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                                                                                                                Text(
                                                                                                                  "Quantity",
                                                                                                                  style: TextStyle(fontSize: 10),
                                                                                                                ),
                                                                                                                Text("Price", style: TextStyle(fontSize: 10)),
                                                                                                                Text("Order", style: TextStyle(fontSize: 10))
                                                                                                              ]),
                                                                                                            ),
                                                                                                            Expanded(
                                                                                                                child: Container(
                                                                                                                    child: ListView.builder(
                                                                                                              itemCount: depth['buy'].length,
                                                                                                              itemBuilder: (context, index) {
                                                                                                                var buyDepth = depth['buy'][index];
                                                                                                                return Column(
                                                                                                                  children: [
                                                                                                                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                                                                                                                      Text(
                                                                                                                        "${buyDepth['quantity'].toString()}",
                                                                                                                        textAlign: TextAlign.left,
                                                                                                                      ),
                                                                                                                      Text("${buyDepth['price'].toString()}", textAlign: TextAlign.left),
                                                                                                                      Text("${buyDepth['orders'].toString()}", textAlign: TextAlign.left),
                                                                                                                    ]),
                                                                                                                    SizedBox(
                                                                                                                      height: 10,
                                                                                                                    ),
                                                                                                                  ],
                                                                                                                );
                                                                                                              },
                                                                                                            ))),
                                                                                                            Container(
                                                                                                              height: 20,
                                                                                                            )
                                                                                                          ],
                                                                                                        ),
                                                                                                      )),
                                                                                                    ]),
                                                                                                  )),
                                                                                                  SizedBox(
                                                                                                    width: 30,
                                                                                                  ),
                                                                                                  Expanded(
                                                                                                      child: Container(
                                                                                                    padding: EdgeInsets.symmetric(horizontal: 10),
                                                                                                    child: Column(children: [
                                                                                                      Container(
                                                                                                        height: 20,
                                                                                                        child: Center(child: Text("Sell", style: TextStyle(color: Colors.red))),
                                                                                                      ),
                                                                                                      Expanded(
                                                                                                          child: Container(
                                                                                                              child: Column(
                                                                                                        children: [
                                                                                                          Container(
                                                                                                            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                                                                                                              Text("Quantity"),
                                                                                                              Text("Price"),
                                                                                                              Text("Order")
                                                                                                            ]),
                                                                                                          ),
                                                                                                          Expanded(
                                                                                                              child: Container(
                                                                                                                  alignment: Alignment.topCenter,
                                                                                                                  child: ListView.builder(
                                                                                                                    itemCount: depth['sell'].length,
                                                                                                                    itemBuilder: (context, index) {
                                                                                                                      var sellDepth = depth['sell'][index];
                                                                                                                      return Column(
                                                                                                                        children: [
                                                                                                                          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                                                                                                                            Text(
                                                                                                                              "${sellDepth['quantity'].toString()}",
                                                                                                                              textAlign: TextAlign.left,
                                                                                                                            ),
                                                                                                                            Text("${sellDepth['price'].toString()}", textAlign: TextAlign.left),
                                                                                                                            Text("${sellDepth['orders'].toString()}", textAlign: TextAlign.left),
                                                                                                                          ]),
                                                                                                                          SizedBox(
                                                                                                                            height: 10,
                                                                                                                          ),
                                                                                                                        ],
                                                                                                                      );
                                                                                                                    },
                                                                                                                  ))),
                                                                                                          SizedBox(
                                                                                                            height: 15,
                                                                                                          )
                                                                                                        ],
                                                                                                      ))),
                                                                                                    ]),
                                                                                                  ))
                                                                                                ],
                                                                                              ),
                                                                                            ),
                                                                                          ),
                                                                                        ],
                                                                                      );
                                                                                    } else if (snapshot.hasError) {
                                                                                      return Text("Error");
                                                                                    } else {
                                                                                      return Container(child: Center(child: CircularProgressIndicator()));
                                                                                    }
                                                                                  },
                                                                                ),
                                                                              ),
                                                                            )
                                                                          ]))),
                                                              Expanded(
                                                                  child:
                                                                      Container(
                                                                padding:
                                                                    EdgeInsets
                                                                        .all(
                                                                            10),
                                                                color: Colors
                                                                    .black45,
                                                                child: ListView(
                                                                  children: [
                                                                    Container(
                                                                      child:
                                                                          Row(
                                                                        mainAxisAlignment:
                                                                            MainAxisAlignment.spaceBetween,
                                                                        children: [
                                                                          DepthInput(
                                                                              title: "Instrument",
                                                                              inputController: _instrumentController),
                                                                          SizedBox(
                                                                            width:
                                                                                20,
                                                                          ),
                                                                          DepthInput(
                                                                              title: "Quantity",
                                                                              inputController: _quantityController,
                                                                              inputType: TextInputType.number),
                                                                          SizedBox(
                                                                            width:
                                                                                20,
                                                                          ),
                                                                          depthTypeOptions != "MARKET"
                                                                              ? DepthInput(
                                                                                  title: "Price",
                                                                                  inputController: _priceController,
                                                                                  inputType: TextInputType.number,
                                                                                )
                                                                              : Container(),
                                                                        ],
                                                                      ),
                                                                    ),
                                                                    SizedBox(
                                                                      height:
                                                                          10,
                                                                    ),
                                                                    Container(
                                                                      child:
                                                                          Row(
                                                                        mainAxisAlignment:
                                                                            MainAxisAlignment.spaceBetween,
                                                                        children: [
                                                                          Expanded(
                                                                            child:
                                                                                Container(
                                                                              alignment: Alignment.centerLeft,
                                                                              child: Container(
                                                                                child: Column(
                                                                                  children: [
                                                                                    Text("Product"),
                                                                                    DropdownButton(
                                                                                        value: depthProduct,
                                                                                        style: TextStyle(color: Colors.white),
                                                                                        dropdownColor: Colors.grey[800],
                                                                                        onChanged: (value) {
                                                                                          setState(() => depthProduct = value);
                                                                                        },
                                                                                        items: [
                                                                                          DropdownMenuItem(value: "MIS", child: Text("MIS")),
                                                                                          DropdownMenuItem(value: "CNC", child: Text("CNC"))
                                                                                        ]),
                                                                                  ],
                                                                                ),
                                                                              ),
                                                                            ),
                                                                          ),
                                                                          SizedBox(
                                                                            width:
                                                                                20,
                                                                          ),
                                                                          Expanded(
                                                                            child:
                                                                                Container(
                                                                              alignment: Alignment.centerLeft,
                                                                              child: Container(
                                                                                child: Column(
                                                                                  children: [
                                                                                    Text("Type"),
                                                                                    DropdownButton(
                                                                                        value: depthType,
                                                                                        style: TextStyle(color: Colors.white),
                                                                                        dropdownColor: Colors.grey[800],
                                                                                        onChanged: (value) {
                                                                                          setState(() => depthType = value);
                                                                                        },
                                                                                        items: [
                                                                                          DropdownMenuItem(value: "DAY", child: Text("DAY")),
                                                                                          DropdownMenuItem(value: "IOC", child: Text("IOC"))
                                                                                        ]),
                                                                                  ],
                                                                                ),
                                                                              ),
                                                                            ),
                                                                          ),
                                                                          SizedBox(
                                                                            width:
                                                                                20,
                                                                          ),
                                                                          Expanded(
                                                                            child:
                                                                                Container(
                                                                              alignment: Alignment.centerLeft,
                                                                              child: Container(
                                                                                child: Column(
                                                                                  children: [
                                                                                    Text("Type Options"),
                                                                                    DropdownButton(
                                                                                        value: depthTypeOptions,
                                                                                        style: TextStyle(color: Colors.white),
                                                                                        dropdownColor: Colors.grey[800],
                                                                                        onChanged: (value) {
                                                                                          setState(() => depthTypeOptions = value);
                                                                                          if (depthTypeOptions == "MARKET") {
                                                                                            setState(() => _priceController.text = lastPrice);
                                                                                          }
                                                                                        },
                                                                                        items: [
                                                                                          DropdownMenuItem(value: "MARKET", child: Text("MARKET")),
                                                                                          DropdownMenuItem(value: "LIMIT", child: Text("LIMIT")),
                                                                                          DropdownMenuItem(value: "S/L", child: Text("S/L"))
                                                                                        ]),
                                                                                  ],
                                                                                ),
                                                                              ),
                                                                            ),
                                                                          ),
                                                                          SizedBox(
                                                                            width:
                                                                                20,
                                                                          ),
                                                                          Expanded(
                                                                            child:
                                                                                Container(
                                                                              alignment: Alignment.centerLeft,
                                                                              child: Container(
                                                                                child: Column(
                                                                                  children: [
                                                                                    Text("Validity"),
                                                                                    DropdownButton(
                                                                                        value: depthValidity,
                                                                                        style: TextStyle(color: Colors.white),
                                                                                        dropdownColor: Colors.grey[800],
                                                                                        onChanged: (value) {
                                                                                          setState(() => depthValidity = value);
                                                                                        },
                                                                                        items: [
                                                                                          DropdownMenuItem(value: "DAY", child: Text("DAY")),
                                                                                          DropdownMenuItem(value: "IOC", child: Text("IOC"))
                                                                                        ]),
                                                                                  ],
                                                                                ),
                                                                              ),
                                                                            ),
                                                                          )
                                                                        ],
                                                                      ),
                                                                    ),
                                                                    Padding(
                                                                      padding:
                                                                          const EdgeInsets.all(
                                                                              8.0),
                                                                      child:
                                                                          Container(
                                                                        child:
                                                                            Row(
                                                                          mainAxisAlignment:
                                                                              MainAxisAlignment.spaceBetween,
                                                                          children: [
                                                                            DepthInput(
                                                                              title: "Disclose Quantity",
                                                                              inputController: _discloseQuantityController,
                                                                              inputType: TextInputType.number,
                                                                            ),
                                                                            SizedBox(
                                                                              width: 20,
                                                                            ),
                                                                          ],
                                                                        ),
                                                                      ),
                                                                    ),
                                                                    Padding(
                                                                        padding:
                                                                            EdgeInsets.all(8),
                                                                        child: Container(
                                                                            child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                                                                          Container(
                                                                              child: MaterialButton(
                                                                            onPressed:
                                                                                () {
                                                                              print("Buy Working");

                                                                              if (depthTypeOptions == "S/L") {
                                                                                setState(() => _priceController.text = lastPrice);
                                                                              }

                                                                              String date = DateTime.now().day.toString().padLeft(2, "0") + "-" + DateTime.now().month.toString().padLeft(2, "0") + "-" + DateTime.now().year.toString().padLeft(2, "0");
                                                                              String time = DateTime.now().hour.toString().padLeft(2, "0") + ":" + DateTime.now().minute.toString().padLeft(2, "0");

                                                                              int tradeType = 0;
                                                                              String tradeBy = "Buy";

                                                                              if (depthTypeOptions == "MARKET") {
                                                                                setState(() => _priceController.text = lastPrice);
                                                                              }

                                                                              if (double.parse(_priceController.text.toString()) < double.parse(lastPrice.toString())) {
                                                                                print("Trade Booked in Order Book");
                                                                                tradeType = 0;
                                                                              } else {
                                                                                tradeType = 1;
                                                                                print("Trade Booked in Trade Book");
                                                                              }

                                                                              var tradeData = jsonEncode({
                                                                                "quantity": _quantityController.text,
                                                                                "price": _priceController.text,
                                                                                "trade_product": depthProduct,
                                                                                "trade_order": depthTypeOptions,
                                                                                "trade_stoploss": _stoplossController.text,
                                                                                "trade_validity": depthValidity,
                                                                                "trade_disclose_quantity": _discloseQuantityController.text,
                                                                                "buy_sell": tradeBy,
                                                                                "script_name": _instrumentController.text,
                                                                                "trade_category": stockCategory,
                                                                                "trade_in": tradeType,
                                                                                "trade_date": date,
                                                                                "trade_time": time,
                                                                                "client_id": userID
                                                                              });

                                                                              _createOrder(lastPrice, tradeType, tradeData);
                                                                            },
                                                                            color:
                                                                                Colors.green,
                                                                            child:
                                                                                Text("Buy", style: TextStyle(color: Colors.white)),
                                                                          )),
                                                                          Container(
                                                                              child: MaterialButton(
                                                                                  onPressed: () {
                                                                                    print("Sell Working");

                                                                                    if (depthTypeOptions == "S/L") {
                                                                                      setState(() => _priceController.text = lastPrice);
                                                                                    }

                                                                                    String date = DateTime.now().day.toString().padLeft(2, "0") + "-" + DateTime.now().month.toString().padLeft(2, "0") + "-" + DateTime.now().year.toString().padLeft(2, "0");
                                                                                    String time = DateTime.now().hour.toString().padLeft(2, "0") + ":" + DateTime.now().minute.toString().padLeft(2, "0");

                                                                                    int tradeType = 0;
                                                                                    String tradeBy = "Sell";

                                                                                    if (depthTypeOptions == "MARKET") {
                                                                                      setState(() => _priceController.text = lastPrice);
                                                                                    }

                                                                                    if (double.parse(_priceController.text.toString()) > double.parse(lastPrice.toString())) {
                                                                                      print("Trade Booked in Order Book");
                                                                                      tradeType = 0;
                                                                                    } else {
                                                                                      tradeType = 1;
                                                                                      print("Trade Booked in Trade Book");
                                                                                    }

                                                                                    var tradeData = jsonEncode({
                                                                                      "quantity": _quantityController.text,
                                                                                      "price": _priceController.text,
                                                                                      "trade_product": depthProduct,
                                                                                      "trade_order": depthTypeOptions,
                                                                                      "trade_stoploss": _stoplossController.text,
                                                                                      "trade_validity": depthValidity,
                                                                                      "trade_disclose_quantity": _discloseQuantityController.text,
                                                                                      "buy_sell": tradeBy,
                                                                                      "script_name": _instrumentController.text,
                                                                                      "trade_category": stockCategory,
                                                                                      "trade_in": tradeType,
                                                                                      "trade_date": date,
                                                                                      "trade_time": time,
                                                                                      "client_id": userID
                                                                                    });

                                                                                    _createOrder(lastPrice, tradeType, tradeData);
                                                                                  },
                                                                                  color: Colors.red,
                                                                                  child: Text("Sell", style: TextStyle(color: Colors.white))))
                                                                        ])))
                                                                  ],
                                                                ),
                                                              )),
                                                            ],
                                                          ),
                                                        ));
                                                  },
                                                );
                                              },
                                            );
                                          },
                                          child: Container(
                                              width: 130,
                                              child: Text(
                                                "${script['script_name']}",
                                                style: TextStyle(fontSize: 10),
                                              ))),
                                      SizedBox(
                                        width: 10,
                                      ),
                                      StreamBuilder(
                                        stream: _scriptStream.stream,
                                        builder: (context, snapshot) {
                                          // var provider_value = "0";
                                          Color color = Colors.transparent;
                                          Color scriptColor =
                                              Colors.transparent;

                                          if (snapshot.hasData) {
                                            var data = snapshot.data['data'];

                                            double todaysMarket = double.parse(
                                                    data['last_price']
                                                        .toString()) -
                                                double.parse(data['ohlc']
                                                        ['close']
                                                    .toString());

                                            return Row(
                                              children: [
                                                Container(
                                                  alignment:
                                                      Alignment.centerLeft,
                                                  width: 100,
                                                  child: Text(
                                                    "${data['last_price'].toString()}",
                                                    style: TextStyle(
                                                        backgroundColor:
                                                            scriptColor),
                                                  ),
                                                ),
                                                Container(
                                                    alignment:
                                                        Alignment.centerLeft,
                                                    width: 100,
                                                    child: Text(
                                                        " ${todaysMarket.toDouble() > 0 ? "+" : ""}${double.parse(todaysMarket.toString()).toStringAsFixed(2)}",
                                                        style: TextStyle(
                                                            color: todaysMarket
                                                                        .toDouble() >
                                                                    0
                                                                ? Colors.green
                                                                : todaysMarket
                                                                            .toDouble() ==
                                                                        0
                                                                    ? Colors
                                                                        .transparent
                                                                    : Colors
                                                                        .red))),
                                                Container(
                                                    alignment:
                                                        Alignment.centerLeft,
                                                    width: 100,
                                                    child: Text(
                                                        "${data['volume'].toString()}")),
                                                Container(
                                                    alignment:
                                                        Alignment.centerLeft,
                                                    width: 100,
                                                    child: Text(
                                                        "${data['ohlc']['open'].toString()}")),
                                                Container(
                                                    alignment:
                                                        Alignment.centerLeft,
                                                    width: 100,
                                                    child: Text(
                                                        "${data['ohlc']['close'].toString()}")),
                                                Container(
                                                    alignment:
                                                        Alignment.centerLeft,
                                                    width: 100,
                                                    child: Text(
                                                        "${data['ohlc']['high'].toString()}",
                                                        style: TextStyle(
                                                            color:
                                                                Colors.green))),
                                                Container(
                                                    alignment:
                                                        Alignment.centerLeft,
                                                    width: 70,
                                                    child: Text(
                                                        "${data['ohlc']['low'].toString()}",
                                                        style: TextStyle(
                                                            color:
                                                                Colors.red))),
                                                GestureDetector(
                                                  onTap: () async {
                                                    print(script['script_id']);
                                                    socket.emit('unsubscribe', {
                                                      "token": [
                                                        script[
                                                            'instrument_token']
                                                      ]
                                                    });

                                                    _scripts.removeAt(index);

                                                    setState(() {});
                                                    _streamController
                                                        .add(_scripts);
                                                  },
                                                  child: Container(
                                                      alignment:
                                                          Alignment.centerLeft,
                                                      width: 30,
                                                      child: Icon(
                                                        Icons.cancel,
                                                        size: 12,
                                                        color: Colors.white,
                                                      )),
                                                ),
                                              ],
                                            );
                                          } else if (snapshot.hasError) {
                                            print('has Error');
                                            return Text("Has Error");
                                          } else {
                                            print("loading data");
                                            return Text("Loading Data");
                                          }
                                        },
                                      )
                                    ],
                                  ),
                                );
                              },
                            );
                          } else {
                            return Center(
                                child:
                                    Container(child: Text("Data not found")));
                          }
                        },
                      )
                    : Container(
                        child: Center(
                          child: Text("Add Watchlist from + button"),
                        ),
                      ),
              ),
            )
          ],
        ),
      ),
    );
  }

  List<Widget> _getTitleWidget() {
    return [
      _getTitleItemWidget('Script', 100),
      Padding(
        padding: const EdgeInsets.only(left: 10),
        child: _getTitleItemWidget('Last Price', 100),
      ),
      _getTitleItemWidget('L.Quantity', 100),
      _getTitleItemWidget('Volume', 100),
      _getTitleItemWidget('Open', 100),
      _getTitleItemWidget('High', 100),
      _getTitleItemWidget('Low', 100),
      _getTitleItemWidget('Close', 100),
    ];
  }

  Widget _getTitleItemWidget(String label, double width) {
    return Container(
      color: Colors.grey,
      child:
          Text(label, style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
      width: width,
      height: 56,
      padding: EdgeInsets.fromLTRB(5, 0, 0, 0),
      alignment: Alignment.center,
    );
  }

  Widget _generateRightHandSideColumnRow(
      BuildContext context, KiteScriptDataModel script, int index) {
    if (script != null) {
      _storeOldValue(script.data.lastPrice);
    }
    return Padding(
      padding: const EdgeInsets.only(left: 10),
      child: Row(
        children: <Widget>[
          Container(
            child: Text(
              "${script.data.lastPrice}",
              style: GoogleFonts.poppins(),
            ),
            width: 100,
            height: 52,
            alignment: Alignment.center,
          ),
          Container(
            child: Text(
              "${script.data.lastQuantity}",
              style: GoogleFonts.poppins(),
            ),
            width: 100,
            height: 52,
            alignment: Alignment.center,
          ),
          Container(
            child: Text(
              "${script.data.volume}",
              style: GoogleFonts.poppins(),
            ),
            width: 100,
            height: 52,
            alignment: Alignment.center,
          ),
          Container(
            child: Text(
              "${script.data.ohlc.open}",
              style: GoogleFonts.poppins(),
            ),
            width: 100,
            height: 52,
            alignment: Alignment.center,
          ),
          Container(
            child: Text(
              "${script.data.ohlc.high}",
              style: GoogleFonts.poppins(),
            ),
            width: 100,
            height: 52,
            alignment: Alignment.center,
          ),
          Container(
            child: Text(
              "${script.data.ohlc.low}",
              style: GoogleFonts.poppins(),
            ),
            width: 100,
            height: 52,
            padding: EdgeInsets.fromLTRB(5, 0, 0, 0),
            alignment: Alignment.center,
          ),
          Container(
            child:
                Text("${script.data.ohlc.close}", style: GoogleFonts.poppins()),
            width: 100,
            height: 52,
            padding: EdgeInsets.fromLTRB(5, 0, 0, 0),
            alignment: Alignment.center,
          ),
        ],
      ),
    );
  }
}

class DepthInput extends StatelessWidget {
  const DepthInput({
    Key key,
    this.inputController,
    this.title,
    this.inputType,
  }) : super(key: key);

  final TextEditingController inputController;
  final String title;
  final TextInputType inputType;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        child: Column(
          children: [
            Container(alignment: Alignment.centerLeft, child: Text("$title")),
            Container(
              padding: EdgeInsets.only(left: 10),
              decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.all(Radius.circular(8))),
              child: TextField(
                controller: inputController,
                keyboardType: inputType ?? TextInputType.text,
                style: TextStyle(fontSize: 10, color: Colors.white),
                decoration: InputDecoration(
                  border: InputBorder.none,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
