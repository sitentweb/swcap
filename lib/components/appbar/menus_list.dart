import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:swcap/pages/homepage.dart';

class Menus {

  static List listMenus(BuildContext context) {

    List menus = [
      {
        "title" : "Home",
        "showDropdown" : false,
        "route" : HomePage(),
        "showDialog" : false
      },
      {
        "title" : "Market Watch Profile",
        "showDropdown" : false,
        "showDialog" : true
      },
      {
        "title" : "Buy",
        "showDropdown" : false,
        "showDialog" : true
      },
      {
        "title" : "Sell",
        "showDropdown" : false,
        "showDialog": true
      }
    ];

    return menus;

  }

}