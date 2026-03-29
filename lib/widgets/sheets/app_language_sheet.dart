import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:habitt/models/language_option.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/widgets/settings/app_language_sheet.dart';

class AppLanguageSheet extends StatelessWidget {
  const AppLanguageSheet({
    super.key,
    required this.maxSheetHeight,
    required this.cp,
  });

  final double maxSheetHeight;
  final ColorProvider cp;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxSheetHeight),
      child: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
          child: Column(
            spacing: 20,
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              topSection(context),
              Column(
                spacing: 10,
                children: [
                  for (var option in LanguageOption.values)
                    LanguageOptionWidget(languageOption: option),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Padding topSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            height: 36,
            width: 66,
            child: GestureDetector(
              onTap: () {
                Navigator.pop(context);
              },
              child: Align(
                alignment: Alignment.centerLeft,
                child: SvgPicture.asset(
                  "assets/images/new-svg/back.svg",
                  colorFilter: ColorFilter.mode(cp.text, BlendMode.srcIn),
                ),
              ),
            ),
          ),
          Text(
            'Choose app language',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: cp.text,
              fontSize: 22,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(width: 66), // To balance the back button
        ],
      ),
    );
  }
}
