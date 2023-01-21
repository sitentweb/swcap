import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:swcap/config/storage_constants.dart';

class UserController extends GetxController {
  RxBool isUserLoggedIn = false.obs;
  GetStorage mind = GetStorage();

  init() {
    if (mind.read(IS_USER_LOGGED_IN) != null) {
      isUserLoggedIn = mind.read(IS_USER_LOGGED_IN);
      isUserLoggedIn.refresh();
    }
  }
}
