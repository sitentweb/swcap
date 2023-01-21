// To parse this JSON data, do
//
//     final userModel = userModelFromJson(jsonString);

import 'dart:convert';

UserModel userModelFromJson(String str) => UserModel.fromJson(json.decode(str));

String userModelToJson(UserModel data) => json.encode(data.toJson());

class UserModel {
  UserModel({
    this.status,
    this.data,
  });

  bool status;
  Data data;

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
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
    this.name,
    this.username,
    this.email,
    this.mobileNumber,
    this.password,
    this.openingBalance,
    this.deliveryMargin,
    this.span,
    this.exposure,
    this.optionPremium,
    this.balanceInAccount,
    this.showAccount,
    this.isLoggedin,
    this.lastLogin,
    this.isActive,
    this.publicIp,
    this.status,
    this.createdAt,
  });

  String id;
  String name;
  String username;
  String email;
  String mobileNumber;
  String password;
  String openingBalance;
  String deliveryMargin;
  String span;
  String exposure;
  String optionPremium;
  String balanceInAccount;
  String showAccount;
  String isLoggedin;
  String lastLogin;
  String isActive;
  String publicIp;
  String status;
  DateTime createdAt;

  factory Data.fromJson(Map<String, dynamic> json) => Data(
        id: json["id"],
        name: json["name"],
        username: json["username"],
        email: json["email"],
        mobileNumber: json["mobile_number"],
        password: json["password"],
        openingBalance: json["opening_balance"],
        deliveryMargin: json["delivery_margin"],
        span: json["span"],
        exposure: json["exposure"],
        optionPremium: json["option_premium"],
        balanceInAccount: json["balance_in_account"],
        showAccount: json["show_account"],
        isLoggedin: json["is_loggedin"],
        lastLogin: json["last_login"],
        isActive: json["is_active"],
        publicIp: json["public_ip"],
        status: json["status"],
        createdAt: DateTime.parse(json["created_at"]),
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
        "username": username,
        "email": email,
        "mobile_number": mobileNumber,
        "password": password,
        "opening_balance": openingBalance,
        "delivery_margin": deliveryMargin,
        "span": span,
        "exposure": exposure,
        "option_premium": optionPremium,
        "balance_in_account": balanceInAccount,
        "show_account": showAccount,
        "is_loggedin": isLoggedin,
        "last_login": lastLogin,
        "is_active": isActive,
        "public_ip": publicIp,
        "status": status,
        "created_at": createdAt.toIso8601String(),
      };
}
