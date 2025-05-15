import 'dart:io'; // Import for File type

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/ticket_model.dart';
import '../services/storage_service.dart';


class TicketService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final StorageService _storageService = StorageService();
    // Update createTicket to handle errors better
  // Update to make attachments truly optional
  Future<String> createTicket(TicketModel ticket, List<File>? attachments, String userId) async {
    try {
      print('Creating ticket: ${ticket.title}');
      
      // Create a basic version of the ticket first (without attachments)
      final initialTicket = ticket.copyWith(
        clientId: userId,
        createdAt: DateTime.now(),
        attachmentUrls: [], // Start with empty list
      );
      
      // Save the ticket to Firestore first
      print('Saving ticket to Firestore...');
      DocumentReference docRef = await _firestore.collection('tickets')
          .add(initialTicket.toMap())
          .timeout(const Duration(seconds: 8), 
              onTimeout: () => throw Exception('Initial ticket save timed out'));
      
      print('Ticket created with ID: ${docRef.id}');
        // Now process attachments directly instead of in background
      if (attachments != null && attachments.isNotEmpty) {
        print('Processing ${attachments.length} attachments...');
        try {
          // Upload the files and wait for them to complete
          final attachmentUrls = await _storageService.uploadFiles(attachments, 'tickets/$userId')
              .timeout(const Duration(seconds: 60), 
                  onTimeout: () {
                    print('Attachment upload timed out');
                    return [];
                  });
          
          if (attachmentUrls.isNotEmpty) {
            // Update the ticket with attachment URLs
            await _firestore.collection('tickets').doc(docRef.id).update({
              'attachmentUrls': attachmentUrls,
              'updatedAt': FieldValue.serverTimestamp(),
            });
            
            print('Ticket ${docRef.id} updated with ${attachmentUrls.length} attachments');
          }
        } catch (e) {
          print('Error processing attachments: $e');
          // Don't let attachment errors prevent ticket creation
        }
      }
      
      // Return the ID
      return docRef.id;    } catch (e) {
      print('Error creating ticket: $e');
      throw Exception('Could not create ticket: ${e.toString().contains('Exception:') ? 
          e.toString().split('Exception:').last.trim() : e}');
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
