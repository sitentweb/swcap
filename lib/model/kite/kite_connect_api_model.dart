// To parse this JSON data, do
//
//     final kiteConnectApiModel = kiteConnectApiModelFromJson(jsonString);

import 'dart:convert';

KiteConnectApiModel kiteConnectApiModelFromJson(String str) => KiteConnectApiModel.fromJson(json.decode(str));

String kiteConnectApiModelToJson(KiteConnectApiModel data) => json.encode(data.toJson());

class KiteConnectApiModel {
    KiteConnectApiModel({
        this.status,
        this.data,
    });

    bool status;
    Data data;

    factory KiteConnectApiModel.fromJson(Map<String, dynamic> json) => KiteConnectApiModel(
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
        this.id,
        this.apiKey,
        this.apiSecret,
        this.requestToken,
        this.accessToken,
        this.lastUpdated,
        this.createdOn,
    });

    String id;
    String apiKey;
    String apiSecret;
    String requestToken;
    String accessToken;
    String lastUpdated;
    String createdOn;

    factory Data.fromJson(Map<String, dynamic> json) => Data(
        id: json["id"],
        apiKey: json["api_key"],
        apiSecret: json["api_secret"],
        requestToken: json["request_token"],
        accessToken: json["access_token"],
        lastUpdated: json["last_updated"],
        createdOn: json["created_on"],
    );

    Map<String, dynamic> toJson() => {
        "id": id,
        "api_key": apiKey,
        "api_secret": apiSecret,
        "request_token": requestToken,
        "access_token": accessToken,
        "last_updated": lastUpdated,
        "created_on": createdOn,
    };
}
