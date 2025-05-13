import 'package:cloud_firestore/cloud_firestore.dart';

class TicketModel {
  final String? id;
  final String title;
  final String description;
  final String status;
  final String priority;
  final String clientId;
  final String? assignedToId;
  final DateTime createdAt;
  final DateTime? updatedAt;

  TicketModel({
    this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.priority,
    required this.clientId,
    this.assignedToId,
    required this.createdAt,
    this.updatedAt,
  });

  factory TicketModel.fromMap(Map<String, dynamic> map, String docId) {
    return TicketModel(
      id: docId,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      status: map['status'] ?? 'open',
      priority: map['priority'] ?? 'medium',
      clientId: map['clientId'] ?? '',
      assignedToId: map['assignedToId'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: map['updatedAt'] != null 
          ? (map['updatedAt'] as Timestamp).toDate() 
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'status': status,
      'priority': priority,
      'clientId': clientId,
      'assignedToId': assignedToId,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  TicketModel copyWith({
    String? id,
    String? title,
    String? description,
    String? status,
    String? priority,
    String? clientId,
    String? assignedToId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TicketModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      clientId: clientId ?? this.clientId,
      assignedToId: assignedToId ?? this.assignedToId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
