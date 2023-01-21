import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:swcap/config/app_config.dart';

class CustomInput extends StatelessWidget {
  final bool showLabel;
  final bool showHint;
  final String labelText;
  final String hintText;
  final bool isPassword;
  final void Function() onTap;
  final TextEditingController textEditingController;

  const CustomInput({Key key, this.showHint, this.labelText, this.hintText, this.isPassword, this.showLabel, this.textEditingController, this.onTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(2.0),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: 10,
        ),
        decoration: BoxDecoration(
          color: AppConfig.kMediumDarkColor.withOpacity(0.3),
          borderRadius: BorderRadius.all(Radius.circular(12))
        ),
        child: TextFormField(
                          controller: textEditingController,
                          style: GoogleFonts.poppins(
                            color: Colors.white
                          ),
                          decoration: InputDecoration(
                            labelText: showLabel ? labelText : "",
                            hintText:  showHint ? hintText : "",
                            border: InputBorder.none
                          ),
                          onTap: onTap ?? null,
                          obscureText: isPassword ?? false,
                        ),
      ),
    );
  }
}