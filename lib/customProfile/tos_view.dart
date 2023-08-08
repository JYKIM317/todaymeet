import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:famet/customSignIn/termofservicelist.dart';

class ToSView extends StatelessWidget {
  const ToSView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          '약관',
          style: TextStyle(fontSize: 16.w, color: Colors.black),
        ),
        leading: InkWell(
          child: Icon(Icons.arrow_back_ios, color: Colors.grey, size: 18.w),
          onTap: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Padding(
          padding: EdgeInsets.fromLTRB(15.w, 15.w, 15.w, 10.w),
          child: Column(
            children: [
              SizedBox(height: 12.w),
              InkWell(
                child: Container(
                  width: double.infinity,
                  child: Text(
                    '서비스 이용약관',
                    style:
                        TextStyle(fontWeight: FontWeight.w700, fontSize: 20.w),
                  ),
                  padding: EdgeInsets.only(bottom: 6.w),
                  decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: Colors.grey))),
                ),
                onTap: () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (context) => TermOfService()));
                },
              ),
              SizedBox(height: 16.w),
              InkWell(
                child: Container(
                  width: double.infinity,
                  child: Text(
                    '개인정보 수집 및 이용',
                    style:
                        TextStyle(fontWeight: FontWeight.w700, fontSize: 20.w),
                  ),
                  padding: EdgeInsets.only(bottom: 6.w),
                  decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: Colors.grey))),
                ),
                onTap: () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (context) => PrivacyPolicy()));
                },
              ),
            ],
          )),
    );
  }
}
