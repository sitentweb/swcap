import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socket_io_client/socket_io_client.dart';
import 'package:swcap/api/fetch_scripts.dart';
import 'package:swcap/api/kite_api.dart';
import 'package:swcap/controllers/main_controller.dart';
import 'package:swcap/model/kite/all_script_model.dart';
import 'package:swcap/pages/homepage.dart';

class Search extends StatefulWidget {
  final String userID;
  const Search({Key key, this.userID}) : super(key: key);

  @override
  _SearchState createState() => _SearchState();
}

class _SearchState extends State<Search> {
  MainController mainController = Get.put(MainController());
  String searchString = "";
  String apiKey = "";
  String accessToken = "";
  List<dynamic> _allScripts = [];
  Future<ScriptListModel> _scriptListModel;
  bool searching = false;
  Socket socket;

  @override
  void initState() {
    // TODO: implement initState
    getUserData();
    _socketSetup();
    super.initState();
  }

  getUserData() async {
    SharedPreferences pref = await SharedPreferences.getInstance();

    setState(() {
      apiKey = pref.getString("apiKey");
      accessToken = pref.getString("accessToken");
    });
  }

  _socketSetup() async {
    socket = io('https://remarkablehr.in:8443', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false
    });
  }

  searchScript(String search) async {
    setState(() {
      _scriptListModel =
          FetchScripts().fetchScriptFromBackEnd(search, widget.userID);
    });
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8),
              width: size.width,
              child: Row(
                children: [
                  InkWell(
                    onTap: () => Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => HomePage(),
                        )),
                    child: Padding(
                      padding: EdgeInsets.all(8),
                      child: Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Expanded(
                    child: TextFormField(
                      onChanged: (value) {
                        if (value.length > 2) {
                          searchScript(value);
                          setState(() {
                            searching = true;
                          });
                        }
                        print(value);
                      },
                      onEditingComplete: () {
                        print("Editing Completed");
                        setState(() {
                          searching = false;
                        });
                      },
                      textCapitalization: TextCapitalization.characters,
                      style: TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                          label: Text("Enter Stock Symbol"),
                          hintText: "Enter minimum 3 characters"),
                    ),
                  ),
                ],
              ),
            ),
            Divider(
              color: Colors.white.withOpacity(0.3),
            ),
            Expanded(
              child: Container(
                  color: Colors.white,
                  child: searching
                      ? FutureBuilder<ScriptListModel>(
                          future: _scriptListModel,
                          builder: (context, snapshot) {
                            if (snapshot.hasData) {
                              print(snapshot.data.status);

                              if (snapshot.data.status) {
                                return ListView.builder(
                                  itemCount: snapshot.data.data.length,
                                  itemBuilder: (context, index) {
                                    Datum script = snapshot.data.data[index];

                                    bool watched = false;

                                    if (script.watched == 'true') {
                                      watched = true;
                                    } else {
                                      watched = false;
                                    }

                                    return ListTile(
                                      leading: InkWell(
                                        onTap: () {
                                          if (!watched) {
                                            print("add");
                                            script.watched = 'true';
                                            // watched = true;
                                            var segment = "";

                                            if (script.segment == "NSE") {
                                              segment = "CASH";
                                            } else if (script.segment ==
                                                "NFO-OPT") {
                                              segment = "OPTION";
                                            } else if (script.segment ==
                                                "NFO-FUT") {
                                              segment = "FUTURE";
                                            } else {
                                              segment = script.segment;
                                            }

                                            final response =
                                                KiteApi.addWatchList(
                                                    script.tradingsymbol,
                                                    script.instrumentToken,
                                                    script.exchange,
                                                    segment,
                                                    widget.userID);

                                            response.then((res) {
                                              SnackBar snackBar;

                                              if (res.status) {
                                                socket.emit('subscribe', [
                                                  int.parse(
                                                      script.instrumentToken)
                                                ]);

                                                snackBar = SnackBar(
                                                    content: Text(
                                                  "${script.tradingsymbol} is added successfully",
                                                  style: TextStyle(
                                                      color: Colors.green),
                                                ));
                                              } else {
                                                snackBar = SnackBar(
                                                    content: Text(
                                                  "${script.tradingsymbol} is not added",
                                                  style: TextStyle(
                                                      color: Colors.red),
                                                ));
                                              }

                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(snackBar);
                                            });
                                          } else {
                                            final response =
                                                KiteApi.removeWatchList(
                                                    script.instrumentToken,
                                                    widget.userID);

                                            response.then((res) {
                                              SnackBar snackBar;
                                              if (res.status) {
                                                snackBar = SnackBar(
                                                    content: Text(
                                                        "${script.tradingsymbol} removed"));
                                              } else {
                                                snackBar = SnackBar(
                                                    content: Text(
                                                        "Something went wrong"));
                                              }

                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(snackBar);
                                            });

                                            script.watched = 'false';
                                            // watched = false;
                                            print("remove");
                                          }

                                          setState(() {});

                                          print("Script " + script.watched);
                                        },
                                        child: Padding(
                                          padding: EdgeInsets.all(8),
                                          child: !watched
                                              ? Icon(
                                                  Icons.add,
                                                  color: Colors.green,
                                                )
                                              : Icon(
                                                  Icons.cancel,
                                                  color: Colors.red,
                                                ),
                                        ),
                                      ),
                                      title: Text(script.tradingsymbol),
                                      subtitle: Row(
                                        children: [
                                          Text(script.segment),
                                          SizedBox(
                                            width: 20,
                                          ),
                                          script.exchange == "NFO"
                                              ? Text(
                                                  "Lot Size : ${script.lotSize} ")
                                              : Container(),
                                          SizedBox(
                                            width: 20,
                                          ),
                                          script.exchange == "NFO"
                                              ? Text(
                                                  "Expiry : ${script.expiry} ")
                                              : Container()
                                        ],
                                      ),
                                    );
                                  },
                                );
                              } else {
                                return Center(
                                  child: Text(
                                    "NO STOCK FOUND",
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                );
                              }
                            } else if (snapshot.hasError) {
                              return Text(snapshot.error);
                            } else {
                              return Center(child: CircularProgressIndicator());
                            }
                          },
                        )
                      : Center(
                          child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search,
                              color: Colors.grey,
                            ),
                            Text(
                              "Search Something",
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ))),
            )
          ],
        ),
      ),
    );
  }
}
