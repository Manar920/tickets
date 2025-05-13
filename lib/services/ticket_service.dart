import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/ticket_model.dart';

class TicketService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Create a new ticket
  Future<String> createTicket(TicketModel ticket) async {
    try {
      DocumentReference docRef = await _firestore.collection('tickets').add(ticket.toMap());
      return docRef.id;
    } catch (e) {
      print('Error creating ticket: $e');
      throw Exception('Failed to create ticket: $e');
    }
  }
  
  // Get all tickets for a client - Fixed to avoid index issues
  Stream<List<TicketModel>> getClientTickets(String clientId) {
    try {
      // Using only one orderBy to avoid composite index requirement initially
      return _firestore
          .collection('tickets')
          .where('clientId', isEqualTo: clientId)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => TicketModel.fromMap(doc.data(), doc.id))
              .toList());
    } catch (e) {
      print('Error getting client tickets: $e');
      // Return empty list on error
      return Stream.value([]);
    }
  }
  
  // Get all tickets (for admin) - Fixed to avoid index issues
  Stream<List<TicketModel>> getAllTickets() {
    try {
      // Using only one orderBy to avoid composite index requirement initially
      return _firestore
          .collection('tickets')
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => TicketModel.fromMap(doc.data(), doc.id))
              .toList());
    } catch (e) {
      print('Error getting all tickets: $e');
      // Return empty list on error
      return Stream.value([]);
    }
  }
  
  // Get a specific ticket
  Future<TicketModel?> getTicket(String ticketId) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('tickets').doc(ticketId).get();
      
      if (doc.exists) {
        return TicketModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
      
      return null;
    } catch (e) {
      print('Error getting ticket: $e');
      throw Exception('Failed to get ticket: $e');
    }
  }
  
  // Update a ticket
  Future<void> updateTicket(TicketModel ticket) async {
    try {
      if (ticket.id == null) {
        throw Exception('Ticket ID cannot be null');
      }
      
      await _firestore.collection('tickets').doc(ticket.id).update(
        ticket.copyWith(updatedAt: DateTime.now()).toMap()
      );
    } catch (e) {
      print('Error updating ticket: $e');
      throw Exception('Failed to update ticket: $e');
    }
  }
  
  // Delete a ticket
  Future<void> deleteTicket(String ticketId) async {
    try {
      await _firestore.collection('tickets').doc(ticketId).delete();
    } catch (e) {
      print('Error deleting ticket: $e');
      throw Exception('Failed to delete ticket: $e');
    }
  }
}
