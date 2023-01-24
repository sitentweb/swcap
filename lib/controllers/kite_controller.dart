import 'dart:async';
import 'dart:developer';

import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:swcap/api/kite_connect_api.dart';
import 'package:swcap/config/storage_constants.dart';

class KiteController extends GetxController {
  Rx<StreamController<List>> streamController = StreamController<List>().obs;
  RxString apiKey = "".obs;
  RxString accessToken = "".obs;
  GetStorage mind = GetStorage();

  init() async {
    await fetchApis();
  }

  fetchApis() async {
    final res = await KiteConnectApi.getKiteApi();

    if (res.status) {
      apiKey.value = res.data.apiKey;
      accessToken.value = res.data.accessToken;

      mind.write(Kite['API_KEY'], apiKey.value);
      mind.write(Kite['ACCESS_TOKEN'], accessToken.value);
    } else {
      print("KITE API NOT FOUND");
    }
  }

  addForStream(List listOfScripts) {
    log(listOfScripts.toString(), name: "WatchLists");
    streamController.value.add(listOfScripts);
    streamController.refresh();
  }

  stopStream() {
    streamController.value.close();
    streamController.refresh();
  }
}
