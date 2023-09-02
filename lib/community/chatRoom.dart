import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:famet/customProfile/people_Profile_View.dart';

/*
import 'package:http/http.dart' as http;
import 'dart:convert';
*/
User? _user = FirebaseAuth.instance.currentUser;

/*
const fcmServerKey = 'AAAA8cL90wc:APA91bF-RBJ3dRn0d_1uSIoJE1BNIzaA8weml0I-3xVH44Zshxqgo7342rmr5TT1JDE-aNNej6DekBinmbSTQ2llvBCBxE4EqHTSQ1x-UwxphCorQWAUcrb_c3jaNiQfEu04IhgETBQf';
Future<void> sendMessage({
  required List<dynamic> userToken,
  required String title,
  required String body,
}) async {
  http.Response response;
  try {
    response = await http.post(
        Uri.parse('https://fcm.googleapis.com/fcm/send'),
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
            'status': 'done',
            "action": '테스트',
          },
          'registration_ids': userToken, // 'to': token
          'content_available': true,
          'priority': 'high',
        })
    );
  } catch (e) {
    print('error $e');
  }
}*/

class Chatting extends StatefulWidget {
  final chatAdress;
  final title;
  final hostUID;
  const Chatting(
      {Key? key,
      required this.chatAdress,
      required this.title,
      required this.hostUID})
      : super(key: key);
  @override
  State<Chatting> createState() => _ChattingState();
}

class _ChattingState extends State<Chatting> {
  late CollectionReference chatRoom;
  TextEditingController messageController = TextEditingController();
  late String messageParameter;
  late bool isGroup;
  late List members, memberphotos, titles, memberToken;
  @override
  void initState() {
    _user = FirebaseAuth.instance.currentUser;
    chatRoom = FirebaseFirestore.instance
        .collection('chatRoom')
        .doc('available')
        .collection(widget.chatAdress);
    super.initState();
  }

  getUserData() async {
    final List<String> userData = [];
    final database = await FirebaseFirestore.instance
        .collection('users')
        .doc('${_user!.uid}')
        .get();
    final username = await database.get('username');
    final photoUrl = await database.get('photoUrl');
    userData.add(username);
    userData.add(photoUrl);
    return userData;
  }

