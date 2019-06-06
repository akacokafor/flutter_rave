//library flutter_rave;

part of "flutter_rave.dart";

typedef Widget RaveWidgetBuilder(
  BuildContext context,
  VoidCallback processCard,
);

class RaveInAppLocalhostServer {
  HttpServer _server;
  int _port = 8184;
  Function(Map<String, dynamic>) _onResponse;

  RaveInAppLocalhostServer(
      {int port = 8184, Function(Map<String, dynamic>) onResponse}) {
    this._port = port;
    this._onResponse = onResponse;
  }

  Future<void> start() async {
    if (this._server != null) {
      throw Exception('Server already started on http://127.0.0.1:$_port');
    }
    var completer = new Completer();
    runZoned(() {
      HttpServer.bind('127.0.0.1', _port).then((server) {
        this._server = server;
        server.listen((HttpRequest request) async {
          var qParams = request.requestedUri.queryParameters;
          if (this._onResponse != null) {
            this._onResponse(qParams);
          }
          request.response.close();
        });

        completer.complete();
      });
    }, onError: (e, stackTrace) => print('Error: $e $stackTrace'));

    return completer.future;
  }

  ///Closes the server.
  Future<void> close() async {
    if (this._server != null) {
      await this._server.close(force: true);

      this._server = null;
    }
  }
}

class RaveProvider extends StatefulWidget {
  final RaveWidgetBuilder builder;
  final CreditCardInfo cardInfo;
  final List<Map<String, dynamic>> subaccounts;
  final String publicKey;
  final String encKey;
  final String transactionRef;
  final double amount;
  final String email;
  final Function onSuccess;
  final Function onFailure;
  final bool isDemo;

  RaveProvider({
    Key key,
    this.builder,
    this.isDemo = false,
    @required this.cardInfo,
    @required this.publicKey,
    @required this.encKey,
    this.subaccounts,
    this.transactionRef,
    this.amount,
    this.email,
    this.onSuccess,
    this.onFailure,
  }) : super(key: key);

  @override
  _RaveProviderState createState() => _RaveProviderState();
}

class _RaveProviderState extends State<RaveProvider> {
  RaveApiService _raveService = RaveApiService.instance;

  static const AUTH_PIN = "PIN";
  static const ACCESS_OTP = "ACCESS_OTP";
  static const NOAUTH_INTERNATIONAL = "NOAUTH_INTERNATIONAL";
  static const AVS_VBVSECURECODE = "AVS_VBVSECURECODE";
  RaveInAppLocalhostServer localhostServer;

  bool isProcessing = false;
  bool webhookSuccess = false;
  bool canContinue = false;
  Map<String, dynamic> responseResult;

  Route verificationRoute;
  BuildContext verificationRouteContext;

  @override
  void initState() {
    super.initState();
    this.webhookSuccess = false;
    this.canContinue = false;
    this.responseResult = null;
    verificationRoute = null;
    _startServer();
  }

  _startServer() async {
    localhostServer = RaveInAppLocalhostServer(
      onResponse: this.onRaveFeedback,
    );
    await localhostServer.start();
  }

