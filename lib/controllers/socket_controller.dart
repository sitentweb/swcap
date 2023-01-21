import 'package:get/get.dart';
import 'package:socket_io_client/socket_io_client.dart';

class SocketController extends GetxController {
  Socket socket;

  init() async {
    socket = await io('https://remarkhr.com:8443', <String, dynamic>{
      'transports': ['websocket', 'polling'],
    });

    socket.connect();

    socket.emit('registerMeSwcap', {'user': 1});

    socket.onConnect((data) => {print("Socket Connected")});

    socket.onConnectTimeout((data) => print("Connection Timeout"));
  }
}
