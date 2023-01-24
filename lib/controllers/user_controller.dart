import 'dart:developer';

import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:swcap/api/kite_api.dart';
import 'package:swcap/api/user_api.dart';
import 'package:swcap/config/storage_constants.dart';
import 'package:swcap/model/user/user_model.dart' as UserData;

class UserController extends GetxController {
  RxBool isUserLoggedIn = false.obs;
  RxString userId = "0".obs;
  Rx<UserData.Data> user = UserData.Data().obs;
  GetStorage mind = GetStorage();
  RxList<int> watchListsToken = <int>[].obs;
  RxList watchListScripts = [].obs;

  init() {
    watchListScripts.clear();
    watchListsToken.clear();

    if (mind.read(IS_USER_LOGGED_IN) != null) {
      isUserLoggedIn.value = mind.read(IS_USER_LOGGED_IN);
      isUserLoggedIn.refresh();

      if (mind.read(User['ID']) != null) {
        userId(mind.read(User['ID']));
        userId.refresh();
      }
    }
  }

  getUser() async {
    await UserApi.fetchUser(userId.value).then((res) {
      if (res.status) {
        user.value = res.data;
        user.refresh();
      }
    });
  }

  fetchWatchLists() async {
    final response = await KiteApi.getWatchLists(user.value.id);

    if (response.status) {
      var scripts = [];

      response.data.forEach((element) {
        scripts.insert(0, {
          "script_id": element.watchlistId,
          "script_name": element.watchlistScriptName,
          "script_token": element.watchlistScriptToken,
          "script_category": element.watchlistScriptCategory
        });

        watchListsToken.add(int.parse(element.watchlistScriptToken));
      });

      watchListScripts.value = scripts;

      watchListScripts.refresh();
      watchListsToken.refresh();
    }
  }

  clearWatchList() {
    watchListScripts.clear();
    watchListsToken.clear();
  }
}
