class ResponseBase<T> {
  final int status;
  final T? data;
  final String message;

  ResponseBase({
    required this.status,
    required this.data,
    required this.message,
  });

  factory ResponseBase.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic json) fromJsonT,
  ) {
    return ResponseBase(
      status: json['status'] ?? 0,
      data: json['data'] != null ? fromJsonT(json['data']) : null,
      message: json['message'] ?? '',
    );
  }
}
