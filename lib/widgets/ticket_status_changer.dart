import 'package:flutter/material.dart';
import '../models/ticket_model.dart';
import '../providers/ticket_provider.dart';
import 'package:provider/provider.dart';

class TicketStatusChanger extends StatelessWidget {
  final TicketModel ticket;
  final bool showActions;
  final Function(String)? onStatusChanged;

  const TicketStatusChanger({
    Key? key,
    required this.ticket,
    this.showActions = true,
    this.onStatusChanged,
  }) : super(key: key);
  // Get status color
  Color _getStatusColor(String status) {
    switch (status) {
      case 'open':
        return Colors.blue;
      case 'in_progress':
        return Colors.orange;
      case 'waiting_on_client':
        return Colors.purple;
      case 'pending_review':
        return Colors.amber;
      case 'resolved':
        return Colors.green;
      case 'closed':
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }

  // Get status icon
  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'open':
        return Icons.fiber_new;
      case 'in_progress':
        return Icons.pending;
      case 'waiting_on_client':
        return Icons.hourglass_empty;
      case 'pending_review':
        return Icons.rate_review;
      case 'resolved':
        return Icons.check_circle;
      case 'closed':
        return Icons.cancel;
      default:
        return Icons.fiber_new;
    }
  }
  // Format status text
  String _formatStatus(String status) {
    switch (status) {
      case 'in_progress':
        return 'In Progress';
      case 'open':
        return 'New';
      case 'waiting_on_client':
        return 'Waiting on Client';
      case 'pending_review':
        return 'Pending Review';
      default:
        return status.substring(0, 1).toUpperCase() + status.substring(1);
    }
  }

  // Format date
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _updateTicketStatus(BuildContext context, String newStatus) async {
    if (onStatusChanged != null) {
      onStatusChanged!(newStatus);
      return;
    }

    try {
      final ticketProvider = Provider.of<TicketProvider>(context, listen: false);
      
      // Create updated ticket with new status
      final updatedTicket = ticket.copyWith(
        status: newStatus,
        updatedAt: DateTime.now(),
      );
      
      // Update ticket
      await ticketProvider.updateTicket(updatedTicket);
      
      // Show success message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ticket status updated to ${_formatStatus(newStatus)}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // Show error message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update ticket status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color statusColor = _getStatusColor(ticket.status);
    final IconData statusIcon = _getStatusIcon(ticket.status);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [        // Current status display
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: statusColor.withOpacity(0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: statusColor.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                statusIcon,
                size: 16,
                color: statusColor,
              ),
              const SizedBox(width: 8),
              Text(
                _formatStatus(ticket.status),
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (ticket.updatedAt != null) ...[
                const SizedBox(width: 8),
                Tooltip(
                  message: 'Last updated: ${_formatDate(ticket.updatedAt!)}',
                  child: Icon(
                    Icons.history,
                    size: 14,
                    color: statusColor.withOpacity(0.7),
                  ),
                ),
              ],
            ],
          ),
        ),
        
        // Status change actions (if enabled)
        if (showActions) ...[
          const SizedBox(height: 16),
          const Text(
            'Change Status:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [              if (ticket.status != 'open')
                Tooltip(
                  message: 'Mark ticket as new/reopened',
                  child: ActionChip(
                    avatar: Icon(Icons.fiber_new, color: _getStatusColor('open')),
                    label: const Text('New'),
                    backgroundColor: _getStatusColor('open').withOpacity(0.1),
                    labelStyle: TextStyle(color: _getStatusColor('open')),
                    onPressed: () => _updateTicketStatus(context, 'open'),
                  ),
                ),              if (ticket.status != 'in_progress')
                Tooltip(
                  message: 'Mark ticket as being worked on',
                  child: ActionChip(
                    avatar: Icon(Icons.pending, color: _getStatusColor('in_progress')),
                    label: const Text('In Progress'),
                    backgroundColor: _getStatusColor('in_progress').withOpacity(0.1),
                    labelStyle: TextStyle(color: _getStatusColor('in_progress')),
                    onPressed: () => _updateTicketStatus(context, 'in_progress'),
                  ),
                ),
              if (ticket.status != 'waiting_on_client')
                Tooltip(
                  message: 'Waiting for client response',
                  child: ActionChip(
                    avatar: Icon(Icons.hourglass_empty, color: _getStatusColor('waiting_on_client')),
                    label: const Text('Waiting on Client'),
                    backgroundColor: _getStatusColor('waiting_on_client').withOpacity(0.1),
                    labelStyle: TextStyle(color: _getStatusColor('waiting_on_client')),
                    onPressed: () => _updateTicketStatus(context, 'waiting_on_client'),
                  ),
                ),
              if (ticket.status != 'pending_review')
                Tooltip(
                  message: 'Pending manager review',
                  child: ActionChip(
                    avatar: Icon(Icons.rate_review, color: _getStatusColor('pending_review')),
                    label: const Text('Pending Review'),
                    backgroundColor: _getStatusColor('pending_review').withOpacity(0.1),
                    labelStyle: TextStyle(color: _getStatusColor('pending_review')),
                    onPressed: () => _updateTicketStatus(context, 'pending_review'),
                  ),
                ),
              if (ticket.status != 'resolved')
                Tooltip(
                  message: 'Mark ticket as resolved, waiting for client confirmation',
                  child: ActionChip(
                    avatar: Icon(Icons.check_circle, color: _getStatusColor('resolved')),
                    label: const Text('Resolved'),
                    backgroundColor: _getStatusColor('resolved').withOpacity(0.1),
                    labelStyle: TextStyle(color: _getStatusColor('resolved')),
                    onPressed: () => _updateTicketStatus(context, 'resolved'),
                  ),
                ),
              if (ticket.status != 'closed')
                Tooltip(
                  message: 'Permanently close this ticket',
                  child: ActionChip(
                    avatar: Icon(Icons.cancel, color: _getStatusColor('closed')),
                    label: const Text('Closed'),
                    backgroundColor: _getStatusColor('closed').withOpacity(0.1),
                    labelStyle: TextStyle(color: _getStatusColor('closed')),
                    onPressed: () => _updateTicketStatus(context, 'closed'),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}
