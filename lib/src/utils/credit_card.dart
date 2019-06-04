final Map _INDUSTRY_IDENTIFIER_MAP = {
  "1": Industries.AIRLINES,
  "2": Industries.AIRLINES,
  "3": Industries.TRAVEL_AND_ENTERTAINMENT,
  "4": Industries.BANKING_AND_FINANCIAL,
  "5": Industries.BANKING_AND_FINANCIAL,
  "6": Industries.MERCHANDIZING_AND_BANKING,
  "7": Industries.PETROLEUM,
  "8": Industries.TELECOMMUNICATIONS,
  "9": Industries.NATIONAL_ASSIGNMENT
};

final List _ISSUER_IDENTIFIER_LIST = [
  {"RegExp": new RegExp(r'^4'), "Issuers": Issuers.VISA},
  {"RegExp": new RegExp(r'^5[1-5]'), "Issuers": Issuers.MASTERCARD},
  {"RegExp": new RegExp(r'^50'), "Issuers": Issuers.VERVE},
  {"RegExp": new RegExp(r'^6(0|4|5)(1|4)?(1)?'), "Issuers": Issuers.DISCOVER},
  {"RegExp": new RegExp(r'^3(4|7)'), "Issuers": Issuers.AMEX}
];

class CreditCardUtils {
  String cardNumber;
  Issuers cardIssuer;
  Industries cardIndustry;
  bool valid;

  CreditCardUtils(String number) {
    this.cardNumber = number.replaceAll(new RegExp(r"-|\s"), "");
    this._load();
  }

  CreditCardUtils.clean(String number, RegExp patten) {
    this.cardNumber = number.replaceAll(patten, "");
    this._load();
  }

  bool _check(String number) {
    var reg = new RegExp(r'^\d*$');
    return reg.hasMatch(number) && number.isNotEmpty;
  }

  _load() {
    if (_check(this.cardNumber)) {
      this.valid = this._validate(this.cardNumber);
      this.cardIndustry = this._industry(this.cardNumber);
      this.cardIssuer = this._issuer(this.cardNumber);
    } else {
      throw new FormatException("Unclean Input: ${this.cardNumber}");
    }
  }

  int _calculate(luhn) {
    var sum = luhn
        .split("")
        .map((e) => int.parse(e, radix: 10))
        .reduce((a, b) => a + b);

    var delta = [0, 1, 2, 3, 4, -4, -3, -2, -1, 0];
    for (var i = luhn.length - 1; i >= 0; i -= 2) {
      sum += delta[int.parse(luhn.substring(i, i + 1), radix: 10)];
    }

    var mod10 = 10 - (sum % 10);
    return mod10 == 10 ? 0 : mod10;
  }

  bool _validate(luhn) {
    var luhnDigit =
        int.parse(luhn.substring(luhn.length - 1, luhn.length), radix: 10);
    var luhnLess = luhn.substring(0, luhn.length - 1);
    return (this._calculate(luhnLess) == luhnDigit);
  }

  Industries _industry(String number) {
    return _INDUSTRY_IDENTIFIER_MAP[number.substring(0, 1)];
  }

  Issuers _issuer(String number) {
    Issuers issuer = Issuers.UNKNOWN;
    var issuerID = number.substring(0, 6);
    _ISSUER_IDENTIFIER_LIST.forEach((item) {
      if (item["RegExp"].hasMatch(issuerID)) {
        issuer = item["Issuers"];
      }
    });
    return issuer;
  }

  toJson() => {
        "number": this.cardNumber,
        "industry": this.cardIndustry,
        "issuer": this.cardIssuer,
        "valid": this.valid
      };

  toString() =>
      "number: ${this.cardNumber}, industry: ${this.cardIndustry}, issuer: ${this.cardIssuer}, valid: ${this.valid}";
}

class Industries {
  final _value;
  const Industries._internal(this._value);
  toString() => '$_value';
  toJson() => '$_value';

  static const AIRLINES = const Industries._internal('Airlines');
  static const TRAVEL_AND_ENTERTAINMENT =
      const Industries._internal('Travel and Entertainment');
  static const BANKING_AND_FINANCIAL =
      const Industries._internal('Banking and Financial');
  static const MERCHANDIZING_AND_BANKING =
      const Industries._internal('Merchandizing and Banking');
  static const PETROLEUM = const Industries._internal('Petroleum');
  static const TELECOMMUNICATIONS =
      const Industries._internal('Telecommunications');
  static const NATIONAL_ASSIGNMENT =
      const Industries._internal('National Assignment');
}

class Issuers {
  final _value;
  const Issuers._internal(this._value);
  toString() => '$_value';
  toJson() => '$_value';

  static const VISA = const Issuers._internal('Visa');
  static const MASTERCARD = const Issuers._internal('Mastercard');
  static const DISCOVER = const Issuers._internal('Discover');
  static const AMEX = const Issuers._internal('Amex');
  static const VERVE = const Issuers._internal('Verve');
  static const UNKNOWN = const Issuers._internal('Unknown');
}
