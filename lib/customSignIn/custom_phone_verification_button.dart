import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuth;
import 'package:flutter/cupertino.dart';
import 'package:flutterfire_ui/auth.dart';
import 'package:flutter/material.dart';
import 'package:flutterfire_ui/src/auth/widgets/internal/universal_page_route.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'custom_phone_input_screen.dart';

class CustomPhoneVerificationButton extends StatelessWidget {
  final FirebaseAuth? auth;
  final AuthAction? action;
  final String label;

  const CustomPhoneVerificationButton({
    Key? key,
    required this.label,
    this.action,
    this.auth,
  }) : super(key: key);

  void _onPressed(BuildContext context) {
    final _action = FlutterFireUIAction.ofType<VerifyPhoneAction>(context);
    if (_action != null) {
      _action.callback(context, action);
    } else {
      startPhoneVerification(context: context, action: action, auth: auth);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Color(0xFF51CF6D),
        border: Border.all(
          color: Color(0xFF51CF6D),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(16.w),
      ),
      padding: EdgeInsets.fromLTRB(8.w, 2.w, 8.w, 2.w),
      child: Center(
        child: TextButton(
          onPressed: () => _onPressed(context),
          child: Text(label,
              style: TextStyle(fontSize: 18.w, color: Colors.white)),
        ),
      ),
    );
  }
}

Future<void> startPhoneVerification({
  required BuildContext context,
  AuthAction? action,
  FirebaseAuth? auth,
}) async {
  await Navigator.of(context).push(
    createPageRoute(
      context: context,
      builder: (_) => FlutterFireUIActions.inherit(
        from: context,
        child: CustomPhoneInputScreen(action: action),
      ),
    ),
  );
}
