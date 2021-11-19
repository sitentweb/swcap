import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socket_io_client/socket_io_client.dart';
import 'package:swcap/auth/login.dart';
import 'package:swcap/config/app_config.dart';
import 'package:swcap/notifier/theme_notifier.dart';
import 'package:swcap/notifier/tick_notifier.dart';
import 'package:swcap/pages/homepage.dart';

void main() {
  runApp(MultiProvider(
    providers: [ChangeNotifierProvider(create: (_) => TickNotifier())],
    child: MyApp(),
  ));
}

class MyApp extends StatefulWidget {
  // This widget is the root of your application.
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool userLogged = false;
  CustomTheme currentTheme = CustomTheme();
  Socket socket;
  int user;

  @override
  void initState() {
    currentTheme.addListener(() {
      setState(() {});
    });
    getUserData();
    super.initState();
  }

  getUserData() async {
    SharedPreferences pref = await SharedPreferences.getInstance();

    if (pref.get("isLogged") != null) {
      if (pref.getBool("isLogged")) {
        userLogged = true;

        socket = io('https://remarkablehr.in:8443', <String, dynamic>{
          'transports': ['websocket'],
          'autoConnect': false
        });

        socket.connect();

        user = Random().nextInt(10000);

        socket.emit('registerMeSwcap', {"user": user});

        socket.on('userconnected', (data) {
          print(data);
        });

        socket.onConnectTimeout((data) {
          print('Connection Time Out');
        });

        socket.onConnectError((data) {
          print("Connection Error");
          print(data);
        });

        socket.onDisconnect((data) {
          print("Connection Disconnected");
          print(data);
        });

        socket.onError((data) {
          print("Error");
          print(data);
        });
      } else {
        userLogged = false;
      }

      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Swing',
      theme: AppConfig.darkTheme,
      home: userLogged ? HomePage() : Login(),
      darkTheme: AppConfig.darkTheme,
      themeMode: currentTheme.currentTheme,
    );
  }
}