  @override
  Widget build(BuildContext context) {
    final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
    int chatCount = 0;
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        body: Scaffold(
          key: scaffoldKey,
          endDrawer: Drawer(
            width: 200.w,
            child: Column(
              children: [
                Container(
                  alignment: Alignment.centerLeft,
                  height: 70.w,
                  decoration: BoxDecoration(
                      border: Border(
                          bottom: BorderSide(
                              color: Colors.grey.withOpacity(0.5), width: 2))),
                  padding: EdgeInsets.fromLTRB(8.w, 16.w, 0, 0),
                  child: Text('멤버', style: TextStyle(fontSize: 24.w)),
                ),
                Expanded(
                    child: Padding(
                  padding: EdgeInsets.fromLTRB(10.w, 0, 0, 10.w),
                  child: FutureBuilder<DocumentSnapshot>(
                    future: chatRoom.doc('info').get(),
                    builder: (BuildContext context,
                        AsyncSnapshot<DocumentSnapshot> snapshot) {
                      if (snapshot.hasError) return Text('');
                      if (snapshot.connectionState == ConnectionState.waiting)
                        return Text('');
                      Map<String, dynamic>? info =
                          snapshot.data?.data() as Map<String, dynamic>?;
                      if (info == null) return Text('');
                      List memberUID = info['member'];
                      return ListView.separated(
                        shrinkWrap: true,
                        itemCount: memberUID.length,
                        itemBuilder: (BuildContext ctx, int idx) {
                          return FutureBuilder(
                            future: FirebaseFirestore.instance
                                .collection('users')
                                .doc('${memberUID[idx]}')
                                .get(),
                            builder:
                                (BuildContext context, AsyncSnapshot snapshot) {
                              if (snapshot.hasError) return Text('오류가 발생했습니다.');
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) return Text('');
                              Map<String, dynamic>? data = snapshot.data?.data()
                                  as Map<String, dynamic>?;
                              if (data == null) return SizedBox(height: 0);
                              return InkWell(
                                child: SizedBox(
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                          backgroundColor: Colors.grey,
                                          radius: 22.w,
                                          backgroundImage:
                                              NetworkImage(data['photoUrl'])),
                                      SizedBox(width: 8.w),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          ConstrainedBox(
                                            constraints:
                                                BoxConstraints(maxWidth: 120.w),
                                            child: Text(
                                              '${data['username']}',
                                              style: TextStyle(fontSize: 18.w),
                                            ),
                                          ),
                                          ConstrainedBox(
                                            constraints:
                                                BoxConstraints(maxWidth: 120.w),
                                            child: Text(
                                              "${(data['introduce'] ?? '').toString().replaceAll('\n', ' ')}",
                                              style: TextStyle(
                                                fontSize: 16.w,
                                                color: Colors.grey,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
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
                                              user: memberUID[idx])));
                                },
                              );
                            },
                          );
                        },
                        separatorBuilder: (ctx, idx) {
                          return SizedBox(height: 12.w);
                        },
                      );
                    },
                  ),
                )),
                Container(
                  alignment: Alignment.centerRight,
                  height: 60.w,
                  decoration: BoxDecoration(
                      border: Border(
                          top: BorderSide(
                              color: Colors.grey.withOpacity(0.5), width: 2))),
                  padding: EdgeInsets.only(left: 16.w),
                  child: Center(
                      child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      InkWell(
                        child: SizedBox(
                          child: Icon(
                            Icons.logout,
                            size: 22.w,
                            color: Colors.grey,
                          ),
                        ),
                        onTap: () async {
                          isGroup
                              ? showDialog(
                                  barrierDismissible: true,
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(6.w)),
                                      content: Text("모임 대화방은 나가실 수 없습니다."),
                                    );
                                  })
                              : showDialog(
                                  barrierDismissible: true,
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(6.w)),
                                      content: Text("정말 대화방을 나가시겠습니까?"),
                                      actions: [
                                        TextButton(
                                            child: Text('취소하기',
                                                style: TextStyle(
                                                  color: Colors.grey,
                                                  fontSize: 12.w,
                                                )),
                                            onPressed: () {
                                              Navigator.of(context).pop();
                                            }),
                                        TextButton(
                                            child: Text('나가기',
                                                style: TextStyle(
                                                  color: Color(0xFF51CF6D),
                                                  fontSize: 12.w,
                                                )),
                                            onPressed: () async {
                                              Navigator.pop(context);
                                              Navigator.pop(context);
                                              Navigator.pop(context);
                                              int memberindex =
                                                  members.indexOf(_user!.uid);
                                              members.removeAt(memberindex);
                                              memberToken.removeAt(memberindex);
                                              if (memberindex == 0) {
                                                memberphotos = memberphotos
                                                    .reversed
                                                    .toList();
                                                titles =
                                                    titles.reversed.toList();
                                                if (members.isEmpty) {
                                                  await chatRoom
                                                      .get()
                                                      .then((messageSnapshot) {
                                                    for (DocumentSnapshot doc
                                                        in messageSnapshot
                                                            .docs) {
                                                      Map<String, dynamic>
                                                          doneMessage =
                                                          doc.data() as Map<
                                                              String, dynamic>;
                                                      FirebaseFirestore.instance
                                                          .collection(
                                                              'chatRoom')
                                                          .doc('done')
                                                          .collection(
                                                              '${DateTime.now().year}.${DateTime.now().month}.${DateTime.now().day} ${DateTime.now().hour}:${DateTime.now().minute}_${widget.chatAdress}')
                                                          .doc('${doc.id}')
                                                          .set(doneMessage);
                                                      doc.reference.delete();
                                                    }
                                                  });
                                                }
                                              }
                                              await chatRoom
                                                  .doc('info')
                                                  .update({
                                                'member': members,
                                                'memberPhotoUrl': memberphotos,
                                                'memberTokenList': memberToken,
                                                'title': titles,
                                              });
                                              await FirebaseFirestore.instance
                                                  .collection('users')
                                                  .doc(_user!.uid)
                                                  .collection('chat')
                                                  .doc(widget.chatAdress)
                                                  .delete();
                                            }),
                                      ],
                                    );
                                  });
                        },
                      ),
                      SizedBox(
                        width: 24.w,
                      ),
                      Icon(
                        Icons.notifications_active,
                        size: 22.w,
                        color: Colors.transparent,
                      )
                    ],
                  )),
                ),
              ],
            ),
          ),
          body: Padding(
            padding: EdgeInsets.fromLTRB(20.w, 16.w, 20.w, 10.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 24.w),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InkWell(
                      child: SizedBox(
                        child: Icon(Icons.arrow_back_ios,
                            color: Colors.grey, size: 22.w),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                      },
                    ),
                    SizedBox(width: 4.w),
                    Expanded(
                      flex: 1,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            padding: EdgeInsets.fromLTRB(10.w, 0, 10.w, 10.w),
                            decoration: BoxDecoration(
                                border: Border(
                                    bottom: BorderSide(
                                        color: Color(0xFF51CF6D), width: 1))),
                            child: Text(
                              widget.hostUID != _user!.uid
                                  ? '${widget.title[0]}'
                                  : '${widget.title[1]}',
                              style: TextStyle(
                                fontSize: 18.w,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 4.w),
                    InkWell(
                      child: SizedBox(
                          child:
                              Icon(Icons.menu, color: Colors.grey, size: 22.w)),
                      onTap: () {
                        scaffoldKey.currentState!.openEndDrawer();
                      },
                    ),
                  ],
                ),
                SizedBox(height: 18.w),
                Expanded(
                  child: SingleChildScrollView(
                    reverse: true,
                    physics: BouncingScrollPhysics(),
                    child: StreamBuilder<QuerySnapshot>(
                      stream: chatRoom.snapshots(),
                      builder: (BuildContext context,
                          AsyncSnapshot<QuerySnapshot> snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting)
                          return Text('');
                        List<DocumentSnapshot>? chatList = snapshot.data!.docs;
                        members = chatList.first.get('member');
                        memberToken = chatList.first.get('memberTokenList');
                        isGroup = chatList.first.get('isGroup');
                        if (isGroup == false) {
                          memberphotos = chatList.first.get('memberPhotoUrl');
                          titles = chatList.first.get('title');
                        }
                        if (!snapshot.hasData) {
                          return SizedBox(
                            height: 102.w,
                            child: Center(
                              child: Text(
                                '대화방이 존재하지 않습니다.',
                                style: TextStyle(
                                  fontSize: 22.w,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          );
                        }
                        chatList.removeAt(0);
                        chatCount = chatList.length;
                        return chatList.isNotEmpty
                            ? ListView.separated(
                                shrinkWrap: true,
                                physics: BouncingScrollPhysics(),
                                itemCount: chatList.length,
                                itemBuilder: (BuildContext ctx, int idx) {
                                  String? userUid = chatList[idx]['uid'];
                                  DateTime messageTime =
                                      chatList[idx]['sendTime'] == null
                                          ? DateTime(9999, 12, 31, 23, 59)
                                          : chatList[idx]['sendTime'].toDate();
                                  return userUid != _user!.uid
                                      ? userUid != 'system'
                                          ? Container(
                                              alignment: Alignment.centerLeft,
                                              child: Row(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                mainAxisAlignment:
                                                    MainAxisAlignment.start,
                                                children: [
                                                  InkWell(
                                                    child: CircleAvatar(
                                                      backgroundColor:
                                                          Colors.grey,
                                                      radius: 32.w,
                                                      backgroundImage: NetworkImage(
                                                          '${chatList[idx]['photoUrl']}'),
                                                    ),
                                                    onTap: () {
                                                      Navigator.push(
                                                          context,
                                                          MaterialPageRoute(
                                                              builder: (context) =>
                                                                  OtherProfile(
                                                                      user: chatList[
                                                                              idx]
                                                                          [
                                                                          'uid'])));
                                                    },
                                                  ),
                                                  SizedBox(width: 6.w),
                                                  Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      SizedBox(height: 2.w),
                                                      Text(
                                                          '${chatList[idx]['username']}',
                                                          style: TextStyle(
                                                            fontWeight:
                                                                FontWeight.w700,
                                                            fontSize: 16.w,
                                                          )),
                                                      SizedBox(height: 2.w),
                                                      Row(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .end,
                                                        children: [
                                                          Container(
                                                              decoration:
                                                                  BoxDecoration(
                                                                color: Colors
                                                                    .white,
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            4.w),
                                                              ),
                                                              padding:
                                                                  EdgeInsets
                                                                      .fromLTRB(
                                                                          6.w,
                                                                          6.w,
                                                                          6.w,
                                                                          6.w),
                                                              alignment: Alignment
                                                                  .centerLeft,
                                                              child:
                                                                  ConstrainedBox(
                                                                constraints:
                                                                    BoxConstraints(
                                                                        maxWidth:
                                                                            180.w),
                                                                child: Text(
                                                                  '${chatList[idx]['text']}',
                                                                  style: TextStyle(
                                                                      fontSize:
                                                                          14.w),
                                                                ),
                                                              )),
                                                          SizedBox(width: 4.w),
                                                          Text(
                                                            '${messageTime.hour.toString()}:${messageTime.minute.toString().length == 1 ? '0${messageTime.minute}' : '${messageTime.minute}'}',
                                                            style: TextStyle(
                                                                fontSize: 10.w),
                                                          ),
                                                        ],
                                                      )
                                                    ],
                                                  )
                                                ],
                                              ),
                                            )
                                          : Container(
                                              decoration: BoxDecoration(
                                                color: Colors.grey,
                                                borderRadius:
                                                    BorderRadius.horizontal(
                                                        left: Radius.circular(
                                                            8.w),
                                                        right: Radius.circular(
                                                            8.w)),
                                              ),
                                              padding: EdgeInsets.fromLTRB(
                                                  6.w, 6.w, 6.w, 6.w),
                                              alignment: Alignment.center,
                                              child: ConstrainedBox(
                                                constraints: BoxConstraints(
                                                    maxWidth: 180.w),
                                                child: Text(
                                                  '${chatList[idx]['text']}',
                                                  style: TextStyle(
                                                      fontSize: 14.w,
                                                      color: Colors.white),
                                                  textAlign: TextAlign.center,
                                                ),
                                              ))
                                      : Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          mainAxisAlignment:
                                              MainAxisAlignment.end,
                                          children: [
                                            Text(
                                              '${messageTime.hour.toString()}:${messageTime.minute.toString().length == 1 ? '0${messageTime.minute}' : '${messageTime.minute}'}',
                                              style: TextStyle(fontSize: 10.w),
                                            ),
                                            SizedBox(width: 4.w),
                                            Container(
                                                decoration: BoxDecoration(
                                                  color: Color(0xFFD6D6D6),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          4.w),
                                                ),
                                                padding: EdgeInsets.fromLTRB(
                                                    6.w, 6.w, 6.w, 6.w),
                                                alignment:
                                                    Alignment.centerRight,
                                                child: ConstrainedBox(
                                                  constraints: BoxConstraints(
                                                      maxWidth: 180.w),
                                                  child: Text(
                                                    '${chatList[idx]['text']}',
                                                    style: TextStyle(
                                                        fontSize: 14.w),
                                                    textAlign: TextAlign.end,
                                                  ),
                                                )),
                                          ],
                                        );
                                },
                                separatorBuilder: (ctx, idx) {
                                  return SizedBox(height: 12.w);
                                },
                              )
                            : SizedBox(height: 0);
                      },
                    ),
                  ),
                ),
                SizedBox(height: 4.w),
              ],
            ),
          ),
          bottomNavigationBar: Row(
            children: [
              Expanded(
                flex: 1,
                child: BottomAppBar(
                  height: 62.w,
                  color: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 8.w),
                  child: TextField(
                    maxLines: 2,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      focusedBorder: InputBorder.none,
                    ),
                    controller: messageController,
                    onChanged: (value) {
                      messageParameter = value;
                    },
                  ),
                ),
              ),
              InkWell(
                child: Container(
                  width: 46.w,
                  height: 62.w,
                  color: Color(0xFF51CF6D),
                  child: Icon(
                    Icons.shortcut,
                    color: Colors.white,
                  ),
                ),
                onTap: () async {
                  if (messageController.text.isNotEmpty) {
                    final textData = messageParameter;
                    messageController.clear();
                    messageParameter = messageController.text;
                    List<String> userData = await getUserData();
                    DateTime sendTime = DateTime.now();
                    int userindex = members.indexOf(_user!.uid);
                    /*List sendToMember = memberToken;
                    sendToMember.removeAt(userindex);
                    await sendMessage(
                      userToken: sendToMember,
                      title: userData[0],
                      body: messageParameter,
                    );*/
                    await chatRoom
                        .doc('message_${sendTime.toString()}_${_user!.uid}')
                        .set({
                      'sendTime': sendTime,
                      'username': userData[0],
                      'photoUrl': userData[1],
                      'text': textData,
                      'uid': _user!.uid
                    });
                    await chatRoom.doc('info').update({
                      'newestTime': sendTime,
                      'newestMessage': textData.replaceAll('\n', ' '),
                    });
                    if (isGroup) {
                      if (chatCount % 25 == 0 || chatCount == 1) {
                        chatRoom.doc('message_${DateTime.now()}_system').set({
                          'sendTime': DateTime.now(),
                          'text': '그룹 대화방은 모임 시작 후 24시간 뒤 해체됩니다.',
                          'uid': 'system'
                        });
                      }
                    }
                    if (!isGroup) {
                      if (userindex != 0) {
                        FirebaseFirestore.instance
                            .collection('users')
                            .doc(members[0])
                            .collection('chat')
                            .doc(widget.chatAdress)
                            .set({'recent': DateTime.now(), 'read': 1});
                      } else if (userindex != 1) {
                        FirebaseFirestore.instance
                            .collection('users')
                            .doc(members[1])
                            .collection('chat')
                            .doc(widget.chatAdress)
                            .set({'recent': DateTime.now(), 'read': 1});
                      }
                      if (userindex == -1) {
                        members.add(_user!.uid);
                        final currentUser = await FirebaseFirestore.instance
                            .collection('users')
                            .doc(_user!.uid)
                            .get();
                        Map<String, dynamic>? currentUserData =
                            currentUser.data() as Map<String, dynamic>?;
                        memberToken.add(currentUserData!['pushToken']);
                        await chatRoom.doc('info').update({
                          'member': members,
                          'memberTokenList': memberToken,
                        });
                        await FirebaseFirestore.instance
                            .collection('users')
                            .doc(_user!.uid)
                            .collection('chat')
                            .doc(widget.chatAdress)
                            .set({
                          'read': 0,
                          'recent': DateTime.now(),
                        });
                      }
                    }
                  }
                },
              )
            ],
          ),
        ),
      ),
    );
  }
}
