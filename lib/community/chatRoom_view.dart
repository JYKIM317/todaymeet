import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'chatRoom.dart';
import 'package:famet/customProfile/people_Profile_View.dart';

User? _user = FirebaseAuth.instance.currentUser;
CollectionReference myChat = FirebaseFirestore.instance
    .collection('users')
    .doc(_user!.uid)
    .collection('chat');
DocumentReference chatRoom =
    FirebaseFirestore.instance.collection('chatRoom').doc('available');
DocumentReference favorite = FirebaseFirestore.instance
    .collection('users')
    .doc(_user!.uid)
    .collection('other')
    .doc('favorite');

class ChatRoomView extends StatefulWidget {
  const ChatRoomView({Key? key}) : super(key: key);
  @override
  State<ChatRoomView> createState() => _ChatRoomViewState();
}

class _ChatRoomViewState extends State<ChatRoomView> {
  bool viewState = true;

  @override
  void initState() {
    viewState = true;
    _user = FirebaseAuth.instance.currentUser;
    myChat = FirebaseFirestore.instance
        .collection('users')
        .doc(_user!.uid)
        .collection('chat');
    chatRoom =
        FirebaseFirestore.instance.collection('chatRoom').doc('available');
    favorite = FirebaseFirestore.instance
        .collection('users')
        .doc(_user!.uid)
        .collection('other')
        .doc('favorite');
    super.initState();
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

  @override
  Widget build(BuildContext context) {
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
                    child: Text('대화방',
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
                    child: Text('관심회원',
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
        SizedBox(height: 10.w),
        Expanded(
          child: SingleChildScrollView(
            physics: BouncingScrollPhysics(),
            child: Padding(
              padding: EdgeInsets.fromLTRB(15.w, 15.w, 15.w, 10.w),
              child: viewState == true
                  ? FutureBuilder<QuerySnapshot>(
                      future: myChat.orderBy('recent', descending: true).get(),
                      builder: (BuildContext context,
                          AsyncSnapshot<QuerySnapshot> snapshot) {
                        if (snapshot.hasError) return Text('오류가 발생했습니다.');
                        if (snapshot.connectionState == ConnectionState.waiting)
                          return Text('');
                        final List<DocumentSnapshot> chatList =
                            snapshot.data!.docs;
                        return chatList.isNotEmpty
                            ? ListView.separated(
                                shrinkWrap: true,
                                itemCount: chatList.length,
                                physics: BouncingScrollPhysics(),
                                itemBuilder: (BuildContext ctx, int idx) {
                                  int read = chatList[idx].get('read');
                                  return StreamBuilder(
                                    stream: chatRoom
                                        .collection('${chatList[idx].id}')
                                        .doc('info')
                                        .snapshots(),
                                    builder: (BuildContext context,
                                        AsyncSnapshot<DocumentSnapshot>
                                            snapshot) {
                                      if (snapshot.hasError)
                                        return Text('오류가 발생했습니다.');
                                      if (snapshot.connectionState ==
                                          ConnectionState.waiting)
                                        return Text('');
                                      Map<String, dynamic>? data = snapshot.data
                                          ?.data() as Map<String, dynamic>?;
                                      List<dynamic> headcount =
                                          data?['member'] ?? [];
                                      final targetTime = DateTime(
                                          data?['targetYear'] == null
                                              ? 9999
                                              : data?['targetYear'] as int,
                                          data?['targetMonth'] == null
                                              ? 12
                                              : data?['targetMonth'] as int,
                                          data?['targetDay'] == null
                                              ? 31
                                              : data?['targetDay'] as int,
                                          data?['targetHour'] == null
                                              ? 23
                                              : data?['targetHour'] as int,
                                          data?['targetMinute'] == null
                                              ? 59
                                              : data?['targetMinute'] as int);
                                      DateTime? newestTime =
                                          data?['newestTime'] == null
                                              ? DateTime(9999, 12, 31, 23, 59)
                                              : data?['newestTime'].toDate();
                                      if (data == null) {
                                        myChat
                                            .doc('${chatList[idx].id}')
                                            .delete();
                                        return SizedBox(height: 0);
                                      }
                                      int? newestMessageTime = DateTime.now()
                                          .difference(newestTime!)
                                          .inSeconds;

                                      if (DateTime.now()
                                              .difference(targetTime)
                                              .inMinutes >
                                          1440) {
                                        chatRoom
                                            .collection('${chatList[idx].id}')
                                            .get()
                                            .then((messageSnapshot) {
                                          for (DocumentSnapshot doc
                                              in messageSnapshot.docs) {
                                            Map<String, dynamic> doneMessage =
                                                doc.data()
                                                    as Map<String, dynamic>;
                                            FirebaseFirestore.instance
                                                .collection('chatRoom')
                                                .doc('done')
                                                .collection(
                                                    '${DateTime.now().year.toString()}_${chatList[idx].id}')
                                                .doc('${doc.id}')
                                                .set(doneMessage);
                                            doc.reference.delete();
                                          }
                                        });
                                        return SizedBox(height: 0);
                                      }
                                      return Container(
                                        height: 94.w,
                                        width: double.infinity,
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
                                                            backgroundImage: NetworkImage(data[
                                                                    'isGroup']
                                                                ? '${data['hostPhotoUrl']}'
                                                                : data['member']
                                                                            [
                                                                            0] ==
                                                                        _user!
                                                                            .uid
                                                                    ? '${data['memberPhotoUrl'][1]}'
                                                                    : '${data['memberPhotoUrl'][0]}'),
                                                          ),
                                                          if (headcount
                                                                      .length >=
                                                                  2 &&
                                                              data['isGroup'] ==
                                                                  true)
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
                                                                  3 &&
                                                              data['isGroup'] ==
                                                                  true)
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
                                                      width: 180.w,
                                                      child: Column(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .start,
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          SizedBox(height: 8.w),
                                                          Row(
                                                            children: [
                                                              ConstrainedBox(
                                                                constraints:
                                                                    BoxConstraints(
                                                                        maxWidth:
                                                                            161.w),
                                                                child: Text(
                                                                    data['member'][0] !=
                                                                            _user!
                                                                                .uid
                                                                        ? '${data['title'][0]}'
                                                                        : '${data['title'][1]}',
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
                                                                          14.w,
                                                                    )),
                                                              ),
                                                              SizedBox(
                                                                  width: 4.w),
                                                              if (read == 1)
                                                                CircleAvatar(
                                                                  backgroundColor:
                                                                      Color(
                                                                          0xFFFFA000),
                                                                  radius: 4.w,
                                                                ),
                                                              data['isGroup'] ==
                                                                      true
                                                                  ? Container(
                                                                      width:
                                                                          15.w,
                                                                      height:
                                                                          15.w,
                                                                      alignment:
                                                                          Alignment
                                                                              .center,
                                                                      decoration:
                                                                          BoxDecoration(
                                                                        border: Border.all(
                                                                            width:
                                                                                2,
                                                                            color:
                                                                                Colors.grey),
                                                                        borderRadius:
                                                                            BorderRadius.circular(2.w),
                                                                      ),
                                                                      child: Text(
                                                                          '${data['member'].length.toString()}',
                                                                          style: TextStyle(
                                                                              fontWeight: FontWeight.w700,
                                                                              fontSize: 8.w,
                                                                              color: Colors.grey)),
                                                                    )
                                                                  : SizedBox(
                                                                      height:
                                                                          0),
                                                            ],
                                                          ),
                                                          SizedBox(height: 8.w),
                                                          Text(
                                                              '${data['newestMessage']}',
                                                              maxLines: 1,
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis,
                                                              softWrap: false,
                                                              style: TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500,
                                                                fontSize: 12.w,
                                                              )),
                                                        ],
                                                      ),
                                                    ),
                                                    SizedBox(width: 4.w),
                                                    SizedBox(
                                                      width: 44.w,
                                                      child: newestMessageTime <
                                                              -10000
                                                          ? Text(' ')
                                                          : newestMessageTime <
                                                                  60
                                                              ? Text('방금',
                                                                  style: TextStyle(
                                                                      fontSize:
                                                                          10.w))
                                                              : newestMessageTime <
                                                                      3600
                                                                  ? Text(
                                                                      '${newestMessageTime ~/ 60}분 전',
                                                                      style: TextStyle(
                                                                          fontSize: 10
                                                                              .w))
                                                                  : newestMessageTime <
                                                                          86400
                                                                      ? Text(
                                                                          '${newestMessageTime ~/ 3600}시간 전',
                                                                          style: TextStyle(
                                                                              fontSize: 10
                                                                                  .w))
                                                                      : newestMessageTime <
                                                                              864000
                                                                          ? Text(
                                                                              '${newestMessageTime ~/ 86400}일 전',
                                                                              style: TextStyle(fontSize: 10.w))
                                                                          : Text('오래 전', style: TextStyle(fontSize: 10.w)),
                                                    ),
                                                  ],
                                                ),
                                                onTap: () async {
                                                  await Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                          builder:
                                                              (context) =>
                                                                  Chatting(
                                                                    chatAdress:
                                                                        chatList[idx]
                                                                            .id,
                                                                    title: data[
                                                                        'title'],
                                                                    hostUID:
                                                                        data['member']
                                                                            [0],
                                                                  )) //모임 자세히보기
                                                      );
                                                  myChat
                                                      .doc(chatList[idx].id)
                                                      .update({'read': 0});
                                                  setState(() {});
                                                },
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
                            : SizedBox(height: 0);
                      })
                  : FutureBuilder<DocumentSnapshot>(
                      future: favorite.get(),
                      builder: (BuildContext context,
                          AsyncSnapshot<DocumentSnapshot> snapshot) {
                        if (snapshot.hasError) return Text('오류가 발생했습니다.');
                        if (snapshot.connectionState == ConnectionState.waiting)
                          return Text('');
                        Map<String, dynamic>? data =
                            snapshot.data?.data() as Map<String, dynamic>?;
                        List<dynamic> favoritemembers = data?['list'] ?? [];
                        favoritemembers.reversed.toList();
                        return favoritemembers.isNotEmpty
                            ? ListView.separated(
                                shrinkWrap: true,
                                physics: BouncingScrollPhysics(),
                                itemCount: favoritemembers.length,
                                itemBuilder: (BuildContext ctx, int idx) {
                                  return FutureBuilder<DocumentSnapshot>(
                                    future: FirebaseFirestore.instance
                                        .collection('users')
                                        .doc('${favoritemembers[idx]}')
                                        .get(),
                                    builder: (BuildContext context,
                                        AsyncSnapshot<DocumentSnapshot>
                                            snapshot) {
                                      if (snapshot.hasError)
                                        return Text('오류가 발생했습니다.');
                                      if (snapshot.connectionState ==
                                          ConnectionState.waiting)
                                        return Text('');
                                      Map<String, dynamic>? member =
                                          snapshot.data?.data()
                                              as Map<String, dynamic>?;
                                      String username =
                                          member?['username'] ?? '';
                                      return username.isNotEmpty &&
                                              username != ''
                                          ? Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                InkWell(
                                                  child: Row(
                                                    children: [
                                                      CircleAvatar(
                                                          backgroundColor:
                                                              Colors.grey,
                                                          radius: 30.w,
                                                          backgroundImage:
                                                              NetworkImage(member![
                                                                  'photoUrl'])),
                                                      SizedBox(width: 8.w),
                                                      Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Row(
                                                            children: [
                                                              Text(
                                                                '${member['username']}',
                                                                style: TextStyle(
                                                                    fontSize:
                                                                        22.w),
                                                              ),
                                                              SizedBox(
                                                                  width: 4.w),
                                                              Text(
                                                                "${member['year']}.${member['month']}",
                                                                style:
                                                                    TextStyle(
                                                                  fontSize:
                                                                      14.w,
                                                                  color: Colors
                                                                      .grey,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                          ConstrainedBox(
                                                            constraints:
                                                                BoxConstraints(
                                                                    maxWidth:
                                                                        180.w),
                                                            child: Text(
                                                              "${(member['introduce'] ?? '').toString().replaceAll('\n', ' ')}",
                                                              style: TextStyle(
                                                                fontSize: 16.w,
                                                                color:
                                                                    Colors.grey,
                                                              ),
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                  onTap: () {
                                                    Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                            builder: (context) =>
                                                                OtherProfile(
                                                                    user: favoritemembers[
                                                                        idx])));
                                                  },
                                                ),
                                                InkWell(
                                                  child: Icon(
                                                    Icons.remove,
                                                    size: 32.w,
                                                    color: Colors.grey,
                                                  ),
                                                  onTap: () async {
                                                    var favoritelist =
                                                        await favoriteCheck();
                                                    favoritelist.remove(
                                                        '${favoritemembers[idx]}');
                                                    await FirebaseFirestore
                                                        .instance
                                                        .collection('users')
                                                        .doc('${_user!.uid}')
                                                        .collection('other')
                                                        .doc('favorite')
                                                        .update({
                                                      'list': favoritelist
                                                    });
                                                    setState(() {});
                                                  },
                                                )
                                              ],
                                            )
                                          : SizedBox(height: 0);
                                    },
                                  );
                                },
                                separatorBuilder: (ctx, idx) {
                                  return SizedBox(height: 10.w);
                                },
                              )
                            : SizedBox(
                                height: 102.w,
                                child: Center(
                                  child: Text(
                                    '관심회원이 없습니다',
                                    style: TextStyle(
                                      fontSize: 22.w,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                              );
                      }),
            ),
          ),
        )
      ],
    );
  }
}
