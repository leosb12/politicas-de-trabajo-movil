class ForgotPasswordRequestModel {
  const ForgotPasswordRequestModel({
    required this.email,
  });

  final String email;

  Map<String, dynamic> toJson() => {
    'email': email,
  };

  factory ForgotPasswordRequestModel.fromJson(Map<String, dynamic> json) =>
      ForgotPasswordRequestModel(
        email: json['email'] as String,
      );
}
