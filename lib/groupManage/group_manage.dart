import 'dart:math';
import 'package:flutter/material.dart';
import 'build_group.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:famet/roomType/host_room_screen.dart';
import 'package:famet/roomType/member_room_screen.dart';
import 'package:famet/roomType/done_room_screen.dart';
import 'package:flutter_progress_hud/flutter_progress_hud.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_analytics/firebase_analytics.dart';

User? _user = FirebaseAuth.instance.currentUser;
DocumentReference _roominfoM = FirebaseFirestore.instance
    .collection('users')
    .doc(_user!.uid)
    .collection('room')
    .doc('made');
DocumentReference _roominfoJ = FirebaseFirestore.instance
    .collection('users')
    .doc(_user!.uid)
    .collection('room')
    .doc('join');
DocumentReference _roominfoA = FirebaseFirestore.instance
    .collection('users')
    .doc(_user!.uid)
    .collection('room')
    .doc('attention');
var _activeRoom = FirebaseFirestore.instance.collection('activateRoom');
var _inProgressRoom = FirebaseFirestore.instance.collection('inProgressRoom');
var _doneRoom = FirebaseFirestore.instance
    .collection('users')
    .doc(_user!.uid)
    .collection('done');

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

class GroupManagePage extends StatefulWidget {
  const GroupManagePage({Key? key}) : super(key: key);

  @override
  State<GroupManagePage> createState() => _GroupManagePageState();
}

class _GroupManagePageState extends State<GroupManagePage> {
  bool roomStateM = true, roomStateJ = false, roomStateI = false;
  bool viewState = true;

  FirebaseAnalytics analytics = FirebaseAnalytics.instance;

