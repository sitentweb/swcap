import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socket_io_client/socket_io_client.dart';
import 'package:swcap/api/kite_api.dart';
import 'package:swcap/api/order_book_api.dart';
import 'package:swcap/api/trade_book_api.dart';
import 'package:swcap/model/kite/kite_quote_data_model.dart';
import 'package:swcap/model/order_book/fetch_order_book.dart';

class OrderConfig {
  // Initialize the socket
  Socket socket;

  // Setup the socket here
  _socketSetup() async {
    socket = io('https://remarkhr.com:8443', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false
    });

    socket.connect();
  }

  getInstrumentTokens(String scriptName, String scriptType) async {
    String sType = "";

    int instrumentToken = 0;

    if (scriptType == "CASH") {
      sType = "NSE";
    } else if (scriptType == "OPTION" || scriptType == "FUTURE") {
      sType = "NFO";
    }

    try {
      final response = await KiteApi.getScriptData(scriptName, sType);

      if (response.status) {
        instrumentToken = response.data.instrumentToken;
      } else {
        return {"status": false, "msg": "Failed to get script data"};
      }
    } catch (e) {
      return {"status": false, "msg": e.toString()};
    }

    return {
      "status": true,
      "msg": "Instrument Token got",
      "data": instrumentToken
    };
  }

  _fetchAndSubscribeOrders() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    String userID = pref.getString("userID");
    final order = await OrderBookApi.fetchOrderBook(userID);

    if (order.status) {
      List<int> subsToken = [];

      try {
        order.data.forEach((trade) async {
          final scriptData =
              await getInstrumentTokens(trade.scriptName, trade.tradeCategory);

          if (scriptData['status']) {
            int iToken = scriptData['data'];

            print(iToken);
            subsToken.add(iToken);

            print(subsToken);
            socket.emit('subscribe', {
              "token": [iToken]
            });
          } else {
            return {"status": false, "msg": "Failed to get Token"};
          }
        });
      } catch (e) {
        print(e);
      }

      return {
        "status": true,
        "msg": "Orders fetched successfully",
        "data": order.data
      };
    } else {
      return {"status": false, "msg": "Orders not fetching"};
    }
  }

  executeOrder(BuildContext context) async {
    // CALL THE SETUP OF SOCKET
    _socketSetup();

    // GET ALL THE ORDERS OF THE USER
    // JUST WAIT FOR SUBSCRIPTION OF ORDER BOOK TOKENS

    final orders = await _fetchAndSubscribeOrders();

    if (orders['status']) {
      List<Datum> allOrders = orders['data'];

      allOrders.forEach((order) async {
        String iToken;

        // GET INSTRUMENT TOKEN FOR EACH SCRIPTS
        dynamic scriptData =
            await getInstrumentTokens(order.scriptName, order.tradeCategory);

        if (scriptData['status']) {
          iToken = scriptData['data'].toString();
        }

        // RECEIVING THE TICKS FROM SOCKET
        socket.on('receiveticks', (ticks) {
          ticks['tick'].forEach((tick) {
            // MATCH THE SCRIPTS WITH TOKEN

            print(tick);

            KiteQuoteDataModel kiteQuoteDataModel =
                kiteQuoteDataModelFromJson(jsonEncode(tick));

            if (kiteQuoteDataModel.toString().isNotEmpty) {
              if (kiteQuoteDataModel.instrumentToken == iToken) {
                String executedOrder = "";

                //  IF THE ORDER IS BUY

                if (order.buySell == "Buy") {
                  if (double.parse(kiteQuoteDataModel.lastPrice) <=
                      double.parse(order.price)) {
                    executedOrder = "Buy";
                    shiftOrderToTradeBook(order.tradeBookId, order.scriptName,
                        kiteQuoteDataModel.lastPrice, context);
                  }
                }

                // IF THE ORDER IS SELL
                if (order.buySell == "Sell") {
                  if (double.parse(kiteQuoteDataModel.lastPrice) >=
                      double.parse(order.price)) {
                    executedOrder = "Sell";
                    shiftOrderToTradeBook(order.tradeBookId, order.scriptName,
                        kiteQuoteDataModel.lastPrice, context);
                  }
                }
              }
            } else {
              print("Empty");
            }
          });
        });
      });
    }
  }

  shiftOrderToTradeBook(tradeID, scriptName, lastPrice, context) async {
    // Update the executed trade in TradeBook
    // Where Order = 0 & Trade = 1

    // Get the response in response variable
    final response = await TradeBookApi.updateTradeBook(
        tradeID, jsonEncode({"trade_in": '1'}));

    // Initialize the SnackBar
    SnackBar snackBar;

    // Check if the status of the response is true or false
    if (response.status) {
      // Set the snackBar custom message
      snackBar = SnackBar(
        content: Text("$scriptName is executed at $lastPrice"),
      );
    } else {
      // Set the snackBar custom message
      snackBar = SnackBar(content: Text("Something went wrong in $scriptName"));
    }

    // ScaffoldMessenger.of(context).showSnackBar(snackBar);
    print("Order Executed");
  }

  updateAccountMargin(userID, scriptName, ScriptCategory) async {
    //  UPDATE ACCOUNTS MARGIN PRICES
  }
}
