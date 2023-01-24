import 'package:get_storage/get_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:swcap/config/storage_constants.dart';
import 'package:swcap/model/user/user_model.dart';

class UserConfig {
  static setUserSession(UserModel user) async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    GetStorage mind = GetStorage();

    // STORED IN SHARED PREFERENCE
    pref.setBool("isLogged", true);
    pref.setString("userID", user.data.id ?? "");
    pref.setString("userName", user.data.name ?? "");
    pref.setString("userUserName", user.data.username);
    pref.setString("userPassword", user.data.password);
    pref.setString("userMobile", user.data.mobileNumber);
    pref.setString("userShowAccount", user.data.showAccount);

    // STORED IN GET STORAGE
    mind.write(IS_USER_LOGGED_IN, true);
    mind.write(USER_ID, user.data.id ?? "");
    mind.write(USER_NAME, user.data.name);
    mind.write(USER_USERNAME, user.data.username);
    mind.write(USER_MOBILE, user.data.mobileNumber);
    mind.write(USER_SHOW_ACCOUNT, user.data.showAccount);
  }

  static unsetUserSession() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    pref.setBool("isLogged", false);
    pref.remove("userID");
    pref.remove("userName");
    pref.remove("userUserName");
    pref.remove("UserPassword");
    pref.remove("userMobile");
    pref.remove("userShowAccount");
  }
}
