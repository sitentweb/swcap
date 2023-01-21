import 'package:flutter/cupertino.dart';

class TickNotifier extends ChangeNotifier {
    String _lastPrice = "";
    String _lastOldPrice = "";
    String _lastOldToken = "";
    String _token = "";
    dynamic _tick = {};
    dynamic _oldTick = {};

    String get lastPrice => _lastPrice;
    String get token => _token;
    String get lastOldPrice => _lastOldPrice;
    String get lastOldToken => _lastOldToken;
    dynamic get tick => _tick;
    dynamic get oldTick => _oldTick;

    storeValue(lPrice , lToken) {
       _lastPrice = lPrice.toString();
       _token = lToken.toString();
    }

    storeTick(tick){
      _tick = tick;
    }

    storeOldTick(tick){
       _oldTick = tick;
    }

    storeOldValue(lPrice , lToken) {
      _lastOldPrice = lPrice;
      _lastOldToken = lToken;
    }

}