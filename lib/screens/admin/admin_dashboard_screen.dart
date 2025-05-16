import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/ticket_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/ticket_model.dart';
import '../../widgets/ticket_list_item.dart';
import '../ticket_detail_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({Key? key}) : super(key: key);

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _filterStatus = 'all';
  String _filterPriority = 'all';
  String _sortBy = 'date';
  bool _sortAscending = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // Refresh tickets when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final provider = Provider.of<TicketProvider>(context, listen: false);
        provider.refreshTickets();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  // Apply filtering and sorting to tickets
  List<TicketModel> _getFilteredTickets(List<TicketModel> tickets) {
    // Apply status filter
    var filtered = _filterStatus == 'all'
        ? tickets
        : tickets.where((ticket) => ticket.status == _filterStatus).toList();
    
    // Apply priority filter
    filtered = _filterPriority == 'all'
        ? filtered
        : filtered.where((ticket) => ticket.priority == _filterPriority).toList();
    
    // Apply sorting
    filtered.sort((a, b) {
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
    
    return filtered;
  }
  
  // Helper function to convert priority to numeric value for sorting
  int _getPriorityValue(String priority) {
    switch (priority) {
      case 'low': return 0;
      case 'medium': return 1;
      case 'high': return 2;
      case 'critical': return 3;
      default: return 0;
    }
  }
  
  // Helper function to convert status to numeric value for sorting
  int _getStatusValue(String status) {
    switch (status) {
      case 'open': return 0;
      case 'in_progress': return 1;
      case 'resolved': return 2;
      case 'closed': return 3;
      default: return 0;
    }
  }
  
  
  Widget _buildStatsWidget(TicketProvider ticketProvider) {
    final tickets = ticketProvider.tickets;
    
    // Count tickets by status
    final openCount = tickets.where((t) => t.status == 'open').length;
    final inProgressCount = tickets.where((t) => t.status == 'in_progress').length;
    final resolvedCount = tickets.where((t) => t.status == 'resolved').length;
    final closedCount = tickets.where((t) => t.status == 'closed').length;
    
    // Count tickets by priority
    final lowCount = tickets.where((t) => t.priority == 'low').length;
    final mediumCount = tickets.where((t) => t.priority == 'medium').length;
    final highCount = tickets.where((t) => t.priority == 'high').length;
    final criticalCount = tickets.where((t) => t.priority == 'critical').length;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stats overview card
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Ticket Overview',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildStatItem('Total', tickets.length, Colors.blue),
                      _buildStatItem('Open', openCount, Colors.orange),
                      _buildStatItem('Resolved', resolvedCount, Colors.green),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Status breakdown
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Status Breakdown',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Create a simple bar chart
                  _buildStatusBar('New', openCount, tickets.length, Colors.blue),
                  const SizedBox(height: 8),
                  _buildStatusBar('In Progress', inProgressCount, tickets.length, Colors.orange),
                  const SizedBox(height: 8),
                  _buildStatusBar('Resolved', resolvedCount, tickets.length, Colors.green),
                  const SizedBox(height: 8),
                  _buildStatusBar('Closed', closedCount, tickets.length, Colors.grey),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Priority breakdown
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Priority Breakdown',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Create a simple bar chart
                  _buildStatusBar('Low', lowCount, tickets.length, Colors.green),
                  const SizedBox(height: 8),
                  _buildStatusBar('Medium', mediumCount, tickets.length, Colors.orange),
                  const SizedBox(height: 8),
                  _buildStatusBar('High', highCount, tickets.length, Colors.red),
                  const SizedBox(height: 8),
                  _buildStatusBar('Critical', criticalCount, tickets.length, Colors.purple),
                ],
              ),
            ),
          ),
          
          // Performance stats
          const SizedBox(height: 16),
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Performance',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Tickets created this week/month 
                  _buildPeriodStats(tickets),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  // Build tickets list view
  Widget _buildTicketsListView(TicketProvider ticketProvider) {
    final filteredTickets = _getFilteredTickets(ticketProvider.tickets);
    
    return Column(
      children: [
        // Filtering options
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Filter row
              Row(
                children: [
                  // Status filter
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Status',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                      value: _filterStatus,
                      onChanged: (value) {
                        setState(() {
                          _filterStatus = value!;
                        });
                      },
                      items: const [
                        DropdownMenuItem(value: 'all', child: Text('All Statuses')),
                        DropdownMenuItem(value: 'open', child: Text('New')),
                        DropdownMenuItem(value: 'in_progress', child: Text('In Progress')),
                        DropdownMenuItem(value: 'resolved', child: Text('Resolved')),
                        DropdownMenuItem(value: 'closed', child: Text('Closed')),
                      ],
                    ),
                  ),
                  
                  const SizedBox(width: 8),
                  
                  // Priority filter
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Priority',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                      value: _filterPriority,
                      onChanged: (value) {
                        setState(() {
                          _filterPriority = value!;
                        });
                      },
                      items: const [
                        DropdownMenuItem(value: 'all', child: Text('All Priorities')),
                        DropdownMenuItem(value: 'low', child: Text('Low')),
                        DropdownMenuItem(value: 'medium', child: Text('Medium')),
                        DropdownMenuItem(value: 'high', child: Text('High')),
                        DropdownMenuItem(value: 'critical', child: Text('Critical')),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // Sorting options
              Row(
                children: [
                  // Sort by
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Sort By',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                      value: _sortBy,
                      onChanged: (value) {
                        setState(() {
                          _sortBy = value!;
                        });
                      },
                      items: const [
                        DropdownMenuItem(value: 'date', child: Text('Date')),
                        DropdownMenuItem(value: 'priority', child: Text('Priority')),
                        DropdownMenuItem(value: 'status', child: Text('Status')),
                      ],
                    ),
                  ),
                  
                  const SizedBox(width: 8),
                  
                  // Sort direction toggle
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _sortAscending = !_sortAscending;
                      });
                    },
                    icon: Icon(_sortAscending ? Icons.arrow_upward : Icons.arrow_downward),
                    label: Text(_sortAscending ? 'Ascending' : 'Descending'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        // Ticket count
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Text(
                'Showing ${filteredTickets.length} of ${ticketProvider.tickets.length} tickets',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () {
                  ticketProvider.refreshTickets();
                },
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Refresh'),
              ),
            ],
          ),
        ),
        
        // Ticket list
        Expanded(
          child: ticketProvider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : ticketProvider.tickets.isEmpty
                  ? const Center(child: Text('No tickets found'))
                  : filteredTickets.isEmpty
                      ? const Center(child: Text('No tickets match your filters'))
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: filteredTickets.length,
                          itemBuilder: (context, index) {
                            final ticket = filteredTickets[index];
                            return TicketListItem(
                              ticket: ticket,
                              showClientInfo: true,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => TicketDetailScreen(
                                      ticketId: ticket.id!,
                                      isAdmin: true,
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
                                      content: Text('Ticket status updated to $_formatStatus(newStatus)'),
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
      ],
    );
  }
  
  // Build user management tab (simplified for now)
  Widget _buildUserManagement() {
    return const Center(
      child: Text('User management features coming soon'),
    );
  }
  
  // Helper to build stat item widgets
  Widget _buildStatItem(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            '$count',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
  
  // Helper to build status bar widgets
  Widget _buildStatusBar(String label, int count, int total, Color color) {
    final percentage = total > 0 ? count / total : 0.0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label),
            Text('$count (${(percentage * 100).toStringAsFixed(0)}%)'),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percentage,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 10,
          ),
        ),
      ],
    );
  }
  
  // Helper to build period stats
  Widget _buildPeriodStats(List<TicketModel> tickets) {
    final now = DateTime.now();
    final lastWeekStart = now.subtract(const Duration(days: 7));
    final lastMonthStart = DateTime(now.year, now.month - 1, now.day);
    
    // Count this week's tickets
    final thisWeekTickets = tickets.where((t) => t.createdAt.isAfter(lastWeekStart)).length;
    
    // Count this month's tickets
    final thisMonthTickets = tickets.where((t) => t.createdAt.isAfter(lastMonthStart)).length;
    
    // Count resolved this week
    final resolvedThisWeek = tickets.where((t) => 
      t.status == 'resolved' && 
      (t.updatedAt?.isAfter(lastWeekStart) ?? false)
    ).length;
    
    // Average resolution time (for resolved tickets with updatedAt)
    final resolvedTickets = tickets.where((t) => 
      t.status == 'resolved' && t.updatedAt != null
    ).toList();
    
    String avgResolutionTime = 'N/A';
    if (resolvedTickets.isNotEmpty) {
      final totalHours = resolvedTickets.fold<double>(0, (sum, ticket) {
        final duration = ticket.updatedAt!.difference(ticket.createdAt);
        return sum + duration.inHours;
      });
      
      final avgHours = totalHours / resolvedTickets.length;
      
      if (avgHours < 24) {
        avgResolutionTime = '${avgHours.toStringAsFixed(1)} hours';
      } else {
        final days = avgHours / 24;
        avgResolutionTime = '${days.toStringAsFixed(1)} days';
      }
    }
    
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildPerformanceItem('This Week', '$thisWeekTickets tickets', Colors.blue),
            _buildPerformanceItem('This Month', '$thisMonthTickets tickets', Colors.green),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildPerformanceItem('Resolved (Week)', '$resolvedThisWeek tickets', Colors.orange),
            _buildPerformanceItem('Avg. Resolution', avgResolutionTime, Colors.purple),
          ],
        ),
      ],
    );
  }
  
  Widget _buildPerformanceItem(String label, String value, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  String _formatStatus(String status) {
    switch (status) {
      case 'in_progress':
        return 'In Progress';
      case 'open':
        return 'New';
      default:
        return status.substring(0, 1).toUpperCase() + status.substring(1);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final ticketProvider = Provider.of<TicketProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Statistics'),
            Tab(text: 'Tickets'),
            Tab(text: 'Users'),
          ],
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authProvider.signOut();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
            tooltip: 'Logout',
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          
          _buildStatsWidget(ticketProvider),
          
          
          _buildTicketsListView(ticketProvider),
          
          
          _buildUserManagement(),
        ],
      ),
    );
  }
}
