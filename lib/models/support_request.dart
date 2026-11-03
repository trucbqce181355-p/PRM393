// Author: Chih An (GitHub: ChangChinAn)
// UC16: Dữ liệu yêu cầu hỗ trợ và trạng thái cho phép chỉnh sửa/hủy.
class SupportRequest {
  const SupportRequest({required this.id, required this.orderId, required this.reason,
    required this.description, required this.status, required this.createdAt, this.adminReply});
  final String id;
  final String orderId;
  final String reason;
  final String description;
  final String status;
  final DateTime createdAt;
  final String? adminReply;
  bool get isPending => status == 'pending';
  String get statusLabel => switch (status) {
    'pending' => 'Chưa xử lý', 'approved' => 'Đã chấp thuận',
    'rejected' => 'Đã từ chối', 'cancelled' => 'Đã hủy', _ => 'Đã xử lý',
  };
  factory SupportRequest.fromJson(Map<String, dynamic> json) => SupportRequest(
    id: json['id'] as String, orderId: json['orderId'] as String? ?? '', reason: json['reason'] as String,
    description: json['description'] as String, status: json['status'] as String,
    adminReply: json['adminReply'] as String?, createdAt: DateTime.parse(json['createdAt'] as String));
}
