import 'package:flutter/widgets.dart';
import 'package:flutterfire_ui/auth.dart';
import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuth;

import 'package:flutterfire_ui/src/auth/widgets/internal/universal_scaffold.dart';

import 'package:flutterfire_ui/src/auth/screens/internal/responsive_page.dart';

import '/customSignIn/custom_login_view.dart';

class CustomLoginScreen extends StatelessWidget {
  final FirebaseAuth? auth;
  final AuthAction action;
  final List<ProviderConfiguration> providerConfigs;
  final HeaderBuilder? headerBuilder;
  final double? headerMaxExtent;
  final OAuthButtonVariant? oauthButtonVariant;
  final SideBuilder? sideBuilder;
  final TextDirection? desktopLayoutDirection;
  final String? email;
  final bool? showAuthActionSwitch;
  final bool? resizeToAvoidBottomInset;
  final CustomAuthViewContentBuilder? subtitleBuilder;
  final CustomAuthViewContentBuilder? footerBuilder;
  final Key? loginViewKey;
  final double breakpoint;
  final Set<FlutterFireUIStyle>? styles;

  const CustomLoginScreen({
    Key? key,
    required this.action,
    required this.providerConfigs,
    this.auth,
    this.oauthButtonVariant,
    this.headerBuilder,
    this.headerMaxExtent = defaultHeaderImageHeight,
    this.sideBuilder,
    this.desktopLayoutDirection = TextDirection.ltr,
    this.email,
    this.showAuthActionSwitch,
    this.resizeToAvoidBottomInset = false,
    this.subtitleBuilder,
    this.footerBuilder,
    this.loginViewKey,
    this.breakpoint = 800,
    this.styles,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final loginContent = ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 500),
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: CustomLoginView(
          key: loginViewKey,
          action: action,
          auth: auth,
          providerConfigs: providerConfigs,
          oauthButtonVariant: oauthButtonVariant,
          email: email,
          showAuthActionSwitch: showAuthActionSwitch,
          subtitleBuilder: subtitleBuilder,
          footerBuilder: footerBuilder,
        ),
      ),
    );

    final body = ResponsivePage(
      breakpoint: breakpoint,
      desktopLayoutDirection: desktopLayoutDirection,
      headerBuilder: headerBuilder,
      headerMaxExtent: headerMaxExtent,
      sideBuilder: sideBuilder,
      child: loginContent,
    );

    return FlutterFireUITheme(
      styles: styles ?? const {},
      child: UniversalScaffold(
        body: body,
        resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      ),
    );
  }
}
