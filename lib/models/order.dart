class Order {
  int? id;
  String? orderNumber;
  int? fuelType;
  double? quantity;
  double? pricePerLiter;
  double? totalAmount;
  int? status;
  String? deliveryAddress;
  double? deliveryLatitude;
  double? deliveryLongitude;
  String? createdAt;

  Order({
    this.id,
    this.orderNumber,
    this.fuelType,
    this.quantity,
    this.pricePerLiter,
    this.totalAmount,
    this.status,
    this.deliveryAddress,
    this.deliveryLatitude,
    this.deliveryLongitude,
    this.createdAt});

  Order.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    orderNumber = json['orderNumber'];
    fuelType = json['fuelType'];
    quantity = (json['quantity'] is int)
        ? (json['quantity'] as int).toDouble()
        : json['quantity'];
    pricePerLiter = (json['pricePerLiter'] is int)
        ? (json['pricePerLiter'] as int).toDouble()
        : json['pricePerLiter'];
    totalAmount = (json['totalAmount'] is int)
        ? (json['totalAmount'] as int).toDouble()
        : json['totalAmount'];
    status = json['status'];
    deliveryAddress = json['deliveryAddress'];
    deliveryLatitude = (json['deliveryLatitude'] is int)
        ? (json['deliveryLatitude'] as int).toDouble()
        : json['deliveryLatitude'];
    deliveryLongitude = (json['deliveryLongitude'] is int)
        ? (json['deliveryLongitude'] as int).toDouble()
        : json['deliveryLongitude'];
    createdAt = json['createdAt'];
  }



  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['orderNumber'] = this.orderNumber;
    data['fuelType'] = this.fuelType;
    data['quantity'] = this.quantity;
    data['pricePerLiter'] = this.pricePerLiter;
    data['totalAmount'] = this.totalAmount;
    data['status'] = this.status;
    data['deliveryAddress'] = this.deliveryAddress;
    data['createdAt'] = this.createdAt;
    return data;
  }






}