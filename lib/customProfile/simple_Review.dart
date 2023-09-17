import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SimpleReview extends StatelessWidget {
  final member;
  final List reviews;
  const SimpleReview({Key? key, required this.member, required this.reviews})
      : super(key: key);

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
              reviews.isNotEmpty
                  ? ListView.separated(
                      physics: BouncingScrollPhysics(),
                      shrinkWrap: true,
                      itemCount: reviews.length,
                      itemBuilder: (BuildContext ctx, int idx) {
                        return FutureBuilder<DocumentSnapshot>(
                            future: FirebaseFirestore.instance
                                .collection('users')
                                .doc(member)
                                .collection('review')
                                .doc('${reviews[idx].id}')
                                .get(),
                            builder: (BuildContext context,
                                AsyncSnapshot<DocumentSnapshot> snapshot) {
                              if (snapshot.hasError) return Text('오류가 발생했습니다.');
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) return Text('');
                              Map<String, dynamic>? data = snapshot.data?.data()
                                  as Map<String, dynamic>?;
                              return Container(
                                child: Text(
                                  '${data?['review']}',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 24.w),
                                ),
                                padding:
                                    EdgeInsets.fromLTRB(8.w, 10.w, 8.w, 10.w),
                                decoration: BoxDecoration(
                                  //border: Border(bottom: BorderSide(color: Colors.grey)),
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(6.w),
                                ),
                              );
                            });
                      },
                      separatorBuilder: (ctx, idx) {
                        return SizedBox(height: 10.w);
                      },
                    )
                  : Center(
                      child: SizedBox(
                        height: 52.w,
                        child: Text(
                          '작성 된 후기가 없습니다',
                          style: TextStyle(
                            fontSize: 22.w,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    )
            ],
          ),
        ),
      ),
    );
  }
}
