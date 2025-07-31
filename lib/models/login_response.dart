class LoginResponse {
  final String token;
  final String username;
  final String fullName;
  final String? avatar;

  LoginResponse({
    required this.token,
    required this.username,
    required this.fullName,
    this.avatar,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      token: json['token'],
      username: json['Username'],
      fullName: json['FullName'],
      avatar: json['Avatar'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'Username': username,
      'FullName': fullName,
      'Avatar': avatar,
    };
  }
}
