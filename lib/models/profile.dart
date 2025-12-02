class Profile{
  int? id;
  String? firstName;
  String? lastName;
  String? email;
  String? phone;

  Profile({
    this.id,
    this.firstName,
    this.lastName,
    this.email,
    this.phone
  });

  Profile.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    firstName = json['firstName'];
    lastName = json['lastName'];
    email = json['email'];
    phone = json['phone'];
  }


  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['firstName'] = this.firstName;
    data['lastName'] = this.lastName;
    data['phone'] = this.phone;
    return data;
  }


}