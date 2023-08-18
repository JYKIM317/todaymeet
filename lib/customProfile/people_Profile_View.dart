import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:famet/community/chatRoom.dart';
import 'simple_Review.dart';
import 'full_ProfilePhoto.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

late DocumentReference _userinfo;

class OtherProfile extends StatefulWidget {
  final user;
  OtherProfile({Key? key, required this.user}) : super(key: key);
  @override
  State<OtherProfile> createState() => _OtherProfileState();
}

class _OtherProfileState extends State<OtherProfile> {
  User? _user = FirebaseAuth.instance.currentUser;

  InterstitialAd? _interstitialAd;
  void interstitialAd() {
    InterstitialAd.load(
        //id 테스트ID -> 실제 Ad ID로 변경해야함
        adUnitId: Platform.isAndroid
            ? 'ca-app-pub-3940256099942544/1033173712'
            : 'ca-app-pub-3940256099942544/4411468910',
        request: AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(onAdLoaded: (ad) {
          debugPrint('$ad loaded');
          _interstitialAd = ad;
        }, onAdFailedToLoad: (LoadAdError error) {
          debugPrint('$error');
        }));
  }

  Widget bannerAd() {
    BannerAdListener bannerAdListener =
        BannerAdListener(onAdWillDismissScreen: (ad) {
      ad.dispose();
    });

    BannerAd _bannerAd = BannerAd(
      size: AdSize.banner,
      adUnitId: Platform.isAndroid
          ? 'ca-app-pub-3940256099942544/6300978111'
          : 'ca-app-pub-3940256099942544/2934735716',
      listener: bannerAdListener,
      request: AdRequest(),
    );

    _bannerAd.load();

    return SizedBox(
      height: 60.h,
      width: double.infinity,
      child: AdWidget(ad: _bannerAd),
    );
  }

  @override
  void initState() {
    _userinfo = FirebaseFirestore.instance.collection('users').doc(widget.user);
    _user = FirebaseAuth.instance.currentUser;
    interstitialAd();
    super.initState();
  }

