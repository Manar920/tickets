import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/ticket_provider.dart';
import 'admin_ticket_detail_screen.dart';
import '../../models/ticket_model.dart';
import '../../widgets/ticket_list_item.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({Key? key}) : super(key: key);

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  String _filterStatus = 'all';
  String _filterPriority = 'all';

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    // Only listen to ticket provider when needed
    final ticketProvider = Provider.of<TicketProvider>(context, listen: false);

    // Filter tickets based on selected filters
    List<TicketModel> filteredTickets = ticketProvider.tickets.where((ticket) {
      bool statusMatch = _filterStatus == 'all' || ticket.status == _filterStatus;
      bool priorityMatch = _filterPriority == 'all' || ticket.priority == _filterPriority;
      return statusMatch && priorityMatch;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ticketProvider.refreshTickets();
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              _navigateToLogin();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Welcome, Admin ${authProvider.user?.name ?? authProvider.user?.email ?? ''}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _filterStatus,
                    decoration: const InputDecoration(
                      labelText: 'Status',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text('All Statuses')),
                      DropdownMenuItem(value: 'open', child: Text('Open')),
                      DropdownMenuItem(value: 'in_progress', child: Text('In Progress')),
                      DropdownMenuItem(value: 'resolved', child: Text('Resolved')),
                      DropdownMenuItem(value: 'closed', child: Text('Closed')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _filterStatus = value!;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _filterPriority,
                    decoration: const InputDecoration(
                      labelText: 'Priority',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text('All Priorities')),
                      DropdownMenuItem(value: 'low', child: Text('Low')),
                      DropdownMenuItem(value: 'medium', child: Text('Medium')),
                      DropdownMenuItem(value: 'high', child: Text('High')),
                      DropdownMenuItem(value: 'critical', child: Text('Critical')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _filterPriority = value!;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ticketProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredTickets.isEmpty
                    ? const Center(
                        child: Text(
                          'No tickets match the selected filters',
                          style: TextStyle(fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () async {
                          ticketProvider.refreshTickets();
                        },
                        child: ListView.builder(
                          itemCount: filteredTickets.length,
                          itemBuilder: (context, index) {
                            TicketModel ticket = filteredTickets[index];
                            return TicketListItem(
                              ticket: ticket,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => AdminTicketDetailScreen(ticketId: ticket.id!),
                                  ),
                                );
                              },
                              showClientInfo: true,
                            );
                          },
                        ),
                      ),
          ),
          if (ticketProvider.error != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                ticketProvider.error!,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }

  void _navigateToLogin() async {
    // Store the auth provider before navigation
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    // Navigate first, then sign out
    await Navigator.of(context).pushReplacementNamed('/login');
    
    // Then sign out
    await authProvider.signOut();
  }
}
