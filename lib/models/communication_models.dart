class Consultation {
  final int? id;
  final String? scanId;
  final String farmerId;
  final String? agronomistId;
  final String? governmentOfficerId;
  final String consultationType;
  final String status;
  final String? farmerMessage;
  final String? agronomistResponse;
  final DateTime? scheduledAt;
  final DateTime? completedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  Consultation({
    this.id,
    this.scanId,
    required this.farmerId,
    this.agronomistId,
    this.governmentOfficerId,
    this.consultationType = 'chat',
    this.status = 'pending',
    this.farmerMessage,
    this.agronomistResponse,
    this.scheduledAt,
    this.completedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Consultation.fromJson(Map<String, dynamic> json) {
    return Consultation(
      id: json['id'] as int?,
      scanId: json['scan_id'] as String?,
      farmerId: json['farmer_id'] as String,
      agronomistId: json['agronomist_id'] as String?,
      governmentOfficerId: json['government_officer_id'] as String?,
      consultationType: json['consultation_type'] as String? ?? 'chat',
      status: json['status'] as String? ?? 'pending',
      farmerMessage: json['farmer_message'] as String?,
      agronomistResponse: json['agronomist_response'] as String?,
      scheduledAt: json['scheduled_at'] != null ? DateTime.parse(json['scheduled_at'] as String) : null,
      completedAt: json['completed_at'] != null ? DateTime.parse(json['completed_at'] as String) : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (scanId != null) 'scan_id': scanId,
      'farmer_id': farmerId,
      if (agronomistId != null) 'agronomist_id': agronomistId,
      if (governmentOfficerId != null) 'government_officer_id': governmentOfficerId,
      'consultation_type': consultationType,
      'status': status,
      if (farmerMessage != null) 'farmer_message': farmerMessage,
      if (agronomistResponse != null) 'agronomist_response': agronomistResponse,
      if (scheduledAt != null) 'scheduled_at': scheduledAt!.toIso8601String(),
      if (completedAt != null) 'completed_at': completedAt!.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class Message {
  final int? id;
  final int? consultationId;
  final String senderId;
  final String receiverId;
  final String messageType;
  final String content;
  final String? attachmentUrl;
  final bool isRead;
  final DateTime? readAt;
  final DateTime createdAt;

  Message({
    this.id,
    this.consultationId,
    required this.senderId,
    required this.receiverId,
    this.messageType = 'text',
    required this.content,
    this.attachmentUrl,
    this.isRead = false,
    this.readAt,
    required this.createdAt,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] as int?,
      consultationId: json['consultation_id'] as int?,
      senderId: json['sender_id'] as String,
      receiverId: json['receiver_id'] as String,
      messageType: json['message_type'] as String? ?? 'text',
      content: json['content'] as String,
      attachmentUrl: json['attachment_url'] as String?,
      isRead: json['is_read'] as bool? ?? false,
      readAt: json['read_at'] != null ? DateTime.parse(json['read_at'] as String) : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (consultationId != null) 'consultation_id': consultationId,
      'sender_id': senderId,
      'receiver_id': receiverId,
      'message_type': messageType,
      'content': content,
      if (attachmentUrl != null) 'attachment_url': attachmentUrl,
      'is_read': isRead,
      if (readAt != null) 'read_at': readAt!.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class Notification {
  final int? id;
  final String userId;
  final String notificationType;
  final String title;
  final String body;
  final dynamic data;
  final bool isRead;
  final DateTime? readAt;
  final DateTime createdAt;

  Notification({
    this.id,
    required this.userId,
    required this.notificationType,
    required this.title,
    required this.body,
    this.data,
    this.isRead = false,
    this.readAt,
    required this.createdAt,
  });

  factory Notification.fromJson(Map<String, dynamic> json) {
    return Notification(
      id: json['id'] as int?,
      userId: json['user_id'] as String,
      notificationType: json['notification_type'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      data: json['data'],
      isRead: json['is_read'] as bool? ?? false,
      readAt: json['read_at'] != null ? DateTime.parse(json['read_at'] as String) : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'notification_type': notificationType,
      'title': title,
      'body': body,
      if (data != null) 'data': data,
      'is_read': isRead,
      if (readAt != null) 'read_at': readAt!.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }
}
