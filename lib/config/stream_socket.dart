import 'dart:async';

import 'package:swcap/model/kite/kite_watch_list_model.dart';

class StreamSocket {
  final _socketResponse= StreamController<List<dynamic>>();

  void Function(List<dynamic>) get addResponse => _socketResponse.sink.add;
  // void Function(String) get addScripts => _socketResponse.sink.add;

  Stream<List<dynamic>> get getResponse => _socketResponse.stream;

  void dispose(){
    _socketResponse.close();
  }
}

StreamSocket streamSocket =StreamSocket();

class StreamScript {
  final _socketResponse= StreamController<Datum>();

  void Function(Datum) get addScript => _socketResponse.sink.add;
  // void Function(String) get addScripts => _socketResponse.sink.add;

  Stream<Datum> get getScripts => _socketResponse.stream;

  void dispose(){
    _socketResponse.close();
  }
}

StreamScript streamScript =StreamScript();