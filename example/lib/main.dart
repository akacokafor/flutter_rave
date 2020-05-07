import 'package:flutter/material.dart';
import 'package:flutter_rave/flutter_rave.dart';

import 'core/pay.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Rave',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 1,
        title: Text(
          'Flutter Rave Payment',
          style: TextStyle(
              color: Colors.black, fontSize: 14, fontWeight: FontWeight.w300),
        ),
        backgroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Text(
              'Click to Pay',
            ),
            SizedBox(
              height: 30,
            ),
            Container(
              height: 50,
              width: 200,
              child: FlatButton.icon(
                color: Colors.redAccent,
                onPressed: () {
                  PayAPI.pay(context, mounted: mounted);
                },
                icon: Icon(
                  Icons.attach_money,
                  color: Colors.white,
                ),
                label: Text("Pay"),
                textColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
