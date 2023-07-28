import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'notice_detail.dart';

class NoticeView extends StatelessWidget {
  const NoticeView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text('공지사항', style: TextStyle(fontSize: 16.w, color: Colors.black),),
        leading: InkWell(
          child: Icon(Icons.arrow_back_ios,color: Colors.grey, size: 18.w),
          onTap: (){Navigator.pop(context);},
        ),
      ),
      body: SingleChildScrollView(
        physics: BouncingScrollPhysics(),
        child: Padding(
            padding: EdgeInsets.fromLTRB(15.w, 15.w, 15.w, 10.w),
            child: Column(
              children: [
                SizedBox(height: 16.w),
                FutureBuilder<QuerySnapshot>(
                  future: FirebaseFirestore.instance.collection('notice').get(),
                  builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot){
                    if(snapshot.hasError) return Text('');
                    if(snapshot.connectionState == ConnectionState.waiting) return Text('');
                    final List<DocumentSnapshot> noticeList = snapshot.data!.docs;
                    return ListView.separated(
                      shrinkWrap: true,
                      itemCount: noticeList.length,
                      itemBuilder: (BuildContext ctx, int idx){
                        String noticeTitle = noticeList[idx].get('title');
                        String when = noticeList[idx].get('when');
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(when, style: TextStyle(
                              fontSize: 14.w,
                              color: Colors.grey,
                            )),
                            InkWell(
                              child: Container(
                                width: double.infinity,
                                child: Text('$noticeTitle',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 20.w
                                  ),
                                ),
                                padding: EdgeInsets.only(bottom: 6.w),
                                decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey))),
                              ),
                              onTap: (){
                                Navigator.push(context,
                                    MaterialPageRoute(builder:
                                        (context) => Notice(noticeAdress: noticeList[idx].id))
                                );
                              },
                            ),
                          ],
                        );
                      },
                      separatorBuilder: (ctx, idx){
                        return SizedBox(height: 16.w);
                      },
                    );
                  },
                ),
              ],
            )
        ),
      ),
    );
  }
}