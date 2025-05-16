import 'dart:io';
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
  

  StreamSubscription? _ticketsSubscription;
  bool _disposed = false;
  

  String? get userId => _userId;
  
  TicketProvider(this._userId) {
    if (_userId != null) {
      _loadTickets();
    } else {
      
      _tickets = [];
      _isLoading = false;
      _error = null;
    }
  }
  
  
  List<TicketModel> get tickets => _tickets;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  
  Future<void> _loadTickets() async {
    if (_disposed) return;
    
    _isLoading = true;
    _error = null;
    safeNotifyListeners();
    
    try {
      
      await _ticketsSubscription?.cancel();
      _ticketsSubscription = null;
      
      if (_userId != null) {
        bool isAdmin = await _roleService.isUserAdmin(_userId!);
        
        if (isAdmin) {
         
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
  
  
  Future<String> createTicket(TicketModel ticket, List<File>? attachments) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (_userId == null) {
        throw Exception('User ID is null');
      }
      
      print('Starting ticket creation process...');
      
      
      final result = await Future.any([
        _ticketService.createTicket(ticket, attachments, _userId!),
        
        Future.delayed(const Duration(seconds: 25)).then((_) => 
          throw Exception('Ticket creation timed out. Please try again.'))
      ]);
      
      print('Ticket created successfully with ID: $result');
      
      _isLoading = false;
      notifyListeners();
      return result;
    } catch (e) {
      print('Error in ticket creation: $e');
      _isLoading = false;
      _error = 'Failed to create ticket: $e';
      notifyListeners();
      
      
      throw Exception('Could not save ticket: Check your internet connection and try again.');
    }
  }
  
  
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
  
  
  void clearError() {
    if (_disposed) return;
    
    _error = null;
    notifyListeners();
  }
  
  
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
  
  
  
  @override
  void dispose() {
    if (_disposed) return; 
    
    _disposed = true;
    
    
    if (_ticketsSubscription != null) {
      _ticketsSubscription!.cancel().then((_) {
        _ticketsSubscription = null;
      }).catchError((e) {
        print('Error canceling ticket subscription: $e');
      });
    }
    
    
    super.dispose();
  }
  
  
  void safeNotifyListeners() {
    if (!_disposed) {
      notifyListeners();
    }
  }
}
