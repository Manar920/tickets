import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/ticket_model.dart';

class AdminTicketOverview extends StatefulWidget {
  final List<TicketModel> tickets;
  final Function(String) onStatusFilterSelected;
  
  const AdminTicketOverview({
    Key? key,
    required this.tickets,
    required this.onStatusFilterSelected,
  }) : super(key: key);

  @override
  State<AdminTicketOverview> createState() => _AdminTicketOverviewState();
}

class _AdminTicketOverviewState extends State<AdminTicketOverview> {
  // Status definitions with colors and icons
  final Map<String, Map<String, dynamic>> statuses = {
    'open': {
      'label': 'New',
      'color': Colors.blue,
      'icon': Icons.fiber_new,
    },
    'in_progress': {
      'label': 'In Progress',
      'color': Colors.orange,
      'icon': Icons.pending,
    },
    'waiting_on_client': {
      'label': 'Waiting on Client',
      'color': Colors.purple,
      'icon': Icons.hourglass_empty,
    },
    'pending_review': {
      'label': 'Pending Review',
      'color': Colors.amber,
      'icon': Icons.rate_review,
    },
    'resolved': {
      'label': 'Resolved',
      'color': Colors.green,
      'icon': Icons.check_circle,
    },
    'closed': {
      'label': 'Closed',
      'color': Colors.grey,
      'icon': Icons.cancel,
    },
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'Admin Dashboard',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        
        // Status Distribution Card
        _buildStatusDistributionCard(),
        
        // Status Quick Filters
        _buildQuickFiltersCard(),
        
        // Priority Analysis Card
        _buildPriorityAnalysisCard(),
        
        // Age Distribution Card
        _buildAgeDistributionCard(),
      ],
    );
  }
  // Status Distribution Card with Pie Chart
  Widget _buildStatusDistributionCard() {
    // Calculate total tickets
    final int totalTickets = widget.tickets.length;
    
    // Calculate tickets by status
    final Map<String, int> statusCounts = {};
    statuses.keys.forEach((status) {
      statusCounts[status] = widget.tickets.where((t) => t.status == status).length;
    });
    
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.pie_chart, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Status Distribution',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    'Total: $totalTickets',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            
            // Status summary bar - shows all statuses with counts
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: statuses.entries.map((entry) {
                  final status = entry.key;
                  final statusInfo = entry.value;
                  final count = statusCounts[status] ?? 0;
                  final Color color = statusInfo['color'] as Color;
                  
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: color.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusInfo['icon'] as IconData, size: 12, color: color),
                        const SizedBox(width: 4),
                        Text(
                          '${statusInfo['label']}: $count',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
              // Status counts in grid layout
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              childAspectRatio: 2.5,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              children: statuses.entries.map((entry) {
                final status = entry.key;
                final statusInfo = entry.value;
                final count = widget.tickets.where((t) => t.status == status).length;
                final double percentage = totalTickets > 0 
                    ? (count / totalTickets * 100) 
                    : 0.0;
                
                return _buildStatusCountTile(
                  statusInfo['label'] as String, 
                  count,
                  percentage,
                  statusInfo['color'] as Color,
                  statusInfo['icon'] as IconData,
                  status,
                );
              }).toList(),
            ),
            
            const SizedBox(height: 24),
              // Pie Chart for status distribution
            widget.tickets.isNotEmpty 
                ? SizedBox(
                    height: 200,
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: PieChart(
                            PieChartData(
                              sectionsSpace: 2,
                              centerSpaceRadius: 40,
                              centerSpaceColor: Colors.white,
                              sections: _getPieChartSections(),
                              pieTouchData: PieTouchData(
                                touchCallback: (FlTouchEvent event, pieTouchResponse) {
                                  if (pieTouchResponse != null && 
                                      pieTouchResponse.touchedSection != null && 
                                      event is FlLongPressEnd) {
                                    final int touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                                    final String status = statuses.keys.elementAt(touchedIndex);
                                    widget.onStatusFilterSelected(status);
                                  }
                                },
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: _buildStatusLegend(),
                        ),
                      ],
                    ),
                  )
                : const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text('No tickets to display'),
                    ),
                  ),
                  
            // Add tips for interaction
            if (widget.tickets.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Center(
                  child: Text(
                    'Tip: Tap on chart or legend items to filter tickets',
                    style: TextStyle(
                      fontSize: 10,
                      fontStyle: FontStyle.italic,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
  // Quick Filters Card
  Widget _buildQuickFiltersCard() {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.filter_list, size: 20),
                SizedBox(width: 8),
                Text(
                  'Quick Filters',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // All tickets chip
            _buildQuickFilterChip(
              'all', 
              'All Tickets (${widget.tickets.length})', 
              Colors.blueGrey,
              isHighlighted: true,
            ),
            
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            
            // Status categories
            const Text(
              'By Status:',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            
            // Status quick filter chips
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: statuses.entries.map((entry) {
                final count = widget.tickets.where((t) => t.status == entry.key).length;
                return _buildQuickFilterChip(
                  entry.key, 
                  '${entry.value['label'] as String} ($count)', 
                  entry.value['color'] as Color,
                );
              }).toList(),
            ),
            
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            
            // Priority categories
            const Text(
              'By Priority:',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            
            // Priority filter chips
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildQuickFilterChip(
                  'critical', 
                  'Critical (${widget.tickets.where((t) => t.priority == 'critical').length})', 
                  Colors.red, 
                  isPriority: true
                ),
                _buildQuickFilterChip(
                  'high', 
                  'High (${widget.tickets.where((t) => t.priority == 'high').length})', 
                  Colors.orange, 
                  isPriority: true
                ),
                _buildQuickFilterChip(
                  'medium', 
                  'Medium (${widget.tickets.where((t) => t.priority == 'medium').length})', 
                  Colors.amber, 
                  isPriority: true
                ),
                _buildQuickFilterChip(
                  'low', 
                  'Low (${widget.tickets.where((t) => t.priority == 'low').length})', 
                  Colors.green, 
                  isPriority: true
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Priority Analysis Card
  Widget _buildPriorityAnalysisCard() {
    final priorityCounts = {
      'critical': widget.tickets.where((t) => t.priority == 'critical').length,
      'high': widget.tickets.where((t) => t.priority == 'high').length,
      'medium': widget.tickets.where((t) => t.priority == 'medium').length,
      'low': widget.tickets.where((t) => t.priority == 'low').length,
    };
    
    final priorityColors = {
      'critical': Colors.red,
      'high': Colors.orange,
      'medium': Colors.amber,
      'low': Colors.green,
    };
    
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.priority_high, size: 20),
                SizedBox(width: 8),
                Text(
                  'Priority Distribution',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Priority counts
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: priorityCounts.entries.map((entry) {
                return _buildPriorityItem(
                  _capitalizeFirst(entry.key),
                  entry.value,
                  priorityColors[entry.key]!,
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  // Age Distribution Card
  Widget _buildAgeDistributionCard() {
    // Grouping tickets by age
    final now = DateTime.now();
    final today = widget.tickets.where((t) => 
      now.difference(t.createdAt).inDays == 0).length;
    final threeDays = widget.tickets.where((t) => 
      now.difference(t.createdAt).inDays > 0 &&
      now.difference(t.createdAt).inDays <= 3).length;
    final week = widget.tickets.where((t) => 
      now.difference(t.createdAt).inDays > 3 &&
      now.difference(t.createdAt).inDays <= 7).length;
    final twoWeeks = widget.tickets.where((t) => 
      now.difference(t.createdAt).inDays > 7 &&
      now.difference(t.createdAt).inDays <= 14).length;
    final older = widget.tickets.where((t) => 
      now.difference(t.createdAt).inDays > 14).length;
    
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.access_time, size: 20),
                SizedBox(width: 8),
                Text(
                  'Ticket Age',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Age distribution
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildAgeItem('Today', today, Colors.green),
                _buildAgeItem('1-3 Days', threeDays, Colors.lime),
                _buildAgeItem('4-7 Days', week, Colors.amber),
                _buildAgeItem('8-14 Days', twoWeeks, Colors.orange),
                _buildAgeItem('Older', older, Colors.red),
              ],
            ),
          ],
        ),
      ),
    );
  }
  // Helper Widgets
  
  // Status count tile
  Widget _buildStatusCountTile(String label, int count, double percentage, Color color, IconData icon, String status) {
    return InkWell(
      onTap: () => widget.onStatusFilterSelected(status),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  count.toString(),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '(${percentage.toStringAsFixed(1)}%)',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  // Priority item
  Widget _buildPriorityItem(String label, int count, Color color) {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 2),
          ),
          alignment: Alignment.center,
          child: Text(
            count.toString(),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
  
  // Age item
  Widget _buildAgeItem(String label, int count, Color color) {
    return Column(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(4),
          ),
          alignment: Alignment.center,
          child: Text(
            count.toString(),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
    // Status legend
  Widget _buildStatusLegend() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: statuses.entries.map((entry) {
        final status = entry.key;
        final statusInfo = entry.value;
        final count = widget.tickets.where((t) => t.status == entry.key).length;
        if (count == 0) return const SizedBox.shrink();
        
        // Calculate percentage
        final double percentage = widget.tickets.isNotEmpty
            ? (count / widget.tickets.length * 100)
            : 0.0;
        
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: InkWell(
            onTap: () => widget.onStatusFilterSelected(status),
            borderRadius: BorderRadius.circular(4),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: statusInfo['color'] as Color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    statusInfo['label'] as String,
                    style: const TextStyle(fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '$count (${percentage.toStringAsFixed(1)}%)',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
        );
      }).where((widget) => widget != const SizedBox.shrink()).toList(),
    );
  }
    // Quick filter chip
  Widget _buildQuickFilterChip(String value, String label, Color color, {bool isPriority = false, bool isHighlighted = false}) {
    return ActionChip(
      avatar: Icon(
        isPriority ? Icons.priority_high : Icons.label,
        size: 16,
        color: color,
      ),
      label: Text(label),
      backgroundColor: isHighlighted ? color.withOpacity(0.2) : color.withOpacity(0.1),
      labelStyle: TextStyle(
        color: color,
        fontSize: 12,
        fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: isHighlighted ? color : color.withOpacity(0.3), width: isHighlighted ? 1.5 : 1.0),
      ),
      onPressed: () {
        if (!isPriority) {
          widget.onStatusFilterSelected(value);
        } else {
          // TODO: Handle priority filtering
        }
      },
    );
  }
  // Pie chart data
  List<PieChartSectionData> _getPieChartSections() {
    final List<PieChartSectionData> sections = [];
    
    if (widget.tickets.isEmpty) return sections;
    
    double totalTickets = widget.tickets.length.toDouble();
    List<String> statusKeysWithData = [];
    
    // First collect all statuses that have tickets
    statuses.keys.forEach((status) {
      final count = widget.tickets.where((t) => t.status == status).length;
      if (count > 0) {
        statusKeysWithData.add(status);
      }
    });
    
    // Then create sections for those statuses
    for (int i = 0; i < statusKeysWithData.length; i++) {
      final status = statusKeysWithData[i];
      final statusInfo = statuses[status]!;
      final count = widget.tickets.where((t) => t.status == status).length;
      final double percentage = count / totalTickets;
      
      sections.add(
        PieChartSectionData(
          color: statusInfo['color'] as Color,
          value: count.toDouble(),
          title: '${(percentage * 100).toStringAsFixed(0)}%',
          radius: 60,
          titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          badgeWidget: count > 0 ? _PieChartBadge(
            statusInfo['icon'] as IconData,
            statusInfo['color'] as Color,
            count,
          ) : null,
          badgePositionPercentageOffset: 1.3,
        ),
      );
    }
    
    return sections;
  }
  
  String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
}

// Custom badge widget for pie chart sections
class _PieChartBadge extends StatelessWidget {
  final IconData icon;
  final Color color;
  final int count;
  
  const _PieChartBadge(this.icon, this.color, this.count);
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
          ),
        ],
      ),
      child: Icon(
        icon,
        size: 12,
        color: color,
      ),
    );
  }
}