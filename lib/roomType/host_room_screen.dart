import 'package:bottom_drawer/bottom_drawer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:famet/customProfile/people_Profile_View.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'dart:io';

User? _user = FirebaseAuth.instance.currentUser;
DocumentReference _roominfoM = FirebaseFirestore.instance
    .collection('users')
    .doc(_user!.uid)
    .collection('room')
    .doc('made');
DocumentReference _activeRoom =
    FirebaseFirestore.instance.collection('activateRoom').doc(_user!.uid);
DocumentReference _inProgressRoom =
    FirebaseFirestore.instance.collection('inProgressRoom').doc(_user!.uid);

const fcmServerKey =
    'AAAA8cL90wc:APA91bF-RBJ3dRn0d_1uSIoJE1BNIzaA8weml0I-3xVH44Zshxqgo7342rmr5TT1JDE-aNNej6DekBinmbSTQ2llvBCBxE4EqHTSQ1x-UwxphCorQWAUcrb_c3jaNiQfEu04IhgETBQf';
Future<void> sendMessage({
  required List<dynamic> userToken,
  required String title,
  required String body,
}) async {
  http.Response response;
  try {
    response = await http.post(Uri.parse('https://fcm.googleapis.com/fcm/send'),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': 'key=$fcmServerKey', //http v1으로 마이그레이션 해야함
        },
        body: jsonEncode({
          'notification': {
            'title': title,
            'body': body,
          },
          'data': {
            'click_action': 'FLUTTER_NOTIFICATION_CLICK',
            'id': '1',
            'status': 'app',
            "action": '테스트',
          },
          'registration_ids': userToken, // 'to': token
          'content_available': true,
          'priority': 'high',
        }));
  } catch (e) {
    print('error $e');
  }
}

class HostRoomPage extends StatefulWidget {
  const HostRoomPage({Key? key}) : super(key: key);
  @override
  State<HostRoomPage> createState() => _HostRoomPageState();
}

class _HostRoomPageState extends State<HostRoomPage> {
  List member = [], memberphoto = [], memberToken = [];
  BottomDrawerController requestController = BottomDrawerController();
  BottomDrawerController managementController = BottomDrawerController();
  BottomDrawerController attendController = BottomDrawerController();
  List<dynamic> requestUser = [];
  late int limitmember;
  late DateTime targetTime;
  late String roomTitle;

