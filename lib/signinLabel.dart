import 'package:flutterfire_ui/i10n.dart';

class LabelOverrides extends DefaultLocalizations {
  const LabelOverrides();
  @override
  String get phoneInputLabel => '전화번호';
  String get signInText => '로그인';
  String get signInWithPhoneButtonText => '전화번호로 로그인 하기';
  String get countryCode => '국가번호';
  String get goBackButtonLabel => '뒤로가기';
  String get verifyCodeButtonText => '인증하기';
  String get verifyPhoneNumberViewTitle => 'SMS Code 입력하기';
  String get phoneNumberInvalidErrorText => '전화번호를 다시 확인해주세요.';
  String get enterSMSCodeText => '인증번호 입력';
  String get verifyPhoneNumberButtonText => '다음';
  String get invalidCountryCode => '존재하지 않는 국가번호입니다.';
  String get chooseACountry => '국가번호를 선택하세요';
  String get phoneVerificationViewTitleText => '전화번호를 입력해주세요';
  String get smsAutoresolutionFailedError =>
      'SMS Code 인증에 실패했습니다. 입력하신 정보가 맞는지 확인해보세요';
  String get verifyingSMSCodeText => '인증 진행중...';
  String get sendingSMSCodeText => 'SMS Code 발송중...';
  String get phoneNumberIsRequiredErrorText => '전화번호를 입력해주세요';
  String get name => '닉네임';
  String get signOutButtonText => '로그아웃';
  String get deleteAccount => '계정탈퇴';
  String get birthday => '생년월일';
  String get gender => '성별';
}
