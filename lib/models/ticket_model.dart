import 'package:cloud_firestore/cloud_firestore.dart';

class TicketModel {
  final String? id;
  final String title;
  final String description;
  final String priority;
  final String status;
  final String clientId;
  final String? assignedToId;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final List<String> attachmentUrls; 

  TicketModel({
    this.id,
    required this.title,
    required this.description,
    required this.priority,
    required this.status,
    required this.clientId,
    this.assignedToId,
    required this.createdAt,
    this.updatedAt,
    this.attachmentUrls = const [], // Default to empty list
  });

  // Create from Firestore map
  factory TicketModel.fromMap(Map<String, dynamic> data, String documentId) {
    
    List<String> attachments = [];
    if (data['attachmentUrls'] != null) {
      
      if (data['attachmentUrls'] is List) {
        attachments = List<String>.from(data['attachmentUrls']);
      } else if (data['attachmentUrls'] is String) {
        
        attachments = [data['attachmentUrls']];
      }
    }
    
    print('DEBUG: Loading ticket $documentId with attachments: $attachments');
    
    return TicketModel(
      id: documentId,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      priority: data['priority'] ?? 'medium',
      status: data['status'] ?? 'open',
      clientId: data['clientId'] ?? '',
      assignedToId: data['assignedToId'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null ? (data['updatedAt'] as Timestamp).toDate() : null,
      attachmentUrls: attachments,
    );
  }

  // Convert to map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'priority': priority,
      'status': status,
      'clientId': clientId,
      'assignedToId': assignedToId,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'attachmentUrls': attachmentUrls,
    };
  }

  // Create a copy with some fields replaced
  TicketModel copyWith({
    String? id,
    String? title,
    String? description,
    String? priority,
    String? status,
    String? clientId,
    String? assignedToId,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? attachmentUrls,
  }) {
    return TicketModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      clientId: clientId ?? this.clientId,
      assignedToId: assignedToId ?? this.assignedToId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      attachmentUrls: attachmentUrls ?? this.attachmentUrls,
    );
  }
}
