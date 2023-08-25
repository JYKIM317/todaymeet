import 'dart:io';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:famet/roomType/member_room_screen.dart';
import 'package:flutter_progress_hud/flutter_progress_hud.dart';
import 'package:http/http.dart' as http;
import 'package:google_mobile_ads/google_mobile_ads.dart';

var _userinfo = FirebaseFirestore.instance.collection('users').doc(_user!.uid);
var _user = FirebaseAuth.instance.currentUser;

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

class GroupSearch extends StatefulWidget {
  const GroupSearch({Key? key}) : super(key: key);

  @override
  State<GroupSearch> createState() => _GroupSearchState();
}

class _GroupSearchState extends State<GroupSearch> {
  final _roomlist = FirebaseFirestore.instance.collection('activateRoom');
  TextEditingController searchController = TextEditingController();
  String searchData = '';
  List<dynamic> searchList = [];

  Future<List<dynamic>> getSearchList(String search) async {
    List<dynamic> result = [];
    var db = await _roomlist.get();
    List<DocumentSnapshot> datalist = db.docs;
    for (DocumentSnapshot document in datalist) {
      Map<String, dynamic>? datafield =
          document.data() as Map<String, dynamic>?;
      if (datafield != null) {
        String inTitle = datafield['title'].toString();
        String inInfo = datafield['info'].toString();
        String inCategories = datafield['Categories'].join('  ');
        if (inTitle.contains(search) ||
            inInfo.contains(search) ||
            inCategories.contains(search)) {
          result.add(document);
        }
      }
    }
    return result;
  }

