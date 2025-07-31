class UserInfo {
  final String username;
  final String fullName;
  final String? avatar;

  UserInfo({
    required this.username,
    required this.fullName,
    required this.avatar,
  });

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    return UserInfo(
      username: json['Username'],
      fullName: json['FullName'],
      avatar: json['Avatar'],
    );
  }

  Map<String, dynamic> toJson(){
    return {
      'Username': username,
      'FullName': fullName,
      'Avatar': avatar,
    };
  }
}
