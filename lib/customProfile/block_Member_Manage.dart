import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

User? _user = FirebaseAuth.instance.currentUser;
DocumentReference blocklist = FirebaseFirestore.instance
    .collection('users')
    .doc('${_user!.uid}')
    .collection('other')
    .doc('block');

class BlockManage extends StatefulWidget {
  const BlockManage({Key? key}) : super(key: key);
  @override
  State<BlockManage> createState() => _BlockManageState();
}

class _BlockManageState extends State<BlockManage> {
  @override
  void initState() {
    _user = FirebaseAuth.instance.currentUser;
    blocklist = FirebaseFirestore.instance
        .collection('users')
        .doc('${_user!.uid}')
        .collection('other')
        .doc('block');
    super.initState();
  }

  Future<List<dynamic>> blockCheck() async {
    final database = FirebaseFirestore.instance
        .collection('users')
        .doc('${_user!.uid}')
        .collection('other')
        .doc('block');
    final document = await database.get();
    final List<dynamic> blocklist = await document.get('block');
    return blocklist;
  }

  Future<List<dynamic>> blocking(String blockmember) async {
    final database = FirebaseFirestore.instance
        .collection('users')
        .doc(blockmember)
        .collection('other')
        .doc('block');
    final document = await database.get();
    final List<dynamic> blockedlist = await document.get('blocked');
    return blockedlist;
  }

  @override
  Widget build(BuildContext context) {
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
              SizedBox(height: 32.w),
              FutureBuilder<DocumentSnapshot>(
                  future: blocklist.get(),
                  builder: (BuildContext context,
                      AsyncSnapshot<DocumentSnapshot> snapshot) {
                    if (snapshot.hasError) return Text('오류가 발생했습니다.');
                    if (snapshot.connectionState == ConnectionState.waiting)
                      return Text('');
                    Map<String, dynamic>? data =
                        snapshot.data?.data() as Map<String, dynamic>?;
                    List<dynamic> blockmembers = data?['block'] ?? [];
                    blockmembers.reversed.toList();
                    return blockmembers.isNotEmpty
                        ? ListView.separated(
                            shrinkWrap: true,
                            physics: BouncingScrollPhysics(),
                            itemCount: blockmembers.length,
                            itemBuilder: (BuildContext ctx, int idx) {
                              return FutureBuilder<DocumentSnapshot>(
                                future: FirebaseFirestore.instance
                                    .collection('users')
                                    .doc('${blockmembers[idx]}')
                                    .get(),
                                builder: (BuildContext context,
                                    AsyncSnapshot<DocumentSnapshot> snapshot) {
                                  if (snapshot.hasError)
                                    return Text('오류가 발생했습니다.');
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) return Text('');
                                  Map<String, dynamic>? member = snapshot.data
                                      ?.data() as Map<String, dynamic>?;
                                  String username = member?['username'] ?? '';
                                  return username.isNotEmpty && username != ''
                                      ? Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Row(
                                              children: [
                                                CircleAvatar(
                                                    backgroundColor:
                                                        Colors.grey,
                                                    radius: 30.w,
                                                    backgroundImage:
                                                        NetworkImage(member![
                                                            'photoUrl'])),
                                                SizedBox(width: 6.w),
                                                Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      '${member['username']}',
                                                      style: TextStyle(
                                                          fontSize: 22.w),
                                                    ),
                                                    Text(
                                                      "${member['year']}.${member['month']}",
                                                      style: TextStyle(
                                                        fontSize: 22.w,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                            InkWell(
                                              child: Icon(
                                                Icons.remove,
                                                size: 32.w,
                                                color: Colors.grey,
                                              ),
                                              onTap: () async {
                                                var blocklist =
                                                    await blockCheck();
                                                var blockedlist =
                                                    await blocking(
                                                        '${blockmembers[idx]}');
                                                blocklist.remove(
                                                    '${blockmembers[idx]}');
                                                blockedlist.remove(_user!.uid);
                                                await FirebaseFirestore.instance
                                                    .collection('users')
                                                    .doc('${_user!.uid}')
                                                    .collection('other')
                                                    .doc('block')
                                                    .update(
                                                        {'block': blocklist});
                                                await FirebaseFirestore.instance
                                                    .collection('users')
                                                    .doc('${blockmembers[idx]}')
                                                    .collection('other')
                                                    .doc('block')
                                                    .update({
                                                  'blocked': blockedlist
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
                                '차단회원이 없습니다',
                                style: TextStyle(
                                  fontSize: 22.w,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          );
                  }),
            ],
          ),
        ),
      ),
    );
  }
}
