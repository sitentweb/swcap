import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart';

class CashMarket extends StatefulWidget {
  const CashMarket({ Key key }) : super(key: key);

  @override
  _CashMarketState createState() => _CashMarketState();
}

class _CashMarketState extends State<CashMarket> {

  Socket socket;

  @override
  void initState() {
    // TODO: implement initState
    _socketSetup();
    super.initState();
  }

  _socketSetup() async {

    socket = io('https://remarkablehr.in:8443' , <String, dynamic>{
        'transports' : ['websocket'],
        'autoConnect' : false
    });

    await socket.connect();

    print(socket.json.opts);
    print(socket.connected);

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
      body: SafeArea(
        child: Center(
          child: Container(
            child: MaterialButton(
              onPressed: _socketSetup,
              child: Text('Connect to Socket' , style: TextStyle(
                color: Colors.white
              ),),
              color: Colors.blueAccent,
            ),
          ),
        ),
      ),
    );
  }
}