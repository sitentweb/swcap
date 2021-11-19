// To parse this JSON data, do
//
//     final kiteWatchLIstModel = kiteWatchLIstModelFromJson(jsonString);

import 'dart:convert';

KiteWatchLIstModel kiteWatchLIstModelFromJson(String str) => KiteWatchLIstModel.fromJson(json.decode(str));

String kiteWatchLIstModelToJson(KiteWatchLIstModel data) => json.encode(data.toJson());

class KiteWatchLIstModel {
    KiteWatchLIstModel({
        this.status,
        this.data,
    });

    bool status;
    List<Datum> data;

    factory KiteWatchLIstModel.fromJson(Map<String, dynamic> json) => KiteWatchLIstModel(
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
        this.watchlistId,
        this.watchlistScriptName,
        this.watchlistScriptToken,
        this.watchlistScriptType,
        this.watchlistScriptCategory,
        this.watchlistClientId,
        this.watchlistCreatedAt,
    });

    String watchlistId;
    String watchlistScriptName;
    String watchlistScriptToken;
    String watchlistScriptType;
    String watchlistScriptCategory;
    String watchlistClientId;
    DateTime watchlistCreatedAt;

    factory Datum.fromJson(Map<String, dynamic> json) => Datum(
        watchlistId: json["watchlist_id"],
        watchlistScriptName: json["watchlist_script_name"],
        watchlistScriptToken: json["watchlist_script_token"],
        watchlistScriptType: json["watchlist_script_type"],
        watchlistScriptCategory: json["watchlist_script_category"],
        watchlistClientId: json["watchlist_client_id"],
        watchlistCreatedAt: DateTime.parse(json["watchlist_created_at"]),
    );

    Map<String, dynamic> toJson() => {
        "watchlist_id": watchlistId,
        "watchlist_script_name": watchlistScriptName,
        "watchlist_script_token": watchlistScriptToken,
        "watchlist_script_type": watchlistScriptType,
        "watchlist_script_category": watchlistScriptCategory,
        "watchlist_client_id": watchlistClientId,
        "watchlist_created_at": watchlistCreatedAt.toIso8601String(),
    };
}
