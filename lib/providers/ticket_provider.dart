import 'package:flutter/foundation.dart';
import 'dart:async';
import '../models/ticket_model.dart';
import '../services/ticket_service.dart';
import '../services/role_service.dart';

class TicketProvider with ChangeNotifier {
  final TicketService _ticketService = TicketService();
  final RoleService _roleService = RoleService();
  final String? _userId;
  
  List<TicketModel> _tickets = [];
  bool _isLoading = false;
  String? _error;
  
  // Add stream subscription tracking
  StreamSubscription? _ticketsSubscription;
  bool _disposed = false;
  
  // Add getter for userId
  String? get userId => _userId;
  
  TicketProvider(this._userId) {
    if (_userId != null) {
      _loadTickets();
    } else {
      // Clear tickets if userId is null (e.g., on logout)
      _tickets = [];
      _isLoading = false;
      _error = null;
    }
  }
  
  // Getters
  List<TicketModel> get tickets => _tickets;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  // Load tickets based on user role
  Future<void> _loadTickets() async {
    if (_disposed) return;
    
    _isLoading = true;
    _error = null;
    safeNotifyListeners();
    
    try {
      // Cancel any existing subscription
      await _ticketsSubscription?.cancel();
      _ticketsSubscription = null;
      
      if (_userId != null) {
        bool isAdmin = await _roleService.isUserAdmin(_userId!);
        
        if (isAdmin) {
          // Listen to all tickets for admin
          _ticketsSubscription = _ticketService.getAllTickets().listen((ticketsList) {
            if (!_disposed) {
              _tickets = ticketsList;
              _isLoading = false;
              safeNotifyListeners();
            }
          }, onError: (e) {
            if (!_disposed) {
              _error = 'Error loading tickets: $e';
              _isLoading = false;
              safeNotifyListeners();
            }
            
            print('Admin tickets error: $e');
          });
        } else {
          // Listen to client's tickets only
          _ticketsSubscription = _ticketService.getClientTickets(_userId!).listen((ticketsList) {
            if (!_disposed) {
              _tickets = ticketsList;
              _isLoading = false;
              safeNotifyListeners();
            }
          }, onError: (e) {
            if (!_disposed) {
              _error = 'Error loading your tickets: $e';
              _isLoading = false;
              safeNotifyListeners();
            }
            
            print('Client tickets error: $e');
          });
        }
      } else {
        _tickets = [];
        _isLoading = false;
        if (!_disposed) safeNotifyListeners();
      }
    } catch (e) {
      if (!_disposed) {
        _error = 'Error loading tickets: $e';
        _isLoading = false;
        safeNotifyListeners();
      }
      print('General ticket loading error: $e');
    }
  }
  
  // Create a new ticket with better error handling
  Future<bool> createTicket(TicketModel ticket) async {
    if (_disposed) return false;
    
    try {
      await _ticketService.createTicket(ticket);
      return true;
    } catch (e) {
      if (!_disposed) {
        _error = 'Error creating ticket: $e';
        notifyListeners();
      }
      print('Create ticket error: $e');
      return false;
    }
  }
  
  // Update a ticket
  Future<bool> updateTicket(TicketModel ticket) async {
    if (_disposed) return false;
    
    try {
      await _ticketService.updateTicket(ticket);
      return true;
    } catch (e) {
      if (!_disposed) {
        _error = 'Error updating ticket: $e';
        notifyListeners();
      }
      print('Update ticket error: $e');
      return false;
    }
  }
  
  // Delete a ticket
  Future<bool> deleteTicket(String ticketId) async {
    if (_disposed) return false;
    
    try {
      await _ticketService.deleteTicket(ticketId);
      return true;
    } catch (e) {
      if (!_disposed) {
        _error = 'Error deleting ticket: $e';
        notifyListeners();
      }
      print('Delete ticket error: $e');
      return false;
    }
  }
  
  // Get a specific ticket
  Future<TicketModel?> getTicket(String ticketId) async {
    if (_disposed) return null;
    
    try {
      return await _ticketService.getTicket(ticketId);
    } catch (e) {
      if (!_disposed) {
        _error = 'Error getting ticket details: $e';
        notifyListeners();
      }
      print('Get ticket error: $e');
      return null;
    }
  }
  
  // Clear any errors
  void clearError() {
    if (_disposed) return;
    
    _error = null;
    notifyListeners();
  }
  
  // Refresh tickets with error handling
  void refreshTickets() {
    if (_disposed) return;
    
    if (_userId != null) {
      try {
        _loadTickets();
      } catch (e) {
        if (!_disposed) {
          _error = 'Error refreshing tickets: $e';
          notifyListeners();
        }
        print('Refresh tickets error: $e');
      }
    }
  }
  
  // Add method to cancel subscriptions
  void _cancelSubscriptions() {
    try {
      _ticketsSubscription?.cancel();
      _ticketsSubscription = null;
    } catch (e) {
      print('Error canceling subscriptions: $e');
    }
  }
  
  @override
  void dispose() {
    if (_disposed) return; // Prevent double disposal
    
    _disposed = true;
    
    // Cancel any active subscriptions
    if (_ticketsSubscription != null) {
      _ticketsSubscription!.cancel().then((_) {
        _ticketsSubscription = null;
      }).catchError((e) {
        print('Error canceling ticket subscription: $e');
      });
    }
    
    // Call super.dispose() at the end
    super.dispose();
  }
  
  // Safe version of notifyListeners that checks if disposed
  void safeNotifyListeners() {
    if (!_disposed) {
      notifyListeners();
    }
  }
}