  @override
  void dispose() {
    this.webhookSuccess = false;
    this.canContinue = false;
    this.responseResult = null;
    verificationRoute = null;
    localhostServer.close();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: AlignmentDirectional.center,
      children: <Widget>[
        Container(
          child: widget.builder(context, processCard),
        ),
        isProcessing
            ? OverlayLoaderWidget()
            : Container(
                width: 0,
                height: 0,
              ),
      ],
    );
  }

  Future<Map<String, dynamic>> processCard({
    String suggestedAuth,
    String redirectUrl = "http://127.0.0.1:8184",
    String suggestedAuthValue,
    Map<String, String> billingAddressInfo,
  }) async {
    try {
      if (widget.cardInfo == null) return null;
      if (!widget.cardInfo.isComplete) return null;

      String authValue;

      setState(() {
        isProcessing = true;
      });

      var response = await _raveService.startChargeCard(
        widget.cardInfo,
        widget.publicKey,
        widget.encKey,
        email: widget.email,
        isProduction: !widget.isDemo,
        transactionReference: widget.transactionRef,
        amount: widget.amount,
        redirectUrl: redirectUrl,
        suggestedAuth: suggestedAuth,
        suggestedAuthValue: suggestedAuthValue,
        billingAddressInfo: billingAddressInfo,
        subaccounts: widget.subaccounts,
      );

      setState(() {
        isProcessing = false;
      });

      if (response["message"] == "AUTH_SUGGESTION") {
        if (response["data"]["suggested_auth"] == AUTH_PIN) {
          authValue = await _getAuthValue(response["data"]["suggested_auth"]);

          setState(() {
            isProcessing = false;
          });

          return processCard(
            suggestedAuth: response["data"]["suggested_auth"],
            suggestedAuthValue: authValue,
          );
        }

        if (response["data"]["suggested_auth"] == AVS_VBVSECURECODE ||
            response["data"]["suggested_auth"] == NOAUTH_INTERNATIONAL) {
          final additionalPayload = await _collectAddressDetails();

          setState(() {
            isProcessing = false;
          });

          return processCard(
            suggestedAuth: response["data"]["suggested_auth"],
            suggestedAuthValue: null,
            billingAddressInfo: additionalPayload,
          );
        }
      }

      if (response["message"] == "V-COMP" &&
          response["data"]["chargeResponseCode"] == "02") {
        if (response["data"]["authModelUsed"] == ACCESS_OTP) {
          final otp = await _getAuthValue(
            "OTP",
            response["data"]["chargeResponseMessage"],
          );

          try {
            setState(() {
              isProcessing = true;
            });
            final r = await _raveService.validateTransaction(
              response["data"]["flwRef"],
              otp,
              widget.publicKey,
              !widget.isDemo,
            );

            setState(() {
              isProcessing = false;
            });
            return r;
          } catch (e) {
            setState(() {
              isProcessing = false;
            });
            rethrow;
          }
        } else if (response["data"]["authModelUsed"] == "PIN") {
          final otp = await _getAuthValue(
            "OTP",
            response["data"]["chargeResponseMessage"],
          );

          try {
            setState(() {
              isProcessing = true;
            });
            final r = await _raveService.validateTransaction(
              response["data"]["flwRef"],
              otp,
              widget.publicKey,
              !widget.isDemo,
            );

            setState(() {
              isProcessing = false;
            });
            return r;
          } catch (e) {
            setState(() {
              isProcessing = false;
            });
            rethrow;
          }
        } else if (response["data"]["authModelUsed"] == "VBVSECURECODE") {
          final uri = Uri.parse(response["data"]["authurl"]);
          var raveVerificationData;

          verificationRoute = MaterialPageRoute<Map<String, dynamic>>(
            builder: (c) {
              verificationRouteContext = c;

              return WebviewScaffold(
                url: uri.toString(),
                appBar: AppBar(
                  elevation: 0,
                  backgroundColor: Colors.white,
                  centerTitle: true,
                  shape: Border(
                    bottom: BorderSide(
                      color: Colors.grey[500],
                    ),
                  ),
                  iconTheme: IconThemeData(
                    color: Colors.grey[600],
                  ),
                  title: const Text(
                    'Card Verification',
                    style: TextStyle(
                      fontSize: 12.0,
                      fontWeight: FontWeight.w500,
                      color: Colors.green,
                    ),
                  ),
                ),
                withZoom: false,
                withLocalStorage: true,
                withJavascript: true,
                hidden: true,
                initialChild: Center(
                  child: CupertinoActivityIndicator(),
                ),
              );
            },
            fullscreenDialog: true,
          );
          await Navigator.of(context).push(verificationRoute);

          if (!webhookSuccess) {
            throw "Failed to process transaction $uri";
          }
          raveVerificationData = responseResult;

          if (raveVerificationData != null &&
              raveVerificationData["chargeResponseCode"].toString() == "00") {
            setState(() {
              isProcessing = false;
            });

            return raveVerificationData;
          }
        }
      }

      if (response["message"] == "V-COMP" &&
          response["data"]["chargeResponseCode"] == "00") {
        setState(() {
          isProcessing = false;
        });

        return response;
      }

      setState(() {
        isProcessing = false;
      });

      return null;
    } catch (e) {
      if (mounted) {
        Scaffold.of(context).showSnackBar(
          SnackBar(
            content: Text("${e.toString()}"),
            duration: Duration(
              seconds: 5,
            ),
            backgroundColor: Colors.red,
          ),
        );

        setState(() {
          isProcessing = false;
        });
      }
      rethrow;
    }
  }

  Future<String> _getAuthValue(String response, [String message]) async {
    final _value = await _showValueModal(
      title: response,
      message: message ?? "Please provide your $response",
    );

    return _value;
  }

  Future<String> _showValueModal({String title, String message}) async {
    String value = await showDialog<String>(
      barrierDismissible: false,
      context: context,
      builder: (c) {
        return ValueCollectorComponent(
            title: title,
            message: message,
            onValueCollected: (value) {
              Navigator.of(
                c,
                rootNavigator: true,
              ).pop(value);
            });
      },
    );

    return value;
  }

  Future<Map<String, String>> _collectAddressDetails() async {
    return await Navigator.of(context).push<Map<String, String>>(
      MaterialPageRoute<Map<String, String>>(
        builder: (c) => BillingInfoProvider(),
        fullscreenDialog: true,
      ),
    );
  }

  onRaveFeedback(Map<String, dynamic> feedback) {
    if (feedback != null && feedback.containsKey("response")) {
      this.responseResult = json.decode(feedback["response"]);
      this.canContinue = true;
      this.webhookSuccess = true;

      if (verificationRoute != null && verificationRouteContext != null) {
        Navigator.of(verificationRouteContext).pop(this.responseResult);
      }

      setState(() {});
    }
  }
}

