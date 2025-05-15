import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/ticket_provider.dart';
import 'create_ticket_screen.dart';
import '../ticket_detail_screen.dart';
import '../../models/ticket_model.dart';
import '../../widgets/ticket_list_item.dart';


class ClientHomeScreen extends StatefulWidget {
  const ClientHomeScreen({Key? key}) : super(key: key);

  @override
  State<ClientHomeScreen> createState() => _ClientHomeScreenState();
}

class _ClientHomeScreenState extends State<ClientHomeScreen> {
  late TicketProvider _ticketProvider;

  @override
  void initState() {
    super.initState();
    // Schedule the provider lookup for after the first build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _ticketProvider = Provider.of<TicketProvider>(context, listen: false);
      }
    });
  }

  void _navigateToLogin() async {
    // Store the auth provider before navigation
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    // Navigate first, then sign out
    await Navigator.of(context).pushReplacementNamed('/login');
    
    // Only sign out if still mounted (shouldn't be, but check anyway)
    await authProvider.signOut();
  }

  // Safe navigation method that checks mounted state
  void _navigateWithSafety(BuildContext context, Widget screen) {
    if (!mounted) return;
    
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    
    // Get ticket provider in build method to avoid initialization issues
    try {
      _ticketProvider = Provider.of<TicketProvider>(context);
    } catch (e) {
      // Handle case where provider isn't available yet
      return Scaffold(
        appBar: AppBar(title: const Text('My Support Tickets')),
        body: const Center(child: Text('Loading tickets...')),
      );
    }
    
    final user = authProvider.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Tickets'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _ticketProvider.refreshTickets(),
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _navigateToLogin,
            tooltip: 'Logout',
          ),
          IconButton(
            icon: const Icon(Icons.list_alt),
            onPressed: () {
              Navigator.pushNamed(context, '/tickets');
            },
            tooltip: 'View All Tickets',
          ),
        ],
      ),
      body: Column(
        children: [
         
          // Welcome Card
          Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 15),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.white,
                      radius: 25,
                      child: Icon(
                        Icons.person,
                        size: 30,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome back',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            user?.name ?? user?.email ?? 'Client',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                Card(
                  elevation: 0,
                  color: Colors.white.withOpacity(0.9),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 15,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Theme.of(context).primaryColor,
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'Need help? Create a new support ticket!',
                            style: TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Tickets Section
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Your Support Tickets',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_ticketProvider.tickets.length} tickets',
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Ticket List
          Expanded(
            child: _ticketProvider.isLoading
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : _ticketProvider.tickets.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.support_agent,
                              size: 70,
                              color: Colors.grey.withOpacity(0.7),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'No tickets yet',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 40),
                              child: Text(
                                'Create your first support ticket to get help from our team',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              onPressed: () {
                                _navigateWithSafety(
                                  context,
                                  const CreateTicketScreen(),
                                );
                              },
                              icon: const Icon(Icons.add),
                              label: const Text('Create Ticket'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () async {
                          _ticketProvider.refreshTickets();
                        },
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _ticketProvider.tickets.length,
                          itemBuilder: (context, index) {
                            TicketModel ticket = _ticketProvider.tickets[index];
                            return TicketListItem(
                              ticket: ticket,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => TicketDetailScreen(
                                      ticketId: ticket.id!,
                                      isAdmin: false,
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
          ),
          
          // Error message
          if (_ticketProvider.error != null)
            Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    color: Colors.red.shade700,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _ticketProvider.error!,
                      style: TextStyle(color: Colors.red.shade700),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    color: Colors.red.shade700,
                    onPressed: () => _ticketProvider.clearError(),
                  ),
                ],
              ),
            ),
        ],
      ),
      floatingActionButton: _ticketProvider.tickets.isNotEmpty
          ? FloatingActionButton(
              onPressed: () {
              
                
                _navigateWithSafety(
                  context,
                  const CreateTicketScreen(),
                );
              },
              child: const Icon(Icons.add),
              tooltip: 'Create New Ticket',
            )
          : null,
    );
  }
}
