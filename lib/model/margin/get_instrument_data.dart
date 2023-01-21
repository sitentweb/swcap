// To parse this JSON data, do
//
//     final instrumentDataModel = instrumentDataModelFromJson(jsonString);

import 'dart:convert';

InstrumentDataModel instrumentDataModelFromJson(String str) =>
    InstrumentDataModel.fromJson(json.decode(str));

String instrumentDataModelToJson(InstrumentDataModel data) =>
    json.encode(data.toJson());

class InstrumentDataModel {
  InstrumentDataModel({
    this.status,
    this.data,
  });

  bool status;
  Data data;

  factory InstrumentDataModel.fromJson(Map<String, dynamic> json) =>
      InstrumentDataModel(
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

  factory Data.fromJson(Map<String, dynamic> json) => Data(
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
      };
}
