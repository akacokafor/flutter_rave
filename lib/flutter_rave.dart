library flutter_rave;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_rave/src/api/services/rave_api_service.dart';
import 'package:flutter_rave/src/config/constants.dart';
import 'package:flutter_rave/src/ui/components/overlay_loader_widget.dart';
import 'package:flutter_rave/src/utils/assets.dart';
import 'package:flutter_rave/src/utils/credit_card.dart';
import 'package:flutter_rave/src/utils/masked_input_formatter.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_webview_plugin/flutter_webview_plugin.dart';

part 'rave_provider.dart';

class RaveCardPayment {
  final String publicKey;
  final String encKey;
  final String transactionRef;
  final List<Map<String, dynamic>> subaccounts;
  final double amount;
  final String email;
  final Function onSuccess;
  final Function onFailure;
  final Function onClosed;
  final BuildContext context;
  final bool isDemo;

  const RaveCardPayment({
    Key key,
    @required this.publicKey,
    @required this.encKey,
    @required this.transactionRef,
    @required this.amount,
    @required this.email,
    this.subaccounts,
    this.isDemo = false,
    this.onSuccess,
    this.onFailure,
    this.onClosed,
    @required this.context,
  });

  void process() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return _AddDebitCardScreen(
          isDemo: this.isDemo,
          publicKey: this.publicKey,
          encKey: this.encKey,
          transactionRef: this.transactionRef,
          subaccounts: this.subaccounts,
          amount: this.amount,
          email: this.email,
          onSuccess: (r) {
            Navigator.of(dialogContext).pop();
            if (this.onSuccess != null) {
              this.onSuccess(r);
            }

            if (this.onClosed != null) {
              this.onClosed();
            }
          },
          onFailure: (r) {
            Navigator.of(dialogContext).pop();
            if (this.onFailure != null) {
              this.onFailure(r);
            }

            if (this.onClosed != null) {
              this.onClosed();
            }
          },
          onClose: () {
            Navigator.of(dialogContext).pop();
            if (this.onClosed != null) {
              this.onClosed();
            }
          },
        );
      },
    );
  }
}

class CreditCardInfo extends Equatable {
  final String cardNumber;
  final String expirationMonth;
  final String expirationYear;
  final String cvv;

  String brand;
  String type;

  CreditCardInfo(
      this.cardNumber, this.expirationMonth, this.expirationYear, this.cvv)
      : super([
          cvv,
          expirationMonth,
          expirationYear,
          cardNumber,
        ]);

  bool get isComplete {
    return cardNumber != null &&
        cardNumber.isNotEmpty &&
        expirationMonth != null &&
        expirationMonth.isNotEmpty &&
        expirationYear != null &&
        expirationYear.isNotEmpty &&
        cvv != null &&
        cvv.isNotEmpty;
  }
}

class _AddDebitCardScreen extends StatefulWidget {
  static String route = "/debit-cards/add";
  final String publicKey;
  final String encKey;
  final String transactionRef;
  final List<Map<String, dynamic>> subaccounts;
  final double amount;
  final String email;
  final bool isDemo;
  final Function onSuccess;
  final Function onFailure;
  final Function onClose;

  const _AddDebitCardScreen({
    Key key,
    @required this.publicKey,
    @required this.encKey,
    @required this.transactionRef,
    @required this.amount,
    @required this.email,
    this.subaccounts,
    this.isDemo = false,
    this.onSuccess,
    this.onFailure,
    this.onClose,
  }) : super(key: key);

  @override
  __AddDebitCardScreenState createState() => __AddDebitCardScreenState();
}

class __AddDebitCardScreenState extends State<_AddDebitCardScreen> {
  GlobalKey<FormState> _globalKey = GlobalKey();

