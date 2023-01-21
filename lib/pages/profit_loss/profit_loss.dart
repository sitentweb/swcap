import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:swcap/api/profit_loss_api.dart';
import 'package:swcap/api/trade_book_api.dart';
import 'package:swcap/model/profit_loss/profit_loss_model.dart';
import 'package:swcap/model/trade_book/trade_book_model.dart';

class ProfitLoss extends StatefulWidget {
  const ProfitLoss({ Key key }) : super(key: key);

  @override
  _ProfitLossState createState() => _ProfitLossState();
}

class _ProfitLossState extends State<ProfitLoss> {

  Future<ProfitLossModel> _profitLossModel;
  String userID;

  @override
  void initState() {
    // TODO: implement initState
    // calcTrade();
    getUserData();
    super.initState();
  }

  getUserData() async {

    SharedPreferences pref = await SharedPreferences.getInstance();

    setState(() {
      userID = pref.getString("userID");
    });

    _profitLossModel = ProfitLossApi().getProfitLoss(userID);

  }


  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        title: Text("Profit & Loss"),
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
                  child: Text("Buy Quantity" , style: TextStyle(
                    color: Colors.white
                  ),),
                ),
                Container(
                  width: 80,
                  child: Text("Buy Value" , style: TextStyle(
                    color: Colors.white
                  ),),
                ),
                Container(
                  width: 80,
                  child: Text("Buy Average" , style: TextStyle(
                    color: Colors.white
                  ),),
                ),
                Container(
                  width: 80,
                  child: Text("Sell Quantity" , style: TextStyle(
                    color: Colors.white
                  ),),
                ),
                Container(
                  width: 80,
                  child: Text("Sell Value" , style: TextStyle(
                    color: Colors.white
                  ),),
                ),
                Container(
                  width: 80,
                  child: Text("Sell Average" , style: TextStyle(
                    color: Colors.white
                  ),),
                ),
                Container(
                  width: 120,
                  child: Text("Balance Quantity" , style: TextStyle(
                    color: Colors.white
                  ),),
                ),
                Container(
                  width: 80,
                  child: Text("Realized Profit" , style: TextStyle(
                    color: Colors.white
                  ),),
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
                                child: Text("${data.buyQuantity}"),
                              ),
                              Container(
                                width: 80,
                                child: Text("${data.buyValue}"),
                              ),
                              Container(
                                width: 80,
                                child: Text("${data.buyAverage != null ? double.parse(data.buyAverage.toString()).toStringAsFixed(2).toString() : 0}"),
                              ),
                              Container(
                                width: 80,
                                child: Text("${data.sellQuantity}"),
                              ),
                              Container(
                                width: 80,
                                child: Text("${data.sellValue}"),
                              ),
                              Container(
                                width: 80,
                                child: Text("${data.sellAverage != null ? double.parse(data.sellAverage.toString()).toStringAsFixed(2).toString() : 0}"),
                              ),
                              Container(
                                width: 120,
                                child: Text("${data.balanceQuantity}"),
                              ),
                              Container(
                                width: 80,
                                child: Text("${data.realizedProfit}"),
                              ),
                            ],
                          ),
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