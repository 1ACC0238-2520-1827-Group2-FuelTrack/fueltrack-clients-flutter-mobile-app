class Payment {
  int? id;
  int? orderId;
  String? orderNumber;
  double? amount;
  String? transactionId;
  String? processedAt;
  String? createdAt;
  String? cardHolderName;
  String? lastFourDigits;
  String? cardType;

  Payment({
    this.id,
    this.orderId,
    this.orderNumber,
    this.amount,
    this.transactionId,
    this.processedAt,
    this.createdAt,
    this.cardHolderName,
    this.lastFourDigits,
    this.cardType
  });

  Payment.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    orderId = json['orderId'];
    orderNumber = json['orderNumber'];
    amount = json['amount'].toDouble();
    transactionId = json['transactionId'];
    processedAt = json['processedAt'];
    createdAt = json['createdAt'];
    cardHolderName = json['cardHolderName'];
    lastFourDigits = json['lastFourDigits'];
    cardType = json['cardType'];
  }

}