  bool canContinue = false;
  CreditCardInfo _cardInfo;
  Function _processCard;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        color: Colors.black12.withOpacity(0.1),
        child: Stack(
          alignment: AlignmentDirectional.center,
          fit: StackFit.expand,
          children: <Widget>[
            AbsorbPointer(),
            SafeArea(
                child: Center(
                  child: Form(
                    key: _globalKey,
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Stack(
                        alignment: AlignmentDirectional.center,
                        children: <Widget>[
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  SizedBox(
                                    child: RaveProvider(
                                      isDemo: widget.isDemo,
                                      publicKey: widget.publicKey,
                                      encKey: widget.encKey,
                                      transactionRef: widget.transactionRef,
                                      amount: widget.amount,
                                      email: widget.email,
                                      subaccounts: widget.subaccounts,
                                      onSuccess: widget.onSuccess,
                                      onFailure: widget.onSuccess,
                                      cardInfo: _cardInfo,
                                      builder: (context, processCard) {
                                        _processCard = processCard;
                                        return _AddDebitCardWidget(
                                          amount: widget.amount,
                                          onValidated: (CreditCardInfo creditCard) {
                                            if (creditCard != null) {
                                              setState(
                                                    () {
                                                  _cardInfo = creditCard;
                                                },
                                              );
                                            }
                                            setState(
                                                  () {
                                                canContinue = creditCard != null;
                                              },
                                            );
                                          },
                                        );
                                      },
                                    ),
                                  ),
                                  SizedBox(
                                    width: double.infinity,
                                    child: FlatButton(
                                      color: Theme.of(context).accentColor,
                                      disabledColor: Colors.grey[300],
                                      onPressed: canContinue
                                          ? () async {
                                        var result;
                                        try {
                                          result = await _processCard();
                                        } catch (e) {
                                          widget.onFailure(e);
                                          return;
                                        }

                                        if (result != null) {
                                          if (widget.onSuccess != null) {
                                            widget.onSuccess(result);
                                          }
                                        } else {
                                          if (widget.onFailure != null) {
                                            widget.onFailure(
                                                "Transaction Failed");
                                          }
                                        }
                                      }
                                          : null,
                                      child: Text(
                                        "Continue",
                                        style: TextStyle(
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  )
                                ],
                              ),
                            ),
                          ),
                          Positioned(
                            left: 10.0,
                            top: 10.0,
                            width: 20.0,
                            height: 20.0,
                            child: InkWell(
                              onTap: () {
                                if (widget.onClose != null) {
                                  widget.onClose();
                                }
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.red,
                                ),
                                child: Center(
                                  child: Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 15,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

class _AddDebitCardWidget extends StatefulWidget {
  final Function(CreditCardInfo) onValidated;
  final double amount;

  const _AddDebitCardWidget({
    Key key,
    this.onValidated,
    @required this.amount,
  }) : super(key: key);

  @override
  __AddDebitCardWidgetState createState() => __AddDebitCardWidgetState();
}

class __AddDebitCardWidgetState extends State<_AddDebitCardWidget> {
  TextEditingController _creditCardNumberController = TextEditingController();
  TextEditingController _creditCardExpirationController =
      TextEditingController();
  TextEditingController _cvvController = TextEditingController();

  final expirationMaskFormatter = MaskTextInputFormatter('__/__');
  final creditCardTextInputFormatter = CreditCardTextInputFormatter();

  FocusNode _cardNumerFocusNode = FocusNode();
  FocusNode _cardExpDateFocusNode = FocusNode();
  FocusNode _cardCvvFocusNode = FocusNode();

  String cardNumber = '';
  String unmaskedCardNumber = '';

  String expirationValue = '';
  String unmaskedExpirationDateValue = '';

  String cvv;
  String cardBrand;
  String cardBin = "";

  CreditCardInfo _creditCardInfo;

  _onExpirationDateTextChange(String s) {
    setState(() {
      expirationValue = s;
      unmaskedExpirationDateValue = expirationMaskFormatter.getEscapedString(s);
    });

    if (expirationValue.length >= 5) {
      FocusScope.of(context).requestFocus(_cardCvvFocusNode);
    }

    _validate();
  }

  _onCardNumberChanged(String s) {
    final _unmaskedCardNumber = creditCardTextInputFormatter.getRawString();

    if (_unmaskedCardNumber.isNotEmpty) {
      final r = CreditCardUtils(_unmaskedCardNumber);
      final f = r.cardIssuer;
      String _cardBrand;
      if (f == Issuers.VISA) {
        _cardBrand = "visa";
      }
      if (f == Issuers.MASTERCARD) {
        _cardBrand = "mastercard";
      }
      if (f == Issuers.VERVE) {
        _cardBrand = "verve";
      }

      if (f == Issuers.UNKNOWN) {
        _cardBrand = "verve";
      }

      if (_cardBrand != cardBrand) {
        setState(() {
          cardBrand = _cardBrand;
        });
      }
    }

    setState(() {
      cardNumber = _unmaskedCardNumber;
      unmaskedCardNumber = _unmaskedCardNumber;
    });

    _validate();
  }

  _onCvvChange(String s) {
    setState(() {
      cvv = s;
    });
    _validate();
  }

  _validate() {
    if (widget.onValidated != null) {
      widget.onValidated(null);
    }

    if (cardNumber == null || cardNumber.isEmpty) return;
    if (cvv == null || cvv.isEmpty) {
      return;
    }
    if (expirationValue == null || expirationValue.isEmpty) return;
    final expirationParts = expirationValue.split("/");

    _creditCardInfo = CreditCardInfo(
        cardNumber, expirationParts.first, expirationParts.last, cvv);
    _creditCardInfo.brand = cardBrand;

    if (widget.onValidated != null) {
      widget.onValidated(_creditCardInfo);
    }
  }

  @override
  void dispose() {
    _creditCardNumberController.dispose();
    _creditCardExpirationController.dispose();
    _cvvController.dispose();
    _cardCvvFocusNode.dispose();
    _cardExpDateFocusNode.dispose();
    _cardNumerFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(10.0),
      child: Column(
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(
              bottom: 20.0,
            ),
            child: Container(
              height: 50.0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Expanded(
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        "Enter your Card Details",
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      subtitle: Text(
                        "You will be charged $nairaSymbol${widget.amount}",
                        style: Theme.of(context).textTheme.subtitle.copyWith(
                              color: Colors.grey,
                            ),
                      ),
                    ),
                  ),
                  AnimatedOpacity(
                    opacity: 1.0,
                    duration: Duration(
                      milliseconds: 200,
                    ),
                    child: Image.asset(
                      Assets.logo,
                      package: 'flutter_rave',
                      width: 20.0,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 10.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  "Card Number",
                  style: Theme.of(context).textTheme.subtitle.copyWith(
                        fontSize: 14.0,
                        color: Colors.grey[600],
                      ),
                ),
                TextField(
                  focusNode: _cardNumerFocusNode,
                  controller: _creditCardNumberController,
                  onChanged: _onCardNumberChanged,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                  onSubmitted: (v) {
                    _onCardNumberChanged(v);
                    FocusScope.of(context).requestFocus(_cardCvvFocusNode);
                  },
                  inputFormatters: [
                    WhitelistingTextInputFormatter.digitsOnly,
                    creditCardTextInputFormatter,
                  ],
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    hintText: "0000 1234 1234 1234 1234",
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4.0),
                      borderSide: BorderSide(color: Colors.grey[200]),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4.0),
                      borderSide: BorderSide(
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    suffix: _makeCardIconWidget(cardBrand),
                  ),
                )
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 5.0),
            child: Container(
              width: MediaQuery.of(context).size.width,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                mainAxisSize: MainAxisSize.max,
                children: <Widget>[
                  Flexible(
                    child: Container(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            "Expiry Date",
                            style:
                                Theme.of(context).textTheme.subtitle.copyWith(
                                      fontSize: 14.0,
                                      color: Colors.grey[600],
                                    ),
                          ),
                          TextField(
                            focusNode: _cardExpDateFocusNode,
                            maxLength: 5,
                            maxLengthEnforced: true,
                            keyboardType: TextInputType.number,
                            onSubmitted: (v) {
                              _onExpirationDateTextChange(v);
                            },
                            buildCounter: (
                              c, {
                              int currentLength,
                              int maxLength,
                              bool isFocused,
                            }) {
                              return Container();
                            },
                            onChanged: _onExpirationDateTextChange,
                            inputFormatters: [
                              WhitelistingTextInputFormatter.digitsOnly,
                              expirationMaskFormatter,
                            ],
                            controller: _creditCardExpirationController,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.white,
                              hintText: "01/20",
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(4.0),
                                borderSide: BorderSide(color: Colors.grey[200]),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(4.0),
                                borderSide: BorderSide(
                                  color: Theme.of(context).primaryColor,
                                ),
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 10.0,
                  ),
                  Flexible(
                    child: Container(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            "CVV",
                            style:
                                Theme.of(context).textTheme.subtitle.copyWith(
                                      fontSize: 14.0,
                                      color: Colors.grey[600],
                                    ),
                          ),
                          TextField(
                            focusNode: _cardCvvFocusNode,
                            controller: _cvvController,
                            maxLength: 4,
                            maxLengthEnforced: true,
                            keyboardType: TextInputType.number,
                            onSubmitted: (v) {
                              _onCvvChange(v);
                            },
                            buildCounter: (
                              c, {
                              int currentLength,
                              int maxLength,
                              bool isFocused,
                            }) {
                              return Container();
                            },
                            onChanged: _onCvvChange,
                            inputFormatters: [
                              WhitelistingTextInputFormatter.digitsOnly,
                            ],
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.white,
                              hintText: "000",
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(4.0),
                                borderSide: BorderSide(color: Colors.grey[200]),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(4.0),
                                borderSide: BorderSide(
                                  color: Theme.of(context).primaryColor,
                                ),
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  _makeCardIconWidget([String brand]) {
    final size = 20.0;

    if (brand == null) {
      return null;
    }

    switch (brand.toLowerCase()) {
      case "mastercard":
        return SvgPicture.asset(
          Assets.mastercard,
          package: 'flutter_rave',
          width: size,
        );

      case "visa":
        return SvgPicture.asset(
          Assets.visa,
          width: size,
          package: 'flutter_rave',
          color: Colors.white,
        );

      case "verve":
        return Image.asset(
          Assets.verve,
          package: 'flutter_rave',
          width: size,
        );
    }

    return Image.asset(
      Assets.logo,
      package: 'flutter_rave',
      width: size,
    );
  }
}

class _CardAddedSuccessfully extends StatefulWidget {
  @override
  __CardAddedSuccessfullyState createState() => __CardAddedSuccessfullyState();
}

class __CardAddedSuccessfullyState extends State<_CardAddedSuccessfully> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
          child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(15.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              AnimatedOpacity(
                opacity: 1.0,
                duration: Duration(milliseconds: 500),
                curve: Curves.bounceIn,
                child: Container(
                  child: Icon(
                    Icons.check_circle,
                    size: 80.0,
                    color: Theme.of(context).accentColor,
                  ),
                ),
              ),
              SizedBox(
                height: 25,
              ),
              Text(
                "We've added your Debit Card",
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.title.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              SizedBox(
                height: 15,
              ),
              Text(
                "We've successfully added your card, you can now save with it.",
                style: Theme.of(context).textTheme.body1,
                textAlign: TextAlign.center,
              ),
              SizedBox(
                height: 25,
              ),
              SizedBox(
                width: double.infinity,
                child: FlatButton(
                  color: Theme.of(context).primaryColor,
                  disabledColor: Colors.grey[300],
                  onPressed: () {},
                  child: Text(
                    "Continue",
                    style: TextStyle(
                      color: Colors.white,
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      )),
    );
  }
}
