import 'package:flutter/material.dart';

class ScriptDetails extends StatefulWidget {
  final String id;
  const ScriptDetails({Key key, this.id}) : super(key: key);

  @override
  State<ScriptDetails> createState() => _ScriptDetailsState();
}

class _ScriptDetailsState extends State<ScriptDetails> {
  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Container(
      padding: EdgeInsets.all(8),
      width: size.width * 0.7,
      height: 350,
      decoration: BoxDecoration(
          color: Colors.black87, borderRadius: BorderRadius.circular(4)),
      child: Column(
        children: [
          Text(
            "Hello",
            style: TextStyle(color: Colors.white),
          )
        ],
      ),
    );
  }
}
