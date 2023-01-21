// To parse this JSON data, do
//
//     final profitLossModel = profitLossModelFromJson(jsonString);

import 'dart:convert';

ProfitLossModel profitLossModelFromJson(String str) => ProfitLossModel.fromJson(json.decode(str));

String profitLossModelToJson(ProfitLossModel data) => json.encode(data.toJson());

class ProfitLossModel {
    ProfitLossModel({
        this.status,
        this.data,
    });

    bool status;
    List<Datum> data;

    factory ProfitLossModel.fromJson(Map<String, dynamic> json) => ProfitLossModel(
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
        this.scriptName,
        this.buyQuantity,
        this.buyValue,
        this.buyAverage,
        this.sellQuantity,
        this.sellValue,
        this.sellAverage,
        this.balanceQuantity,
        this.realizedProfit,
        this.tradeCategory,
    });

    String scriptName;
    String buyQuantity;
    String buyValue;
    String buyAverage;
    String sellQuantity;
    String sellValue;
    String sellAverage;
    String balanceQuantity;
    String realizedProfit;
    String tradeCategory;

    factory Datum.fromJson(Map<String, dynamic> json) => Datum(
        scriptName: json["script_name"],
        buyQuantity: json["buy_quantity"],
        buyValue: json["buy_value"],
        buyAverage: json["buy_average"] == null ? null : json["buy_average"],
        sellQuantity: json["sell_quantity"],
        sellValue: json["sell_value"],
        sellAverage: json["sell_average"] == null ? null : json["sell_average"],
        balanceQuantity: json["balance_quantity"],
        realizedProfit: json["realized_profit"],
        tradeCategory: json["trade_category"],
    );

    Map<String, dynamic> toJson() => {
        "script_name": scriptName,
        "buy_quantity": buyQuantity,
        "buy_value": buyValue,
        "buy_average": buyAverage == null ? null : buyAverage,
        "sell_quantity": sellQuantity,
        "sell_value": sellValue,
        "sell_average": sellAverage == null ? null : sellAverage,
        "balance_quantity": balanceQuantity,
        "realized_profit": realizedProfit,
        "trade_category": tradeCategory,
    };
}
