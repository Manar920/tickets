import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/ticket_provider.dart';
import '../providers/auth_provider.dart';
import '../services/role_service.dart';
import '../models/ticket_model.dart';
import '../widgets/ticket_list_item.dart';
import 'ticket_detail_screen.dart';

class TicketListScreen extends StatefulWidget {
  const TicketListScreen({Key? key}) : super(key: key);

  @override
  State<TicketListScreen> createState() => _TicketListScreenState();
}

class _TicketListScreenState extends State<TicketListScreen> {
  final RoleService _roleService = RoleService();
  bool _isAdmin = false;
  String _selectedStatusFilter = 'all';
  String _selectedPriorityFilter = 'all';
  String _sortBy = 'date';
  bool _sortAscending = false;

  @override
  void initState() {
    super.initState();
    _checkUserRole();
    
    // Request ticket refresh when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final provider = Provider.of<TicketProvider>(context, listen: false);
        provider.refreshTickets();
      }
    });
  }

  Future<void> _checkUserRole() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.user != null) {
        final isAdmin = await _roleService.isUserAdmin(authProvider.user!.uid);
        if (mounted) {
          setState(() {
            _isAdmin = isAdmin;
          });
        }
      }
    } catch (e) {
      print('Error checking user role: $e');
    }
  }
  @override
  Widget build(BuildContext context) {
    final ticketProvider = Provider.of<TicketProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);

    if (ticketProvider.isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Filter tickets based on status and priority selections
    List<TicketModel> filteredTickets = ticketProvider.tickets;
    
    // Apply status filter
    if (_selectedStatusFilter != 'all') {
      filteredTickets = filteredTickets.where((ticket) => ticket.status == _selectedStatusFilter).toList();
    }
    
    // Apply priority filter
    if (_selectedPriorityFilter != 'all') {
      filteredTickets = filteredTickets.where((ticket) => ticket.priority == _selectedPriorityFilter).toList();
    }
    
    // Apply sorting
    filteredTickets.sort((a, b) {
      int result;
      
      switch (_sortBy) {
        case 'date':
          result = a.createdAt.compareTo(b.createdAt);
          break;
        case 'priority':
          result = _getPriorityValue(a.priority).compareTo(_getPriorityValue(b.priority));
          break;
        case 'status':
          result = _getStatusValue(a.status).compareTo(_getStatusValue(b.status));
          break;
        default:
          result = a.createdAt.compareTo(b.createdAt);
      }
      
      return _sortAscending ? result : -result;
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tickets'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // Refresh tickets
              final provider = Provider.of<TicketProvider>(context, listen: false);
              provider.refreshTickets();
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authProvider.signOut();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Status filter chips
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('all', 'All'),
                  const SizedBox(width: 8),
                  _buildFilterChip('open', 'New', Colors.blue),
                  const SizedBox(width: 8),
                  _buildFilterChip('in_progress', 'In Progress', Colors.orange),
                  const SizedBox(width: 8),
                  _buildFilterChip('resolved', 'Resolved', Colors.green),
                  const SizedBox(width: 8),
                  _buildFilterChip('closed', 'Closed', Colors.grey),
                ],
              ),
            ),
          ),
          
          // Ticket count summary
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text(
                  'Showing ${filteredTickets.length} ${_selectedFilter == 'all' ? 'tickets' : _formatFilterName(_selectedFilter) + ' tickets'}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (_selectedFilter != 'all')
                  Text(
                    '${_getTicketCountByStatus(_selectedFilter, ticketProvider.tickets)} total',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
              ],
            ),
          ),
          
          // Status summary card
          Card(
            elevation: 1,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatusCount('New', ticketProvider.tickets.where((t) => t.status == 'open').length, Colors.blue),
                  _buildStatusCount('In Progress', ticketProvider.tickets.where((t) => t.status == 'in_progress').length, Colors.orange),
                  _buildStatusCount('Resolved', ticketProvider.tickets.where((t) => t.status == 'resolved').length, Colors.green),
                  _buildStatusCount('Closed', ticketProvider.tickets.where((t) => t.status == 'closed').length, Colors.grey),
                ],
              ),
            ),
          ),
          
          // Ticket list
          Expanded(
            child: ticketProvider.tickets.isEmpty
                ? const Center(
                    child: Text('No tickets found'),
                  )
                : filteredTickets.isEmpty
                    ? Center(
                        child: Text('No ${_formatFilterName(_selectedFilter)} tickets found'),
                      )                    : RefreshIndicator(
                        onRefresh: () {
                          final provider = Provider.of<TicketProvider>(context, listen: false);
                          provider.refreshTickets();
                          return Future.value();
                        },
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: filteredTickets.length,
                          itemBuilder: (context, index) {
                            final ticket = filteredTickets[index];
                            return TicketListItem(
                              ticket: ticket,
                              showClientInfo: _isAdmin,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => TicketDetailScreen(
                                      ticketId: ticket.id!,
                                      isAdmin: _isAdmin,
                                    ),
                                  ),
                                );
                              },
                              onStatusChange: (String newStatus) async {
                                try {
                                  final updatedTicket = ticket.copyWith(
                                    status: newStatus,
                                    updatedAt: DateTime.now(),
                                  );
                                  
                                  await ticketProvider.updateTicket(updatedTicket);
                                  
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Ticket status updated to ${_formatFilterName(newStatus)}'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Failed to update ticket status: $e'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              },
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/create-ticket');
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildFilterChip(String filter, String label, [Color? color]) {
    final isSelected = _selectedFilter == filter;
    final chipColor = color ?? Colors.blue;
    
    return FilterChip(
      selected: isSelected,
      label: Text(label),
      onSelected: (selected) {
        setState(() {
          _selectedFilter = selected ? filter : 'all';
        });
      },
      backgroundColor: chipColor.withOpacity(0.1),
      selectedColor: chipColor.withOpacity(0.3),
      checkmarkColor: chipColor,
      labelStyle: TextStyle(
        color: isSelected ? chipColor : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? chipColor : Colors.transparent,
          width: 1,
        ),
      ),
    );
  }

  Widget _buildStatusCount(String label, int count, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            '$count',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  String _formatFilterName(String filter) {
    switch (filter) {
      case 'in_progress':
        return 'in progress';
      case 'open':
        return 'new';
      default:
        return filter;
    }
  }

  int _getTicketCountByStatus(String status, List<TicketModel> tickets) {
    return tickets.where((ticket) => ticket.status == status).length;
  }
}
