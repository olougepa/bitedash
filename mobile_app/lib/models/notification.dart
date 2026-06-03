class NotificationItem {
  final int id;
  final String title;
  final String message;
  final String category;
  bool isRead;

  NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.category,
    this.isRead = false,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      message: json['message'] as String? ?? '',
      category: json['category'] as String? ?? 'all',
      isRead: (json['is_read'] ?? 0) == 1,
    );
  }
}
