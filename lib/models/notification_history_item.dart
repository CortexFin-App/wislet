class NotificationHistoryItem {
  NotificationHistoryItem({
    required this.title,
    required this.body,
    required this.timestamp,
    this.id,
    this.payload,
    this.isRead = false,
  });

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

  final int? id;
  final String title;
  final String body;
  final String? payload;
  final DateTime timestamp;
  final bool isRead;

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
}
