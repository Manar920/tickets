class CommentModel {
  final String? id;
  final String ticketId;
  final String userId;
  final String userEmail;
  final String userRole; // 'client', 'admin', 'support'
  final String message;
  final DateTime createdAt;
  final List<String> attachmentUrls;

  CommentModel({
    this.id,
    required this.ticketId,
    required this.userId,
    required this.userEmail,
    required this.userRole,
    required this.message,
    required this.createdAt,
    this.attachmentUrls = const [],
  });

  // Create from Map for Realtime Database
  factory CommentModel.fromMap(Map<String, dynamic> data, String documentId) {
    // Handle attachment URLs
    List<String> attachments = [];
    if (data['attachmentUrls'] != null) {
      if (data['attachmentUrls'] is List) {
        attachments = List<String>.from(data['attachmentUrls']);
      } else if (data['attachmentUrls'] is String) {
        attachments = [data['attachmentUrls']];
      }
    }
    
    // Handle createdAt timestamp 
    DateTime createdAt;
    if (data['createdAt'] is Map) {
      // Handle Firestore Timestamp format if present
      createdAt = DateTime.fromMillisecondsSinceEpoch(
        (data['createdAt']['seconds'] * 1000) + 
        ((data['createdAt']['nanoseconds'] ?? 0) ~/ 1000000));
    } else if (data['createdAt'] is String) {
      // Handle ISO8601 string format
      createdAt = DateTime.parse(data['createdAt']);
    } else if (data['createdAt'] is int) {
      // Handle milliseconds since epoch integer
      createdAt = DateTime.fromMillisecondsSinceEpoch(data['createdAt']);
    } else {
      // Default to now if format is unknown
      createdAt = DateTime.now();
      print('Warning: Unknown timestamp format for comment $documentId');
    }
    
    return CommentModel(
      id: documentId,
      ticketId: data['ticketId'] ?? '',
      userId: data['userId'] ?? '',
      userEmail: data['userEmail'] ?? '',
      userRole: data['userRole'] ?? 'client',
      message: data['message'] ?? '',
      createdAt: createdAt,
      attachmentUrls: attachments,
    );
  }
  // Convert to map for Realtime Database
  Map<String, dynamic> toMap() {
    return {
      'ticketId': ticketId,
      'userId': userId,
      'userEmail': userEmail,
      'userRole': userRole,
      'message': message,
      'createdAt': createdAt.millisecondsSinceEpoch, 
      'attachmentUrls': attachmentUrls,
    };
  }

  // Create a copy with some fields replaced
  CommentModel copyWith({
    String? id,
    String? ticketId,
    String? userId,
    String? userEmail,
    String? userRole,
    String? message,
    DateTime? createdAt,
    List<String>? attachmentUrls,
  }) {
    return CommentModel(
      id: id ?? this.id,
      ticketId: ticketId ?? this.ticketId,
      userId: userId ?? this.userId,
      userEmail: userEmail ?? this.userEmail,
      userRole: userRole ?? this.userRole,
      message: message ?? this.message,
      createdAt: createdAt ?? this.createdAt,
      attachmentUrls: attachmentUrls ?? this.attachmentUrls,
    );
  }
}
