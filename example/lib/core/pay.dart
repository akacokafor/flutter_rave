import 'package:flutter/material.dart';
import 'package:flutter_rave/flutter_rave.dart';

class PayAPI {
  static pay(BuildContext context, {bool mounted = false}) {
    final _rave = RaveCardPayment(
      isDemo: true,
      encKey: "c53e399709de57d42e2e36ca",
      publicKey: "FLWPUBK-d97d92534644f21f8c50802f0ff44e02-X",
      transactionRef: "hvHPvKYaRuJLlJWSPWGGKUyaAfWeZKnm",
      amount: 100,
      email: "demo1@example.com",
      onSuccess: (response) {
        print("$response");
        print("Transaction Successful");

        if (mounted) {
          Scaffold.of(context).showSnackBar(
            SnackBar(
              content: Text("Transaction Sucessful!"),
              backgroundColor: Colors.green,
              duration: Duration(
                seconds: 5,
              ),
            ),
          );
        }
      },
      onFailure: (err) {
        print("$err");
        print("Transaction failed");
      },
      onClosed: () {
        print("Transaction closed");
      },
      context: context,
    );

    _rave.process();
  }
}
