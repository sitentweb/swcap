import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:swcap/api/auth_api.dart';
import 'package:swcap/api/user_api.dart';
import 'package:swcap/components/buttons/text_button.dart';
import 'package:swcap/components/inputs/custom_input.dart';
import 'package:swcap/config/app_config.dart';
import 'package:swcap/config/user_config.dart';
import 'package:swcap/pages/homepage.dart';

class Login extends StatefulWidget {
  const Login({Key key}) : super(key: key);

  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> {

  bool _isLoading = false;
  TextEditingController _usernameController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();
  String userType = "1";
  String loginValidation = "";

  @override
  void initState() {
    // TODO: implement initState
    _getUserData();
    super.initState();
  }

  _getUserData() async {

    SharedPreferences pref = await SharedPreferences.getInstance();

    if(pref.get("isLogged") != null ){

      if(pref.getBool("isLogged")){
        Navigator.push(context, MaterialPageRoute(builder: (context) => HomePage()));
      }

    }

  }

  _loginProcess() async {

    if(_usernameController.text.isEmpty || _passwordController.text.isEmpty){

    }else{
      setState(() {
        _isLoading = !_isLoading;
      });

      final response = await AuthApi.userLogin(_usernameController.text, _passwordController.text);
      print(response.status);
      if(response.status){

        if(response.data.isLoggedin == "0"){
          final res = await UserApi.updateUser(response.data.id, jsonEncode({
          "is_loggedin" : 1
        }));

        UserConfig.setUserSession(response);
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => HomePage(),));
        }else{
          setState(() {
            loginValidation = "Already Logged In with other device";
          _isLoading = !_isLoading;

          });
        }
        
      }else{

        print(response.data);

        setState(() {
          loginValidation = "Invalid Credentials";
          _isLoading = !_isLoading;
        });
      }


    }


  }


  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return WillPopScope(
      onWillPop: () async {
        await exit(0);
      },
      child: Scaffold(
        body: Container(
            width: size.width,
            height: size.height,
            color: AppConfig.kDarkColor,
            child: Center(
              child: Container(
                width: AppConfig.kIsWebs || AppConfig.kIsWindows ? size.width * 0.4 : size.width * 0.5,
                height: AppConfig.kIsWebs || AppConfig.kIsWindows ? size.height * 0.50 : size.height * 0.60,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppConfig.kDarkColor,
                      AppConfig.kDarkColor
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter
                  ),
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 8,
                      color: Colors.black.withOpacity(0.4),
                      offset: Offset(2,4),
                      spreadRadius: 6
                    )
                  ]
                ),
                child: Column(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        vertical: 5
                      ),
                      child: Center(
                        child: Text("Login Here" , style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold
                        )),
                      )
                    ),
                    Divider(color: AppConfig.kLightColor,),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 15
                      ),
                      child: CustomInput(showHint: false, isPassword: false, showLabel: true, labelText: "Username",textEditingController: _usernameController,),
                    ),
                    SizedBox(height: 10,),
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 15
                      ),
                      child: CustomInput(showHint: false, isPassword: true, showLabel: true, labelText: "Password", textEditingController: _passwordController,),
                    ),
                    SizedBox(height: 10,),
                    Text(loginValidation ,  style : TextStyle(
                      color: Colors.red
                    ) ) ,
                    Container(
                      child: CustomTextButton(
                        onPressed: () {
                          print("Loggin in");
                          _loginProcess();
                        },
                        isLoading: _isLoading,
                        title: "Login",
                      )
                    )
                  ],
                ),
              ),
            ),
            ),
      ),
    );
  }
}
