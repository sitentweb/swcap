import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:swcap/api/fetch_scripts.dart';
import 'package:swcap/api/span_margin_api.dart';
import 'package:swcap/api/trade_book_api.dart';
import 'package:swcap/api/user_api.dart';
import 'package:swcap/components/buttons/text_button.dart';
import 'package:swcap/components/inputs/custom_input.dart';
import 'package:swcap/config/app_config.dart';
import 'package:swcap/model/margin/span_margin_model.dart';
import 'package:swcap/model/user/user_model.dart';

class Account extends StatefulWidget {
  const Account({Key key}) : super(key: key);

  @override
  _AccountState createState() => _AccountState();
}

class _AccountState extends State<Account> {
  String userID = "";
  String userName = "";
  UserModel user = UserModel(status: false);
  List deliveryMargins = [];
  double openingBalance = 0;
  double totalDeliveryMargin = 0.0;
  double totalSpanMargin = 0.0;
  double totalOptionPremium = 0.0;
  double totalMarginUtilized = 0.0;
  var nFormat =
      NumberFormat.currency(locale: "HI", name: "INDIAN", symbol: "Rs. ");
  List<Datum> listSpanMargins = <Datum>[];
  Future<UserModel> _userModel;

  @override
  void initState() {
    // TODO: implement initState
    getUserData();
    // totalMargin();
    super.initState();
  }

