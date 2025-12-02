
class Notification {
  int? id;
  String? title;
  String? message;
  int? type;
  bool? isRead;
  int? relatedOrderId;
  String? relatedOrderNumber;
  String? createdAt;

  Notification({
    this.id,
    this.title,
    this.message,
    this.type,
    this.isRead,
    this.relatedOrderId,
    this.relatedOrderNumber,
    this.createdAt});

  Notification.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    title = json['title'];
    message = json['message'];
    type = json['type'];
    isRead = json['isRead'];
    relatedOrderId = json['relatedOrderId'];
    relatedOrderNumber = json['relatedOrderNumber'];
    createdAt = json['createdAt'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['title'] = this.title;
    data['message'] = this.message;
    data['type'] = this.type;
    data['is_read'] = this.isRead;
    data['related_order_id'] = this.relatedOrderId;
    data['related_order_number'] = this.relatedOrderNumber;
    data['created_at'] = this.createdAt;
    return data;
  }



}