  @override
  void dispose() {
    _interstitialAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Future<List<dynamic>> blockCheck() async {
      final database = FirebaseFirestore.instance
          .collection('users')
          .doc(_user!.uid)
          .collection('other')
          .doc('block');
      final document = await database.get();
      final List<dynamic> blocklist = await document.get('block');
      return blocklist;
    }

    Future<List<dynamic>> blocking() async {
      final database = _userinfo.collection('other').doc('block');
      final document = await database.get();
      final List<dynamic> blockedlist = await document.get('blocked');
      return blockedlist;
    }

    Future<List<dynamic>> favoriteCheck() async {
      final database = FirebaseFirestore.instance
          .collection('users')
          .doc(_user!.uid)
          .collection('other')
          .doc('favorite');
      final document = await database.get();
      final List<dynamic> favoritelist = await document.get('list');
      return favoritelist;
    }

    Future<List<dynamic>> currentUserInfo() async {
      final database = await FirebaseFirestore.instance
          .collection('users')
          .doc(_user!.uid)
          .get();
      final canMessage = await database.get('canMessage');
      final name = await database.get('username');
      final photo = await database.get('photoUrl');
      final pushToken = await database.get('pushToken');
      List<dynamic> responseData = [canMessage, name, photo, pushToken];
      return responseData;
    }

    Future<String> messageExist() async {
      bool check1 = true, check2 = true;
      late String responseData;
      final possibility1 = await FirebaseFirestore.instance
          .collection('chatRoom')
          .doc('available')
          .collection('${_user!.uid}_${widget.user}')
          .get();
      final response1 = possibility1.docs;
      final possibility2 = await FirebaseFirestore.instance
          .collection('chatRoom')
          .doc('available')
          .collection('${widget.user}_${_user!.uid}')
          .get();
      final response2 = possibility2.docs;
      if (response1.isEmpty) check1 = false;
      if (response2.isEmpty) check2 = false;
      if (check1 == true) {
        responseData = '${_user!.uid}_${widget.user}';
      } else if (check2 == true) {
        responseData = '${widget.user}_${_user!.uid}';
      } else if (check1 == false && check2 == false) {
        responseData = 'empty';
      }
      return responseData;
    }

    return Scaffold(
      body: SingleChildScrollView(
        physics: BouncingScrollPhysics(),
        child: Padding(
          padding: EdgeInsets.fromLTRB(20.w, 16.w, 20.w, 10.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 24.w),
              InkWell(
                child: SizedBox(
                  child: Icon(Icons.arrow_back_ios,
                      color: Colors.grey, size: 18.w),
                ),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              SizedBox(height: 24.w),
              FutureBuilder<DocumentSnapshot>(
                  future: _userinfo.get(), //_userinfo 는 상대info임
                  builder: (BuildContext context,
                      AsyncSnapshot<DocumentSnapshot> snapshot) {
                    if (snapshot.hasError) return Text('오류가 발생했습니다.');
                    if (snapshot.connectionState == ConnectionState.waiting)
                      return Text('');
                    Map<String, dynamic>? data =
                        snapshot.data?.data() as Map<String, dynamic>?;
                    if (data == null) {
                      return SizedBox(
                        width: MediaQuery.sizeOf(context).width,
                        height: MediaQuery.sizeOf(context).height - 60.w,
                        child: Center(
                          child: Text(
                            '해당 유저가 존재하지 않습니다.',
                            style: TextStyle(
                              fontSize: 22.w,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      );
                    }
                    List<dynamic>? regionCategory =
                        data['regioncategory'] as List<dynamic>?;
                    List<dynamic>? hobbyCategory =
                        data['hobbycategory'] as List<dynamic>?;
                    String categoryTextR = regionCategory?.join('  ') ?? '';
                    String categoryTextH = hobbyCategory?.join('  ') ?? '';
                    var attendCount = data['attend'];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: 14.w,
                          width: double.infinity,
                        ),
                        Center(
                          child: InkWell(
                            child: Hero(
                              tag: 'profilePhoto',
                              child: CircleAvatar(
                                  backgroundColor: Colors.grey,
                                  radius: 90.w,
                                  backgroundImage:
                                      NetworkImage(data['photoUrl'])),
                            ),
                            onTap: () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => FullScreenPhoto(
                                          photo: data['photoUrl'])));
                            },
                          ),
                        ),
                        SizedBox(
                          height: 20.w,
                        ),
                        if (widget.user != _user!.uid)
                          SizedBox(
                            width: double.infinity,
                            child: Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  InkWell(
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.favorite,
                                          color: Color(0xFFEF5350),
                                          size: 16.w,
                                        ),
                                        SizedBox(width: 2.w),
                                        Text(
                                          '관심회원 등록',
                                          style: TextStyle(fontSize: 14.w),
                                        )
                                      ],
                                    ),
                                    onTap: () async {
                                      var favoritelist = await favoriteCheck();
                                      if (favoritelist.contains(widget.user)) {
                                        showDialog(
                                            barrierDismissible: true,
                                            context: context,
                                            builder: (BuildContext context) {
                                              return AlertDialog(
                                                shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            6.w)),
                                                content:
                                                    Text("이미 관심 등록한 대상입니다."),
                                              );
                                            });
                                      } else {
                                        favoritelist.add(widget.user);
                                        await FirebaseFirestore.instance
                                            .collection('users')
                                            .doc(_user!.uid)
                                            .collection('other')
                                            .doc('favorite')
                                            .update({'list': favoritelist});
                                        showDialog(
                                            barrierDismissible: true,
                                            context: context,
                                            builder: (BuildContext context) {
                                              return AlertDialog(
                                                shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            6.w)),
                                                content:
                                                    Text("관심 목록에 대상을 추가했습니다."),
                                              );
                                            });
                                      }
                                    },
                                  ),
                                  SizedBox(width: 28.w),
                                  InkWell(
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.mode_comment_outlined,
                                          size: 16.w,
                                        ),
                                        SizedBox(width: 2.w),
                                        Text(
                                          '대화하기',
                                          style: TextStyle(fontSize: 14.w),
                                        ),
                                      ],
                                    ),
                                    onTap: () async {
                                      if (_interstitialAd != null)
                                        _interstitialAd?.show();
                                      String messageRoom = await messageExist();
                                      if (messageRoom == 'empty') {
                                        List<dynamic> responseMyData =
                                            await currentUserInfo();
                                        if (responseMyData[0] > 0) {
                                          showDialog(
                                              barrierDismissible: true,
                                              context: context,
                                              builder: (BuildContext context) {
                                                return AlertDialog(
                                                  shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              6.w)),
                                                  content: Text(
                                                      "이번 달 남은 대화 걸기 횟수는\n${responseMyData[0]}회 입니다.\n대화하시겠습니까?"),
                                                  actions: [
                                                    TextButton(
                                                        child: Text('취소하기',
                                                            style: TextStyle(
                                                              color:
                                                                  Colors.grey,
                                                              fontSize: 12.w,
                                                            )),
                                                        onPressed: () {
                                                          Navigator.of(context)
                                                              .pop();
                                                        }),
                                                    TextButton(
                                                        child: Text('대화하기',
                                                            style: TextStyle(
                                                              color: Color(
                                                                  0xFF51CF6D),
                                                              fontSize: 12.w,
                                                            )),
                                                        onPressed: () async {
                                                          int opportunity =
                                                              responseMyData[0];
                                                          opportunity =
                                                              opportunity - 1;
                                                          Navigator.of(context)
                                                              .pop();
                                                          showDialog(
                                                              barrierDismissible:
                                                                  true,
                                                              context: context,
                                                              builder:
                                                                  (BuildContext
                                                                      context) {
                                                                return AlertDialog(
                                                                  shape: RoundedRectangleBorder(
                                                                      borderRadius:
                                                                          BorderRadius.circular(
                                                                              6.w)),
                                                                  content: Text(
                                                                      "대화방을 생성했습니다."),
                                                                );
                                                              });
                                                          await FirebaseFirestore
                                                              .instance
                                                              .collection(
                                                                  'chatRoom')
                                                              .doc('available')
                                                              .collection(
                                                                  '${_user!.uid}_${widget.user}')
                                                              .doc('info')
                                                              .set({
                                                            'title': [
                                                              responseMyData[1],
                                                              data['username']
                                                            ],
                                                            'newestMessage':
                                                                ' ',
                                                            'member': [
                                                              _user!.uid,
                                                              widget.user
                                                            ],
                                                            'isGroup': false,
                                                            'chatRoom':
                                                                '${_user!.uid}_${widget.user}',
                                                            'memberPhotoUrl': [
                                                              responseMyData[2],
                                                              data['photoUrl']
                                                            ],
                                                            'memberTokenList': [
                                                              responseMyData[3],
                                                              data['pushToken']
                                                            ],
                                                          });
                                                          await FirebaseFirestore
                                                              .instance
                                                              .collection(
                                                                  'users')
                                                              .doc(_user!.uid)
                                                              .update({
                                                            'canMessage':
                                                                opportunity,
                                                          });
                                                          await FirebaseFirestore
                                                              .instance
                                                              .collection(
                                                                  'users')
                                                              .doc(_user!.uid)
                                                              .collection(
                                                                  'chat')
                                                              .doc(
                                                                  '${_user!.uid}_${widget.user}')
                                                              .set({
                                                            'read': 0,
                                                            'recent':
                                                                DateTime.now()
                                                          });
                                                        }),
                                                  ],
                                                );
                                              });
                                        } else {
                                          showDialog(
                                              barrierDismissible: true,
                                              context: context,
                                              builder: (BuildContext context) {
                                                return AlertDialog(
                                                  shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              6.w)),
                                                  content: Text(
                                                      "1:1 대화 가능 횟수가 0회 남았습니다.\n횟수는 매월 1일 초기화됩니다."),
                                                );
                                              });
                                        }
                                      } else {
                                        final roomData = await FirebaseFirestore
                                            .instance
                                            .collection('chatRoom')
                                            .doc('available')
                                            .collection(messageRoom)
                                            .doc('info')
                                            .get();
                                        List roomTitle = roomData.get('title');
                                        List memberList =
                                            roomData.get('member');
                                        Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (context) => Chatting(
                                                      chatAdress: messageRoom,
                                                      title: roomTitle,
                                                      hostUID: memberList[0],
                                                    )));
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        SizedBox(
                          height: 20.w,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  height: 48.w,
                                  alignment: Alignment.center,
                                  padding: EdgeInsets.only(top: 15.w),
                                  child: Text(
                                    '이름',
                                    style: TextStyle(
                                      decoration: TextDecoration.underline,
                                      decorationColor: Color(0xFF51CF6D),
                                      fontSize: 16.w,
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  child: Text(
                                    data['username'] ?? '이름이 없습니다.',
                                    style: TextStyle(
                                        fontSize: 22.w,
                                        fontWeight: FontWeight.w700),
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  height: 48.w,
                                  alignment: Alignment.center,
                                  padding: EdgeInsets.only(top: 15.w),
                                  child: Text(
                                    '생년월일',
                                    style: TextStyle(
                                        decoration: TextDecoration.underline,
                                        decorationColor: Color(0xFF51CF6D),
                                        fontSize: 16.w),
                                  ),
                                ),
                                SizedBox(
                                  width: 130.w,
                                  child: Text(
                                    "${data['year']}.${data['month']}",
                                    style: TextStyle(
                                        fontSize: 22.w,
                                        fontWeight: FontWeight.w700),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  height: 48.w,
                                  alignment: Alignment.center,
                                  padding: EdgeInsets.only(top: 15.w),
                                  child: Text(
                                    '성별',
                                    style: TextStyle(
                                        decoration: TextDecoration.underline,
                                        decorationColor: Color(0xFF51CF6D),
                                        fontSize: 16.w),
                                  ),
                                ),
                                SizedBox(
                                  child: Text(
                                    data['gender'] ?? "null",
                                    style: TextStyle(
                                        fontSize: 22.w,
                                        fontWeight: FontWeight.w700),
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  height: 48.w,
                                  alignment: Alignment.center,
                                  padding: EdgeInsets.only(top: 15.w),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      Text(
                                        '매너점수',
                                        style: TextStyle(
                                            decoration:
                                                TextDecoration.underline,
                                            decorationColor: Color(0xFF51CF6D),
                                            fontSize: 16.w),
                                      ),
                                      IconButton(
                                        onPressed: () {
                                          showDialog(
                                              context: context,
                                              barrierDismissible: true,
                                              builder: (BuildContext context) {
                                                return AlertDialog(
                                                  shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              6.w)),
                                                  title: Text(
                                                    '매너점수는 어떻게 올리나요?',
                                                    style: TextStyle(
                                                        decoration:
                                                            TextDecoration
                                                                .underline,
                                                        decorationColor:
                                                            Color(0xFF51CF6D),
                                                        fontSize: 20.w),
                                                  ),
                                                  content: Text(
                                                    '모임 참가자 간 리뷰를 통해\n점수가 오르거나 떨어지게 됩니다\n배려있는 모임활동을 통해 매너점수를 올려보세요!\n\n초기 점수는 50점으로 시작합니다.',
                                                    style: TextStyle(
                                                        fontSize: 16.w),
                                                  ),
                                                );
                                              });
                                        },
                                        icon: Icon(
                                          Icons.help_center_outlined,
                                          size: 18.w,
                                        ),
                                        alignment: Alignment.centerLeft,
                                      )
                                    ],
                                  ),
                                ),
                                SizedBox(
                                  width: 130.w,
                                  child: Text(
                                    "${data['manner'] >= 100 ? 100 : data['manner'] <= 0 ? 0 : data['manner']} 점",
                                    style: TextStyle(
                                        fontSize: 22.w,
                                        fontWeight: FontWeight.w700),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        SizedBox(height: 14.w),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              height: 48.w,
                              //alignment: Alignment.center,
                              padding: EdgeInsets.fromLTRB(0, 15.w, 0, 10.w),
                              child: Text(
                                '자기소개',
                                style: TextStyle(
                                    decoration: TextDecoration.underline,
                                    decorationColor: Color(0xFF51CF6D),
                                    fontSize: 16.w),
                              ),
                            ),
                            SizedBox(
                                child: data['introduce'] != null &&
                                        data['introduce'] != ""
                                    ? Text(
                                        data['introduce'],
                                        style: TextStyle(
                                          fontSize: 18.w,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      )
                                    : Text(
                                        "자기소개가 작성되지 않았습니다.",
                                        style: TextStyle(
                                            fontSize: 18.w,
                                            fontWeight: FontWeight.w700,
                                            color:
                                                Colors.grey.withOpacity(0.8)),
                                      )),
                          ],
                        ),
                        SizedBox(height: 14.w),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              height: 48.w,
                              //alignment: Alignment.center,
                              padding: EdgeInsets.fromLTRB(0, 15.w, 0, 10.w),
                              child: Text(
                                '관심 카테고리',
                                style: TextStyle(
                                    decoration: TextDecoration.underline,
                                    decorationColor: Color(0xFF51CF6D),
                                    fontSize: 16.w),
                              ),
                            ),
                            SizedBox(
                                child: (categoryTextR != '' &&
                                            data['regioncategory'] != null) ||
                                        (categoryTextH != '' &&
                                            data['hobbycategory'] != null)
                                    ? Text(
                                        '$categoryTextR  $categoryTextH',
                                        style: TextStyle(
                                          fontSize: 22.w,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF51CF6D),
                                        ),
                                      )
                                    : Text(
                                        "관심 카테고리를 설정하지 않았습니다.",
                                        style: TextStyle(
                                            fontSize: 18.w,
                                            fontWeight: FontWeight.w700,
                                            color:
                                                Colors.grey.withOpacity(0.8)),
                                      )),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              height: 48.w,
                              //alignment: Alignment.center,
                              padding: EdgeInsets.only(top: 15.w),
                              child: Text(
                                'MBTI',
                                style: TextStyle(
                                    decoration: TextDecoration.underline,
                                    decorationColor: Color(0xFF51CF6D),
                                    fontSize: 16.w),
                              ),
                            ),
                            SizedBox(
                              child: data['mbti'] != null
                                  ? Text(
                                      data['mbti'],
                                      style: TextStyle(
                                          fontSize: 22.w,
                                          fontWeight: FontWeight.w700),
                                    )
                                  : Text(
                                      "-",
                                      style: TextStyle(
                                          fontSize: 18.w,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.grey.withOpacity(0.8)),
                                    ),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  height: 48.w,
                                  alignment: Alignment.center,
                                  padding: EdgeInsets.only(top: 15.w),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      Text(
                                        '참석률',
                                        style: TextStyle(
                                            decoration:
                                                TextDecoration.underline,
                                            decorationColor: Color(0xFF51CF6D),
                                            fontSize: 16.w),
                                      ),
                                      IconButton(
                                        onPressed: () {
                                          showDialog(
                                              context: context,
                                              barrierDismissible: true,
                                              builder: (BuildContext context) {
                                                return AlertDialog(
                                                  shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              6.w)),
                                                  title: Text(
                                                    '참석률이 무엇인가요?',
                                                    style: TextStyle(
                                                        decoration:
                                                            TextDecoration
                                                                .underline,
                                                        decorationColor:
                                                            Color(0xFF51CF6D),
                                                        fontSize: 20.w),
                                                  ),
                                                  content: Text(
                                                      '모임이 정상적으로 시작되고,\n실제로 모임에 참가한 비율을 알려줍니다.\n약속을 지키는 것은 서로에 대한 배려이니\n모임을 약속했다면 지키도록 노력해야합니다.',
                                                      style: TextStyle(
                                                          fontSize: 16.w)),
                                                );
                                              });
                                        },
                                        icon: Icon(
                                          Icons.help_center_outlined,
                                          size: 18.w,
                                        ),
                                        alignment: Alignment.centerLeft,
                                      )
                                    ],
                                  ),
                                ),
                                FutureBuilder(
                                  future: _userinfo.collection('done').get(),
                                  builder: (context, snapshot) {
                                    if (snapshot.hasError) return Text('');
                                    if (snapshot.connectionState ==
                                        ConnectionState.waiting)
                                      return Text('');
                                    final List<DocumentSnapshot> doneRoomCount =
                                        snapshot.data!.docs;
                                    double attendPercent = attendCount /
                                        doneRoomCount.length *
                                        100;
                                    return SizedBox(
                                      child: doneRoomCount.isNotEmpty
                                          ? Text(
                                              "${attendPercent.round()}%",
                                              style: TextStyle(
                                                  fontSize: 22.w,
                                                  fontWeight: FontWeight.w700),
                                            )
                                          : Text(
                                              "-",
                                              style: TextStyle(
                                                  fontSize: 22.w,
                                                  fontWeight: FontWeight.w700,
                                                  color: Colors.grey
                                                      .withOpacity(0.8)),
                                            ),
                                    );
                                  },
                                ),
                              ],
                            ),
                            FutureBuilder<QuerySnapshot>(
                                future: _userinfo.collection('review').get(),
                                builder: (BuildContext context,
                                    AsyncSnapshot<QuerySnapshot> snapshot) {
                                  if (snapshot.hasError)
                                    return Text('오류가 발생했습니다.');
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) return Text('');
                                  List<DocumentSnapshot>? data =
                                      snapshot.data!.docs.reversed.toList();
                                  var fieldCount = data.length;
                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      SizedBox(
                                        child: InkWell(
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Container(
                                                height: 48.w,
                                                alignment: Alignment.center,
                                                padding:
                                                    EdgeInsets.only(top: 15.w),
                                                child: Text(
                                                  '한 줄 후기',
                                                  style: TextStyle(
                                                      decoration: TextDecoration
                                                          .underline,
                                                      decorationColor:
                                                          Color(0xFF51CF6D),
                                                      fontSize: 16.w),
                                                ),
                                              ),
                                              Container(
                                                padding:
                                                    EdgeInsets.only(top: 15.w),
                                                child: Icon(
                                                  Icons.folder_open,
                                                  size: 20.w,
                                                ),
                                              )
                                            ],
                                          ),
                                          onTap: () {
                                            Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                    builder: (context) =>
                                                        SimpleReview(
                                                            member: widget.user,
                                                            reviews: data)));
                                          },
                                        ),
                                      ),
                                      SizedBox(
                                        width: 130.w,
                                        child: Text('$fieldCount 건',
                                            style: TextStyle(
                                                fontSize: 22.w,
                                                fontWeight: FontWeight.w700)),
                                      ),
                                    ],
                                  );
                                }),
                          ],
                        ),
                        SizedBox(height: 48.w),
                      ],
                    );
                  }),
              widget.user != _user!.uid
                  ? Row(children: [
                      InkWell(
                          onTap: () async {
                            var blocklist = await blockCheck();
                            var blockedlist = await blocking();
                            if (blocklist.contains(widget.user)) {
                              showDialog(
                                  barrierDismissible: true,
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(6.w)),
                                      content: Text("이미 차단되어 있는 대상입니다."),
                                    );
                                  });
                            } else {
                              blocklist.add(widget.user);
                              blockedlist.add(_user!.uid);
                              await FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(_user!.uid)
                                  .collection('other')
                                  .doc('block')
                                  .update({'block': blocklist});
                              await _userinfo
                                  .collection('other')
                                  .doc('block')
                                  .update({'blocked': blockedlist});
                              showDialog(
                                  barrierDismissible: true,
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(6.w)),
                                      content: Text("차단 목록에 대상을 추가했습니다."),
                                    );
                                  });
                            }
                          },
                          child: Row(
                            children: [
                              Icon(
                                Icons.block,
                                color: Colors.grey,
                                size: 18.w,
                              ),
                              SizedBox(width: 4.w),
                              Text('차단하기',
                                  style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 14.w,
                                      decoration: TextDecoration.underline)),
                            ],
                          )),
                      SizedBox(width: 16.w),
                      InkWell(
                          onTap: () {
                            showDialog(
                                barrierDismissible: false,
                                context: context,
                                builder: (BuildContext context) {
                                  String reportReason = ' ';
                                  TextEditingController reportController =
                                      TextEditingController();
                                  return AlertDialog(
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(6.w)),
                                    content: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text('신고하기',
                                            style: TextStyle(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 22.w)),
                                        SizedBox(
                                          height: 24.w,
                                          width:
                                              MediaQuery.sizeOf(context).width,
                                        ),
                                        ConstrainedBox(
                                          constraints:
                                              BoxConstraints(maxHeight: 400.h),
                                          child: SingleChildScrollView(
                                            padding: EdgeInsets.fromLTRB(
                                                6.w, 0, 6.w, 0),
                                            physics: BouncingScrollPhysics(),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                SizedBox(
                                                  height: 1.w,
                                                  width:
                                                      MediaQuery.sizeOf(context)
                                                          .width,
                                                ),
                                                Container(
                                                  child: Text(
                                                    '내용',
                                                    style: TextStyle(
                                                        fontSize: 14.w),
                                                  ),
                                                  padding: EdgeInsets.only(
                                                      bottom: 4.w),
                                                  decoration: BoxDecoration(
                                                      border: Border(
                                                          bottom: BorderSide(
                                                              color: Color(
                                                                  0xFF51CF6D)))),
                                                ),
                                                SizedBox(height: 12.w),
                                                TextField(
                                                  controller: reportController,
                                                  minLines: 4,
                                                  maxLines: 8,
                                                  decoration: InputDecoration(
                                                      hintText:
                                                          '신고 내용을 입력해주세요.'),
                                                  onChanged: (value) {
                                                    reportReason = value;
                                                  },
                                                )
                                              ],
                                            ),
                                          ),
                                        ),
                                        SizedBox(height: 24.w),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceEvenly,
                                          children: [
                                            TextButton(
                                                onPressed: () {
                                                  Navigator.pop(context);
                                                },
                                                child: Text(
                                                  '취소하기',
                                                  style: TextStyle(
                                                    fontSize: 16.w,
                                                    color: Colors.grey,
                                                  ),
                                                )),
                                            SizedBox(width: 24.w),
                                            TextButton(
                                                onPressed: () async {
                                                  if (reportReason
                                                      .trim()
                                                      .isNotEmpty) {
                                                    await FirebaseFirestore
                                                        .instance
                                                        .collection('report')
                                                        .doc(
                                                            '${DateTime.now()}_${widget.user}')
                                                        .set({
                                                      'plaintiff': _user!.uid,
                                                      'defendant': widget.user,
                                                      'detail': reportReason,
                                                    });
                                                    Navigator.pop(context);
                                                    showDialog(
                                                        barrierDismissible:
                                                            true,
                                                        context: context,
                                                        builder: (BuildContext
                                                            context) {
                                                          return AlertDialog(
                                                            shape: RoundedRectangleBorder(
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            6.w)),
                                                            content: Text(
                                                                "신고 내용 전달완료\n신고해주셔서 감사합니다."),
                                                          );
                                                        });
                                                  } else {
                                                    showDialog(
                                                        barrierDismissible:
                                                            true,
                                                        context: context,
                                                        builder: (BuildContext
                                                            context) {
                                                          return AlertDialog(
                                                            shape: RoundedRectangleBorder(
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            6.w)),
                                                            content: Text(
                                                                "신고 내용이 없습니다."),
                                                          );
                                                        });
                                                  }
                                                },
                                                child: Text(
                                                  '신고하기',
                                                  style: TextStyle(
                                                    fontSize: 16.w,
                                                    color: Color(0xFFEF5350),
                                                  ),
                                                )),
                                          ],
                                        )
                                      ],
                                    ),
                                  );
                                });
                          },
                          child: Row(
                            children: [
                              Icon(
                                Icons.report,
                                color: Colors.grey,
                                size: 18.w,
                              ),
                              SizedBox(width: 4.w),
                              Text('신고하기',
                                  style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 14.w,
                                      decoration: TextDecoration.underline)),
                            ],
                          )),
                    ])
                  : SizedBox(height: 0),
              SizedBox(height: 18.w),
              bannerAd(),
              SizedBox(height: 12.w),
            ],
          ),
        ),
      ),
    );
  }
}