  getUserData() async {
    SharedPreferences pref = await SharedPreferences.getInstance();

    setState(() {
      userID = pref.getString("userID");
      userName = pref.getString("userName");
      _userModel = UserApi.fetchUser(userID);
    });

    await UserApi.fetchUser(userID).then((value) {
      if (value.status) {
        user = value;
        setState(() {
          openingBalance = double.parse(user.data.openingBalance);
        });
      }
    });

    await TradeBookApi.fetchTradeBook(userID).then((tradeBook) {
      if (tradeBook.status) {
        final trade = tradeBook.data;

        trade.forEach((singleTradeBook) {
          // START CALCULATING DELIVERY MARGIN

          if (singleTradeBook.tradeCategory == "CASH") {
            print(singleTradeBook);
            double deliveryMargin = double.parse(singleTradeBook.price) *
                double.parse(singleTradeBook.quantity);
            // print();

            setState(() {
              totalDeliveryMargin = totalDeliveryMargin + deliveryMargin;
              totalMarginUtilized = totalDeliveryMargin;
            });
          }

          // ENDED CALCULATIN DELIVERY MARGINS
        });
      }
    });

    // await SpanMarginApi().fetchSpanMargin().then((spanMargin) {
    //   if (spanMargin.status) {
    //     setState(() {
    //       listSpanMargins = spanMargin.data;
    //     });
    //   } else {
    //     print("Span Margin got failed");
    //   }
    // });

    await TradeBookApi.fetchTradeBook(userID).then((tradeBook) {
      print("Fetch Future");

      if (tradeBook.status) {
        final trade = tradeBook.data;

        double spanMargin = 0.0;

        trade.forEach((singleTradeBook) async {
          // START CALCUATING SPAN + EXPOSURE MARGINS

          if ((singleTradeBook.tradeCategory == "FUTURE") ||
              (singleTradeBook.tradeCategory == "OPTION" &&
                  singleTradeBook.buySell == "Sell")) {
            await FetchScripts()
                .fetchInstrumentData(singleTradeBook.scriptName)
                .then((res) async {
              if (res.status) {
                // FETCH SPAN MARGIN HERE
                // AND CALCULATE AGAIN
                final response =
                    await SpanMarginApi().fetchMargin(res.data.name);

                log("${singleTradeBook.tradeCategory} -> ${res.data.name} (${singleTradeBook.buySell}) : ${response.data.marginMargin} * ${singleTradeBook.quantity}  ");

                if (response.status) {
                  spanMargin = double.parse(singleTradeBook.price) *
                      double.parse(response.data.marginLotSize) *
                      double.parse(singleTradeBook.quantity);

                  print("now sM : $spanMargin");
                } else {
                  SnackBar snackBar =
                      SnackBar(content: Text("Failed to get Span Margin"));
                  ScaffoldMessenger.of(context).showSnackBar(snackBar);
                }
              } else {
                SnackBar snackBar =
                    SnackBar(content: Text("Failed to get Instrument Details"));
                ScaffoldMessenger.of(context).showSnackBar(snackBar);
              }
            });
          }

          setState(() {
            totalSpanMargin = totalSpanMargin + spanMargin;
            totalMarginUtilized = totalDeliveryMargin + totalSpanMargin / 4;
          });

          print("Total Span Margin : $totalSpanMargin");

          // ENDED CALCULATING SPAN + EXPOSURE MARGINS
        });
      }
    });

    await TradeBookApi.fetchTradeBook(userID).then((tradeBook) {
      print("Fetched Option $userID");
      if (tradeBook.status) {
        final trade = tradeBook.data;

        double optionPremium = 0.0;

        trade.forEach((singleTradeBook) async {
          // START CALCUATING OPTION PREMIUM MARGINS

          if (singleTradeBook.tradeCategory == "OPTION") {
            await FetchScripts()
                .fetchInstrumentData(singleTradeBook.scriptName)
                .then((iData) async {
              if (iData.status) {
                final spanMarginData =
                    await SpanMarginApi().fetchMargin(iData.data.name);

                if (spanMarginData.status) {
                  optionPremium =
                      double.parse(spanMarginData.data.marginLotSize) *
                          double.parse(singleTradeBook.price) *
                          double.parse(singleTradeBook.quantity);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content:
                          Text("Failed to fetched ${iData.data.name} data")));
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(
                        "Failed to fetched ${singleTradeBook.scriptName} data")));
              }
            });
          }

          setState(() {
            totalOptionPremium = totalOptionPremium + optionPremium;
            totalMarginUtilized =
                totalDeliveryMargin + totalSpanMargin / 4 + totalOptionPremium;
          });

          // ENDED CALCULATING OPTION PREMIUM MARGINS
        });
      }
    });

    // UPDATE THE DATA IN DATABASE

    var userData = jsonEncode({
      "delivery_margin": totalDeliveryMargin,
      "span": totalSpanMargin,
      "option_premium": totalOptionPremium,
      "balance_in_account": openingBalance - totalMarginUtilized
    });

    print(userData);

    final updateUser = await UserApi.updateUser(userID, userData);

    if (updateUser.status) {
      log("Account updated");
    } else {
      SnackBar snackBar = SnackBar(
          content: Text("Account is not updating, Please try again later"));
      return false;
    }
  }

  totalMargin() {
    print("Total Margin Utilized : $totalMarginUtilized");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Account Details"),
        centerTitle: true,
      ),
      body: SafeArea(
          child: FutureBuilder<UserModel>(
        future: _userModel,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            if (snapshot.data.status) {
              return Container(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: ListView(
                  physics: AlwaysScrollableScrollPhysics(),
                  children: [
                    Container(
                      margin: EdgeInsets.only(top: 20),
                      child: Row(
                        // mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          AccountDetails(
                            title: "Account Holder Name",
                            value: userName,
                          ),
                          Spacer(),
                          AccountDetails(
                            title: "Opening Balance",
                            value: nFormat.format(openingBalance),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: 30,
                    ),
                    Container(
                      margin: EdgeInsets.only(top: 20),
                      child: Row(
                        children: [
                          AccountDetails(
                            title: "Delivery Margin",
                            value: nFormat.format(totalDeliveryMargin),
                          ),
                          AccountDetails(
                            title: "Span + Exposure Margin",
                            value: nFormat.format(totalSpanMargin),
                          ),
                          AccountDetails(
                            title: "Option Premium",
                            value: nFormat.format(totalOptionPremium),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: 30,
                    ),
                    Container(
                      margin: EdgeInsets.only(top: 20),
                      child: Row(
                        children: [
                          AccountDetails(
                            title: "Total Margin Utilized",
                            value: nFormat.format(totalMarginUtilized),
                          ),
                          AccountDetails(
                            title: "Balance in Account",
                            value: nFormat
                                .format(openingBalance - totalMarginUtilized),
                          ),
                          AccountDetails(
                            title: "Withdrawable Balance",
                            value: nFormat
                                .format(openingBalance - totalMarginUtilized),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: 20,
                    ),
                    Divider(),
                    SizedBox(
                      height: 20,
                    ),
                    Container(
                      alignment: Alignment.center,
                      child: MaterialButton(
                        color: Colors.green,
                        elevation: 8,
                        onPressed: () {
                          TextEditingController _payOut =
                              TextEditingController();

                          showModalBottomSheet(
                            context: context,
                            builder: (context) {
                              return StatefulBuilder(
                                builder: (context, setState) {
                                  return Container(
                                    decoration: BoxDecoration(
                                        color: AppConfig.kDeepDarkColor),
                                    height: MediaQuery.of(context).size.height *
                                        0.6,
                                    child: Container(
                                      padding: EdgeInsets.all(10),
                                      child: Column(
                                        children: [
                                          CustomInput(
                                            textEditingController: _payOut,
                                            showLabel: true,
                                            showHint: false,
                                            labelText: "Money",
                                          ),
                                          SizedBox(
                                            height: 10,
                                          ),
                                          CustomTextButton(
                                            isLoading: false,
                                            onPressed: () async {
                                              var data = jsonEncode({
                                                "client_id": userID,
                                                "status": "0"
                                              });

                                              final res = await UserApi
                                                  .sendPayoutRequest(data);

                                              Navigator.pop(context);
                                            },
                                            title: "Send Request",
                                          )
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          );
                        },
                        child: Text(
                          "Request Pay Out",
                          style: GoogleFonts.poppins(color: Colors.white),
                        ),
                      ),
                    )
                  ],
                ),
              );
            } else {
              return Text("Something went wrong : ${userID}");
            }
          } else if (snapshot.hasError) {
            return Text("Something went wrong");
          } else {
            return Container(
              child: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }
        },
      )),
    );
  }
}

class AccountDetails extends StatelessWidget {
  final String title;
  final String value;

  const AccountDetails({
    Key key,
    this.title,
    this.value,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Expanded(
        child: Container(
      child: Column(
        children: [
          Text(
            "$title",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Text("$value")
        ],
      ),
    ));
  }
}
