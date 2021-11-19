import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:swcap/api/span_margin_api.dart';
import 'package:swcap/api/trade_book_api.dart';
import 'package:swcap/api/user_api.dart';
import 'package:swcap/components/buttons/text_button.dart';
import 'package:swcap/components/inputs/custom_input.dart';
import 'package:swcap/config/app_config.dart';
import 'package:swcap/model/margin/span_margin_model.dart';
import 'package:swcap/model/user/user_model.dart';
import 'package:swcap/pages/trade_book/trade_book.dart';
import 'package:intl/intl.dart';

class Account extends StatefulWidget {
  const Account({Key key}) : super(key: key);

  @override
  _AccountState createState() => _AccountState();
}

class _AccountState extends State<Account> {

  String userID = "";
  UserModel user = UserModel(status: false);
  List deliveryMargins = [];
  double openingBalance = 1000000;
  double totalDeliveryMargin = 0.0;
  double totalSpanMargin = 0.0;
  double totalOptionPremium = 0.0;
  double totalMarginUtilized = 0.0;
  var nFormat = NumberFormat.currency(locale: "HI" , name: "INDIAN" , symbol: "Rs. " );
  List<Datum> listSpanMargins = <Datum>[];

  @override
  void initState() {
    // TODO: implement initState
    getUserData();
    super.initState();
  }

  getUserData() async {

    SharedPreferences pref = await SharedPreferences.getInstance();

    setState(() {
       userID = pref.getString("userID");
    });

    await UserApi.fetchUser(userID).then((value) {
      if(value.status){
        user = value;
        setState(() {
          openingBalance = double.parse(user.data.openingBalance);
        });
      }
    });


    await TradeBookApi.fetchTradeBook(userID).then((tradeBook) {
        if(tradeBook.status){




          final trade = tradeBook.data;




          trade.forEach((singleTradeBook) {



          // START CALCULATING DELIVERY MARGIN


            if(singleTradeBook.tradeCategory == "CASH"){
              print(singleTradeBook);
            double deliveryMargin = double.parse(singleTradeBook.price) * double.parse(singleTradeBook.quantity);
            // print();

            setState(() {
              totalDeliveryMargin = totalDeliveryMargin + deliveryMargin;
            });
            }

          // ENDED CALCULATIN DELIVERY MARGINS

          });

        }
    });


    await SpanMarginApi().fetchSpanMargin().then((spanMargin) {

      if(spanMargin.status){

        setState(() {
          listSpanMargins = spanMargin.data;
        });

      }else{
        print("Span Margin got failed");
      }

    });




 await TradeBookApi.fetchTradeBook(userID).then((tradeBook) {
        if(tradeBook.status){




          final trade = tradeBook.data;


trade.forEach((singleTradeBook) {
            
             // START CALCUATING SPAN + EXPOSURE MARGINS

            double spanMargin = 0.0;
            if(singleTradeBook.tradeCategory == "Future"){
                listSpanMargins.forEach((span) {
                  if(span.marginScriptSymbols == singleTradeBook.scriptName){
                    print(singleTradeBook.price);
                    print(singleTradeBook.quantity);
                    print(span.marginMargin);
                    spanMargin = double.parse(singleTradeBook.price) * double.parse(singleTradeBook.quantity) * double.parse(span.marginMargin);
                  }
                });
            }

            setState(() {
              totalSpanMargin = totalSpanMargin + spanMargin;
            });

          // ENDED CALCULATING SPAN + EXPOSURE MARGINS
          });


        }
    });


      await TradeBookApi.fetchTradeBook(userID).then((tradeBook) {
        if(tradeBook.status){

        final trade = tradeBook.data;

        trade.forEach((singleTradeBook) {
            
             // START CALCUATING OPTION PREMIUM MARGINS

            double optionPremium = 0.0;
            if(singleTradeBook.tradeCategory == "Option"){
                
              optionPremium = double.parse(singleTradeBook.price) * double.parse(singleTradeBook.quantity);

            }

            setState(() {
              totalOptionPremium = totalOptionPremium + optionPremium;
            });

          // ENDED CALCULATING OPTION PREMIUM MARGINS
          });


        }
    });


    totalMarginUtilized = totalSpanMargin + totalDeliveryMargin + totalOptionPremium;

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
          future: UserApi.fetchUser(userID),
          builder: (context, snapshot) {
            if(snapshot.hasData){
              if(snapshot.data.status){
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
                            AccountDetails(title: "Account Holder Name", value: "Abhishek Sharma", ),
                            Spacer(),
                            AccountDetails(title: "Opening Balance", value: nFormat.format(openingBalance) , ),                            
                          ],
                        ),
                      ),
                      SizedBox(height: 30,),
                      Container(
                        margin: EdgeInsets.only(top: 20),
                        child: Row(
                          children: [
                            AccountDetails(title: "Delivery Margin", value: nFormat.format(totalDeliveryMargin), ),
                            AccountDetails(title: "Span + Exposure Margin", value: nFormat.format(totalSpanMargin), ),
                            AccountDetails(title: "Option Premium", value: nFormat.format(totalOptionPremium), ),
                          ],
                        ),
                      ),
                      SizedBox(height: 30,),
                      Container(
                        margin: EdgeInsets.only(top: 20),
                        child: Row(
                          children: [
                            AccountDetails(title: "Total Margin Utilized", value: nFormat.format(totalMarginUtilized), ),
                            AccountDetails(title: "Balance in Account", value: nFormat.format(openingBalance - totalMarginUtilized), ),
                            AccountDetails(title: "Withdrawable Balance", value: nFormat.format(openingBalance - totalMarginUtilized), ),
                          ],
                        ),
                      ),
                      SizedBox(height: 20,),
                      Divider(),
                      SizedBox(height: 20,),

                      Container(
                        alignment: Alignment.center,
                        child: MaterialButton(
                          color: Colors.green,
                          elevation: 8,
                          onPressed: () {
                            TextEditingController _payOut = TextEditingController();
                      
                            showModalBottomSheet(
                                context: context,
                                builder: (context) {
                                  return StatefulBuilder(builder: (context, setState) {
                                    return Container(
                                      decoration: BoxDecoration(
                                        color: AppConfig.kDeepDarkColor
                                      ),
                                      height: MediaQuery.of(context).size.height * 0.6,
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
                                                  "client_id" : userID,
                                                  "status" : "0"
                                                });
                      
                                                final res = await UserApi.sendPayoutRequest(data);
                      
                                                Navigator.pop(context);
                                              },
                                              title: "Send Request",
                                            )
                                          ],
                                        ),
                                      ),
                                    );
                                  },);
                                },
                            );
                          },
                          child: Text("Request Pay Out" , style: GoogleFonts.poppins(
                            color: Colors.white
                          ),),
                        ),
                      )
                    ],
                  ),
                );
              }else{
                return Text("Something went wrong : ${userID}");
              }
            }else if(snapshot.hasError){
              return Text("Something went wrong");
            }else{
              return Container(
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }
          },
        )
      ),
    );
  }
}

class AccountDetails extends StatelessWidget {

  final String title;
  final String value;

  const AccountDetails({
    Key key, this.title, this.value,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Expanded(child: Container(
      child: Column(
        children: [
        Text("$title" , style: TextStyle(
          fontWeight: FontWeight.bold
        ),),
        Text("$value")
      ],),
    ));
  }
}
