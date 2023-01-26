import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:horizontal_data_table/horizontal_data_table.dart';
import 'package:intl/intl.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socket_io_client/socket_io_client.dart';
import 'package:swcap/api/kite_api.dart';
import 'package:swcap/api/trade_book_api.dart';
import 'package:swcap/components/drawer/custom_drawer.dart';
import 'package:swcap/controllers/kite_controller.dart';
import 'package:swcap/controllers/main_controller.dart';
import 'package:swcap/controllers/socket_controller.dart';
import 'package:swcap/controllers/user_controller.dart';
import 'package:swcap/model/kite/kite_script_model.dart';
import 'package:swcap/model/user/user_model.dart';
import 'package:swcap/pages/account/account.dart';
import 'package:swcap/pages/order_book/order_book.dart';
import 'package:swcap/pages/script_details.dart';
import 'package:swcap/pages/search/search.dart';
import 'package:swcap/pages/trade_book/trade_book.dart';
// import 'package:socket_io_client/socket_io_client.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List _scripts = [];
  String userID;
  UserModel userModel;
  String apiKey;
  String accessToken;
  StreamController<List> _streamController = StreamController();
  StreamController<List> _tabScriptController = StreamController();
  MainController mainController = Get.put(MainController());
  SocketController socketController = Get.put(SocketController());
  UserController userController = Get.put(UserController());
  KiteController kiteController = Get.put(KiteController());
  double oldValue = 0;
  Socket socket;
  int user;
  List subscribeToken = [];
  List scriptData = [];
  SharedPreferences pref;
  bool gotApi = false;
  var nFormat =
      NumberFormat.currency(locale: "HI", name: "INDIAN", symbol: "Rs. ");

  @override
  void initState() {
    init();
    super.initState();
  }

  init() async {
    mainController.init();
    mainController.startEngine();
  }

  _storeOldValue(oldV) {
    oldValue = oldV;
  }

  _createOrder(lastPrice, tradeType, tradeData, script_name, context) async {
    print(tradeData);

    await TradeBookApi.createTradeBook(tradeData).then((value) {
      SnackBar snackBar;
      if (value.status) {
        snackBar = SnackBar(
            content: Text(
          "Order Created Successfully of $script_name",
          style: TextStyle(color: Colors.green),
        ));
        Navigator.pop(context);
      } else {
        snackBar = SnackBar(
            content: Text(
          "Something went wrong",
          style: TextStyle(color: Colors.red),
        ));
        print("Something went wrong");
      }

      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    });
  }

  @override
  void dispose() {
    // TODO: implement dispose
    // socket.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.black12,
          leadingWidth: MediaQuery.of(context).size.width * 0.5,
          leading: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                InkWell(
                  onTap: () => Get.to(() => HomePage()),
                  child: Container(
                    child: Text("Watchlist"),
                  ),
                ),
                SizedBox(
                  width: 20,
                ),
                InkWell(
                  onTap: () => Get.to(() => OrderBook()),
                  child: Container(
                    child: Text("Orders"),
                  ),
                ),
                SizedBox(
                  width: 20,
                ),
                InkWell(
                  onTap: () => Get.to(() => TradeBook()),
                  child: Container(
                    child: Text("Trades"),
                  ),
                ),
                SizedBox(
                  width: 20,
                ),
                InkWell(
                  onTap: () => Get.to(() => Account()),
                  child: Container(
                    child: Text("Account"),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            InkWell(
              onTap: () {
                mainController.restartEngine();
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
            Get.to(() => Search(userID: userController.user.value.id));
          },
          child: Icon(Icons.add),
        ),
        body: Obx(() {
          print(kiteController.apiKey);
          return Container(
              child: HorizontalDataTable(
            leftHandSideColumnWidth: 100,
            rightHandSideColumnWidth: MediaQuery.of(context).size.width,
            isFixedHeader: true,
            horizontalScrollController:
                ScrollController(keepScrollOffset: true),
            headerWidgets: _getTitleWidget(),
            // horizontalScrollPhysics: NeverScrollableScrollPhysics(),
            leftSideItemBuilder: _generateFirstColumnRow,
            rightSideItemBuilder: _generateRightHandSideColumnRow,
            leftHandSideColBackgroundColor: Colors.black,
            rightHandSideColBackgroundColor: Colors.black54,
            itemCount: mainController.watchListData.length,
            rowSeparatorWidget: Divider(
              height: 2,
              color: Colors.white,
              thickness: 0.3,
            ),
            elevationColor: Colors.black,
          ));
        }));
  }

  List<Widget> _getTitleWidget() {
    return [
      _getTitleItemWidget('Symbol', 100),
      _getTitleItemWidget('Last Price', 80),
      _getTitleItemWidget('Buy Qty', 60),
      _getTitleItemWidget('Buy Price', 80),
      _getTitleItemWidget(' ', 10),
      _getTitleItemWidget('Sell Price', 80),
      _getTitleItemWidget('Sell Qty', 60),
      _getTitleItemWidget('Volume', 100),
      _getTitleItemWidget('High', 60),
      _getTitleItemWidget('Low', 60),
      _getTitleItemWidget('Open', 60),
      _getTitleItemWidget('Close', 60),
      _getTitleItemWidget('Avg', 60),
    ];
  }

  Widget _getTitleItemWidget(String label, double width) {
    return Container(
      color: Colors.grey,
      child:
          Text(label, style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
      width: width,
      height: 20,
      padding: EdgeInsets.fromLTRB(5, 0, 0, 0),
      alignment: Alignment.center,
    );
  }

  Widget _generateFirstColumnRow(BuildContext context, int index) {
    var script = mainController.watchListData[index];
    return InkWell(
      onTap: () {
        print(script['SCRIPT_NAME']);
        String stockName = script['SCRIPT_NAME'];
        String stockToken = script['SCRIPT_TOKEN'];
        String stockCategory = script['SCRIPT_CATEGORY'].toString();
        StreamController _depthStream = StreamController();
        TextEditingController _instrumentController = TextEditingController();

        TextEditingController _quantityController = TextEditingController();

        _quantityController.text = '0';
        TextEditingController _priceController = TextEditingController();

        _priceController.text = "0.0";
        TextEditingController _stoplossController = TextEditingController();
        TextEditingController _discloseQuantityController =
            TextEditingController();
        var lotSize = 0;
        _instrumentController.text = stockName;
        var lastPrice = "0.0";

        dynamic depthProduct = "MIS";
        dynamic depthType = "DAY";
        dynamic depthValidity = "DAY";
        dynamic depthTypeOptions = "MARKET";

        String errorAlert = "";

        // GET SCRIPT DATA

        socketController.socket.on(
            "receiveticks",
            (ticks) => {
                  ticks['tick'].forEach((tick) {
                    print(tick);
                    if (tick['instrument_token'] == int.parse(stockToken)) {
                      _depthStream.add({"data": tick, "token": stockToken});
                    }
                  })
                });
        showMaterialModalBottomSheet(
          context: context,
          builder: (context) {
            return StatefulBuilder(
              builder: (context, setState) {
                return Container(
                    decoration: BoxDecoration(color: Colors.black),
                    height: MediaQuery.of(context).size.height * 0.50,
                    child: Container(
                      child: Row(
                        children: [
                          Expanded(
                              child: Container(
                                  color: Colors.grey,
                                  child: Column(children: [
                                    Container(
                                        height: 20,
                                        color: Colors.black,
                                        child: Center(
                                          child:
                                              Text("Market Depth ($stockName)"),
                                        )),
                                    Expanded(
                                      child: Container(
                                        color: Colors.black87,
                                        child: StreamBuilder(
                                          stream: _depthStream.stream,
                                          builder: (context, snapshot) {
                                            if (snapshot.hasData) {
                                              lastPrice = snapshot.data['data']
                                                      ['last_price']
                                                  .toString();
                                              var depth = snapshot.data['data']
                                                  ['depth'];
                                              return Column(
                                                children: [
                                                  Container(
                                                    height: 20,
                                                    child: Text(
                                                      " $stockName : $lastPrice",
                                                      style: TextStyle(
                                                          fontSize: 15),
                                                    ),
                                                  ),
                                                  Expanded(
                                                    child: Container(
                                                      child: Row(
                                                        children: [
                                                          Expanded(
                                                              child: Container(
                                                            padding: EdgeInsets
                                                                .symmetric(
                                                                    horizontal:
                                                                        10),
                                                            child: Column(
                                                                children: [
                                                                  Container(
                                                                    height: 20,
                                                                    child: Center(
                                                                        child: Text(
                                                                            "Buy",
                                                                            style:
                                                                                TextStyle(color: Colors.green))),
                                                                  ),
                                                                  Expanded(
                                                                      child:
                                                                          Container(
                                                                    child:
                                                                        Column(
                                                                      mainAxisAlignment:
                                                                          MainAxisAlignment
                                                                              .start,
                                                                      children: [
                                                                        Container(),
                                                                        Container(
                                                                          padding:
                                                                              EdgeInsets.all(0),
                                                                          margin:
                                                                              EdgeInsets.all(0),
                                                                          child: Row(
                                                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                              children: [
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
                                                                          itemCount:
                                                                              depth['buy'].length,
                                                                          itemBuilder:
                                                                              (context, index) {
                                                                            var buyDepth =
                                                                                depth['buy'][index];
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
                                                                          height:
                                                                              20,
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
                                                            padding: EdgeInsets
                                                                .symmetric(
                                                                    horizontal:
                                                                        10),
                                                            child: Column(
                                                                children: [
                                                                  Container(
                                                                    height: 20,
                                                                    child: Center(
                                                                        child: Text(
                                                                            "Sell",
                                                                            style:
                                                                                TextStyle(color: Colors.red))),
                                                                  ),
                                                                  Expanded(
                                                                      child: Container(
                                                                          child: Column(
                                                                    children: [
                                                                      Container(
                                                                        child: Row(
                                                                            mainAxisAlignment:
                                                                                MainAxisAlignment.spaceBetween,
                                                                            children: [
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
                                                                        height:
                                                                            15,
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
                                              return Container(
                                                  child: Center(
                                                      child:
                                                          CircularProgressIndicator()));
                                            }
                                          },
                                        ),
                                      ),
                                    )
                                  ]))),
                          Expanded(
                              child: Container(
                            padding: EdgeInsets.all(10),
                            color: Colors.black45,
                            child: ListView(
                              children: [
                                Container(
                                    child: Text(
                                        "Current Balance : ${nFormat.format(double.parse(userController.user.value.balanceInAccount))}")),
                                Divider(
                                  color: Colors.white,
                                ),
                                Container(
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      DepthInput(
                                          title: "Instrument",
                                          inputController:
                                              _instrumentController),
                                      SizedBox(
                                        width: 20,
                                      ),
                                      DepthInput(
                                          title: stockCategory == "CASH"
                                              ? "Quantity (Shares)"
                                              : "Quantity (Lots)",
                                          inputController: _quantityController,
                                          inputType: TextInputType.number),
                                      SizedBox(
                                        width: 20,
                                      ),
                                      depthTypeOptions != "MARKET"
                                          ? DepthInput(
                                              title: depthTypeOptions == "S/L"
                                                  ? "StopLoss Price"
                                                  : "Price",
                                              inputController: _priceController,
                                              inputType: TextInputType
                                                  .numberWithOptions(
                                                      decimal: true,
                                                      signed: false),
                                            )
                                          : Container(),
                                    ],
                                  ),
                                ),
                                SizedBox(
                                  height: 10,
                                ),
                                Container(
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Container(
                                          alignment: Alignment.centerLeft,
                                          child: Container(
                                            child: Column(
                                              children: [
                                                Text("Product"),
                                                DropdownButton(
                                                    value: depthProduct,
                                                    style: TextStyle(
                                                        color: Colors.white),
                                                    dropdownColor:
                                                        Colors.grey[800],
                                                    onChanged: (value) {
                                                      setState(() =>
                                                          depthProduct = value);
                                                    },
                                                    items: [
                                                      DropdownMenuItem(
                                                          value: "MIS",
                                                          child: Text("MIS")),
                                                      DropdownMenuItem(
                                                          value: "CNC",
                                                          child: Text("CNC"))
                                                    ]),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                      SizedBox(
                                        width: 20,
                                      ),
                                      Expanded(
                                        child: Container(
                                          alignment: Alignment.centerLeft,
                                          child: Container(
                                            child: Column(
                                              children: [
                                                Text("Type"),
                                                DropdownButton(
                                                    value: depthType,
                                                    style: TextStyle(
                                                        color: Colors.white),
                                                    dropdownColor:
                                                        Colors.grey[800],
                                                    onChanged: (value) {
                                                      setState(() =>
                                                          depthType = value);
                                                    },
                                                    items: [
                                                      DropdownMenuItem(
                                                          value: "DAY",
                                                          child: Text("DAY")),
                                                      DropdownMenuItem(
                                                          value: "IOC",
                                                          child: Text("IOC"))
                                                    ]),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                      SizedBox(
                                        width: 20,
                                      ),
                                      Expanded(
                                        child: Container(
                                          alignment: Alignment.centerLeft,
                                          child: Container(
                                            child: Column(
                                              children: [
                                                Text("Type Options"),
                                                DropdownButton(
                                                    value: depthTypeOptions,
                                                    style: TextStyle(
                                                        color: Colors.white),
                                                    dropdownColor:
                                                        Colors.grey[800],
                                                    onChanged: (value) {
                                                      setState(() =>
                                                          depthTypeOptions =
                                                              value);
                                                      if (depthTypeOptions ==
                                                          "MARKET") {
                                                        setState(() =>
                                                            _priceController
                                                                    .text =
                                                                lastPrice);
                                                      }
                                                    },
                                                    items: [
                                                      DropdownMenuItem(
                                                          value: "MARKET",
                                                          child:
                                                              Text("MARKET")),
                                                      DropdownMenuItem(
                                                          value: "LIMIT",
                                                          child: Text("LIMIT")),
                                                      DropdownMenuItem(
                                                          value: "S/L",
                                                          child: Text("S/L"))
                                                    ]),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                      SizedBox(
                                        width: 20,
                                      ),
                                      Expanded(
                                        child: Container(
                                          alignment: Alignment.centerLeft,
                                          child: Container(
                                            child: Column(
                                              children: [
                                                Text("Validity"),
                                                DropdownButton(
                                                    value: depthValidity,
                                                    style: TextStyle(
                                                        color: Colors.white),
                                                    dropdownColor:
                                                        Colors.grey[800],
                                                    onChanged: (value) {
                                                      setState(() =>
                                                          depthValidity =
                                                              value);
                                                    },
                                                    items: [
                                                      DropdownMenuItem(
                                                          value: "DAY",
                                                          child: Text("DAY")),
                                                      DropdownMenuItem(
                                                          value: "IOC",
                                                          child: Text("IOC"))
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
                                  padding: const EdgeInsets.all(8.0),
                                  child: Container(
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        DepthInput(
                                          title: "Disclose Quantity",
                                          inputController:
                                              _discloseQuantityController,
                                          inputType: TextInputType.number,
                                        ),
                                        SizedBox(
                                          width: 20,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                Container(
                                  alignment: Alignment.center,
                                  child: Text(
                                    errorAlert,
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                                Padding(
                                    padding: EdgeInsets.all(8),
                                    child: Container(
                                        child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceEvenly,
                                            children: [
                                          Container(
                                              child: MaterialButton(
                                            onPressed: () {
                                              if (_quantityController.text ==
                                                      "" ||
                                                  int.parse(_quantityController
                                                          .text) <
                                                      1) {
                                                setState(() => errorAlert =
                                                    "Invalid Quantity");
                                                return false;
                                              }

                                              if (_priceController.text == "") {
                                                print(_priceController.text);
                                                print(lastPrice);
                                                setState(() => errorAlert =
                                                    "Invalid Price");
                                                return false;
                                              }

                                              print("Buy Working");

                                              if (depthTypeOptions == "S/L") {
                                                setState(() => _priceController
                                                    .text = lastPrice);
                                              }

                                              String date = DateTime.now()
                                                      .day
                                                      .toString()
                                                      .padLeft(2, "0") +
                                                  "-" +
                                                  DateTime.now()
                                                      .month
                                                      .toString()
                                                      .padLeft(2, "0") +
                                                  "-" +
                                                  DateTime.now()
                                                      .year
                                                      .toString()
                                                      .padLeft(2, "0");
                                              String time = DateTime.now()
                                                      .hour
                                                      .toString()
                                                      .padLeft(2, "0") +
                                                  ":" +
                                                  DateTime.now()
                                                      .minute
                                                      .toString()
                                                      .padLeft(2, "0");

                                              int tradeType = 0;
                                              String tradeBy = "Buy";

                                              if (depthTypeOptions ==
                                                  "MARKET") {
                                                setState(() => _priceController
                                                    .text = lastPrice);
                                              }

                                              if (double.parse(_priceController
                                                      .text
                                                      .toString()) <
                                                  double.parse(
                                                      lastPrice.toString())) {
                                                print(
                                                    "Trade Booked in Order Book");
                                                tradeType = 0;
                                              } else {
                                                tradeType = 1;
                                                print(
                                                    "Trade Booked in Trade Book");
                                              }

                                              var tradeData = jsonEncode({
                                                "quantity":
                                                    _quantityController.text,
                                                "price": _priceController.text,
                                                "trade_product": depthProduct,
                                                "trade_order": depthTypeOptions,
                                                "trade_stoploss":
                                                    _stoplossController.text,
                                                "trade_validity": depthValidity,
                                                "trade_disclose_quantity":
                                                    _discloseQuantityController
                                                        .text,
                                                "buy_sell": tradeBy,
                                                "script_name":
                                                    _instrumentController.text,
                                                "trade_category": stockCategory,
                                                "trade_in": tradeType,
                                                "trade_date": date,
                                                "trade_time": time,
                                                "client_id": userID
                                              });

                                              _createOrder(
                                                  lastPrice,
                                                  tradeType,
                                                  tradeData,
                                                  _instrumentController.text,
                                                  context);
                                            },
                                            color: Colors.green,
                                            child: Text("Buy",
                                                style: TextStyle(
                                                    color: Colors.white)),
                                          )),
                                          Container(
                                              child: MaterialButton(
                                                  onPressed: () {
                                                    print("Sell Working");

                                                    if (depthTypeOptions ==
                                                        "S/L") {
                                                      setState(() =>
                                                          _priceController
                                                                  .text =
                                                              lastPrice);
                                                    }

                                                    String date = DateTime.now()
                                                            .day
                                                            .toString()
                                                            .padLeft(2, "0") +
                                                        "-" +
                                                        DateTime.now()
                                                            .month
                                                            .toString()
                                                            .padLeft(2, "0") +
                                                        "-" +
                                                        DateTime.now()
                                                            .year
                                                            .toString()
                                                            .padLeft(2, "0");
                                                    String time = DateTime.now()
                                                            .hour
                                                            .toString()
                                                            .padLeft(2, "0") +
                                                        ":" +
                                                        DateTime.now()
                                                            .minute
                                                            .toString()
                                                            .padLeft(2, "0");

                                                    int tradeType = 0;
                                                    String tradeBy = "Sell";

                                                    if (depthTypeOptions ==
                                                        "MARKET") {
                                                      setState(() =>
                                                          _priceController
                                                                  .text =
                                                              lastPrice);
                                                    }

                                                    if (double.parse(
                                                            _priceController
                                                                .text
                                                                .toString()) >
                                                        double.parse(lastPrice
                                                            .toString())) {
                                                      print(
                                                          "Trade Booked in Order Book");
                                                      tradeType = 0;
                                                    } else {
                                                      tradeType = 1;
                                                      print(
                                                          "Trade Booked in Trade Book");
                                                    }

                                                    var tradeData = jsonEncode({
                                                      "quantity":
                                                          _quantityController
                                                              .text,
                                                      "price":
                                                          _priceController.text,
                                                      "trade_product":
                                                          depthProduct,
                                                      "trade_order":
                                                          depthTypeOptions,
                                                      "trade_stoploss":
                                                          _stoplossController
                                                              .text,
                                                      "trade_validity":
                                                          depthValidity,
                                                      "trade_disclose_quantity":
                                                          _discloseQuantityController
                                                              .text,
                                                      "buy_sell": tradeBy,
                                                      "script_name":
                                                          _instrumentController
                                                              .text,
                                                      "trade_category":
                                                          stockCategory,
                                                      "trade_in": tradeType,
                                                      "trade_date": date,
                                                      "trade_time": time,
                                                      "client_id": userID
                                                    });

                                                    _createOrder(
                                                        lastPrice,
                                                        tradeType,
                                                        tradeData,
                                                        _instrumentController
                                                            .text,
                                                        context);
                                                  },
                                                  color: Colors.red,
                                                  child: Text("Sell",
                                                      style: TextStyle(
                                                          color:
                                                              Colors.white))))
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
        // showDialog(
        //   context: context,
        //   builder: (context) {
        //     return AlertDialog(
        //       contentPadding: EdgeInsets.all(0),
        //       actionsPadding: EdgeInsets.all(0),
        //       insetPadding: EdgeInsets.all(0),
        //       titlePadding: EdgeInsets.all(0),
        //       content: Container(
        //         height: 300,
        //         child: SingleChildScrollView(
        //           child: Column(
        //             children: [
        //               ScriptDetails(
        //                 id: script['ID'],
        //               ),
        //             ],
        //           ),
        //         ),
        //       ),
        //     );
        //   },
        // );
      },
      child: Container(
        child: Text("${script['SCRIPT_NAME']}"),
        width: 100,
        height: 25,
        padding: EdgeInsets.fromLTRB(5, 0, 0, 0),
        alignment: Alignment.center,
      ),
    );
  }

  Widget _generateRightHandSideColumnRow(BuildContext context, int index) {
    var script = mainController.watchListData[index];
    return Row(
      children: <Widget>[
        Container(
          decoration: BoxDecoration(
              color: script['COLOR'] == 'G'
                  ? Colors.green
                  : script['COLOR'] == 'R'
                      ? Colors.red
                      : Colors.transparent),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[Text('${script['CURRENT_PRICE']}')],
          ),
          width: 80,
          height: 25,
          padding: EdgeInsets.fromLTRB(5, 0, 0, 0),
          alignment: Alignment.center,
        ),
        Container(
          decoration: BoxDecoration(),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[Text('${script['BUY_QUANTITY']}')],
          ),
          width: 60,
          height: 25,
          padding: EdgeInsets.fromLTRB(5, 0, 0, 0),
          alignment: Alignment.center,
        ),
        Container(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[Text('${script['BUY_PRICE']}')],
          ),
          width: 80,
          height: 25,
          padding: EdgeInsets.fromLTRB(5, 0, 0, 0),
          alignment: Alignment.center,
        ),
        Container(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[Text('|')],
          ),
          width: 10,
          height: 25,
          padding: EdgeInsets.fromLTRB(5, 0, 0, 0),
          alignment: Alignment.center,
        ),
        Container(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[Text('${script['CURRENT_PRICE']}')],
          ),
          width: 80,
          height: 25,
          padding: EdgeInsets.fromLTRB(5, 0, 0, 0),
          alignment: Alignment.center,
        ),
        Container(
          child: Text('${script['SELL_QUANTITY']}'),
          width: 60,
          height: 25,
          padding: EdgeInsets.fromLTRB(5, 0, 0, 0),
          alignment: Alignment.center,
        ),
        Container(
          child: Text('${script['VOLUME_TRADE']}'),
          width: 100,
          height: 25,
          padding: EdgeInsets.fromLTRB(5, 0, 0, 0),
          alignment: Alignment.center,
        ),
        Container(
          child: Text('${script['HIGH']}'),
          width: 60,
          height: 25,
          padding: EdgeInsets.fromLTRB(5, 0, 0, 0),
          alignment: Alignment.center,
        ),
        Container(
          child: Text('${script['LOW']}'),
          width: 60,
          height: 25,
          padding: EdgeInsets.fromLTRB(5, 0, 0, 0),
          alignment: Alignment.center,
        ),
        Container(
          child: Text('${script['OPEN']}'),
          width: 60,
          height: 25,
          padding: EdgeInsets.fromLTRB(5, 0, 0, 0),
          alignment: Alignment.center,
        ),
        Container(
          child: Text('${script['CLOSE']}'),
          width: 60,
          height: 25,
          padding: EdgeInsets.fromLTRB(5, 0, 0, 0),
          alignment: Alignment.center,
        ),
        Container(
          child: Text('${script['AVERAGE_TRADE_PRICE']}'),
          width: 60,
          height: 25,
          padding: EdgeInsets.fromLTRB(5, 0, 0, 0),
          alignment: Alignment.center,
        ),
      ],
    );
  }
}

class DepthInput extends StatelessWidget {
  const DepthInput({Key key, this.inputController, this.title, this.inputType})
      : super(key: key);

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
                inputFormatters: inputType == TextInputType.number
                    ? <TextInputFormatter>[
                        FilteringTextInputFormatter.digitsOnly
                      ]
                    : [],
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
