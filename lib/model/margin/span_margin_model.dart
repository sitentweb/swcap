// To parse this JSON data, do
//
//     final spanMarginModel = spanMarginModelFromJson(jsonString);

import 'dart:convert';

SpanMarginModel spanMarginModelFromJson(String str) => SpanMarginModel.fromJson(json.decode(str));

String spanMarginModelToJson(SpanMarginModel data) => json.encode(data.toJson());

class SpanMarginModel {
    SpanMarginModel({
        this.status,
        this.data,
    });

    bool status;
    List<Datum> data;

    factory SpanMarginModel.fromJson(Map<String, dynamic> json) => SpanMarginModel(
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

    factory Datum.fromJson(Map<String, dynamic> json) => Datum(
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
