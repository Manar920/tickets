import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:tickets/providers/auth_provider.dart';
import '../../providers/ticket_provider.dart';
import '../../models/ticket_model.dart';
import '../../services/auth_service.dart';

class AdminTicketDetailScreen extends StatefulWidget {
  final String ticketId;

  const AdminTicketDetailScreen({
    Key? key,
    required this.ticketId,
  }) : super(key: key);

  @override
  State<AdminTicketDetailScreen> createState() => _AdminTicketDetailScreenState();
}

class _AdminTicketDetailScreenState extends State<AdminTicketDetailScreen> {
  bool _isLoading = true;
  TicketModel? _ticket;
  String? _error;
  String? _clientEmail;
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _loadTicket();
  }

  Future<void> _loadTicket() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final ticketProvider = Provider.of<TicketProvider>(context, listen: false);
      final ticket = await ticketProvider.getTicket(widget.ticketId);
      
      if (ticket != null) {
        // Try to get client's email from Firebase
        try {
          final clientDoc = await _authService.getUserInfo(ticket.clientId);
          if (clientDoc != null && clientDoc.containsKey('email')) {
            _clientEmail = clientDoc['email'];
          }
        } catch (e) {
          print('Error fetching client info: $e');
          // Continue without client email
        }
      }
      
      if (mounted) {
        setState(() {
          _ticket = ticket;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load ticket: $e';
          _isLoading = false;
        });
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'open':
        return Colors.blue;
      case 'in_progress':
        return Colors.orange;
      case 'resolved':
        return Colors.green;
      case 'closed':
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'low':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'high':
        return Colors.red;
      case 'critical':
        return Colors.purple;
      default:
        return Colors.orange;
    }
  }

  String _formatStatus(String status) {
    switch (status) {
      case 'in_progress':
        return 'In Progress';
      default:
        return status.substring(0, 1).toUpperCase() + status.substring(1);
    }
  }

  Future<void> _updateTicketStatus(String newStatus) async {
    if (_ticket == null) return;
    
    try {
      final ticketProvider = Provider.of<TicketProvider>(context, listen: false);
      final updatedTicket = _ticket!.copyWith(
        status: newStatus,
        updatedAt: DateTime.now(),
        assignedToId: _ticket!.assignedToId ?? Provider.of<AuthProvider>(context, listen: false).user?.uid,
      );
      
      await ticketProvider.updateTicket(updatedTicket);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ticket status updated to ${_formatStatus(newStatus)}'),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {
          _ticket = updatedTicket;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update ticket: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Ticket'),
        actions: [
          if (_ticket != null)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Delete Ticket'),
                    content: const Text('Are you sure you want to delete this ticket? This action cannot be undone.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                );

                if (confirmed == true && mounted) {
                  final ticketProvider = Provider.of<TicketProvider>(context, listen: false);
                  try {
                    await ticketProvider.deleteTicket(_ticket!.id!);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Ticket deleted successfully'),
                          backgroundColor: Colors.green,
                        ),
                      );
                      Navigator.pop(context);
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to delete ticket: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                }
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _error!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadTicket,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _ticket == null
                  ? const Center(child: Text('Ticket not found'))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  _ticket!.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 24,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(_ticket!.status).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(
                                  _formatStatus(_ticket!.status),
                                  style: TextStyle(
                                    color: _getStatusColor(_ticket!.status),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 16,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Created on ${DateFormat('MMM dd, yyyy – HH:mm').format(_ticket!.createdAt)}',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          if (_ticket!.updatedAt != null) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.update,
                                  size: 16,
                                  color: Colors.grey[600],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Updated on ${DateFormat('MMM dd, yyyy – HH:mm').format(_ticket!.updatedAt!)}',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: _getPriorityColor(_ticket!.priority).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(
                                  'Priority: ${_ticket!.priority.substring(0, 1).toUpperCase() + _ticket!.priority.substring(1)}',
                                  style: TextStyle(
                                    color: _getPriorityColor(_ticket!.priority),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Card(
                            margin: EdgeInsets.zero,
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Client Information',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(Icons.person, size: 16),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Client ID: ${_ticket!.clientId}',
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (_clientEmail != null) ...[
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(Icons.email, size: 16),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'Email: $_clientEmail',
                                            style: const TextStyle(fontSize: 14),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Description',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(16),
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: Text(
                              _ticket!.description,
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'Update Status',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              if (_ticket!.status != 'open')
                                ActionChip(
                                  avatar: Icon(Icons.fiber_new, color: _getStatusColor('open')),
                                  label: const Text('Open'),
                                  backgroundColor: _getStatusColor('open').withOpacity(0.1),
                                  labelStyle: TextStyle(color: _getStatusColor('open')),
                                  onPressed: () => _updateTicketStatus('open'),
                                ),
                              if (_ticket!.status != 'in_progress')
                                ActionChip(
                                  avatar: Icon(Icons.pending, color: _getStatusColor('in_progress')),
                                  label: const Text('In Progress'),
                                  backgroundColor: _getStatusColor('in_progress').withOpacity(0.1),
                                  labelStyle: TextStyle(color: _getStatusColor('in_progress')),
                                  onPressed: () => _updateTicketStatus('in_progress'),
                                ),
                              if (_ticket!.status != 'resolved')
                                ActionChip(
                                  avatar: Icon(Icons.check_circle, color: _getStatusColor('resolved')),
                                  label: const Text('Resolved'),
                                  backgroundColor: _getStatusColor('resolved').withOpacity(0.1),
                                  labelStyle: TextStyle(color: _getStatusColor('resolved')),
                                  onPressed: () => _updateTicketStatus('resolved'),
                                ),
                              if (_ticket!.status != 'closed')
                                ActionChip(
                                  avatar: Icon(Icons.cancel, color: _getStatusColor('closed')),
                                  label: const Text('Closed'),
                                  backgroundColor: _getStatusColor('closed').withOpacity(0.1),
                                  labelStyle: TextStyle(color: _getStatusColor('closed')),
                                  onPressed: () => _updateTicketStatus('closed'),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
    );
  }
}
