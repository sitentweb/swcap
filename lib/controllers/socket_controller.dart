import 'dart:developer';

import 'package:get/get.dart';
import 'package:socket_io_client/socket_io_client.dart';
import 'package:swcap/api/kite_connect_api.dart';

class SocketController extends GetxController {
  Socket socket;
  RxBool isSocketConnected = false.obs;

  init() async {
    socket = await io('https://remarkhr.com:8443', <String, dynamic>{
      'transports': ['websocket', 'polling'],
    });

    socket.connect();

    socket.onConnect((data) {
      isSocketConnected(true);
      log("Socket Server Connected", name: 'SOCKET CONNECTION');
    });
  }

  registerUser(userID) {
    socket.emit('registerMeSwcap', {'user': userID});

    socket.onConnectTimeout((data) {
      print("Connection Timeout");
      init();
    });
  }

  sendKiteApi(apiKey, accessToken) async {
    socket.emit('kiteApi', {"apiKey": apiKey, "accessToken": accessToken});
  }

  sendKiteSubscription(subscriptionsList) {
    socket.on('apiReceived', (data) {
      socket.emit('subscribe', {"token": subscriptionsList});
    });
  }

  getTicksofKite() {
    socket.on('receiveticks', (data) {
      return data;
    });
  }

  closeConnection() {
    socket.disconnect();
    socket.close();
  }
}
