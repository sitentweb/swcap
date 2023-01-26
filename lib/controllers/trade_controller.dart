import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';

class TradeController extends GetxController {
  RxString stockName = "".obs;
  RxString stockToken = "".obs;
  RxString stockCategory = "".obs;
  Rx<TextEditingController> instrumentController = TextEditingController().obs;
  Rx<TextEditingController> quantityController = TextEditingController().obs;

  init() {
    quantityController.value.text = "0";
  }
}
