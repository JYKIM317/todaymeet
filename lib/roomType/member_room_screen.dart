import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:famet/customProfile/people_Profile_View.dart';
import 'package:bottom_drawer/bottom_drawer.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'dart:io';

const fcmServerKey =
    'AAAA8cL90wc:APA91bF-RBJ3dRn0d_1uSIoJE1BNIzaA8weml0I-3xVH44Zshxqgo7342rmr5TT1JDE-aNNej6DekBinmbSTQ2llvBCBxE4EqHTSQ1x-UwxphCorQWAUcrb_c3jaNiQfEu04IhgETBQf';
Future<void> sendMessage({
  required String userToken,
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
          'to': userToken, // 'registration_ids': tokenList
          'content_available': true,
          'priority': 'high',
        }));
  } catch (e) {
    print('error $e');
  }
}

int requestNum = 0;

class MemberRoomPage extends StatefulWidget {
  final host;
  final bool inProgress;
  const MemberRoomPage({Key? key, required this.host, required this.inProgress})
      : super(key: key);

  @override
  State<MemberRoomPage> createState() => _MemberRoomPageState();
}

class _MemberRoomPageState extends State<MemberRoomPage> {
  late User? _user;
  late DocumentReference _roomAdressA, _roomAdressI, _requestAdress;
  late bool requestState = false, dontexitState = true;
  late List<dynamic> member = [],
      headcount = [],
      headcountPhoto = [],
      memberToken = [];
  late DateTime targetTime;
  BottomDrawerController attendController = BottomDrawerController();

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
    dontexitState = true;
    _user = FirebaseAuth.instance.currentUser;
    _roomAdressA = FirebaseFirestore.instance
        .collection('activateRoom')
        .doc('${widget.host}');
    _roomAdressI = FirebaseFirestore.instance
        .collection('inProgressRoom')
        .doc('${widget.host}');
    _requestAdress = FirebaseFirestore.instance
        .collection('users')
        .doc('${widget.host}')
        .collection('room')
        .doc('made');
    interstitialAd();
    super.initState();
  }

  @override
  void dispose() {
    _interstitialAd?.dispose();
    super.dispose();
  }

  Future<String> chatRoomName() async {
    final nameData = await _roomAdressA.get();
    final String chatRoom = await nameData.get('chatRoom');
    return chatRoom;
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
              stream: _roomAdressI.snapshots(),
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
                                                '${data['photoUrl']}'),
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
                                                      user: absentMember[
                                                          index])));
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
                                              userToken: memberToken[index],
                                              title: '오늘모임',
                                              body: '진행중인 모임에서 출석 인정을 받으셨습니다.');
                                          absentMember.removeAt(index);
                                          _roomAdressI
                                              .update({'absent': absentMember});
                                          _requestAdress
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
      body: Stack(
        children: [
          SingleChildScrollView(
            physics: BouncingScrollPhysics(),
            child: Padding(
              padding: EdgeInsets.fromLTRB(20.w, 32.w, 20.w, 10.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    child: InkWell(
                      child: Icon(Icons.arrow_back_ios,
                          color: Colors.grey, size: 18.w),
                      onTap: () {
                        Navigator.pop(context);
                      },
                    ),
                  ),
                  SizedBox(height: 24.w),
                  StreamBuilder<DocumentSnapshot>(
                      stream: widget.inProgress
                          ? _roomAdressI.snapshots()
                          : _roomAdressA.snapshots(),
                      builder: (BuildContext context,
                          AsyncSnapshot<DocumentSnapshot> snapshot) {
                        if (snapshot.hasError) return Text('오류가 발생했습니다.');
                        if (snapshot.connectionState == ConnectionState.waiting)
                          return Center(child: Text(''));
                        String? categoryTextH;
                        List<dynamic>? memberPhotoUrl = [];
                        Map<String, dynamic>? data =
                            snapshot.data?.data() as Map<String, dynamic>?;
                        if (data == null) {
                          return SizedBox(
                            width: MediaQuery.sizeOf(context).width,
                            height: MediaQuery.sizeOf(context).height - 60.w,
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
                        headcount = data['memberUID'];
                        member = headcount;
                        headcountPhoto = data['memberPhotoUrl'];
                        memberToken = data['memberTokenList'];
                        categoryTextH = data['Categories'].join('  ');
                        memberPhotoUrl = data['memberPhotoUrl'];
                        targetTime = DateTime(
                            data['targetYear'] as int,
                            data['targetMonth'] as int,
                            data['targetDay'] as int,
                            data['targetHour'] as int,
                            data['targetMinute'] as int);
                        return headcount.isNotEmpty
                            ? Column(
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
                                              '${data!['title']}',
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
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      fontSize: 12.w,
                                                    )),
                                                Text('${data['place']}',
                                                    style: TextStyle(
                                                        fontSize: 12.w))
                                              ],
                                            ),
                                            SizedBox(height: 4.w),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
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
                                            if (memberPhotoUrl!.length >= 1)
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
                              )
                            : Center(
                                child: Text('참가 한 방이 존재하지 않습니다.\n다시 확인해보세요',
                                    style: TextStyle(
                                      fontSize: 24.w,
                                      fontWeight: FontWeight.w700,
                                    )));
                      }),
                ],
              ),
            ),
          ),
          attendDrawer(context),
        ],
      ),
      bottomNavigationBar: widget.inProgress == false
          ? StreamBuilder<DocumentSnapshot>(
              stream: _requestAdress.snapshots(),
              builder: (BuildContext context,
                  AsyncSnapshot<DocumentSnapshot> snapshot) {
                if (snapshot.hasError) return Text('오류가 발생했습니다.');
                if (snapshot.connectionState == ConnectionState.waiting)
                  return Center(child: Text(''));
                Map<String, dynamic>? data =
                    snapshot.data?.data() as Map<String, dynamic>?;
                int? limitmember = data?['headcount'];
                List<dynamic>? membercount = data?['memberUID'];
                List<dynamic>? requestCheck = data?['requestUID'] ?? [];
                if (data == null) {
                  return SizedBox(height: 0);
                }
                return requestCheck!.contains('${_user!.uid}') != true
                    ? membercount?.contains('${_user!.uid}') != true
                        ? InkWell(
                            child: BottomAppBar(
                              height: 42.w,
                              color: Color(0xFF51CF6D),
                              child: Center(
                                child: Text('참가 신청하기',
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 18.w)),
                              ),
                            ),
                            onTap: () async {
                              requestNum++;
                              if (requestNum % 4 == 0) {
                                if (_interstitialAd != null)
                                  _interstitialAd?.show();
                              }
                              DateTime requestTime;
                              DocumentReference joinExist = FirebaseFirestore
                                  .instance
                                  .collection('users')
                                  .doc('${_user!.uid}')
                                  .collection('room')
                                  .doc('join');
                              Future<DocumentSnapshot> existData =
                                  joinExist.get();
                              dontexitState == true &&
                                      targetTime
                                              .difference(DateTime.now())
                                              .inMinutes <
                                          30
                                  ? showDialog(
                                      barrierDismissible: true,
                                      context: context,
                                      builder: (BuildContext context) {
                                        return AlertDialog(
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(6.w)),
                                          content: Text(
                                              "현재 신청하신 모임의 약속시간이\n30분내로 남아 들어가게 될 시\n모임탈퇴가 불가능합니다."),
                                          actions: [
                                            Center(
                                              child: TextButton(
                                                  child: Text('알겠습니다',
                                                      style: TextStyle(
                                                        color:
                                                            Color(0xFF51CF6D),
                                                        fontSize: 16.w,
                                                      )),
                                                  onPressed: () {
                                                    dontexitState = false;
                                                    Navigator.of(context).pop();
                                                  }),
                                            )
                                          ],
                                        );
                                      })
                                  : await existData.then((docSnapshot) async {
                                      docSnapshot.exists
                                          ? showDialog(
                                              barrierDismissible: true,
                                              context: context,
                                              builder: (BuildContext context) {
                                                return AlertDialog(
                                                  shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              6.w)),
                                                  content:
                                                      Text("모임은 하나만 가입 가능합니다."),
                                                );
                                              })
                                          : membercount!.length < limitmember!
                                              ? {
                                                  requestCheck.add(_user!.uid),
                                                  await _requestAdress.update({
                                                    'requestUID': requestCheck
                                                  }),
                                                  requestTime = DateTime(
                                                    DateTime.now().year,
                                                    DateTime.now().month,
                                                    DateTime.now().day,
                                                    DateTime.now().hour,
                                                    DateTime.now().minute,
                                                  ),
                                                  await FirebaseFirestore
                                                      .instance
                                                      .collection('users')
                                                      .doc('${widget.host}')
                                                      .collection(
                                                          'notification')
                                                      .doc(
                                                          '${requestTime}_${_user!.uid}')
                                                      .set({
                                                    'uid': _user!.uid,
                                                    'title': data['title'],
                                                    'timeStamp': requestTime,
                                                    'state': 'request',
                                                  }),
                                                  await sendMessage(
                                                      userToken: memberToken[0],
                                                      title: '오늘모임',
                                                      body: '새로운 가입 요청이 있습니다.'),
                                                }
                                              : showDialog(
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
                                                          "모임 인원 충족되어 신청할 수 없습니다."),
                                                    );
                                                  });
                                    });
                            },
                          )
                        : data!['hostUID'] != _user!.uid
                            ? InkWell(
                                child: BottomAppBar(
                                  height: 42.w,
                                  color: Color(0xFF51CF6D),
                                  child: Center(
                                    child: Text('모임 탈퇴하기',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 18.w)),
                                  ),
                                ),
                                onTap: () async {
                                  if (targetTime
                                          .difference(DateTime.now())
                                          .inMinutes >
                                      30) {
                                    final int indexToRemove =
                                        headcount.indexOf('${_user!.uid}');
                                    DateTime exitTime;
                                    headcount.removeAt(indexToRemove);
                                    headcountPhoto.removeAt(indexToRemove - 1);
                                    memberToken.removeAt(indexToRemove);
                                    final String chat = await chatRoomName();
                                    await _requestAdress.update({
                                      'memberUID': headcount,
                                      'memberPhotoUrl': headcountPhoto,
                                      'memberTokenList': memberToken,
                                    });
                                    await _roomAdressA.update({
                                      'memberUID': headcount,
                                      'memberPhotoUrl': headcountPhoto,
                                      'memberTokenList': memberToken,
                                    });
                                    exitTime = DateTime(
                                      DateTime.now().year,
                                      DateTime.now().month,
                                      DateTime.now().day,
                                      DateTime.now().hour,
                                      DateTime.now().minute,
                                    );
                                    await FirebaseFirestore.instance
                                        .collection('users')
                                        .doc('${widget.host}')
                                        .collection('notification')
                                        .doc('${exitTime}_${_user!.uid}')
                                        .set({
                                      'uid': _user!.uid,
                                      'title': data['title'],
                                      'timeStamp': exitTime,
                                      'state': 'exit',
                                    });
                                    await FirebaseFirestore.instance
                                        .collection('users')
                                        .doc('${_user!.uid}')
                                        .collection('room')
                                        .doc('join')
                                        .delete();
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
                                        .doc('info')
                                        .update({
                                      'member': headcount,
                                      'memberPhotoUrl': headcountPhoto,
                                      'memberTokenList': memberToken,
                                    });
                                    await sendMessage(
                                        userToken: memberToken[0],
                                        title: '오늘모임',
                                        body: '모임에서 일부 멤버가 탈퇴했습니다.');
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
                                                "약속시간 30분 전 부터는\n모임을 나갈 수 없습니다."),
                                          );
                                        });
                                  }
                                },
                              )
                            : BottomAppBar(
                                height: 42.w,
                                color: Colors.grey,
                                child: Center(
                                  child: Text('모임관리 페이지에서 확인해주세요 ',
                                      style: TextStyle(
                                          color: Colors.white, fontSize: 18.w)),
                                ),
                              )
                    : InkWell(
                        child: BottomAppBar(
                          height: 42.w,
                          color: Colors.grey,
                          child: Center(
                            child: Text('신청 중.. 다시 눌러 취소하기',
                                style: TextStyle(
                                    color: Colors.white, fontSize: 18.w)),
                          ),
                        ),
                        onTap: () async {
                          final int indexToRemove =
                              requestCheck.indexOf('${_user!.uid}');
                          requestCheck.removeAt(indexToRemove);
                          await _requestAdress
                              .update({'requestUID': requestCheck});
                        },
                      );
              })
          : InkWell(
              child: BottomAppBar(
                height: 42.w,
                color: Color(0xFF51CF6D),
                child: Center(
                  child: Text('출석체크',
                      style: TextStyle(color: Colors.white, fontSize: 18.w)),
                ),
              ),
              onTap: () {
                setState(() {});
                attendController.open();
              },
            ),
    );
  }
}
