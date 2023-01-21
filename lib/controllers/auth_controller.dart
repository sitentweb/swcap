import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:swcap/api/auth_api.dart';
import 'package:swcap/api/user_api.dart';
import 'package:swcap/config/storage_constants.dart';
import 'package:swcap/config/user_config.dart';
import 'package:swcap/pages/homepage.dart';

class AuthController extends GetxController {
  RxBool isUserLoggedIn = false.obs;
  RxBool isLoggingIn = false.obs;
  RxBool isErrorLogin = false.obs;
  RxString loginError = "".obs;
  Rx<TextEditingController> usernameController = TextEditingController().obs;
  Rx<TextEditingController> passwordController = TextEditingController().obs;
  GetStorage mind = GetStorage();

  init() {
    if (mind.read(IS_USER_LOGGED_IN)) {
      isUserLoggedIn = mind.read(IS_USER_LOGGED_IN);
    }
  }

  doLogin() async {
    if (usernameController.value.text.isEmpty ||
        passwordController.value.text.isEmpty) {
    } else {
      isErrorLogin(false);
      loginError("");
      isLoggingIn(true);

      final response = await AuthApi.userLogin(
          usernameController.value.text, passwordController.value.text);
      print(response.status);
      if (response.status) {
        if (response.data.isLoggedin == "0") {
          await UserApi.updateUser(
              response.data.id, jsonEncode({"is_loggedin": 1}));

          UserConfig.setUserSession(response);

          Get.to(() => HomePage(), transition: Transition.circularReveal);
        } else {
          loginError("You are not authorized to use this credentials");
          isErrorLogin(true);
        }
      } else {
        print(response.data);
        loginError("Invalid Credentials");
        isErrorLogin(true);
      }

      isLoggingIn(false);
    }
  }
}
