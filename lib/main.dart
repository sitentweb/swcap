import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socket_io_client/socket_io_client.dart';
import 'package:swcap/auth/login.dart';
import 'package:swcap/config/app_config.dart';
import 'package:swcap/config/order_config.dart';
import 'package:swcap/controllers/app_controller.dart';
import 'package:swcap/controllers/socket_controller.dart';
import 'package:swcap/controllers/user_controller.dart';
import 'package:swcap/notifier/theme_notifier.dart';
import 'package:swcap/notifier/tick_notifier.dart';
import 'package:swcap/pages/homepage.dart';
import 'package:swcap/pages/trade_book/trade_book.dart';

void main() async {
  await GetStorage.init();
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
  AppController appController = Get.put(AppController());
  UserController userController = UserController();
  SocketController socketController = SocketController();
  CustomTheme currentTheme = CustomTheme();
  int user;

  @override
  void initState() {
    currentTheme.addListener(() {
      setState(() {});
    });
    getUserData();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.initState();
  }

  getUserData() async {
    await userController.init();

    if (userController.isUserLoggedIn.isTrue) {
      await socketController.init();
      await socketController.registerUser(userController.user.value.id);
    }

    return CallbackShortcuts(
      bindings: {SingleActivator(LogicalKeyboardKey.keyT): _handleResetPressed},
      child: Focus(
        autofocus: true,
        child: TradeBook(),
      ),
    );
  }

  _handleResetPressed() {}

  @override
  void dispose() {
    // TODO: implement dispose
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Swing',
      theme: AppConfig.darkTheme,
      home: userController.isUserLoggedIn.isTrue ? HomePage() : Login(),
      darkTheme: AppConfig.darkTheme,
      themeMode: currentTheme.currentTheme,
    );
  }
}
