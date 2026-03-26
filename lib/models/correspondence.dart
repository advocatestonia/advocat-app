class Correspondence {
  final String id;
  final String caseId;
  final String userId;
  final String subject;
  final String body;
  final String sender;
  final String recipient;
  final CorrespondenceDirection direction;
  final CorrespondenceChannel channel;
  final String? aiSummary;
  final List<String> extractedActionItems;
  final List<String> attachmentIds;
  final bool isRead;
  final DateTime sentAt;
  final DateTime createdAt;

  const Correspondence({
    required this.id,
    required this.caseId,
    required this.userId,
    required this.subject,
    required this.body,
    required this.sender,
    required this.recipient,
    this.direction = CorrespondenceDirection.incoming,
    this.channel = CorrespondenceChannel.email,
    this.aiSummary,
    this.extractedActionItems = const [],
    this.attachmentIds = const [],
    this.isRead = false,
    required this.sentAt,
    required this.createdAt,
  });

  Correspondence copyWith({
    String? id,
    String? caseId,
    String? userId,
    String? subject,
    String? body,
    String? sender,
    String? recipient,
    CorrespondenceDirection? direction,
    CorrespondenceChannel? channel,
    String? aiSummary,
    List<String>? extractedActionItems,
    List<String>? attachmentIds,
    bool? isRead,
    DateTime? sentAt,
    DateTime? createdAt,
  }) {
    return Correspondence(
      id: id ?? this.id,
      caseId: caseId ?? this.caseId,
      userId: userId ?? this.userId,
      subject: subject ?? this.subject,
      body: body ?? this.body,
      sender: sender ?? this.sender,
      recipient: recipient ?? this.recipient,
      direction: direction ?? this.direction,
      channel: channel ?? this.channel,
      aiSummary: aiSummary ?? this.aiSummary,
      extractedActionItems: extractedActionItems ?? this.extractedActionItems,
      attachmentIds: attachmentIds ?? this.attachmentIds,
      isRead: isRead ?? this.isRead,
      sentAt: sentAt ?? this.sentAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory Correspondence.fromJson(Map<String, dynamic> json) {
    return Correspondence(
      id: json['id'] as String,
      caseId: json['case_id'] as String,
      userId: json['user_id'] as String,
      subject: json['subject'] as String,
      body: json['body'] as String,
      sender: json['sender'] as String,
      recipient: json['recipient'] as String,
      direction: json['direction'] == 'outgoing'
          ? CorrespondenceDirection.outgoing
          : CorrespondenceDirection.incoming,
      channel: _channelFromJson(json['channel'] as String?),
      aiSummary: json['ai_summary'] as String?,
      extractedActionItems: (json['extracted_action_items'] as List<dynamic>?)
              ?.cast<String>() ??
          [],
      attachmentIds:
          (json['attachment_ids'] as List<dynamic>?)?.cast<String>() ?? [],
      isRead: json['is_read'] as bool? ?? false,
      sentAt: DateTime.parse(json['sent_at'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'case_id': caseId,
      'user_id': userId,
      'subject': subject,
      'body': body,
      'sender': sender,
      'recipient': recipient,
      'direction': direction == CorrespondenceDirection.outgoing ? 'outgoing' : 'incoming',
      'channel': _channelToJson(channel),
      'ai_summary': aiSummary,
      'extracted_action_items': extractedActionItems,
      'attachment_ids': attachmentIds,
      'is_read': isRead,
      'sent_at': sentAt.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  static CorrespondenceChannel _channelFromJson(String? value) {
    switch (value) {
      case 'postal': return CorrespondenceChannel.postal;
      case 'portal': return CorrespondenceChannel.portal;
      default: return CorrespondenceChannel.email;
    }
  }

  static String _channelToJson(CorrespondenceChannel channel) {
    switch (channel) {
      case CorrespondenceChannel.email: return 'email';
      case CorrespondenceChannel.postal: return 'postal';
      case CorrespondenceChannel.portal: return 'portal';
    }
  }
}

enum CorrespondenceDirection {
  incoming,
  outgoing,
}

enum CorrespondenceChannel {
  email,
  postal,
  portal,
}
