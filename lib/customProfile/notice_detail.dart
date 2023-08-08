import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Notice extends StatelessWidget {
  final noticeAdress;
  const Notice({Key? key, required this.noticeAdress}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        physics: BouncingScrollPhysics(),
        child: Padding(
          padding: EdgeInsets.fromLTRB(24.w, 48.w, 24.w, 24.w),
          child: FutureBuilder(
            future: FirebaseFirestore.instance
                .collection('notice')
                .doc(noticeAdress)
                .get(),
            builder: (BuildContext context,
                AsyncSnapshot<DocumentSnapshot> snapshot) {
              if (snapshot.hasError) return Text('');
              if (snapshot.connectionState == ConnectionState.waiting)
                return Text('');
              Map<String, dynamic>? data =
                  snapshot.data?.data() as Map<String, dynamic>?;
              if (data == null) {
                return SizedBox(
                  height: 102.w,
                  child: Center(
                    child: Text(
                      '공지 내용이 삭제되었습니다.',
                      style: TextStyle(
                        fontSize: 22.w,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                );
              }
              String detail = data['detail'];
              detail = detail.replaceAll(r'\n', '\n');
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 24.w),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      InkWell(
                        child: Icon(Icons.arrow_back_ios,
                            color: Colors.grey, size: 18.w),
                        onTap: () {
                          Navigator.pop(context);
                        },
                      ),
                      SizedBox(
                        width: 24.w,
                      ),
                      ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: 260.w),
                        child: Text(
                          '${data['title']}',
                          style: TextStyle(
                            fontSize: 18.w,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10.w),
                  Container(
                    width: MediaQuery.sizeOf(context).width,
                    alignment: Alignment.centerLeft,
                    padding: EdgeInsets.fromLTRB(4.w, 4.w, 8.w, 0),
                    child: Text(
                      '${data['when']}',
                      style: TextStyle(
                        fontSize: 14.w,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  SizedBox(height: 15.w),
                  Container(
                    height: 1.w,
                    width: MediaQuery.sizeOf(context).width,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 18.w),
                  Text(
                    detail,
                    style: TextStyle(fontSize: 16.w),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
