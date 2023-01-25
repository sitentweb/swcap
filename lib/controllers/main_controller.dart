import 'dart:developer';

import 'package:get/get.dart';
import 'package:swcap/controllers/kite_controller.dart';
import 'package:swcap/controllers/socket_controller.dart';
import 'package:swcap/controllers/user_controller.dart';

class MainController extends GetxController {
  // CALLING ALL THE CONTROLLERS HERE
  UserController userController = Get.put(UserController());
  KiteController kiteController = Get.put(KiteController());
  SocketController socketController = Get.put(SocketController());
  RxList watchListData = [].obs;

  init() {
    userController.init();
    socketController.init();
    kiteController.init();
  }

  startEngine() async {
    // await userController.init();
    await userController.getUser();
    await userController.fetchWatchLists();

    if (socketController.isSocketConnected.isTrue) {
      // await socketController.init();
      await socketController.registerUser(userController.user.value.id);

      // await kiteController.init();
      await socketController.sendKiteApi(
          kiteController.apiKey.value, kiteController.accessToken.value);

      await socketController
          .sendKiteSubscription(userController.watchListsToken);

      await kiteController.addForStream(userController.watchListScripts);

      await createWatchlistData();

      // UPDATE WATCH LIST EVERY SECOND;
      await updateWatchList();
    } else {
      print('Socket not connected');
    }
  }

  createWatchlistData() async {
    watchListData.insert(0, {
      "ID": "0",
      "SCRIPT_NAME": "Symbol",
      "CURRENT_PRICE": "Last Price",
      "BUY_QUANTITY": "Buy Qty",
      "BUY_PRICE": "Buy Price",
      " ": ' ',
      "SELL_PRICE": "Sell Price",
      "SELL_QUANTITY": "Sell Qty"
    });

    userController.watchListScripts.forEach((script) {
      watchListData.add({
        "ID": script['script_id'],
        "SCRIPT_NAME": script['script_name'],
        "SCRIPT_TOKEN": script['script_token'],
        "SCRIPT_CATEGORY": script['script_category'],
        "CURRENT_PRICE": 0,
        "BUY_QUANTITY": 0,
        "BUY_PRICE": 0,
        "BUY_QUANTITY_COLOR": "T",
        "OLD_BUY_QUANTITY": 0,
        "SELL_QUANTITY": 0,
        "SELL_PRICE": 0,
        "SELL_QUANTITY_COLOR": "T",
        "OLD_SELL_QUANTITY": 0,
        "OLD_PRICE": 0,
        "COLOR": "T", // COLORS: T = TRANSPARENT, R = RED, G = GREEN
        "DIFFERENCE": 0,
        "VOLUME_TRADE": 0,
        "OPEN": 0,
        "CLOSE": 0,
        "HIGH": 0,
        "LOW": 0,
        "AVERAGE_TRADE_PRICE": 0
      });
    });
  }

  updateWatchList() async {
    socketController.socket.on('receiveticks', (data) {
      print(data);
      data['tick'].forEach((tick) {
        watchListData.forEach((watchlist) {
          if (watchlist['ID'] != "0") {
            if (int.parse(tick['instrument_token'].toString()) ==
                int.parse(watchlist['SCRIPT_TOKEN'].toString())) {
              // GET THE CURRENT PRICE
              watchlist['CURRENT_PRICE'] = tick['last_price'];

              // GET THE DIFFERENCE
              watchlist['DIFFERENCE'] =
                  (double.parse(tick['last_price'].toString()) -
                          double.parse(watchlist['OLD_PRICE'].toString()))
                      .toStringAsFixed(2);

              if (double.parse(watchlist['DIFFERENCE'].toString()) > 0) {
                watchlist['COLOR'] = 'G';
              }

              if (double.parse(watchlist['DIFFERENCE'].toString()) < 0) {
                watchlist['COLOR'] = 'R';
              }

              if (double.parse(watchlist['DIFFERENCE'].toString()) == 0.0) {
                watchlist['COLOR'] = 'T';
              }

              // SET THE VOLUME TRADE
              watchlist['VOLUME_TRADE'] = tick['volume_traded'];

              // SET THE OPEN PRICE
              watchlist['OPEN'] = tick['ohlc']['open'];

              // SET THE CLOSE PRICE
              watchlist['CLOSE'] = tick['ohlc']['close'];

              // SET THE HIGH PRICE
              watchlist['HIGH'] = tick['ohlc']['high'];

              // SET THE LOW PRICE
              watchlist['LOW'] = tick['ohlc']['low'];

              // SET THE OLD PRICE
              watchlist['OLD_PRICE'] = tick['last_price'];

              // SET THE BUY QUANTITY
              watchlist['BUY_QUANTITY'] = tick['depth']['buy'][0]['quantity'];

              watchlist['BUY_PRICE'] = tick['depth']['buy'][0]['price'];

              // SETTING THE BUY QUANTITY COLOR
              if (double.parse(tick['total_buy_quantity'].toString()) >
                  double.parse(watchlist['OLD_BUY_QUANTITY'].toString())) {
                watchlist['BUY_QUANTITY_COLOR'] = 'G';
              }

              if (double.parse(tick['total_buy_quantity'].toString()) <
                  double.parse(watchlist['OLD_BUY_QUANTITY'].toString())) {
                watchlist['BUY_QUANTITY_COLOR'] = 'R';
              }

              if (double.parse(tick['total_buy_quantity'].toString()) ==
                  double.parse(watchlist['OLD_BUY_QUANTITY'].toString())) {
                watchlist['BUY_QUANTITY_COLOR'] = 'T';
              }

              // SET THE OLD BUY QUANTITY
              watchlist['OLD_BUY_QUANTITY'] =
                  tick['depth']['buy'][0]['quantity'];

              // SELL QUANTITY
              // SET THE SELL QUANTITY
              watchlist['SELL_QUANTITY'] = tick['depth']['sell'][0]['quantity'];

              watchlist['SELL_PRICE'] = tick['depth']['sell'][0]['price'];

              // SETTING THE SELL QUANTITY COLOR
              if (double.parse(tick['total_sell_quantity'].toString()) >
                  double.parse(watchlist['OLD_SELL_QUANTITY'].toString())) {
                watchlist['SELL_QUANTITY_COLOR'] = 'G';
              }

              if (double.parse(tick['total_sell_quantity'].toString()) <
                  double.parse(watchlist['OLD_SELL_QUANTITY'].toString())) {
                watchlist['SELL_QUANTITY_COLOR'] = 'R';
              }

              if (double.parse(tick['total_sell_quantity'].toString()) ==
                  double.parse(watchlist['OLD_SELL_QUANTITY'].toString())) {
                watchlist['SELL_QUANTITY_COLOR'] = 'T';
              }

              // SET THE OLD BUY QUANTITY
              watchlist['OLD_SELL_QUANTITY'] =
                  tick['depth']['sell'][0]['quantity'];
            } else {
              print('${watchlist["SCRIPT_NAME"]} is not updated');
            }
          }
        });
      });

      watchListData.refresh();
    });
  }

  closeEngine() async {
    watchListData.clear();
    // socketController.closeConnection();
    userController.clearWatchList();
    // kiteController.stopStream();
  }

  restartEngine() async {
    closeEngine();
    await init();
    await startEngine();
  }
}
