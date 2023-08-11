import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart' hide Title;
import 'package:flutterfire_ui/auth.dart';
import 'package:flutterfire_ui/i10n.dart';
import 'package:flutterfire_ui/src/auth/widgets/internal/universal_button.dart';

import 'package:flutterfire_ui/src/auth/widgets/internal/title.dart' as FireUi;

import 'custom_phone_input.dart';
import 'termofservicelist.dart';

typedef SMSCodeRequestedCallback = void Function(
  BuildContext context,
  AuthAction? action,
  Object flowKey,
  String phoneNumber,
);

typedef PhoneNumberSubmitCallback = void Function(String phoneNumber);

class CustomPhoneInputView extends StatefulWidget {
  final FirebaseAuth? auth;
  final AuthAction? action;
  final Object flowKey;
  final SMSCodeRequestedCallback? onSMSCodeRequested;
  final PhoneNumberSubmitCallback? onSubmit;
  final WidgetBuilder? subtitleBuilder;
  final WidgetBuilder? footerBuilder;

  const CustomPhoneInputView({
    Key? key,
    required this.flowKey,
    this.onSMSCodeRequested,
    this.auth,
    this.action,
    this.onSubmit,
    this.subtitleBuilder,
    this.footerBuilder,
  }) : super(key: key);

  @override
  State<CustomPhoneInputView> createState() => _CustomPhoneInputViewState();
}

class _CustomPhoneInputViewState extends State<CustomPhoneInputView> {
  final customphoneInputKey = GlobalKey<CustomPhoneInputState>();
  bool termone = false, termtwo = false;

  PhoneNumberSubmitCallback onSubmit(PhoneAuthController ctrl) =>
      (String phoneNumber) {
        if (widget.onSubmit != null) {
          widget.onSubmit!(phoneNumber);
        } else {
          ctrl.acceptPhoneNumber(phoneNumber);
        }
      };

  void _next(PhoneAuthController ctrl) {
    final number = CustomPhoneInput.getPhoneNumber(customphoneInputKey);
    if (number != null) {
      onSubmit(ctrl)(number);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = FlutterFireUILocalizations.labelsOf(context);
    final countryCode = Localizations.localeOf(context).countryCode;

    return AuthFlowBuilder<PhoneAuthController>(
      flowKey: widget.flowKey,
      action: widget.action,
      auth: widget.auth,
      listener: (oldState, newState, controller) {
        if (newState is SMSCodeRequested) {
          final cb = widget.onSMSCodeRequested ??
              FlutterFireUIAction.ofType<SMSCodeRequestedAction>(context)
                  ?.callback;

          cb?.call(
            context,
            widget.action,
            widget.flowKey,
            CustomPhoneInput.getPhoneNumber(customphoneInputKey)!,
          );
        }
      },
      builder: (context, state, ctrl, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            FireUi.Title(text: l.phoneVerificationViewTitleText),
            const SizedBox(height: 32),
            if (widget.subtitleBuilder != null)
              widget.subtitleBuilder!(context),
            if (state is AwaitingPhoneNumber || state is SMSCodeRequested) ...[
              CustomPhoneInput(
                initialCountryCode: countryCode!,
                onSubmit: onSubmit(ctrl),
                key: customphoneInputKey,
              ),
              const SizedBox(height: 24),
              //아래부터 추가한 약관동의
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                      padding: EdgeInsets.fromLTRB(20, 10, 30, 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Text('서비스 이용약관 동의',
                                  style: TextStyle(fontSize: 14)),
                              Text('(필수)',
                                  style: TextStyle(
                                      fontSize: 10, color: Color(0xFFEF5350))),
                              IconButton(
                                icon: Icon(Icons.keyboard_arrow_right),
                                onPressed: () {
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              TermOfService()));
                                },
                              )
                            ],
                          ),
                          termone == true
                              ? IconButton(
                                  icon: Icon(Icons.check_box,
                                      color: Color(0xFF51CF6D)),
                                  onPressed: () {
                                    setState(() {
                                      termone = false;
                                    });
                                  },
                                )
                              : IconButton(
                                  icon: Icon(Icons.check_box_outline_blank,
                                      color: Color(0xFF51CF6D)),
                                  onPressed: () {
                                    setState(() {
                                      termone = true;
                                    });
                                  },
                                ),
                        ],
                      )),
                  Container(
                      padding: EdgeInsets.fromLTRB(20, 10, 30, 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Text('개인정보 수집 및 이용동의',
                                  style: TextStyle(fontSize: 14)),
                              Text('(필수)',
                                  style: TextStyle(
                                      fontSize: 10, color: Color(0xFFEF5350))),
                              IconButton(
                                icon: Icon(Icons.keyboard_arrow_right),
                                onPressed: () {
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              PrivacyPolicy()));
                                },
                              )
                            ],
                          ),
                          termtwo == true
                              ? IconButton(
                                  icon: Icon(Icons.check_box,
                                      color: Color(0xFF51CF6D)),
                                  onPressed: () {
                                    setState(() {
                                      termtwo = false;
                                    });
                                  },
                                )
                              : IconButton(
                                  icon: Icon(Icons.check_box_outline_blank,
                                      color: Color(0xFF51CF6D)),
                                  onPressed: () {
                                    setState(() {
                                      termtwo = true;
                                    });
                                  },
                                ),
                        ],
                      )),
                ],
              ),

              const SizedBox(height: 16),
              termone == true && termtwo == true
                  ? UniversalButton(
                      text: l.verifyPhoneNumberButtonText,
                      onPressed: () => _next(ctrl),
                    )
                  : UniversalButton(
                      text: l.verifyPhoneNumberButtonText,
                      onPressed: () => showDialog(
                          barrierDismissible: true,
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              content: Text('필수 이용약관에 동의하지 않았습니다.'),
                              actions: <Widget>[
                                TextButton(
                                    child: Text('확인',
                                        style: TextStyle(
                                            color: Color(0xFF51CF6D))),
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    }),
                              ],
                            );
                          }),
                    ),
            ],
            if (state is AuthFailed) ...[
              const SizedBox(height: 8),
              ErrorText(exception: state.exception),
              const SizedBox(height: 8),
            ],
            if (widget.footerBuilder != null) widget.footerBuilder!(context),
          ],
        );
      },
    );
  }
}
