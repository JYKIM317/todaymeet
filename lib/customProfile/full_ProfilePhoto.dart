import 'package:flutter/material.dart';

class FullScreenPhoto extends StatelessWidget {
  final photo;
  const FullScreenPhoto({Key? key, required this.photo}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        child: Center(
          child: Hero(
            tag: 'profilePhoto',
            child: Image.network(photo),
          ),
        ),
        onTap: (){
          Navigator.pop(context);
        },
      ),
    );
  }
}