  @override
  void initState() {
    _userinfo = FirebaseFirestore.instance.collection('users').doc(_user!.uid);
    _user = FirebaseAuth.instance.currentUser;
    super.initState();
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
  Widget build(BuildContext context) {
    final progress = ProgressHUD.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(14.w, 32.w, 14.w, 10.w),
      child: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          TextField(
            controller: searchController,
            decoration: InputDecoration(
                hintText: '검색어를 입력해주세요',
                suffixIcon: IconButton(
                    onPressed: () {
                      searchController.clear();
                    },
                    icon: Icon(Icons.clear)),
                suffixIconColor: Colors.grey),
            maxLines: 1,
            onSubmitted: (value) {
              searchData = searchController.text;
              progress?.show();
              Future.delayed(Duration(seconds: 1), () {});
              setState(() {});
              progress?.dismiss();
            },
          ),
          SizedBox(height: 12.w),
          if (searchData != '' && searchData.trim().isNotEmpty)
            Expanded(
              child: FutureBuilder<DocumentSnapshot>(
                future: _userinfo.collection('other').doc('block').get(),
                builder: (BuildContext context,
                    AsyncSnapshot<DocumentSnapshot> snapshot) {
                  if (snapshot.hasError) return Text('오류가 발생했습니다.');
                  if (snapshot.connectionState == ConnectionState.waiting)
                    return Text('');
                  Map<String, dynamic>? blocked =
                      snapshot.data?.data() as Map<String, dynamic>?;
                  List<dynamic> blocklist = blocked?['blocked'] ?? [];
                  return FutureBuilder<List<dynamic>>(
                    future: getSearchList(searchData),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) return Text('오류가 발생했습니다.');
                      if (snapshot.connectionState == ConnectionState.waiting)
                        return Text('');
                      final List<dynamic> activateRoom =
                          snapshot.data as List<dynamic>;
                      activateRoom.shuffle();
                      return ListView.separated(
                        physics: BouncingScrollPhysics(),
                        shrinkWrap: true,
                        itemCount: activateRoom.length,
                        itemBuilder: (BuildContext ctx, int idx) {
                          return FutureBuilder<DocumentSnapshot>(
                            future:
                                _roomlist.doc('${activateRoom[idx].id}').get(),
                            builder: (BuildContext context,
                                AsyncSnapshot<DocumentSnapshot> snapshot) {
                              if (snapshot.hasError) return Text('오류가 발생했습니다.');
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) return Text('');
                              Map<String, dynamic>? data = snapshot.data?.data()
                                  as Map<String, dynamic>?;
                              if (data == null) return SizedBox(height: 0);
                              String host = activateRoom[idx].id;
                              List<dynamic> headcount = data['memberUID'] ?? [];
                              var title = data['title'].toString() ?? '',
                                  info = data['info'].toString() ?? '',
                                  place = data['place'].toString();
                              bool blockmember = false;
                              String categoryTextH =
                                  data['Categories'].join('  ') ?? '';
                              final targetTime = DateTime(
                                  data['targetYear'] as int,
                                  data['targetMonth'] as int,
                                  data['targetDay'] as int,
                                  data['targetHour'] as int,
                                  data['targetMinute'] as int);
                              if (targetTime.isBefore(DateTime.now()) &&
                                  headcount.length == 1) {
                                FirebaseFirestore.instance
                                    .collection('users')
                                    .doc('${activateRoom[idx].id}')
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
                                    .doc('${activateRoom[idx].id}')
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
                                  userToken: data['memberTokenList'][0],
                                  title: '오늘모임',
                                  body: '개설하신 모임이 인원 미충족으로 해체되었습니다.',
                                );
                                _roomlist
                                    .doc('${activateRoom[idx].id}')
                                    .delete();
                                FirebaseFirestore.instance
                                    .collection('users')
                                    .doc('${activateRoom[idx].id}')
                                    .collection('room')
                                    .doc('made')
                                    .delete();
                                return SizedBox(height: 0);
                              }
                              for (int b = 0; b < headcount.length; b++) {
                                if (blocklist.contains(headcount[b]))
                                  blockmember = true;
                              }
                              if (targetTime.isBefore(DateTime.now()) &&
                                  headcount.length >= 2) {
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
                                    .doc('${activateRoom[idx].id}')
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
                                  'inProgress': true,
                                  'memberTokenList': data['memberTokenList'],
                                });
                                FirebaseFirestore.instance
                                    .collection('users')
                                    .doc('${activateRoom[idx].id}')
                                    .collection('room')
                                    .doc('made')
                                    .update({
                                  'inProgress': true,
                                  'absent': data['memberUID'],
                                });
                                _roomlist
                                    .doc('${activateRoom[idx].id}')
                                    .delete();
                                return SizedBox(height: 0);
                              }
                              return headcount.isNotEmpty && blockmember != true
                                  ? Container(
                                      height: 94.w,
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                          border: Border.all(
                                              color: Colors.grey, width: 1)),
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
                                                        if (headcount.length >=
                                                            2)
                                                          Transform.translate(
                                                            offset: headcount
                                                                        .length ==
                                                                    2
                                                                ? Offset(
                                                                    35.w, 35.w)
                                                                : Offset(
                                                                    25.w, 35.w),
                                                            child: CircleAvatar(
                                                              backgroundColor:
                                                                  Colors.grey,
                                                              radius: 18.w,
                                                              backgroundImage:
                                                                  NetworkImage(
                                                                      '${data['memberPhotoUrl'][0]}'),
                                                            ),
                                                          ),
                                                        if (headcount.length >=
                                                            3)
                                                          Transform.translate(
                                                            offset: Offset(
                                                                35.w, 35.w),
                                                            child: CircleAvatar(
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
                                                        Text('${data['title']}',
                                                            maxLines: 1,
                                                            overflow:
                                                                TextOverflow
                                                                    .fade,
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
                                                              TextOverflow.fade,
                                                          softWrap: false,
                                                          style: TextStyle(
                                                              fontSize: 10.w),
                                                        ),
                                                        SizedBox(height: 3.w),
                                                        Text('눌러서 자세히 보기',
                                                            style: TextStyle(
                                                                color:
                                                                    Colors.grey,
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
                                                        builder: (context) =>
                                                            MemberRoomPage(
                                                              host: host,
                                                              inProgress: false,
                                                            )) //모임 자세히보기
                                                    );
                                                setState(() {});
                                              },
                                            ),
                                            SizedBox(width: 4.w),
                                            StreamBuilder<DocumentSnapshot>(
                                              stream: _userinfo
                                                  .collection('room')
                                                  .doc('attention')
                                                  .snapshots(),
                                              builder: (BuildContext context,
                                                  AsyncSnapshot<
                                                          DocumentSnapshot>
                                                      snapshot) {
                                                Map<String, dynamic>? data =
                                                    snapshot.data?.data()
                                                        as Map<String,
                                                            dynamic>?;
                                                List<dynamic> attention =
                                                    data != null
                                                        ? data['attention'] ??
                                                            []
                                                        : [];
                                                return attention.contains(
                                                            '${activateRoom[idx].id}') !=
                                                        true
                                                    ? Container(
                                                        width: 14.w,
                                                        alignment: Alignment
                                                            .bottomCenter,
                                                        child: InkWell(
                                                            child: Icon(
                                                              Icons
                                                                  .favorite_outline,
                                                              color: Color(
                                                                  0xFFEF5350),
                                                              size: 16.w,
                                                            ),
                                                            onTap: () async {
                                                              attention.add(
                                                                  '${activateRoom[idx].id}');
                                                              await _userinfo
                                                                  .collection(
                                                                      'room')
                                                                  .doc(
                                                                      'attention')
                                                                  .set({
                                                                'attention':
                                                                    attention,
                                                              });
                                                              setState(() {});
                                                            }),
                                                      )
                                                    : Container(
                                                        width: 14.w,
                                                        alignment: Alignment
                                                            .bottomCenter,
                                                        child: InkWell(
                                                            child: Icon(
                                                              Icons.favorite,
                                                              color: Color(
                                                                  0xFFEF5350),
                                                              size: 16.w,
                                                            ),
                                                            onTap: () async {
                                                              final int
                                                                  indexToRemove =
                                                                  attention.indexOf(
                                                                      '${activateRoom[idx].id}');
                                                              attention.removeAt(
                                                                  indexToRemove);
                                                              await _userinfo
                                                                  .collection(
                                                                      'room')
                                                                  .doc(
                                                                      'attention')
                                                                  .set({
                                                                'attention':
                                                                    attention,
                                                              });
                                                              setState(() {});
                                                            }),
                                                      );
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                    )
                                  : SizedBox(height: 0);
                            },
                          );
                        },
                        separatorBuilder: (ctx, idx) {
                          return idx % 5 == 0
                              ? Column(
                                  children: [
                                    SizedBox(height: 8.w),
                                    bannerAd(),
                                    SizedBox(height: 8.w),
                                  ],
                                )
                              : SizedBox(height: 8.w);
                        },
                      );
                    },
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