class BillingInfoProvider extends StatefulWidget {
  @override
  _BillingInfoProviderState createState() => _BillingInfoProviderState();
}

class _BillingInfoProviderState extends State<BillingInfoProvider> {
  GlobalKey<FormState> _globalKey = GlobalKey();

  String billingzip = "";
  String billingcity = "";
  String billingaddress = "";
  String billingstate = "";
  String billingcountry = "";

  Future<List<Map<String, dynamic>>> countries;

  Map<String, dynamic> selectedCountry;
  Map<String, dynamic> selectedState;

  @override
  void initState() {
    super.initState();

    countries = fetchCountries(context);
  }

  List<Map<String, dynamic>> parseCountries(String responseBody) {
    final decoded = json.decode(responseBody);
    final parsed = (decoded as List<dynamic>)
        .map((i) => (i as Map<String, dynamic>))
        .toList();
    return parsed;
  }

  Future<List<Map<String, dynamic>>> fetchCountries(
      BuildContext context) async {
    try {
      final response = await rootBundle.loadString(Assets.jsonCountries);

      return parseCountries(response); // compute(, response);
    } catch (e) {
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
          child: SingleChildScrollView(
        child: Form(
          key: _globalKey,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 20.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  "Provide your Billing details",
                  style: Theme.of(context).textTheme.title.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                SizedBox(
                  height: 15,
                ),
                Text(
                  "Your billings details are required to validate your card",
                  style: Theme.of(context).textTheme.body1,
                ),
                SizedBox(
                  height: 15,
                ),
                TextFormField(
                  textInputAction: TextInputAction.continueAction,
                  keyboardType: TextInputType.text,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty)
                      return "Address is required";
                  },
                  onSaved: (v) {
                    setState(() {
                      billingaddress = v;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: "Address",
                  ),
                ),
                SizedBox(
                  height: 15,
                ),
                FutureBuilder<List<Map<String, dynamic>>>(
                    future: countries,
                    builder: (context, snapshot) {
                      return DropdownButton<Map<String, dynamic>>(
                        items: !snapshot.hasData
                            ? []
                            : snapshot.data
                                .map(
                                  (i) => DropdownMenuItem<Map<String, dynamic>>(
                                        value: i,
                                        child: Text(
                                          i["name"],
                                        ),
                                      ),
                                )
                                .toList(),
                        hint: Text("Select Country"),
                        value: selectedCountry,
                        onChanged: (item) {
                          setState(() {
                            selectedCountry = item;
                            billingcountry = item["code2"];
                          });
                        },
                      );
                    }),
                SizedBox(
                  height: 15,
                ),
                DropdownButton<Map<String, dynamic>>(
                  items: selectedCountry == null
                      ? []
                      : (selectedCountry["states"] as List<dynamic>)
                          .map((i) => (i as Map<String, dynamic>))
                          .map((i) => DropdownMenuItem<Map<String, dynamic>>(
                                value: i,
                                child: Text(
                                  i["name"],
                                ),
                              ))
                          .toList(),
                  hint: Text("Select State"),
                  value: selectedState,
                  onChanged: (item) {
                    setState(() {
                      selectedState = item;
                      billingstate = item["code"];
                    });
                  },
                ),
                SizedBox(
                  height: 15,
                ),
                TextFormField(
                  textInputAction: TextInputAction.continueAction,
                  keyboardType: TextInputType.text,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty)
                      return "Name is required";
                  },
                  onSaved: (v) {
                    setState(() {
                      billingcity = v;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: "Your City Code",
                    helperText: "Example: LA",
                  ),
                ),
                SizedBox(
                  height: 15,
                ),
                TextFormField(
                  textInputAction: TextInputAction.continueAction,
                  keyboardType: TextInputType.text,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty)
                      return "Zip Code is required";
                  },
                  onSaved: (v) {
                    setState(() {
                      billingzip = v;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: "Zip Code",
                  ),
                ),
                SizedBox(
                  height: 15,
                ),
                FlatButton(
                  color: Theme.of(context).accentColor,
                  onPressed: () {
                    _globalKey.currentState.save();
                    if (_globalKey.currentState.validate()) {
                      Navigator.of(context).pop({
                        "billingaddress": billingaddress,
                        "billingcountry": billingcountry,
                        "billingzip": billingzip,
                        "billingstate": billingstate,
                        "billingcity": billingcity,
                      });
                    }
                  },
                  child: Text(
                    "Continue",
                    style: TextStyle(
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      )),
    );
  }
}

class ValueCollectorComponent extends StatefulWidget {
  final String title;
  final String message;
  final Function(String) onValueCollected;

  const ValueCollectorComponent({
    Key key,
    this.title,
    this.message,
    this.onValueCollected,
  }) : super(key: key);

  @override
  _ValueCollectorComponentState createState() =>
      _ValueCollectorComponentState();
}

class _ValueCollectorComponentState extends State<ValueCollectorComponent> {
  String value;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.title,
        style: Theme.of(context)
            .textTheme
            .title
            .copyWith(color: Theme.of(context).primaryColor),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(bottom: 10.0),
            child: Text(
              widget.message,
              style: Theme.of(context).textTheme.body1,
            ),
          ),
          TextField(
            keyboardType: TextInputType.numberWithOptions(),
            inputFormatters: [
              WhitelistingTextInputFormatter.digitsOnly,
            ],
            onChanged: (v) {
              setState(() {
                value = v?.trim();
              });
            },
            decoration: InputDecoration(
              hintText: "Enter ${widget.title}",
            ),
          ),
          SizedBox(
            height: 30,
          ),
          SizedBox(
            width: double.infinity,
            child: RaisedButton(
              onPressed: () {
                if (value != null && value.isNotEmpty) {
                  if (widget.onValueCollected != null) {
                    widget.onValueCollected(value);
                  }
                }
              },
              child: Text(
                "Submit",
                style: TextStyle(
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
