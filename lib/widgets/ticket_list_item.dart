import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/ticket_model.dart';

class TicketListItem extends StatelessWidget {
  final TicketModel ticket;
  final VoidCallback onTap;
  final bool showClientInfo;
  final Function(String)? onStatusChange;

  const TicketListItem({
    Key? key,
    required this.ticket,
    required this.onTap,
    this.showClientInfo = false,
    this.onStatusChange,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Get status color
    Color statusColor;
    IconData statusIcon;
    switch (ticket.status) {
      case 'open':
        statusColor = Colors.blue;
        statusIcon = Icons.fiber_new;
        break;
      case 'in_progress':
        statusColor = Colors.orange;
        statusIcon = Icons.pending;
        break;
      case 'resolved':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'closed':
        statusColor = Colors.grey;
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = Colors.blue;
        statusIcon = Icons.fiber_new;
    }

    // Get priority color
    Color priorityColor;
    IconData priorityIcon;
    switch (ticket.priority) {
      case 'low':
        priorityColor = Colors.green;
        priorityIcon = Icons.arrow_downward;
        break;
      case 'medium':
        priorityColor = Colors.orange;
        priorityIcon = Icons.remove;
        break;
      case 'high':
        priorityColor = Colors.red;
        priorityIcon = Icons.arrow_upward;
        break;
      case 'critical':
        priorityColor = Colors.purple;
        priorityIcon = Icons.priority_high;
        break;
      default:
        priorityColor = Colors.orange;
        priorityIcon = Icons.remove;
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: statusColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Priority indicator
                  Container(
                    decoration: BoxDecoration(
                      color: priorityColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.all(8),
                    child: Icon(
                      priorityIcon,
                      color: priorityColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Ticket title and details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ticket.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          ticket.description,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Status and date row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Status chip
                  onStatusChange != null
                      ? InkWell(
                          onTap: () {
                            _showStatusChangeDialog(context);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: statusColor.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  statusIcon,
                                  size: 14,
                                  color: statusColor,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _formatStatus(ticket.status),
                                  style: TextStyle(
                                    color: statusColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (onStatusChange != null) ...[
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.arrow_drop_down,
                                    size: 14,
                                    color: statusColor,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        )
                      : Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                statusIcon,
                                size: 14,
                                color: statusColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _formatStatus(ticket.status),
                                style: TextStyle(
                                  color: statusColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                  // Date
                  Text(
                    DateFormat.yMMMd().format(ticket.createdAt),
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              // Show client info for admin view
              if (showClientInfo && ticket.clientId.isNotEmpty) ...[
                const SizedBox(height: 8),
                const Divider(),
                Row(
                  children: [
                    const Icon(
                      Icons.person_outline,
                      size: 14,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Client: ${ticket.clientId}',
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatStatus(String status) {
    switch (status) {
      case 'in_progress':
        return 'In Progress';
      default:
        return status.substring(0, 1).toUpperCase() + status.substring(1);
    }
  }

  // Show status change dialog
  void _showStatusChangeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Change Ticket Status'),
        children: [
          if (ticket.status != 'open')
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(context);
                onStatusChange?.call('open');
              },
              child: _buildStatusOption('open', 'New', Colors.blue, Icons.fiber_new),
            ),
          if (ticket.status != 'in_progress')
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(context);
                onStatusChange?.call('in_progress');
              },
              child: _buildStatusOption('in_progress', 'In Progress', Colors.orange, Icons.pending),
            ),
          if (ticket.status != 'resolved')
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(context);
                onStatusChange?.call('resolved');
              },
              child: _buildStatusOption('resolved', 'Resolved', Colors.green, Icons.check_circle),
            ),
          if (ticket.status != 'closed')
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(context);
                onStatusChange?.call('closed');
              },
              child: _buildStatusOption('closed', 'Closed', Colors.grey, Icons.cancel),
            ),
          SimpleDialogOption(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Build status option for dialog
  Widget _buildStatusOption(String status, String label, Color color, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
