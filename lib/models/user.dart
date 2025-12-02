class User {
  int? id;
  String? accessToken;
  String? refreshToken;
  String? role;

  User({
        this.id,
        this.accessToken,
        this.refreshToken,
        this.role});

  User.fromJson(Map<String, dynamic> json) {
    final dynamic userObj = json['user'];
    if (userObj != null) {
      final dynamic rawId = userObj['id'] ?? userObj['ID'];
      if (rawId != null) {
        id = rawId is int ? rawId : int.tryParse(rawId.toString());
      }
      role = userObj['role'] ?? userObj['rol'];
    } else {
      final dynamic rawId = json['id'] ?? json['ID'];
      if (rawId != null) {
        id = rawId is int ? rawId : int.tryParse(rawId.toString());
      }
      role = json['role'] ?? json['rol'];
    }
    accessToken = json['accessToken'] ?? json['access_token'] ?? json['token'];
    refreshToken = json['refreshToken'] ?? json['refresh_token'];
  }



  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['refreshToken'] = this.refreshToken;
    return data;
  }


  Map<String, dynamic> toMap(){
    return{
      'id': id,
      'accessToken': accessToken,
      'refreshToken': refreshToken,
      'role': role,
    };
  }


}