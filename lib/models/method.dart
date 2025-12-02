// lib/models/method.dart
class Method {
  int? id;
  String? cardHolderName;
  String? lastFourDigits;
  String? cardType;
  String? expiryDate;
  bool? isDefault;

  Method({
    this.id,
    this.cardHolderName,
    this.lastFourDigits,
    this.cardType,
    this.expiryDate,
    this.isDefault,
  });

  Method.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    cardHolderName = json['cardHolderName'];
    lastFourDigits = json['lastFourDigits'];
    cardType = json['cardType'];
    expiryDate = json['expiryDate'];
    isDefault = json['isDefault'] == 1 || json['isDefault'] == true;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'cardHolderName': cardHolderName,
      'lastFourDigits': lastFourDigits,
      'cardType': cardType,
      'expiryDate': expiryDate,
      'isDefault': isDefault == true ? 1 : 0,
    };
  }
}