  @override
  void initState() {
    _user = FirebaseAuth.instance.currentUser;
    _roominfoM = FirebaseFirestore.instance
        .collection('users')
        .doc(_user!.uid)
        .collection('room')
        .doc('made');
    _roominfoJ = FirebaseFirestore.instance
        .collection('users')
        .doc(_user!.uid)
        .collection('room')
        .doc('join');
    _roominfoA = FirebaseFirestore.instance
        .collection('users')
        .doc(_user!.uid)
        .collection('room')
        .doc('attention');
    _doneRoom = FirebaseFirestore.instance
        .collection('users')
        .doc(_user!.uid)
        .collection('done');
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final progress = ProgressHUD.of(context);
    return Column(
      children: [
        SizedBox(height: 20.w),
        SizedBox(
          width: double.infinity,
          child:
              Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            Expanded(
              flex: 1,
              child: Container(
                decoration: BoxDecoration(
                    border: Border(
                        bottom: viewState == true
                            ? BorderSide(
                                color: Color(0xFF51CF6D),
                                width: 2,
                              )
                            : BorderSide(
                                color: Colors.grey,
                                width: 1,
                              ))),
                child: TextButton(
                    onPressed: () {
                      viewState = true;
                      setState(() {});
                    },
                    child: Text('참가모임',
                        style: viewState == true
                            ? TextStyle(
                                fontSize: 14.w,
                                fontWeight: FontWeight.w700,
                              )
                            : TextStyle(
                                fontSize: 14.w,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey))),
              ),
            ),
            Expanded(
              flex: 1,
              child: Container(
                decoration: BoxDecoration(
                    border: Border(
                        bottom: viewState == false
                            ? BorderSide(
                                color: Color(0xFF51CF6D),
                                width: 2,
                              )
                            : BorderSide(
                                color: Colors.grey,
                                width: 1,
                              ))),
                child: TextButton(
                    onPressed: () {
                      viewState = false;
                      setState(() {});
                    },
                    child: Text('참가내역',
                        style: viewState == false
                            ? TextStyle(
                                fontSize: 14.w,
                                fontWeight: FontWeight.w700,
                              )
                            : TextStyle(
                                fontSize: 14.w,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey))),
              ),
            )
          ]),
        ),
        Expanded(
          child: SingleChildScrollView(
            physics: BouncingScrollPhysics(),
            child: Padding(
              padding: EdgeInsets.fromLTRB(15.w, 15.w, 15.w, 10.w),
              child: viewState == true
                  ? Column(
                      mainAxisSize: MainAxisSize.max,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 10.w),
                        Container(
                            height: 34.w,
                            alignment: Alignment.centerLeft,
                            width: double.infinity,
                            decoration: BoxDecoration(
                                border: Border(
                                    bottom: BorderSide(
                                        color: Color(0xFF51CF6D), width: 1))),
                            child: Row(
                              children: [
                                Text('참가중인 모임',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16.w,
                                    )),
                                SizedBox(width: 4.w),
                                TextButton(
                                    onPressed: () async {
                                      if (roomStateM == false) {
                                        progress?.show();
                                        await FirebaseAnalytics.instance
                                            .logEvent(
                                                name: 'Create_BuildGroup');
                                        await Future.delayed(
                                            Duration(seconds: 1), () {
                                          progress?.dismiss();
                                        });
                                        await Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (context) =>
                                                    ProgressHUD(
                                                        child:
                                                            BuildGroupPage())));
                                        setState(() {});
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
                                                content:
                                                    Text("모임은 한 개만 생성 가능합니다."),
                                              );
                                            });
                                      }
                                    },
                                    child: Text(
                                      '모임 개설하기 +',
                                      style: TextStyle(
                                          color: Colors.grey, fontSize: 12.w),
                                    ))
                              ],
                            )),
                        SizedBox(height: 10.w),
                        StreamBuilder<DocumentSnapshot>(
                          stream: _roominfoM.snapshots(),
                          builder: (BuildContext context,
                              AsyncSnapshot<DocumentSnapshot> snapshot) {
                            if (snapshot.hasError) return Text('오류가 발생했습니다.');
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) return Text('');
                            Map<String, dynamic>? data =
                                snapshot.data?.data() as Map<String, dynamic>?;
                            data == null
                                ? roomStateM = false
                                : roomStateM = true;
                            String? categoryTextH;
                            if (data == null) return SizedBox(height: 0);
                            List<dynamic> headcount = data['memberUID'] ?? [];
                            categoryTextH = data['Categories'].join('  ');
                            final targetTime = DateTime(
                                data['targetYear'] == null
                                    ? 9999
                                    : data['targetYear'] as int,
                                data['targetMonth'] == null
                                    ? 12
                                    : data['targetMonth'] as int,
                                data['targetDay'] == null
                                    ? 31
                                    : data['targetDay'] as int,
                                data['targetHour'] == null
                                    ? 23
                                    : data['targetHour'] as int,
                                data['targetMinute'] == null
                                    ? 59
                                    : data['targetMinute'] as int);
                            if (targetTime.isBefore(DateTime.now()) &&
                                headcount.length == 1) {
                              FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(_user!.uid)
                                  .collection('notification')
                                  .doc('${targetTime}_${data['hostUID']}')
                                  .set({
                                'uid': data['hostUID'],
                                'title': data['title'],
                                'timeStamp': targetTime,
                                'state': 'notEnough',
                              });
                              FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(_user!.uid)
                                  .collection('chat')
                                  .doc('${data['chatRoom']}')
                                  .delete();
                              FirebaseFirestore.instance
                                  .collection('chatRoom')
                                  .doc('available')
                                  .collection('${data['chatRoom']}')
                                  .get()
                                  .then((snapshot) {
                                for (DocumentSnapshot doc in snapshot.docs) {
                                  doc.reference.delete();
                                }
                              });
                              sendMessage(
                                userToken: data['memberTokenList'],
                                title: '오늘모임',
                                body: '개설하신 모임이 인원 미충족으로 해체되었습니다.',
                              );
                              _activeRoom.doc(_user!.uid).delete();
                              _roominfoM.delete();
                              setState(() {});
                              return SizedBox(height: 0);
                            }

                            if (targetTime.isBefore(DateTime.now()) &&
                                headcount.length >= 2 &&
                                data['inProgress'] == false) {
                              for (int h = 0; h < headcount.length; h++) {
                                FirebaseFirestore.instance
                                    .collection('users')
                                    .doc('${headcount[h]}')
                                    .collection('notification')
                                    .doc('${targetTime}_${data['hostUID']}')
                                    .set({
                                  'uid': data['hostUID'],
                                  'title': data['title'],
                                  'timeStamp': targetTime,
                                  'state': 'start',
                                });
                              }
                              FirebaseFirestore.instance
                                  .collection('inProgressRoom')
                                  .doc(_user!.uid)
                                  .set({
                                'Categories': data['Categories'],
                                'headcount': data['headcount'],
                                'hostPhotoUrl': data['hostPhotoUrl'],
                                'hostUID': data['hostUID'],
                                'info': data['info'],
                                'memberPhotoUrl': data['memberPhotoUrl'],
                                'memberUID': data['memberUID'],
                                'absent': data['memberUID'],
                                'place': data['place'],
                                'targetDay': data['targetDay'],
                                'targetHour': data['targetHour'],
                                'targetMinute': data['targetMinute'],
                                'targetMonth': data['targetMonth'],
                                'targetYear': data['targetYear'],
                                'title': data['title'],
                                'chatRoom': data['chatRoom'],
                                'inProgress': true,
                                'memberTokenList': data['memberTokenList'],
                              });
                              FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(_user!.uid)
                                  .collection('room')
                                  .doc('made')
                                  .update({
                                'inProgress': true,
                                'absent': data['memberUID'],
                              });
                              _activeRoom.doc(_user!.uid).delete();
                            }

                            if (data['inProgress'] == true &&
                                DateTime.now()
                                        .difference(targetTime)
                                        .inMinutes >=
                                    60) {
                              final random = Random();
                              final String roomNum =
                                  '${targetTime.year}${targetTime.month}${targetTime.day}_${random.nextInt(4294967296)}';
                              List absentMember = data['absent'];
                              for (int i = 1; i < headcount.length; i++) {
                                FirebaseFirestore.instance
                                    .collection('users')
                                    .doc('${headcount[i]}')
                                    .collection('room')
                                    .doc('join')
                                    .delete();
                              }
                              if (absentMember.length != headcount.length) {
                                for (int j = 0; j < headcount.length; j++) {
                                  int doAbsent =
                                      absentMember.indexOf(headcount[j]);
                                  if (doAbsent == -1) {
                                    FirebaseFirestore.instance
                                        .collection('users')
                                        .doc('${headcount[j]}')
                                        .update({
                                      'attend': FieldValue.increment(1),
                                    });
                                  }
                                  FirebaseFirestore.instance
                                      .collection('users')
                                      .doc('${headcount[j]}')
                                      .collection('done')
                                      .doc('$roomNum')
                                      .set({
                                    'Categories': data['Categories'],
                                    'headcount': data['headcount'],
                                    'hostPhotoUrl': data['hostPhotoUrl'],
                                    'hostUID': data['hostUID'],
                                    'info': data['info'],
                                    'memberPhotoUrl': data['memberPhotoUrl'],
                                    'memberUID': data['memberUID'],
                                    'absent': data['absent'],
                                    'place': data['place'],
                                    'targetDay': data['targetDay'],
                                    'targetHour': data['targetHour'],
                                    'targetMinute': data['targetMinute'],
                                    'targetMonth': data['targetMonth'],
                                    'targetYear': data['targetYear'],
                                    'title': data['title'],
                                    'chatRoom': data['chatRoom'],
                                    'reviewState': false,
                                  });
                                }
                                sendMessage(
                                  userToken: data['memberTokenList'],
                                  title: '오늘모임',
                                  body: '모임이 종료되었습니다. 모임에 대한 후기를 작성해주세요!',
                                );
                              }
                              FirebaseFirestore.instance
                                  .collection('users')
                                  .doc('${_user!.uid}')
                                  .collection('room')
                                  .doc('made')
                                  .delete();
                              _inProgressRoom.doc('${_user!.uid}').delete();
                              return SizedBox(height: 0);
                            }

                            return headcount.isNotEmpty
                                ? Container(
                                    height: 94.w,
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                        border: Border.all(
                                            color: Colors.grey, width: 1)),
                                    child: Padding(
                                      padding: EdgeInsets.all(8.w),
                                      child: Stack(
                                        children: [
                                          if (data['inProgress'] == true)
                                            Center(
                                                child: Text('진행 중',
                                                    style: TextStyle(
                                                        color: Colors.grey,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                        fontSize: 36.w))),
                                          Row(
                                            children: [
                                              InkWell(
                                                child: Row(
                                                  children: [
                                                    SizedBox(
                                                      width: 70.w,
                                                      child: Stack(
                                                        children: [
                                                          CircleAvatar(
                                                            backgroundColor:
                                                                Colors.grey,
                                                            radius: 32.w,
                                                            backgroundImage:
                                                                NetworkImage(
                                                                    '${data['hostPhotoUrl']}'),
                                                          ),
                                                          if (headcount
                                                                  .length >=
                                                              2)
                                                            Transform.translate(
                                                              offset: headcount
                                                                          .length ==
                                                                      2
                                                                  ? Offset(35.w,
                                                                      35.w)
                                                                  : Offset(25.w,
                                                                      35.w),
                                                              child:
                                                                  CircleAvatar(
                                                                backgroundColor:
                                                                    Colors.grey,
                                                                radius: 18.w,
                                                                backgroundImage:
                                                                    NetworkImage(
                                                                        '${data['memberPhotoUrl'][0]}'),
                                                              ),
                                                            ),
                                                          if (headcount
                                                                  .length >=
                                                              3)
                                                            Transform.translate(
                                                              offset: Offset(
                                                                  35.w, 35.w),
                                                              child:
                                                                  CircleAvatar(
                                                                backgroundColor:
                                                                    Colors.white
                                                                        .withOpacity(
                                                                            0.8),
                                                                radius: 18.w,
                                                                child: Center(
                                                                  child: Text(
                                                                    '+${headcount.length - 2}',
                                                                    style:
                                                                        TextStyle(
                                                                      color: Colors
                                                                          .black,
                                                                      fontSize:
                                                                          12.w,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w700,
                                                                    ),
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                        ],
                                                      ),
                                                    ),
                                                    SizedBox(width: 6.w),
                                                    SizedBox(
                                                      width: 210.w,
                                                      child: Column(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .center,
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Text(
                                                              '${data['title']}',
                                                              maxLines: 1,
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis,
                                                              softWrap: false,
                                                              style: TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w700,
                                                                fontSize: 12.w,
                                                              )),
                                                          SizedBox(height: 2.w),
                                                          Text(
                                                              '장소: ${data['place']}',
                                                              style: TextStyle(
                                                                  fontSize:
                                                                      10.w)),
                                                          Row(
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .spaceBetween,
                                                            children: [
                                                              Text(
                                                                  '약속시간: ${data['targetMonth']}월${data['targetDay']}일 ${data['targetHour']}:${data['targetMinute'].toString().length == 1 ? '0${data['targetMinute']}' : data['targetMinute']}',
                                                                  style: TextStyle(
                                                                      fontSize:
                                                                          10.w)),
                                                              Text(
                                                                  '인원:${headcount.length}/${data['headcount']}',
                                                                  style: TextStyle(
                                                                      fontSize:
                                                                          10.w))
                                                            ],
                                                          ),
                                                          Text(
                                                            '$categoryTextH',
                                                            maxLines: 1,
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                            softWrap: false,
                                                            style: TextStyle(
                                                                fontSize: 10.w),
                                                          ),
                                                          SizedBox(height: 3.w),
                                                          Text('눌러서 자세히 보기',
                                                              style: TextStyle(
                                                                  color: Colors
                                                                      .grey,
                                                                  fontSize:
                                                                      10.w))
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                onTap: () async {
                                                  await Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                          builder: (context) =>
                                                              HostRoomPage()) //모임 자세히보기
                                                      );
                                                  setState(() {});
                                                },
                                              ),
                                              SizedBox(width: 4.w),
                                              SizedBox(width: 14.w),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                : SizedBox(height: 0);
                          },
                        ),
                        SizedBox(height: 6.w),
                        StreamBuilder<DocumentSnapshot>(
                            stream: _roominfoJ.snapshots(),
                            builder: (BuildContext context,
                                AsyncSnapshot<DocumentSnapshot> snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) return Text('');
                              Map<String, dynamic>? uid = snapshot.data?.data()
                                  as Map<String, dynamic>?;
                              uid == null
                                  ? roomStateI = false
                                  : roomStateI = true;
                              String host = uid?['hostUID'] ?? '';
                              return uid != null
                                  ? StreamBuilder<DocumentSnapshot>(
                                      stream: _inProgressRoom
                                          .doc('$host')
                                          .snapshots(),
                                      builder: (BuildContext context,
                                          AsyncSnapshot<DocumentSnapshot>
                                              snapshot) {
                                        String? categoryTextH;
                                        if (snapshot.hasError)
                                          return Text('오류가 발생했습니다.');
                                        if (snapshot.connectionState ==
                                            ConnectionState.waiting)
                                          return Text('');
                                        Map<String, dynamic>? data =
                                            snapshot.data?.data()
                                                as Map<String, dynamic>?;
                                        if (data == null)
                                          return SizedBox(height: 0);
                                        List<dynamic> headcount =
                                            data['memberUID'] ?? [];
                                        categoryTextH =
                                            data['Categories'].join('  ');
                                        final targetTime = DateTime(
                                            data['targetYear'] == null
                                                ? 9999
                                                : data['targetYear'] as int,
                                            data['targetMonth'] == null
                                                ? 12
                                                : data['targetMonth'] as int,
                                            data['targetDay'] == null
                                                ? 31
                                                : data['targetDay'] as int,
                                            data['targetHour'] == null
                                                ? 23
                                                : data['targetHour'] as int,
                                            data['targetMinute'] == null
                                                ? 59
                                                : data['targetMinute'] as int);
                                        if (DateTime.now()
                                                .difference(targetTime)
                                                .inMinutes >=
                                            60) {
                                          final random = Random();
                                          final String roomNum =
                                              '${targetTime.year}${targetTime.month}${targetTime.day}_${random.nextInt(4294967296)}';
                                          List absentMember = data['absent'];
                                          for (int i = 1;
                                              i < headcount.length;
                                              i++) {
                                            FirebaseFirestore.instance
                                                .collection('users')
                                                .doc('${headcount[i]}')
                                                .collection('room')
                                                .doc('join')
                                                .delete();
                                          }
                                          if (absentMember.length !=
                                              headcount.length) {
                                            for (int j = 0;
                                                j < headcount.length;
                                                j++) {
                                              int doAbsent = absentMember
                                                  .indexOf(headcount[j]);
                                              if (doAbsent == -1) {
                                                FirebaseFirestore.instance
                                                    .collection('users')
                                                    .doc('${headcount[j]}')
                                                    .update({
                                                  'attend':
                                                      FieldValue.increment(1),
                                                });
                                              }
                                              FirebaseFirestore.instance
                                                  .collection('users')
                                                  .doc('${headcount[j]}')
                                                  .collection('done')
                                                  .doc('$roomNum')
                                                  .set({
                                                'Categories':
                                                    data['Categories'],
                                                'headcount': data['headcount'],
                                                'hostPhotoUrl':
                                                    data['hostPhotoUrl'],
                                                'hostUID': data['hostUID'],
                                                'info': data['info'],
                                                'memberPhotoUrl':
                                                    data['memberPhotoUrl'],
                                                'memberUID': data['memberUID'],
                                                'absent': data['absent'],
                                                'place': data['place'],
                                                'targetDay': data['targetDay'],
                                                'targetHour':
                                                    data['targetHour'],
                                                'targetMinute':
                                                    data['targetMinute'],
                                                'targetMonth':
                                                    data['targetMonth'],
                                                'targetYear':
                                                    data['targetYear'],
                                                'title': data['title'],
                                                'chatRoom': data['chatRoom'],
                                                'reviewState': false,
                                              });
                                            }
                                            sendMessage(
                                              userToken:
                                                  data['memberTokenList'],
                                              title: '오늘모임',
                                              body:
                                                  '모임이 종료되었습니다. 모임에 대한 후기를 작성해주세요!',
                                            );
                                          }
                                          FirebaseFirestore.instance
                                              .collection('users')
                                              .doc('$host')
                                              .collection('room')
                                              .doc('made')
                                              .delete();
                                          _inProgressRoom.doc('$host').delete();
                                          roomStateI = false;
                                          return SizedBox(height: 0);
                                        }
                                        return headcount.isNotEmpty &&
                                                data != null
                                            ? Container(
                                                height: 94.w,
                                                width: double.infinity,
                                                decoration: BoxDecoration(
                                                    border: Border.all(
                                                        color: Colors.grey,
                                                        width: 1)),
                                                child: Padding(
                                                  padding: EdgeInsets.all(8.w),
                                                  child: Stack(
                                                    children: [
                                                      Center(
                                                          child: Text('진행 중',
                                                              style: TextStyle(
                                                                  color: Colors
                                                                      .grey,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w700,
                                                                  fontSize:
                                                                      36.w))),
                                                      Row(
                                                        children: [
                                                          InkWell(
                                                            child: Row(
                                                              children: [
                                                                SizedBox(
                                                                  width: 70.w,
                                                                  child: Stack(
                                                                    children: [
                                                                      CircleAvatar(
                                                                        backgroundColor:
                                                                            Colors.grey,
                                                                        radius:
                                                                            32.w,
                                                                        backgroundImage:
                                                                            NetworkImage('${data['hostPhotoUrl']}'),
                                                                      ),
                                                                      if (headcount
                                                                              .length >=
                                                                          2)
                                                                        Transform
                                                                            .translate(
                                                                          offset: headcount.length == 2
                                                                              ? Offset(35.w, 35.w)
                                                                              : Offset(25.w, 35.w),
                                                                          child:
                                                                              CircleAvatar(
                                                                            backgroundColor:
                                                                                Colors.grey,
                                                                            radius:
                                                                                18.w,
                                                                            backgroundImage:
                                                                                NetworkImage('${data['memberPhotoUrl'][0]}'),
                                                                          ),
                                                                        ),
                                                                      if (headcount
                                                                              .length >=
                                                                          3)
                                                                        Transform
                                                                            .translate(
                                                                          offset: Offset(
                                                                              35.w,
                                                                              35.w),
                                                                          child:
                                                                              CircleAvatar(
                                                                            backgroundColor:
                                                                                Colors.white.withOpacity(0.8),
                                                                            radius:
                                                                                18.w,
                                                                            child:
                                                                                Center(
                                                                              child: Text(
                                                                                '+${headcount.length - 2}',
                                                                                style: TextStyle(
                                                                                  color: Colors.black,
                                                                                  fontSize: 12.w,
                                                                                  fontWeight: FontWeight.w700,
                                                                                ),
                                                                              ),
                                                                            ),
                                                                          ),
                                                                        ),
                                                                    ],
                                                                  ),
                                                                ),
                                                                SizedBox(
                                                                    width: 6.w),
                                                                SizedBox(
                                                                  width: 210.w,
                                                                  child: Column(
                                                                    mainAxisAlignment:
                                                                        MainAxisAlignment
                                                                            .center,
                                                                    crossAxisAlignment:
                                                                        CrossAxisAlignment
                                                                            .start,
                                                                    children: [
                                                                      Text(
                                                                          '${data['title']}',
                                                                          maxLines:
                                                                              1,
                                                                          overflow: TextOverflow
                                                                              .ellipsis,
                                                                          softWrap:
                                                                              false,
                                                                          style:
                                                                              TextStyle(
                                                                            fontWeight:
                                                                                FontWeight.w700,
                                                                            fontSize:
                                                                                12.w,
                                                                          )),
                                                                      SizedBox(
                                                                          height:
                                                                              2.w),
                                                                      Text(
                                                                          '장소: ${data['place']}',
                                                                          style:
                                                                              TextStyle(fontSize: 10.w)),
                                                                      Row(
                                                                        mainAxisAlignment:
                                                                            MainAxisAlignment.spaceBetween,
                                                                        children: [
                                                                          Text(
                                                                              '약속시간: ${data['targetMonth']}월${data['targetDay']}일 ${data['targetHour']}:${data['targetMinute'].toString().length == 1 ? '0${data['targetMinute']}' : data['targetMinute']}',
                                                                              style: TextStyle(fontSize: 10.w)),
                                                                          Text(
                                                                              '인원:${headcount.length}/${data['headcount']}',
                                                                              style: TextStyle(fontSize: 10.w))
                                                                        ],
                                                                      ),
                                                                      Text(
                                                                        '$categoryTextH',
                                                                        maxLines:
                                                                            1,
                                                                        overflow:
                                                                            TextOverflow.ellipsis,
                                                                        softWrap:
                                                                            false,
                                                                        style: TextStyle(
                                                                            fontSize:
                                                                                10.w),
                                                                      ),
                                                                      SizedBox(
                                                                          height:
                                                                              3.w),
                                                                      Text(
                                                                          '눌러서 자세히 보기',
                                                                          style: TextStyle(
                                                                              color: Colors.grey,
                                                                              fontSize: 10.w))
                                                                    ],
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                            onTap: () async {
                                                              await Navigator.push(
                                                                  context,
                                                                  MaterialPageRoute(
                                                                      builder: (context) => MemberRoomPage(
                                                                            host:
                                                                                host,
                                                                            inProgress:
                                                                                true,
                                                                          )) //모임 자세히보기
                                                                  );
                                                              setState(() {});
                                                            },
                                                          ),
                                                          SizedBox(width: 4.w),
                                                          SizedBox(
                                                              width: 14
                                                                  .w), //관심모임엔 favorite 아이콘
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              )
                                            : SizedBox(height: 0);
                                      },
                                    )
                                  : SizedBox(height: 0);
                            }),
                        StreamBuilder<DocumentSnapshot>(
                            stream: _roominfoJ.snapshots(),
                            builder: (BuildContext context,
                                AsyncSnapshot<DocumentSnapshot> snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) return Text('');
                              Map<String, dynamic>? uid = snapshot.data?.data()
                                  as Map<String, dynamic>?;
                              uid == null
                                  ? roomStateJ = false
                                  : roomStateJ = true;
                              String host = uid?['hostUID'] ?? '';
                              return uid != null
                                  ? StreamBuilder<DocumentSnapshot>(
                                      stream:
                                          _activeRoom.doc('$host').snapshots(),
                                      builder: (BuildContext context,
                                          AsyncSnapshot<DocumentSnapshot>
                                              snapshot) {
                                        String? categoryTextH;
                                        if (snapshot.hasError)
                                          return Text('오류가 발생했습니다.');
                                        if (snapshot.connectionState ==
                                            ConnectionState.waiting)
                                          return Text('');
                                        Map<String, dynamic>? data =
                                            snapshot.data?.data()
                                                as Map<String, dynamic>?;
                                        if (data == null)
                                          return SizedBox(height: 0);
                                        List<dynamic> headcount =
                                            data['memberUID'] ?? [];
                                        categoryTextH =
                                            data['Categories'].join('  ');
                                        final targetTime = DateTime(
                                            data['targetYear'] == null
                                                ? 9999
                                                : data['targetYear'] as int,
                                            data['targetMonth'] == null
                                                ? 12
                                                : data['targetMonth'] as int,
                                            data['targetDay'] == null
                                                ? 31
                                                : data['targetDay'] as int,
                                            data['targetHour'] == null
                                                ? 23
                                                : data['targetHour'] as int,
                                            data['targetMinute'] == null
                                                ? 59
                                                : data['targetMinute'] as int);
                                        if (targetTime
                                                .isBefore(DateTime.now()) &&
                                            headcount.length >= 2) {
                                          for (int h = 0;
                                              h < headcount.length;
                                              h++) {
                                            FirebaseFirestore.instance
                                                .collection('users')
                                                .doc('${headcount[h]}')
                                                .collection('notification')
                                                .doc(
                                                    '${targetTime}_${data?['hostUID']}')
                                                .set({
                                              'uid': data['hostUID'],
                                              'title': data['title'],
                                              'timeStamp': targetTime,
                                              'state': 'start',
                                            });
                                          }
                                          FirebaseFirestore.instance
                                              .collection('inProgressRoom')
                                              .doc('$host')
                                              .set({
                                            'Categories': data['Categories'],
                                            'headcount': data['headcount'],
                                            'hostPhotoUrl':
                                                data['hostPhotoUrl'],
                                            'hostUID': data['hostUID'],
                                            'info': data['info'],
                                            'memberPhotoUrl':
                                                data['memberPhotoUrl'],
                                            'memberUID': data['memberUID'],
                                            'absent': data['memberUID'],
                                            'place': data['place'],
                                            'targetDay': data['targetDay'],
                                            'targetHour': data['targetHour'],
                                            'targetMinute':
                                                data['targetMinute'],
                                            'targetMonth': data['targetMonth'],
                                            'targetYear': data['targetYear'],
                                            'title': data['title'],
                                            'chatRoom': data['chatRoom'],
                                            'inProgress': true,
                                            'memberTokenList':
                                                data['memberTokenList'],
                                          });
                                          FirebaseFirestore.instance
                                              .collection('users')
                                              .doc('$host')
                                              .collection('room')
                                              .doc('made')
                                              .update({
                                            'inProgress': true,
                                            'absent': data['memberUID'],
                                          });
                                          _activeRoom.doc('$host').delete();
                                          return SizedBox(height: 0);
                                        }

                                        return headcount.isNotEmpty &&
                                                data != null
                                            ? Container(
                                                height: 94.w,
                                                width: double.infinity,
                                                decoration: BoxDecoration(
                                                    border: Border.all(
                                                        color: Colors.grey,
                                                        width: 1)),
                                                child: Padding(
                                                  padding: EdgeInsets.all(8.w),
                                                  child: Row(
                                                    children: [
                                                      InkWell(
                                                        child: Row(
                                                          children: [
                                                            SizedBox(
                                                              width: 70.w,
                                                              child: Stack(
                                                                children: [
                                                                  CircleAvatar(
                                                                    backgroundColor:
                                                                        Colors
                                                                            .grey,
                                                                    radius:
                                                                        32.w,
                                                                    backgroundImage:
                                                                        NetworkImage(
                                                                            '${data['hostPhotoUrl']}'),
                                                                  ),
                                                                  if (headcount
                                                                          .length >=
                                                                      2)
                                                                    Transform
                                                                        .translate(
                                                                      offset: headcount.length ==
                                                                              2
                                                                          ? Offset(
                                                                              35
                                                                                  .w,
                                                                              35
                                                                                  .w)
                                                                          : Offset(
                                                                              25.w,
                                                                              35.w),
                                                                      child:
                                                                          CircleAvatar(
                                                                        backgroundColor:
                                                                            Colors.grey,
                                                                        radius:
                                                                            18.w,
                                                                        backgroundImage:
                                                                            NetworkImage('${data['memberPhotoUrl'][0]}'),
                                                                      ),
                                                                    ),
                                                                  if (headcount
                                                                          .length >=
                                                                      3)
                                                                    Transform
                                                                        .translate(
                                                                      offset: Offset(
                                                                          35.w,
                                                                          35.w),
                                                                      child:
                                                                          CircleAvatar(
                                                                        backgroundColor: Colors
                                                                            .white
                                                                            .withOpacity(0.8),
                                                                        radius:
                                                                            18.w,
                                                                        child:
                                                                            Center(
                                                                          child:
                                                                              Text(
                                                                            '+${headcount.length - 2}',
                                                                            style:
                                                                                TextStyle(
                                                                              color: Colors.black,
                                                                              fontSize: 12.w,
                                                                              fontWeight: FontWeight.w700,
                                                                            ),
                                                                          ),
                                                                        ),
                                                                      ),
                                                                    ),
                                                                ],
                                                              ),
                                                            ),
                                                            SizedBox(
                                                                width: 6.w),
                                                            SizedBox(
                                                              width: 210.w,
                                                              child: Column(
                                                                mainAxisAlignment:
                                                                    MainAxisAlignment
                                                                        .center,
                                                                crossAxisAlignment:
                                                                    CrossAxisAlignment
                                                                        .start,
                                                                children: [
                                                                  Text(
                                                                      '${data['title']}',
                                                                      maxLines:
                                                                          1,
                                                                      overflow:
                                                                          TextOverflow
                                                                              .ellipsis,
                                                                      softWrap:
                                                                          false,
                                                                      style:
                                                                          TextStyle(
                                                                        fontWeight:
                                                                            FontWeight.w700,
                                                                        fontSize:
                                                                            12.w,
                                                                      )),
                                                                  SizedBox(
                                                                      height:
                                                                          2.w),
                                                                  Text(
                                                                      '장소: ${data['place']}',
                                                                      style: TextStyle(
                                                                          fontSize:
                                                                              10.w)),
                                                                  Row(
                                                                    mainAxisAlignment:
                                                                        MainAxisAlignment
                                                                            .spaceBetween,
                                                                    children: [
                                                                      Text(
                                                                          '약속시간: ${data['targetMonth']}월${data['targetDay']}일 ${data['targetHour']}:${data['targetMinute'].toString().length == 1 ? '0${data['targetMinute']}' : data['targetMinute']}',
                                                                          style:
                                                                              TextStyle(fontSize: 10.w)),
                                                                      Text(
                                                                          '인원:${headcount.length}/${data['headcount']}',
                                                                          style:
                                                                              TextStyle(fontSize: 10.w))
                                                                    ],
                                                                  ),
                                                                  Text(
                                                                    '$categoryTextH',
                                                                    maxLines: 1,
                                                                    overflow:
                                                                        TextOverflow
                                                                            .ellipsis,
                                                                    softWrap:
                                                                        false,
                                                                    style: TextStyle(
                                                                        fontSize:
                                                                            10.w),
                                                                  ),
                                                                  SizedBox(
                                                                      height:
                                                                          3.w),
                                                                  Text(
                                                                      '눌러서 자세히 보기',
                                                                      style: TextStyle(
                                                                          color: Colors
                                                                              .grey,
                                                                          fontSize:
                                                                              10.w))
                                                                ],
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                        onTap: () async {
                                                          await Navigator.push(
                                                              context,
                                                              MaterialPageRoute(
                                                                  builder: (context) =>
                                                                      MemberRoomPage(
                                                                        host:
                                                                            host,
                                                                        inProgress:
                                                                            false,
                                                                      )) //모임 자세히보기
                                                              );
                                                          setState(() {});
                                                        },
                                                      ),
                                                      SizedBox(width: 4.w),
                                                      SizedBox(
                                                          width: 14
                                                              .w), //관심모임엔 favorite 아이콘
                                                    ],
                                                  ),
                                                ),
                                              )
                                            : SizedBox(height: 0);
                                      },
                                    )
                                  : (roomStateM == false &&
                                          roomStateJ == false &&
                                          roomStateI == false)
                                      ? SizedBox(
                                          height: 52.w,
                                          child: Text(
                                            ' 참가중인 모임이 없습니다.',
                                            style: TextStyle(
                                              fontSize: 22.w,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        )
                                      : SizedBox(height: 0);
                            }),
                        SizedBox(height: 22.w),
                        Container(
                            height: 34.w,
                            alignment: Alignment.centerLeft,
                            width: double.infinity,
                            decoration: BoxDecoration(
                                border: Border(
                                    bottom: BorderSide(
                                        color: Color(0xFF51CF6D), width: 1))),
                            child: Text('관심 모임',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16.w,
                                ))),
                        SizedBox(height: 16.w),
                        StreamBuilder<DocumentSnapshot>(
                          stream: _roominfoA.snapshots(),
                          builder: (BuildContext context,
                              AsyncSnapshot<DocumentSnapshot> snapshot) {
                            if (snapshot.hasError) return Text('오류가 발생했습니다.');
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) return Text('');
                            Map<String, dynamic>? data =
                                snapshot.data?.data() as Map<String, dynamic>?;
                            List<dynamic> attention = data?['attention'] ?? [];
                            return attention.isNotEmpty
                                ? ListView.separated(
                                    physics: BouncingScrollPhysics(),
                                    shrinkWrap: true,
                                    itemCount: attention.length,
                                    itemBuilder: (BuildContext ctx, int idx) {
                                      return FutureBuilder<DocumentSnapshot?>(
                                        future: _activeRoom
                                            .doc('${attention[idx]}')
                                            .get(),
                                        builder: (BuildContext context,
                                            AsyncSnapshot<DocumentSnapshot?>
                                                snapshot) {
                                          String? categoryTextH;
                                          if (snapshot.hasError)
                                            return Text('오류가 발생했습니다.');
                                          if (snapshot.connectionState ==
                                              ConnectionState.waiting)
                                            return Text('');
                                          Map<String, dynamic>? data =
                                              snapshot.data?.data()
                                                  as Map<String, dynamic>?;
                                          if (snapshot.data == null ||
                                              data == null) {
                                            attention.removeAt(idx);
                                            _roominfoA.set({
                                              'attention': attention,
                                            });
                                            return SizedBox(height: 0);
                                          }
                                          List<dynamic> headcount =
                                              data['memberUID'] ?? [];
                                          categoryTextH =
                                              data['Categories'].join('  ');
                                          final targetTime = DateTime(
                                              data['targetYear'] as int,
                                              data['targetMonth'] as int,
                                              data['targetDay'] as int,
                                              data['targetHour'] as int,
                                              data['targetMinute'] as int);
                                          if (targetTime
                                                  .isBefore(DateTime.now()) &&
                                              headcount.length == 1) {
                                            FirebaseFirestore.instance
                                                .collection('users')
                                                .doc('${attention[idx]}')
                                                .collection('chat')
                                                .doc('${data['chatRoom']}')
                                                .delete();
                                            FirebaseFirestore.instance
                                                .collection('chatRoom')
                                                .doc('available')
                                                .collection(
                                                    '${data['chatRoom']}')
                                                .get()
                                                .then((snapshot) {
                                              for (DocumentSnapshot doc
                                                  in snapshot.docs) {
                                                doc.reference.delete();
                                              }
                                            });
                                            _activeRoom
                                                .doc('${attention[idx]}')
                                                .delete();
                                            FirebaseFirestore.instance
                                                .collection('users')
                                                .doc('${attention[idx]}')
                                                .collection('room')
                                                .doc('made')
                                                .delete();
                                            return SizedBox(height: 0);
                                          }
                                          return Container(
                                            height: 94.w,
                                            width: double.infinity,
                                            decoration: BoxDecoration(
                                                border: Border.all(
                                                    color: Colors.grey,
                                                    width: 1)),
                                            child: Padding(
                                              padding: EdgeInsets.all(8.w),
                                              child: Row(
                                                children: [
                                                  InkWell(
                                                    child: Row(
                                                      children: [
                                                        SizedBox(
                                                          width: 70.w,
                                                          child: Stack(
                                                            children: [
                                                              CircleAvatar(
                                                                backgroundColor:
                                                                    Colors.grey,
                                                                radius: 32.w,
                                                                backgroundImage:
                                                                    NetworkImage(
                                                                        '${data['hostPhotoUrl']}'),
                                                              ),
                                                              if (headcount
                                                                      .length >=
                                                                  2)
                                                                Transform
                                                                    .translate(
                                                                  offset: headcount
                                                                              .length ==
                                                                          2
                                                                      ? Offset(
                                                                          35.w,
                                                                          35.w)
                                                                      : Offset(
                                                                          25.w,
                                                                          35.w),
                                                                  child:
                                                                      CircleAvatar(
                                                                    backgroundColor:
                                                                        Colors
                                                                            .grey,
                                                                    radius:
                                                                        18.w,
                                                                    backgroundImage:
                                                                        NetworkImage(
                                                                            '${data['memberPhotoUrl'][0]}'),
                                                                  ),
                                                                ),
                                                              if (headcount
                                                                      .length >=
                                                                  3)
                                                                Transform
                                                                    .translate(
                                                                  offset:
                                                                      Offset(
                                                                          35.w,
                                                                          35.w),
                                                                  child:
                                                                      CircleAvatar(
                                                                    backgroundColor: Colors
                                                                        .white
                                                                        .withOpacity(
                                                                            0.8),
                                                                    radius:
                                                                        18.w,
                                                                    child:
                                                                        Center(
                                                                      child:
                                                                          Text(
                                                                        '+${headcount.length - 2}',
                                                                        style:
                                                                            TextStyle(
                                                                          color:
                                                                              Colors.black,
                                                                          fontSize:
                                                                              12.w,
                                                                          fontWeight:
                                                                              FontWeight.w700,
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ),
                                                            ],
                                                          ),
                                                        ),
                                                        SizedBox(width: 6.w),
                                                        SizedBox(
                                                          width: 210.w,
                                                          child: Column(
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .center,
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            children: [
                                                              Text(
                                                                  '${data['title']}',
                                                                  maxLines: 1,
                                                                  overflow:
                                                                      TextOverflow
                                                                          .ellipsis,
                                                                  softWrap:
                                                                      false,
                                                                  style:
                                                                      TextStyle(
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w700,
                                                                    fontSize:
                                                                        12.w,
                                                                  )),
                                                              SizedBox(
                                                                  height: 2.w),
                                                              Text(
                                                                  '장소: ${data['place']}',
                                                                  style: TextStyle(
                                                                      fontSize:
                                                                          10.w)),
                                                              Row(
                                                                mainAxisAlignment:
                                                                    MainAxisAlignment
                                                                        .spaceBetween,
                                                                children: [
                                                                  Text(
                                                                      '약속시간: ${data['targetMonth']}월${data['targetDay']}일 ${data['targetHour']}:${data['targetMinute'] == 0 ? '00' : data['targetMinute']}',
                                                                      style: TextStyle(
                                                                          fontSize:
                                                                              10.w)),
                                                                  Text(
                                                                      '인원:${headcount.length}/${data['headcount']}',
                                                                      style: TextStyle(
                                                                          fontSize:
                                                                              10.w))
                                                                ],
                                                              ),
                                                              Text(
                                                                '$categoryTextH',
                                                                maxLines: 1,
                                                                overflow:
                                                                    TextOverflow
                                                                        .ellipsis,
                                                                softWrap: false,
                                                                style: TextStyle(
                                                                    fontSize:
                                                                        10.w),
                                                              ),
                                                              SizedBox(
                                                                  height: 3.w),
                                                              Text('눌러서 자세히 보기',
                                                                  style: TextStyle(
                                                                      color: Colors
                                                                          .grey,
                                                                      fontSize:
                                                                          10.w))
                                                            ],
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    onTap: () async {
                                                      await Navigator.push(
                                                          context,
                                                          MaterialPageRoute(
                                                              builder: (context) =>
                                                                  MemberRoomPage(
                                                                    host:
                                                                        attention[
                                                                            idx],
                                                                    inProgress:
                                                                        false,
                                                                  )) //모임 자세히보기
                                                          );
                                                      setState(() {});
                                                    },
                                                  ),
                                                  SizedBox(width: 4.w),
                                                  Container(
                                                    width: 14.w,
                                                    alignment:
                                                        Alignment.bottomCenter,
                                                    child: InkWell(
                                                        child: Icon(
                                                          Icons.favorite,
                                                          color:
                                                              Color(0xFFEF5350),
                                                          size: 16.w,
                                                        ),
                                                        onTap: () async {
                                                          attention
                                                              .removeAt(idx);
                                                          await _roominfoA.set({
                                                            'attention':
                                                                attention,
                                                          });
                                                          setState(() {});
                                                        }),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        },
                                      );
                                    },
                                    separatorBuilder: (ctx, idx) {
                                      return SizedBox(height: 8.w);
                                    },
                                  )
                                : SizedBox(
                                    height: 52.w,
                                    child: Text(
                                      ' 관심 등록한 모임이 없습니다.',
                                      style: TextStyle(
                                        fontSize: 22.w,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  );
                          },
                        ),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 10.w),
                        Container(
                            height: 34.w,
                            alignment: Alignment.centerLeft,
                            width: double.infinity,
                            decoration: BoxDecoration(
                                border: Border(
                                    bottom: BorderSide(
                                        color: Color(0xFF51CF6D), width: 1))),
                            child: Text('참가했던 모임',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16.w,
                                ))),
                        SizedBox(height: 16.w),
                        FutureBuilder<QuerySnapshot>(
                            future: _doneRoom.get(),
                            builder: (BuildContext context,
                                AsyncSnapshot<QuerySnapshot> snapshot) {
                              if (snapshot.hasError) return Text('오류가 발생했습니다.');
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) return Text('');
                              final List<DocumentSnapshot> doneRoom =
                                  snapshot.data!.docs.reversed.toList();
                              return doneRoom.isNotEmpty
                                  ? ListView.separated(
                                      physics: BouncingScrollPhysics(),
                                      shrinkWrap: true,
                                      itemCount: doneRoom.length,
                                      itemBuilder: (BuildContext ctx, int idx) {
                                        return FutureBuilder<DocumentSnapshot>(
                                            future: _doneRoom
                                                .doc('${doneRoom[idx].id}')
                                                .get(),
                                            builder: (BuildContext context,
                                                AsyncSnapshot<DocumentSnapshot>
                                                    snapshot) {
                                              if (snapshot.hasError)
                                                return Text('오류가 발생했습니다.');
                                              if (snapshot.connectionState ==
                                                  ConnectionState.waiting)
                                                return Text('');
                                              String? categoryTextH;
                                              Map<String, dynamic>? data =
                                                  snapshot.data?.data()
                                                      as Map<String, dynamic>?;
                                              List<dynamic> headcount =
                                                  data?['memberUID'] ?? [];
                                              categoryTextH =
                                                  data?['Categories']
                                                      .join('  ');
                                              return Container(
                                                height: 94.w,
                                                width: double.infinity,
                                                decoration: BoxDecoration(
                                                    border: Border.all(
                                                        color: Colors.grey,
                                                        width: 1)),
                                                child: Padding(
                                                  padding: EdgeInsets.all(8.w),
                                                  child: Stack(
                                                    children: [
                                                      if (data![
                                                              'reviewState'] ==
                                                          false)
                                                        Center(
                                                            child: Text('미작성',
                                                                style: TextStyle(
                                                                    color: Colors
                                                                        .grey,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w700,
                                                                    fontSize:
                                                                        36.w))),
                                                      Row(
                                                        children: [
                                                          InkWell(
                                                            child: Row(
                                                              children: [
                                                                SizedBox(
                                                                  width: 70.w,
                                                                  child: Stack(
                                                                    children: [
                                                                      CircleAvatar(
                                                                        backgroundColor:
                                                                            Colors.grey,
                                                                        radius:
                                                                            32.w,
                                                                        backgroundImage:
                                                                            NetworkImage('${data['hostPhotoUrl']}'),
                                                                      ),
                                                                      if (headcount
                                                                              .length >=
                                                                          2)
                                                                        Transform
                                                                            .translate(
                                                                          offset: headcount.length == 2
                                                                              ? Offset(35.w, 35.w)
                                                                              : Offset(25.w, 35.w),
                                                                          child:
                                                                              CircleAvatar(
                                                                            backgroundColor:
                                                                                Colors.grey,
                                                                            radius:
                                                                                18.w,
                                                                            backgroundImage:
                                                                                NetworkImage('${data['memberPhotoUrl'][0]}'),
                                                                          ),
                                                                        ),
                                                                      if (headcount
                                                                              .length >=
                                                                          3)
                                                                        Transform
                                                                            .translate(
                                                                          offset: Offset(
                                                                              35.w,
                                                                              35.w),
                                                                          child:
                                                                              CircleAvatar(
                                                                            backgroundColor:
                                                                                Colors.white.withOpacity(0.8),
                                                                            radius:
                                                                                18.w,
                                                                            child:
                                                                                Center(
                                                                              child: Text(
                                                                                '+${headcount.length - 2}',
                                                                                style: TextStyle(
                                                                                  color: Colors.black,
                                                                                  fontSize: 12.w,
                                                                                  fontWeight: FontWeight.w700,
                                                                                ),
                                                                              ),
                                                                            ),
                                                                          ),
                                                                        ),
                                                                    ],
                                                                  ),
                                                                ),
                                                                SizedBox(
                                                                    width: 6.w),
                                                                SizedBox(
                                                                  width: 210.w,
                                                                  child: Column(
                                                                    mainAxisAlignment:
                                                                        MainAxisAlignment
                                                                            .center,
                                                                    crossAxisAlignment:
                                                                        CrossAxisAlignment
                                                                            .start,
                                                                    children: [
                                                                      Text(
                                                                          '${data['title']}',
                                                                          maxLines:
                                                                              1,
                                                                          overflow: TextOverflow
                                                                              .ellipsis,
                                                                          softWrap:
                                                                              false,
                                                                          style:
                                                                              TextStyle(
                                                                            fontWeight:
                                                                                FontWeight.w700,
                                                                            fontSize:
                                                                                12.w,
                                                                          )),
                                                                      SizedBox(
                                                                          height:
                                                                              2.w),
                                                                      Text(
                                                                          '장소: ${data['place']}',
                                                                          style:
                                                                              TextStyle(fontSize: 10.w)),
                                                                      Row(
                                                                        mainAxisAlignment:
                                                                            MainAxisAlignment.spaceBetween,
                                                                        children: [
                                                                          Text(
                                                                              '약속시간: ${data['targetMonth']}월${data['targetDay']}일 ${data['targetHour']}:${data['targetMinute'].toString().length == 1 ? '0${data['targetMinute']}' : data['targetMinute']}',
                                                                              style: TextStyle(fontSize: 10.w)),
                                                                          Text(
                                                                              '인원:${headcount.length}/${data['headcount']}',
                                                                              style: TextStyle(fontSize: 10.w))
                                                                        ],
                                                                      ),
                                                                      Text(
                                                                        '$categoryTextH',
                                                                        maxLines:
                                                                            1,
                                                                        overflow:
                                                                            TextOverflow.ellipsis,
                                                                        softWrap:
                                                                            false,
                                                                        style: TextStyle(
                                                                            fontSize:
                                                                                10.w),
                                                                      ),
                                                                      SizedBox(
                                                                          height:
                                                                              3.w),
                                                                      Text(
                                                                          '눌러서 자세히 보기',
                                                                          style: TextStyle(
                                                                              color: Colors.grey,
                                                                              fontSize: 10.w))
                                                                    ],
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                            onTap: () async {
                                                              await Navigator.push(
                                                                  context,
                                                                  MaterialPageRoute(
                                                                      builder: (context) => DoneRoomPage(
                                                                            roomname:
                                                                                doneRoom[idx].id,
                                                                          )) //모임 자세히보기
                                                                  );
                                                              setState(() {});
                                                            },
                                                          ),
                                                          SizedBox(width: 4.w),
                                                          SizedBox(width: 14.w),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              );
                                            });
                                      },
                                      separatorBuilder: (ctx, idx) {
                                        return SizedBox(height: 8.w);
                                      },
                                    )
                                  : SizedBox(
                                      height: 100.w,
                                      child: Text(
                                        ' 참가한 기록이 없습니다.\n 지금 바로 모임을 즐겨보세요!',
                                        style: TextStyle(
                                          fontSize: 22.w,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    );
                            }),
                      ],
                    ),
            ),
          ),
        ),
      ],
    );
  }
}
