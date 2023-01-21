// To parse this JSON data, do
//
//     final scriptMarginModel = scriptMarginModelFromJson(jsonString);

import 'dart:convert';

ScriptMarginModel scriptMarginModelFromJson(String str) =>
    ScriptMarginModel.fromJson(json.decode(str));

String scriptMarginModelToJson(ScriptMarginModel data) =>
    json.encode(data.toJson());

class ScriptMarginModel {
  ScriptMarginModel({
    this.status,
    this.data,
  });

  bool status;
  Data data;

  factory ScriptMarginModel.fromJson(Map<String, dynamic> json) =>
      ScriptMarginModel(
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
    this.marginId,
    this.marginScriptName,
    this.marginScriptSymbols,
    this.marginLotSize,
    this.marginMargin,
    this.marginApprox,
  });

  String marginId;
  String marginScriptName;
  String marginScriptSymbols;
  String marginLotSize;
  String marginMargin;
  String marginApprox;

  factory Data.fromJson(Map<String, dynamic> json) => Data(
        marginId: json["margin_id"],
        marginScriptName: json["margin_script_name"],
        marginScriptSymbols: json["margin_script_symbols"],
        marginLotSize: json["margin_lot_size"],
        marginMargin: json["margin_margin"],
        marginApprox: json["margin_approx"],
      );

  Map<String, dynamic> toJson() => {
        "margin_id": marginId,
        "margin_script_name": marginScriptName,
        "margin_script_symbols": marginScriptSymbols,
        "margin_lot_size": marginLotSize,
        "margin_margin": marginMargin,
        "margin_approx": marginApprox,
      };
}
