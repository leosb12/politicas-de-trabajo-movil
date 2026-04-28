class ResetPasswordRequestModel {
  const ResetPasswordRequestModel({
    required this.token,
    required this.newPassword,
  });

  final String token;
  final String newPassword;

  Map<String, dynamic> toJson() => {
    'token': token,
    'newPassword': newPassword,
  };

  factory ResetPasswordRequestModel.fromJson(Map<String, dynamic> json) =>
      ResetPasswordRequestModel(
        token: json['token'] as String,
        newPassword: json['newPassword'] as String,
      );
}
