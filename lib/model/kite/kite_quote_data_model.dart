// To parse this JSON data, do
//
//     final kiteQuoteDataModel = kiteQuoteDataModelFromJson(jsonString);

import 'dart:convert';

KiteQuoteDataModel kiteQuoteDataModelFromJson(String str) =>
    KiteQuoteDataModel.fromJson(json.decode(str));

String kiteQuoteDataModelToJson(KiteQuoteDataModel data) =>
    json.encode(data.toJson());

class KiteQuoteDataModel {
  KiteQuoteDataModel({
    this.tradable,
    this.mode,
    this.instrumentToken,
    this.lastPrice,
    this.lastQuantity,
    this.averagePrice,
    this.volume,
    this.buyQuantity,
    this.sellQuantity,
    this.ohlc,
    this.change,
    this.lastTradeTime,
    this.timestamp,
    this.oi,
    this.oiDayHigh,
    this.oiDayLow,
    this.depth,
  });

  String tradable;
  String mode;
  String instrumentToken;
  String lastPrice;
  String lastQuantity;
  String averagePrice;
  String volume;
  String buyQuantity;
  String sellQuantity;
  Ohlc ohlc;
  String change;
  DateTime lastTradeTime;
  DateTime timestamp;
  String oi;
  String oiDayHigh;
  String oiDayLow;
  Depth depth;

  factory KiteQuoteDataModel.fromJson(Map<String, dynamic> json) =>
      KiteQuoteDataModel(
        tradable: json["tradable"].toString(),
        mode: json["mode"].toString(),
        instrumentToken: json["instrument_token"].toString(),
        lastPrice: json["last_price"].toString(),
        lastQuantity: json["last_quantity"].toString(),
        averagePrice: json["average_price"].toString(),
        volume: json["volume"].toString(),
        buyQuantity: json["buy_quantity"].toString(),
        sellQuantity: json["sell_quantity"].toString(),
        ohlc: Ohlc.fromJson(json["ohlc"]),
        change: json["change"].toString(),
        lastTradeTime: DateTime.parse(json["last_trade_time"]),
        timestamp: DateTime.parse(json["timestamp"]),
        oi: json["oi"].toString(),
        oiDayHigh: json["oi_day_high"].toString(),
        oiDayLow: json["oi_day_low"].toString(),
        depth: Depth.fromJson(json["depth"]),
      );

  Map<String, dynamic> toJson() => {
        "tradable": tradable,
        "mode": mode,
        "instrument_token": instrumentToken,
        "last_price": lastPrice,
        "last_quantity": lastQuantity,
        "average_price": averagePrice,
        "volume": volume,
        "buy_quantity": buyQuantity,
        "sell_quantity": sellQuantity,
        "ohlc": ohlc.toJson(),
        "change": change,
        "last_trade_time": lastTradeTime.toIso8601String(),
        "timestamp": timestamp.toIso8601String(),
        "oi": oi,
        "oi_day_high": oiDayHigh,
        "oi_day_low": oiDayLow,
        "depth": depth.toJson(),
      };
}

class Depth {
  Depth({
    this.buy,
    this.sell,
  });

  List<Buy> buy;
  List<Buy> sell;

  factory Depth.fromJson(Map<String, dynamic> json) => Depth(
        buy: List<Buy>.from(json["buy"].map((x) => Buy.fromJson(x))),
        sell: List<Buy>.from(json["sell"].map((x) => Buy.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "buy": List<dynamic>.from(buy.map((x) => x.toJson())),
        "sell": List<dynamic>.from(sell.map((x) => x.toJson())),
      };
}

class Buy {
  Buy({
    this.quantity,
    this.price,
    this.orders,
  });

  String quantity;
  String price;
  String orders;

  factory Buy.fromJson(Map<String, dynamic> json) => Buy(
        quantity: json["quantity"].toString(),
        price: json["price"].toString(),
        orders: json["orders"].toString(),
      );

  Map<String, dynamic> toJson() => {
        "quantity": quantity,
        "price": price,
        "orders": orders,
      };
}

class Ohlc {
  Ohlc({
    this.open,
    this.high,
    this.low,
    this.close,
  });

  String open;
  String high;
  String low;
  String close;

  factory Ohlc.fromJson(Map<String, dynamic> json) => Ohlc(
        open: json["open"].toString(),
        high: json["high"].toString(),
        low: json["low"].toString(),
        close: json["close"].toString(),
      );

  Map<String, dynamic> toJson() => {
        "open": open,
        "high": high,
        "low": low,
        "close": close,
      };
}