  InterstitialAd? _interstitialAd;
  void interstitialAd() {
    InterstitialAd.load(
        adUnitId: Platform.isAndroid
            ? 'ca-app-pub-3581534207395265/8086050879'
            : 'ca-app-pub-3581534207395265/2845849401',
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
          ? 'ca-app-pub-3581534207395265/4667295019'
          : 'ca-app-pub-3581534207395265/6785094412',
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
    _user = FirebaseAuth.instance.currentUser;
    _roominfoM = FirebaseFirestore.instance
        .collection('users')
        .doc(_user!.uid)
        .collection('room')
        .doc('made');
    _activeRoom =
        FirebaseFirestore.instance.collection('activateRoom').doc(_user!.uid);
    interstitialAd();
    super.initState();
  }

  @override
  void dispose() {
    _interstitialAd?.dispose();
    super.dispose();
  }

  Future<String> chatRoomName() async {
    final nameData = await _roominfoM.get();
    final String chatRoom = await nameData.get('chatRoom');
    return chatRoom;
  }

  Widget requestDrawer(BuildContext context) {
    return BottomDrawer(
      cornerRadius: 14.w,
      header: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: EdgeInsets.fromLTRB(14.w, 14.w, 0, 0),
            alignment: Alignment.centerLeft,
            color: Colors.transparent,
            child: Text('가입요청',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16.w,
                )),
          ),
          Container(
              padding: EdgeInsets.fromLTRB(0, 14.w, 14.w, 0),
              alignment: Alignment.centerRight,
              child: IconButton(
                  onPressed: () {
                    requestController.close();
                  },
                  icon: Icon(
                    Icons.close,
                    size: 24.w,
                  )))
        ],
      ),
      body: SingleChildScrollView(
        physics: BouncingScrollPhysics(),
        child: Padding(
          padding: EdgeInsets.fromLTRB(10.w, 14.w, 10.w, 0),
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: requestUser.length,
            itemBuilder: (BuildContext context, int index) {
              return FutureBuilder(
                  future: FirebaseFirestore.instance
                      .collection('users')
                      .doc('${requestUser[index]}')
                      .get(),
                  builder: (BuildContext context,
                      AsyncSnapshot<DocumentSnapshot> snapshot) {
                    if (snapshot.hasError) return Text('오류가 발생했습니다.');
                    if (snapshot.connectionState == ConnectionState.waiting)
                      return Center(child: Text(''));
                    Map<String, dynamic>? data =
                        snapshot.data?.data() as Map<String, dynamic>?;
                    if (data == null) return SizedBox(height: 0);
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        InkWell(
                          child: Container(
                            height: 40.w,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                SizedBox(width: 8.w),
                                CircleAvatar(
                                  backgroundColor: Colors.grey,
                                  radius: 24.w,
                                  backgroundImage:
                                      NetworkImage('${data['photoUrl']}'),
                                ),
                                SizedBox(width: 8.w),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text('${data['username']}',
                                            style: TextStyle(fontSize: 14.w)),
                                        SizedBox(width: 6.w),
                                        Text('${data['gender']}',
                                            style: TextStyle(
                                                color: Colors.grey,
                                                fontSize: 14.w)),
                                      ],
                                    ),
                                    Text(
                                      '${data['year']}.${data['month']}.${data['day']}',
                                      style: TextStyle(fontSize: 14.w),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          onTap: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => OtherProfile(
                                        user: requestUser[index])));
                          },
                        ),
                        Row(
                          children: [
                            InkWell(
                              child: Container(
                                alignment: Alignment.center,
                                width: 64.w,
                                height: 36.w,
                                decoration: BoxDecoration(
                                    color: Colors.transparent,
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(6.w)),
                                    border: Border.all(
                                      width: 1,
                                      color: Colors.grey,
                                    )),
                                child: Text(
                                  '거절',
                                  style: TextStyle(
                                      color: Colors.grey, fontSize: 18.w),
                                ),
                              ),
                              onTap: () async {
                                DateTime deniedTime = DateTime(
                                  DateTime.now().year,
                                  DateTime.now().month,
                                  DateTime.now().day,
                                  DateTime.now().hour,
                                  DateTime.now().minute,
                                );
                                await FirebaseFirestore.instance
                                    .collection('users')
                                    .doc('${requestUser[index]}')
                                    .collection('notification')
                                    .doc('${deniedTime}_${_user!.uid}')
                                    .set({
                                  'uid': _user!.uid,
                                  'title': roomTitle,
                                  'timeStamp': deniedTime,
                                  'state': 'denied',
                                });
                                requestUser.removeAt(index);
                                await _roominfoM
                                    .update({'requestUID': requestUser});
                                setState(() {});
                              },
                            ),
                            SizedBox(width: 18.w),
                            InkWell(
                              child: Container(
                                alignment: Alignment.center,
                                width: 64.w,
                                height: 36.w,
                                decoration: BoxDecoration(
                                  color: Color(0xFF51CF6D),
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(6.w)),
                                ),
                                child: Text(
                                  '수락',
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 18.w),
                                ),
                              ),
                              onTap: () async {
                                if (member.length < limitmember) {
                                  DocumentReference joinExist =
                                      FirebaseFirestore.instance
                                          .collection('users')
                                          .doc('${requestUser[index]}')
                                          .collection('room')
                                          .doc('join');
                                  Future<DocumentSnapshot> existData =
                                      joinExist.get();
                                  String chat;
                                  DateTime acceptTime;
                                  await existData.then((docSnapshot) async {
                                    docSnapshot.exists
                                        ? {
                                            requestUser.removeAt(index),
                                            await _roominfoM.update(
                                                {'requestUID': requestUser}),
                                            setState(() {}),
                                            showDialog(
                                                barrierDismissible: true,
                                                context: context,
                                                builder:
                                                    (BuildContext context) {
                                                  return AlertDialog(
                                                    shape:
                                                        RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        6.w)),
                                                    content: Text(
                                                        "대상이 이미 가입되어있는 모임이 존재합니다."),
                                                  );
                                                }),
                                          }
                                        : {
                                            chat = await chatRoomName(),
                                            member.add('${requestUser[index]}'),
                                            memberphoto
                                                .add('${data['photoUrl']}'),
                                            memberToken
                                                .add('${data['pushToken']}'),
                                            await _roominfoM.update({
                                              'memberUID': member,
                                              'memberPhotoUrl': memberphoto,
                                              'memberTokenList': memberToken,
                                            }),
                                            await _activeRoom.update({
                                              'memberUID': member,
                                              'memberPhotoUrl': memberphoto,
                                              'memberTokenList': memberToken,
                                            }),
                                            await FirebaseFirestore.instance
                                                .collection('users')
                                                .doc('${requestUser[index]}')
                                                .collection('room')
                                                .doc('join')
                                                .set({
                                              'hostUID': '${_user!.uid}'
                                            }),
                                            await FirebaseFirestore.instance
                                                .collection('users')
                                                .doc('${requestUser[index]}')
                                                .collection('chat')
                                                .doc(chat)
                                                .set({
                                              'read': 0,
                                              'recent':
                                                  DateTime(2099, 1, 1, 1, 1),
                                            }),
                                            await FirebaseFirestore.instance
                                                .collection('chatRoom')
                                                .doc('available')
                                                .collection(chat)
                                                .doc('info')
                                                .update({
                                              'member': member,
                                              'memberPhotoUrl': memberphoto,
                                              'memberTokenList': memberToken,
                                            }),
                                            acceptTime = DateTime(
                                              DateTime.now().year,
                                              DateTime.now().month,
                                              DateTime.now().day,
                                              DateTime.now().hour,
                                              DateTime.now().minute,
                                            ),
                                            await FirebaseFirestore.instance
                                                .collection('users')
                                                .doc('${requestUser[index]}')
                                                .collection('notification')
                                                .doc(
                                                    '${acceptTime}_${_user!.uid}')
                                                .set({
                                              'uid': _user!.uid,
                                              'title': roomTitle,
                                              'timeStamp': acceptTime,
                                              'state': 'accept',
                                            }),
                                            await sendMessage(
                                                userToken: [data['pushToken']],
                                                title: '오늘모임',
                                                body: '신청하신 모임에 가입되었습니다.'),
                                            requestUser.removeAt(index),
                                            await _roominfoM.update(
                                                {'requestUID': requestUser}),
                                            setState(() {}),
                                          };
                                  });
                                } else
                                  showDialog(
                                      barrierDismissible: true,
                                      context: context,
                                      builder: (BuildContext context) {
                                        return AlertDialog(
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(6.w)),
                                          content: Text("모임 인원이 가득 찼습니다."),
                                        );
                                      });
                              },
                            ),
                            SizedBox(width: 10.w),
                          ],
                        ),
                      ],
                    );
                  });
            },
            separatorBuilder: (context, index) {
              return SizedBox(height: 10.w);
            },
          ),
        ),
      ),
      headerHeight: 0,
      drawerHeight: 240.w,
      controller: requestController,
    );
  }

  Widget managementDrawer(BuildContext context) {
    return BottomDrawer(
      cornerRadius: 14.w,
      header: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: EdgeInsets.fromLTRB(14.w, 14.w, 0, 0),
            alignment: Alignment.centerLeft,
            color: Colors.transparent,
            child: Text('멤버관리',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16.w,
                )),
          ),
          Container(
              padding: EdgeInsets.fromLTRB(0, 14.w, 14.w, 0),
              alignment: Alignment.centerRight,
              child: IconButton(
                  onPressed: () {
                    managementController.close();
                  },
                  icon: Icon(
                    Icons.close,
                    size: 24.w,
                  )))
        ],
      ),
      body: SingleChildScrollView(
        physics: BouncingScrollPhysics(),
        child: Padding(
          padding: EdgeInsets.fromLTRB(10.w, 14.w, 10.w, 0),
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: member.length >= 2 ? member.length - 1 : 0,
            itemBuilder: (BuildContext context, int index) {
              return FutureBuilder(
                  future: FirebaseFirestore.instance
                      .collection('users')
                      .doc('${member[index + 1]}')
                      .get(),
                  builder: (BuildContext context,
                      AsyncSnapshot<DocumentSnapshot> snapshot) {
                    if (snapshot.hasError) return Text('오류가 발생했습니다.');
                    if (snapshot.connectionState == ConnectionState.waiting)
                      return Center(child: Text(''));
                    Map<String, dynamic>? data =
                        snapshot.data?.data() as Map<String, dynamic>?;
                    if (data == null) return SizedBox(height: 0);
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        InkWell(
                          child: Container(
                            height: 40.w,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                SizedBox(width: 8.w),
                                CircleAvatar(
                                  backgroundColor: Colors.grey,
                                  radius: 24.w,
                                  backgroundImage:
                                      NetworkImage('${data['photoUrl']}'),
                                ),
                                SizedBox(width: 8.w),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text('${data['username']}',
                                            style: TextStyle(fontSize: 14.w)),
                                        SizedBox(width: 6.w),
                                        Text('${data['gender']}',
                                            style: TextStyle(
                                                color: Colors.grey,
                                                fontSize: 14.w)),
                                      ],
                                    ),
                                    Text(
                                      '${data['year']}.${data['month']}.${data['day']}',
                                      style: TextStyle(fontSize: 14.w),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          onTap: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        OtherProfile(user: member[index + 1])));
                          },
                        ),
                        Row(
                          children: [
                            InkWell(
                              child: Container(
                                alignment: Alignment.center,
                                width: 64.w,
                                height: 36.w,
                                decoration: BoxDecoration(
                                    color: Colors.transparent,
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(6.w)),
                                    border: Border.all(
                                      width: 1,
                                      color: Colors.grey,
                                    )),
                                child: Text(
                                  '내보내기',
                                  style: TextStyle(
                                      color: Colors.grey, fontSize: 14.w),
                                ),
                              ),
                              onTap: () async {
                                if (targetTime
                                        .difference(DateTime.now())
                                        .inMinutes >
                                    30) {
                                  final String chat = await chatRoomName();
                                  await FirebaseFirestore.instance
                                      .collection('users')
                                      .doc('${member[index + 1]}')
                                      .collection('room')
                                      .doc('join')
                                      .delete();
                                  await FirebaseFirestore.instance
                                      .collection('users')
                                      .doc('${member[index + 1]}')
                                      .collection('chat')
                                      .doc(chat)
                                      .delete();
                                  DateTime kickTime = DateTime(
                                    DateTime.now().year,
                                    DateTime.now().month,
                                    DateTime.now().day,
                                    DateTime.now().hour,
                                    DateTime.now().minute,
                                  );
                                  await FirebaseFirestore.instance
                                      .collection('users')
                                      .doc('${member[index + 1]}')
                                      .collection('notification')
                                      .doc('${kickTime}_${_user!.uid}')
                                      .set({
                                    'uid': _user!.uid,
                                    'title': roomTitle,
                                    'timeStamp': kickTime,
                                    'state': 'kick',
                                  });
                                  await sendMessage(
                                      userToken: [memberToken[index + 1]],
                                      title: '오늘모임',
                                      body: '가입하신 모임에서 내보내기 되었습니다.');
                                  member.removeAt(index + 1);
                                  memberToken.removeAt(index + 1);
                                  memberphoto.removeAt(index);
                                  await FirebaseFirestore.instance
                                      .collection('chatRoom')
                                      .doc('available')
                                      .collection(chat)
                                      .doc('info')
                                      .update({
                                    'member': member,
                                    'memberPhotoUrl': memberphoto,
                                    'memberTokenList': memberToken,
                                  });
                                  await _roominfoM.update({
                                    'memberUID': member,
                                    'memberPhotoUrl': memberphoto,
                                    'memberTokenList': memberToken,
                                  });
                                  await _activeRoom.update({
                                    'memberUID': member,
                                    'memberPhotoUrl': memberphoto,
                                    'memberTokenList': memberToken,
                                  });
                                  setState(() {});
                                } else {
                                  showDialog(
                                      barrierDismissible: true,
                                      context: context,
                                      builder: (BuildContext context) {
                                        return AlertDialog(
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(6.w)),
                                          content: Text(
                                              "약속시간 30분 전 부터는\n멤버를 내보낼 수 없습니다."),
                                        );
                                      });
                                }
                              },
                            ),
                            SizedBox(width: 10.w),
                          ],
                        ),
                      ],
                    );
                  });
            },
            separatorBuilder: (context, index) {
              return SizedBox(height: 10.w);
            },
          ),
        ),
      ),
      headerHeight: 0,
      drawerHeight: 240.w,
      controller: managementController,
    );
  }

  Widget attendDrawer(BuildContext context) {
    return BottomDrawer(
      cornerRadius: 14.w,
      header: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: EdgeInsets.fromLTRB(14.w, 14.w, 0, 0),
            alignment: Alignment.centerLeft,
            color: Colors.transparent,
            child: Text('출석체크',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16.w,
                )),
          ),
          Container(
              padding: EdgeInsets.fromLTRB(0, 14.w, 14.w, 0),
              alignment: Alignment.centerRight,
              child: IconButton(
                  onPressed: () {
                    attendController.close();
                  },
                  icon: Icon(
                    Icons.close,
                    size: 24.w,
                  )))
        ],
      ),
      body: SingleChildScrollView(
        physics: BouncingScrollPhysics(),
        child: Padding(
          padding: EdgeInsets.fromLTRB(10.w, 14.w, 10.w, 0),
          child: StreamBuilder<DocumentSnapshot>(
              stream: _roominfoM.snapshots(),
              builder: (BuildContext context,
                  AsyncSnapshot<DocumentSnapshot> snapshot) {
                if (snapshot.hasError) return Text('');
                if (snapshot.connectionState == ConnectionState.waiting)
                  return Text('');
                Map<String, dynamic>? roominfo =
                    snapshot.data?.data() as Map<String, dynamic>?;
                if (roominfo == null) return SizedBox(height: 0);
                List absentMember = roominfo['absent'];
                if (absentMember.isEmpty) return SizedBox(height: 0);
                return ListView.separated(
                  shrinkWrap: true,
                  itemCount: absentMember.length,
                  itemBuilder: (BuildContext context, int index) {
                    return absentMember[index] != _user!.uid
                        ? FutureBuilder(
                            future: FirebaseFirestore.instance
                                .collection('users')
                                .doc('${absentMember[index]}')
                                .get(),
                            builder: (BuildContext context,
                                AsyncSnapshot<DocumentSnapshot> snapshot) {
                              if (snapshot.hasError) return Text('오류가 발생했습니다.');
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting)
                                return Center(child: Text(''));
                              Map<String, dynamic>? data = snapshot.data?.data()
                                  as Map<String, dynamic>?;
                              if (data == null) return SizedBox(height: 0);
                              return Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  InkWell(
                                    child: SizedBox(
                                      height: 40.w,
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        children: [
                                          SizedBox(width: 8.w),
                                          CircleAvatar(
                                            backgroundColor: Colors.grey,
                                            radius: 24.w,
                                            backgroundImage: NetworkImage(
                                                '${data!['photoUrl']}'),
                                          ),
                                          SizedBox(width: 8.w),
                                          Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Text('${data['username']}',
                                                      style: TextStyle(
                                                          fontSize: 14.w)),
                                                  SizedBox(width: 6.w),
                                                  Text('${data['gender']}',
                                                      style: TextStyle(
                                                          color: Colors.grey,
                                                          fontSize: 14.w)),
                                                ],
                                              ),
                                              Text(
                                                '${data['year']}.${data['month']}.${data['day']}',
                                                style:
                                                    TextStyle(fontSize: 14.w),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    onTap: () {
                                      Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) =>
                                                  OtherProfile(
                                                      user: member[index])));
                                    },
                                  ),
                                  Row(
                                    children: [
                                      InkWell(
                                        child: Container(
                                          alignment: Alignment.center,
                                          width: 90.w,
                                          height: 36.w,
                                          decoration: BoxDecoration(
                                              color: Colors.transparent,
                                              borderRadius: BorderRadius.all(
                                                  Radius.circular(6.w)),
                                              border: Border.all(
                                                width: 1,
                                                color: Colors.grey,
                                              )),
                                          child: Text(
                                            '출석확인',
                                            style: TextStyle(
                                                color: Colors.grey,
                                                fontSize: 14.w),
                                          ),
                                        ),
                                        onTap: () async {
                                          await sendMessage(
                                              userToken: [
                                                memberToken[index + 1]
                                              ],
                                              title: '오늘모임',
                                              body: '진행중인 모임에서 출석 인정을 받으셨습니다.');
                                          absentMember.removeAt(index);
                                          _inProgressRoom
                                              .update({'absent': absentMember});
                                          _roominfoM
                                              .update({'absent': absentMember});
                                        },
                                      ),
                                      SizedBox(width: 10.w),
                                    ],
                                  ),
                                ],
                              );
                            })
                        : SizedBox(height: 0);
                  },
                  separatorBuilder: (context, index) {
                    return SizedBox(height: 10.w);
                  },
                );
              }),
        ),
      ),
      headerHeight: 0,
      drawerHeight: 240.w,
      controller: attendController,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: GestureDetector(
          onTap: () {
            requestController.close();
            managementController.close();
          },
          child: Stack(
            children: [
              SingleChildScrollView(
                physics: BouncingScrollPhysics(),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20.w, 32.w, 20.w, 10.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                      StreamBuilder<DocumentSnapshot>(
                          stream: _roominfoM.snapshots(),
                          builder: (BuildContext context,
                              AsyncSnapshot<DocumentSnapshot> snapshot) {
                            if (snapshot.hasError) return Text('오류가 발생했습니다.');
                            if (snapshot.connectionState ==
                                ConnectionState.waiting)
                              return Center(child: Text(''));
                            Map<String, dynamic>? data =
                                snapshot.data?.data() as Map<String, dynamic>?;
                            if (data == null) {
                              return SizedBox(
                                width: MediaQuery.sizeOf(context).width,
                                height:
                                    MediaQuery.sizeOf(context).height - 60.w,
                                child: Center(
                                  child: Text(
                                    '방이 존재하지 않습니다.',
                                    style: TextStyle(
                                      fontSize: 22.w,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                              );
                            }
                            List<dynamic> headcount = data['memberUID'];
                            member = headcount;
                            requestUser = data['requestUID'] ?? [];
                            String? categoryTextH =
                                data['Categories'].join('  ');
                            List<dynamic> memberPhotoUrl =
                                data['memberPhotoUrl'];
                            List<dynamic> memberTokenList =
                                data['memberTokenList'];
                            limitmember = data['headcount'];
                            memberphoto = memberPhotoUrl;
                            memberToken = memberTokenList;
                            roomTitle = data['title'];
                            targetTime = DateTime(
                                data['targetYear'] as int,
                                data['targetMonth'] as int,
                                data['targetDay'] as int,
                                data['targetHour'] as int,
                                data['targetMinute'] as int);
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                      border: Border(
                                          bottom: BorderSide(
                                              color: Color(0xFF51CF6D),
                                              width: 1))),
                                  child: Padding(
                                    padding: EdgeInsets.all(10.w),
                                    child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '${data['title']}',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 16.w,
                                            ),
                                          ),
                                          SizedBox(height: 10.w),
                                          Row(
                                            children: [
                                              Text('장소: ',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w700,
                                                    fontSize: 12.w,
                                                  )),
                                              Text('${data['place']}',
                                                  style:
                                                      TextStyle(fontSize: 12.w))
                                            ],
                                          ),
                                          SizedBox(height: 4.w),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Row(
                                                children: [
                                                  Text('약속시간: ',
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.w700,
                                                        fontSize: 12.w,
                                                      )),
                                                  Text(
                                                      '${data['targetYear']}년${data['targetMonth']}월${data['targetDay']}일 ${data['targetHour']}:${data['targetMinute'].toString().length == 1 ? '0${data['targetMinute']}' : data['targetMinute']}',
                                                      style: TextStyle(
                                                          fontSize: 12.w))
                                                ],
                                              ),
                                              Row(
                                                children: [
                                                  Text('인원: ',
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.w700,
                                                        fontSize: 12.w,
                                                      )),
                                                  Text(
                                                      '${headcount.length}/${data['headcount']}',
                                                      style: TextStyle(
                                                          fontSize: 12.w))
                                                ],
                                              ),
                                            ],
                                          ),
                                        ]),
                                  ),
                                ),
                                Container(
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                      border: Border(
                                          bottom: BorderSide(
                                              color: Color(0xFF51CF6D),
                                              width: 1))),
                                  child: Padding(
                                    padding: EdgeInsets.fromLTRB(
                                        10.w, 20.w, 10.w, 20.w),
                                    child: Text('${data['info']}',
                                        style: TextStyle(fontSize: 12.w)),
                                  ),
                                ),
                                Container(
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                      border: Border(
                                          bottom: BorderSide(
                                              color: Color(0xFF51CF6D),
                                              width: 1))),
                                  child: Padding(
                                    padding: EdgeInsets.fromLTRB(
                                        10.w, 20.w, 10.w, 10.w),
                                    child: Text('$categoryTextH',
                                        style: TextStyle(fontSize: 12.w)),
                                  ),
                                ),
                                SizedBox(height: 24.w),
                                Container(
                                  padding: EdgeInsets.all(5.w),
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                      border: Border(
                                          bottom: BorderSide(
                                              color: Color(0xFF51CF6D),
                                              width: 1))),
                                  child: Row(
                                    children: [
                                      Text(
                                        '현재 참가중인 멤버',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 12.w,
                                        ),
                                      ),
                                      SizedBox(width: 4.w),
                                      Text(
                                        '사진을 클릭하여 프로필 보기',
                                        style: TextStyle(
                                          fontSize: 8.w,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.all(10.w),
                                  child: Column(
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        children: [
                                          InkWell(
                                            child: CircleAvatar(
                                              backgroundColor: Colors.grey,
                                              radius: 34.w,
                                              backgroundImage: NetworkImage(
                                                  '${data['hostPhotoUrl']}'),
                                            ),
                                            onTap: () {
                                              Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                      builder: (context) =>
                                                          OtherProfile(
                                                              user: data[
                                                                  'hostUID'])));
                                            }, //해당 유저 프로필로 이동
                                          ),
                                          SizedBox(width: 8.w),
                                          if (memberPhotoUrl.length >= 1)
                                            InkWell(
                                              child: CircleAvatar(
                                                backgroundColor: Colors.grey,
                                                radius: 34.w,
                                                backgroundImage: NetworkImage(
                                                    '${data['memberPhotoUrl'][0]}'),
                                              ),
                                              onTap: () {
                                                Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                        builder: (context) =>
                                                            OtherProfile(
                                                                user: data[
                                                                        'memberUID']
                                                                    [1])));
                                              }, //해당 유저 프로필로 이동
                                            ),
                                          SizedBox(width: 8.w),
                                          if (memberPhotoUrl.length >= 2)
                                            InkWell(
                                              child: CircleAvatar(
                                                backgroundColor: Colors.grey,
                                                radius: 34.w,
                                                backgroundImage: NetworkImage(
                                                    '${data['memberPhotoUrl'][1]}'),
                                              ),
                                              onTap: () {
                                                Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                        builder: (context) =>
                                                            OtherProfile(
                                                                user: data[
                                                                        'memberUID']
                                                                    [2])));
                                              }, //해당 유저 프로필로 이동
                                            ),
                                          SizedBox(width: 8.w),
                                          if (memberPhotoUrl.length >= 3)
                                            InkWell(
                                              child: CircleAvatar(
                                                backgroundColor: Colors.grey,
                                                radius: 34.w,
                                                backgroundImage: NetworkImage(
                                                    '${data['memberPhotoUrl'][2]}'),
                                              ),
                                              onTap: () {
                                                Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                        builder: (context) =>
                                                            OtherProfile(
                                                                user: data[
                                                                        'memberUID']
                                                                    [3])));
                                              }, //해당 유저 프로필로 이동
                                            ),
                                        ],
                                      ),
                                      SizedBox(height: 8.w),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        children: [
                                          if (memberPhotoUrl.length >= 4)
                                            InkWell(
                                              child: CircleAvatar(
                                                backgroundColor: Colors.grey,
                                                radius: 34.w,
                                                backgroundImage: NetworkImage(
                                                    '${data['memberPhotoUrl'][3]}'),
                                              ),
                                              onTap: () {
                                                Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                        builder: (context) =>
                                                            OtherProfile(
                                                                user: data[
                                                                        'memberUID']
                                                                    [4])));
                                              }, //해당 유저 프로필로 이동
                                            ),
                                          SizedBox(width: 8.w),
                                          if (memberPhotoUrl.length >= 5)
                                            InkWell(
                                              child: CircleAvatar(
                                                backgroundColor: Colors.grey,
                                                radius: 34.w,
                                                backgroundImage: NetworkImage(
                                                    '${data['memberPhotoUrl'][4]}'),
                                              ),
                                              onTap: () {
                                                Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                        builder: (context) =>
                                                            OtherProfile(
                                                                user: data[
                                                                        'memberUID']
                                                                    [5])));
                                              }, //해당 유저 프로필로 이동
                                            ),
                                          SizedBox(width: 8.w),
                                          if (memberPhotoUrl.length >= 6)
                                            InkWell(
                                              child: CircleAvatar(
                                                backgroundColor: Colors.grey,
                                                radius: 34.w,
                                                backgroundImage: NetworkImage(
                                                    '${data['memberPhotoUrl'][5]}'),
                                              ),
                                              onTap: () {
                                                Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                        builder: (context) =>
                                                            OtherProfile(
                                                                user: data[
                                                                        'memberUID']
                                                                    [6])));
                                              }, //해당 유저 프로필로 이동
                                            ),
                                          SizedBox(width: 8.w),
                                          if (memberPhotoUrl.length >= 7)
                                            InkWell(
                                              child: CircleAvatar(
                                                backgroundColor: Colors.grey,
                                                radius: 34.w,
                                                backgroundImage: NetworkImage(
                                                    '${data['memberPhotoUrl'][6]}'),
                                              ),
                                              onTap: () {
                                                Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                        builder: (context) =>
                                                            OtherProfile(
                                                                user: data[
                                                                        'memberUID']
                                                                    [7])));
                                              }, //해당 유저 프로필로 이동
                                            ),
                                        ],
                                      ),
                                      SizedBox(height: 8.w),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        children: [
                                          if (memberPhotoUrl.length >= 8)
                                            InkWell(
                                              child: CircleAvatar(
                                                backgroundColor: Colors.grey,
                                                radius: 34.w,
                                                backgroundImage: NetworkImage(
                                                    '${data['memberPhotoUrl'][7]}'),
                                              ),
                                              onTap: () {
                                                Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                        builder: (context) =>
                                                            OtherProfile(
                                                                user: data[
                                                                        'memberUID']
                                                                    [8])));
                                              }, //해당 유저 프로필로 이동
                                            ),
                                          SizedBox(width: 8.w),
                                          if (memberPhotoUrl.length >= 9)
                                            InkWell(
                                              child: CircleAvatar(
                                                backgroundColor: Colors.grey,
                                                radius: 34.w,
                                                backgroundImage: NetworkImage(
                                                    '${data['memberPhotoUrl'][8]}'),
                                              ),
                                              onTap: () {
                                                Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                        builder: (context) =>
                                                            OtherProfile(
                                                                user: data[
                                                                        'memberUID']
                                                                    [9])));
                                              }, //해당 유저 프로필로 이동
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: 12.w),
                                bannerAd(),
                              ],
                            );
                          }),
                    ],
                  ),
                ),
              ),
              requestDrawer(context),
              managementDrawer(context),
              attendDrawer(context),
            ],
          ),
        ),
        bottomNavigationBar: StreamBuilder<DocumentSnapshot>(
          stream: _roominfoM.snapshots(),
          builder:
              (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot) {
            if (snapshot.hasError) return Text('오류가 발생했습니다.');
            if (snapshot.connectionState == ConnectionState.waiting)
              return Text('');
            Map<String, dynamic>? data =
                snapshot.data?.data() as Map<String, dynamic>?;
            if (data == null) {
              return SizedBox(height: 0);
            }
            return !data['inProgress']
                ? BottomAppBar(
                    height: 42.w,
                    color: Color(0xFF51CF6D),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        InkWell(
                          child: SizedBox(
                            child: Text('모임해체',
                                style: TextStyle(
                                    color: Colors.white, fontSize: 18.w)),
                          ),
                          onTap: () async {
                            showDialog(
                                barrierDismissible: true,
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(6.w)),
                                    content: Row(
                                      children: [
                                        Text("정말 모임을 "),
                                        Text(
                                          "해체",
                                          style: TextStyle(
                                              color: Color(0xFFEF5350)),
                                        ),
                                        Text("하시겠습니까?"),
                                      ],
                                    ),
                                    actions: [
                                      TextButton(
                                          child: Text('취소',
                                              style: TextStyle(
                                                  color: Color(0xFF51CF6D))),
                                          onPressed: () {
                                            Navigator.pop(context);
                                          }),
                                      TextButton(
                                          child: Text('해체',
                                              style: TextStyle(
                                                  color: Color(0xFFEF5350))),
                                          onPressed: () async {
                                            if (_interstitialAd != null)
                                              _interstitialAd?.show();
                                            final String chat =
                                                await chatRoomName();
                                            if (targetTime
                                                        .difference(
                                                            DateTime.now())
                                                        .inMinutes >
                                                    30 ||
                                                member.length == 1) {
                                              final dismissTime = DateTime(
                                                DateTime.now().year,
                                                DateTime.now().month,
                                                DateTime.now().day,
                                                DateTime.now().hour,
                                                DateTime.now().minute,
                                              );
                                              for (int i = 1;
                                                  i < member.length;
                                                  i++) {
                                                await FirebaseFirestore.instance
                                                    .collection('users')
                                                    .doc('${member[i]}')
                                                    .collection('room')
                                                    .doc('join')
                                                    .delete();
                                                await FirebaseFirestore.instance
                                                    .collection('users')
                                                    .doc('${member[i]}')
                                                    .collection('chat')
                                                    .doc(chat)
                                                    .delete();
                                                await FirebaseFirestore.instance
                                                    .collection('users')
                                                    .doc('${member[i]}')
                                                    .collection('notification')
                                                    .doc(
                                                        '${dismissTime}_${_user!.uid}')
                                                    .set({
                                                  'uid': _user!.uid,
                                                  'title': data['title'],
                                                  'timeStamp': dismissTime,
                                                  'state': 'dismiss',
                                                });
                                              }
                                              await FirebaseFirestore.instance
                                                  .collection('users')
                                                  .doc('${_user!.uid}')
                                                  .collection('chat')
                                                  .doc(chat)
                                                  .delete();
                                              await FirebaseFirestore.instance
                                                  .collection('chatRoom')
                                                  .doc('available')
                                                  .collection(chat)
                                                  .get()
                                                  .then((snapshot) {
                                                for (DocumentSnapshot doc
                                                    in snapshot.docs) {
                                                  doc.reference.delete();
                                                }
                                              });
                                              await sendMessage(
                                                  userToken: memberToken,
                                                  title: '오늘모임',
                                                  body: '가입하신 모임이 해체되었습니다.');
                                              await _activeRoom.delete();
                                              await _roominfoM.delete();
                                              Navigator.pop(context);
                                              Navigator.pop(context);
                                              setState(() {});
                                              await showDialog(
                                                  barrierDismissible: true,
                                                  context: context,
                                                  builder:
                                                      (BuildContext context) {
                                                    return AlertDialog(
                                                      shape:
                                                          RoundedRectangleBorder(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          6.w)),
                                                      content:
                                                          Text("모임이 해체되었습니다."),
                                                    );
                                                  });
                                            } else {
                                              Navigator.pop(context);
                                              showDialog(
                                                  barrierDismissible: true,
                                                  context: context,
                                                  builder:
                                                      (BuildContext context) {
                                                    return AlertDialog(
                                                      shape:
                                                          RoundedRectangleBorder(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          6.w)),
                                                      content: Text(
                                                          "약속시간 30분 전 부터는\n모임을 해체 할 수 없습니다."),
                                                    );
                                                  });
                                            }
                                          })
                                    ],
                                  );
                                });
                          },
                        ),
                        Container(
                          width: 1,
                          height: 32.w,
                          color: Colors.white,
                        ),
                        InkWell(
                          child: SizedBox(
                            child: Text('요청확인',
                                style: TextStyle(
                                    color: Colors.white, fontSize: 18.w)),
                          ),
                          onTap: () {
                            setState(() {});
                            requestController.open();
                            managementController.close();
                          },
                        ),
                        Container(
                          width: 1,
                          height: 32.w,
                          color: Colors.white,
                        ),
                        InkWell(
                          child: SizedBox(
                            child: Text('멤버관리',
                                style: TextStyle(
                                    color: Colors.white, fontSize: 18.w)),
                          ),
                          onTap: () {
                            setState(() {});
                            managementController.open();
                            requestController.close();
                          },
                        ),
                      ],
                    ),
                  )
                : InkWell(
                    child: BottomAppBar(
                      height: 42.w,
                      color: Color(0xFF51CF6D),
                      child: Center(
                        child: Text('출석체크',
                            style:
                                TextStyle(color: Colors.white, fontSize: 18.w)),
                      ),
                    ),
                    onTap: () {
                      setState(() {});
                      attendController.open();
                    },
                  );
          },
        ));
  }
}
