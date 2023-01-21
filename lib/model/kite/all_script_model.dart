// To parse this JSON data, do
//
//     final scriptListModel = scriptListModelFromJson(jsonString);

import 'dart:convert';

ScriptListModel scriptListModelFromJson(String str) =>
    ScriptListModel.fromJson(json.decode(str));

String scriptListModelToJson(ScriptListModel data) =>
    json.encode(data.toJson());

class ScriptListModel {
  ScriptListModel({
    this.status,
    this.data,
  });

  bool status;
  List<Datum> data;

  factory ScriptListModel.fromJson(Map<String, dynamic> json) =>
      ScriptListModel(
        status: json["status"],
        data: List<Datum>.from(json["data"].map((x) => Datum.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "status": status,
        "data": List<dynamic>.from(data.map((x) => x.toJson())),
      };
}

class Datum {
  Datum({
    this.instrumentToken,
    this.exchangeToken,
    this.tradingsymbol,
    this.name,
    this.last,
    this.expiry,
    this.strike,
    this.tickSize,
    this.lotSize,
    this.instrumentType,
    this.segment,
    this.exchange,
    this.watched,
  });

  String instrumentToken;
  String exchangeToken;
  String tradingsymbol;
  String name;
  String last;
  String expiry;
  String strike;
  String tickSize;
  String lotSize;
  String instrumentType;
  String segment;
  String exchange;
  String watched;

  factory Datum.fromJson(Map<String, dynamic> json) => Datum(
        instrumentToken: json["instrument_token"],
        exchangeToken: json["exchange_token"],
        tradingsymbol: json["tradingsymbol"],
        name: json["name"],
        last: json["last"],
        expiry: json["expiry"],
        strike: json["strike"],
        tickSize: json["tick_size"],
        lotSize: json["lot_size"],
        instrumentType: json["instrument_type"],
        segment: json["segment"],
        exchange: json["exchange"],
        watched: json["watched"],
      );

  Map<String, dynamic> toJson() => {
        "instrument_token": instrumentToken,
        "exchange_token": exchangeToken,
        "tradingsymbol": tradingsymbol,
        "name": name,
        "last": last,
        "expiry": expiry,
        "strike": strike,
        "tick_size": tickSize,
        "lot_size": lotSize,
        "instrument_type": instrumentType,
        "segment": segment,
        "exchange": exchange,
        "watched": watched,
      };
}
