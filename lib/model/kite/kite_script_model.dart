// To parse this JSON data, do
//
//     final kiteScriptDataModel = kiteScriptDataModelFromJson(jsonString);

import 'dart:convert';

KiteScriptDataModel kiteScriptDataModelFromJson(String str) => KiteScriptDataModel.fromJson(json.decode(str));

String kiteScriptDataModelToJson(KiteScriptDataModel data) => json.encode(data.toJson());

class KiteScriptDataModel {
    KiteScriptDataModel({
        this.status,
        this.data,
    });

    bool status;
    Data data;

    factory KiteScriptDataModel.fromJson(Map<String, dynamic> json) => KiteScriptDataModel(
        status: json["status"],
        data: Data.fromJson(json["data"]),
    );

    Map<String, dynamic> toJson() => {
        "status": status,
        "data": data.toJson(),
    };
}

class Data {
    Data({
        this.instrumentToken,
        this.timestamp,
        this.lastTradeTime,
        this.lastPrice,
        this.lastQuantity,
        this.buyQuantity,
        this.sellQuantity,
        this.volume,
        this.averagePrice,
        this.oi,
        this.oiDayHigh,
        this.oiDayLow,
        this.netChange,
        this.lowerCircuitLimit,
        this.upperCircuitLimit,
        this.ohlc,
        this.depth,
    });

    int instrumentToken;
    LastTradeTime timestamp;
    LastTradeTime lastTradeTime;
    dynamic lastPrice;
    dynamic lastQuantity;
    dynamic buyQuantity;
    dynamic sellQuantity;
    dynamic volume;
    dynamic averagePrice;
    dynamic oi;
    dynamic oiDayHigh;
    dynamic oiDayLow;
    dynamic netChange;
    dynamic lowerCircuitLimit;
    dynamic upperCircuitLimit;
    Ohlc ohlc;
    Depth depth;

    factory Data.fromJson(Map<String, dynamic> json) => Data(
        instrumentToken: json["instrument_token"],
        timestamp: LastTradeTime.fromJson(json["timestamp"]),
        lastTradeTime: LastTradeTime.fromJson(json["last_trade_time"]),
        lastPrice: json["last_price"].toDouble(),
        lastQuantity: json["last_quantity"],
        buyQuantity: json["buy_quantity"],
        sellQuantity: json["sell_quantity"],
        volume: json["volume"],
        averagePrice: json["average_price"],
        oi: json["oi"],
        oiDayHigh: json["oi_day_high"],
        oiDayLow: json["oi_day_low"],
        netChange: json["net_change"],
        lowerCircuitLimit: json["lower_circuit_limit"].toDouble(),
        upperCircuitLimit: json["upper_circuit_limit"].toDouble(),
        ohlc: Ohlc.fromJson(json["ohlc"]),
        depth: Depth.fromJson(json["depth"]),
    );

    Map<String, dynamic> toJson() => {
        "instrument_token": instrumentToken,
        "timestamp": timestamp.toJson(),
        "last_trade_time": lastTradeTime.toJson(),
        "last_price": lastPrice,
        "last_quantity": lastQuantity,
        "buy_quantity": buyQuantity,
        "sell_quantity": sellQuantity,
        "volume": volume,
        "average_price": averagePrice,
        "oi": oi,
        "oi_day_high": oiDayHigh,
        "oi_day_low": oiDayLow,
        "net_change": netChange,
        "lower_circuit_limit": lowerCircuitLimit,
        "upper_circuit_limit": upperCircuitLimit,
        "ohlc": ohlc.toJson(),
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
        this.price,
        this.quantity,
        this.orders,
    });

    dynamic price;
    dynamic quantity;
    dynamic orders;

    factory Buy.fromJson(Map<String, dynamic> json) => Buy(
        price: json["price"],
        quantity: json["quantity"],
        orders: json["orders"],
    );

    Map<String, dynamic> toJson() => {
        "price": price,
        "quantity": quantity,
        "orders": orders,
    };
}

class LastTradeTime {
    LastTradeTime({
        this.date,
        this.timezoneType,
        this.timezone,
    });

    DateTime date;
    dynamic timezoneType;
    dynamic timezone;

    factory LastTradeTime.fromJson(Map<String, dynamic> json) => LastTradeTime(
        date: DateTime.parse(json["date"]),
        timezoneType: json["timezone_type"],
        timezone: json["timezone"],
    );

    Map<String, dynamic> toJson() => {
        "date": date.toIso8601String(),
        "timezone_type": timezoneType,
        "timezone": timezone,
    };
}

class Ohlc {
    Ohlc({
        this.open,
        this.high,
        this.low,
        this.close,
    });

    double open;
    double high;
    dynamic low;
    double close;

    factory Ohlc.fromJson(Map<String, dynamic> json) => Ohlc(
        open: json["open"].toDouble(),
        high: json["high"].toDouble(),
        low: json["low"],
        close: json["close"].toDouble(),
    );

    Map<String, dynamic> toJson() => {
        "open": open,
        "high": high,
        "low": low,
        "close": close,
    };
}
