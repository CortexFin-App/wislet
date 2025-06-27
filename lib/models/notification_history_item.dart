class NotificationHistoryItem {
  final int? id;
  final String title;
  final String body;
  final String? payload;
  final DateTime timestamp;
  final bool isRead;

  NotificationHistoryItem({
    this.id,
    required this.title,
    required this.body,
    this.payload,
    required this.timestamp,
    this.isRead = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'payload': payload,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead ? 1 : 0,
    };
  }

  factory NotificationHistoryItem.fromMap(Map<String, dynamic> map) {
    return NotificationHistoryItem(
      id: map['id'] as int?,
      title: map['title'] as String,
      body: map['body'] as String,
      payload: map['payload'] as String?,
      timestamp: DateTime.parse(map['timestamp'] as String),
      isRead: (map['isRead'] as int) == 1,
    );
  }
}