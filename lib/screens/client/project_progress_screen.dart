import 'package:flutter/material.dart';
import '../../models/database_models.dart';
import '../../services/database_service.dart';
import '../../widgets/kanban_board.dart';
import '../../widgets/report_card.dart';

class ProjectProgressScreen extends StatefulWidget {
  final Project project;
  final int initialTabIndex;

  const ProjectProgressScreen({
    Key? key,
    required this.project,
    this.initialTabIndex = 0,
  }) : super(key: key);

  @override
  State<ProjectProgressScreen> createState() => _ProjectProgressScreenState();
}

class _ProjectProgressScreenState extends State<ProjectProgressScreen> with SingleTickerProviderStateMixin {
  final DatabaseService _databaseService = DatabaseService();
  late TabController _tabController;
  bool _isLoading = true;
  List<Announcement> _announcements = [];
  List<Task> _todoTasks = [];
  List<Task> _inProgressTasks = [];
  List<Task> _doneTasks = [];
  double _completionPercentage = 0.0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
    _loadProjectData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadProjectData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load announcements
      final announcements = await _databaseService.getProjectAnnouncements(
        widget.project.id!,
        publishedOnly: true, // Only show published announcements to clients
      );
      
      // Load tasks
      final todoTasks = await _databaseService.getProjectTasksByStatus(widget.project.id!, 'todo');
      final inProgressTasks = await _databaseService.getProjectTasksByStatus(widget.project.id!, 'in-progress');
      final doneTasks = await _databaseService.getProjectTasksByStatus(widget.project.id!, 'done');

      // Calculate completion percentage
      final totalTasks = todoTasks.length + inProgressTasks.length + doneTasks.length;
      double completionPercentage = 0.0;
      if (totalTasks > 0) {
        completionPercentage = doneTasks.length / totalTasks;
      }

      setState(() {
        _announcements = announcements;
        _todoTasks = todoTasks;
        _inProgressTasks = inProgressTasks;
        _doneTasks = doneTasks;
        _completionPercentage = completionPercentage;
        _isLoading = false;
      });
    } catch (e) {
      // Handle error
      print('Error loading project data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.project.title),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Tasks'),
            Tab(text: 'Updates'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildTasksTab(),
                _buildUpdatesTab(),
              ],
            ),
    );
  }

  Widget _buildTasksTab() {
    final totalTasks = _todoTasks.length + _inProgressTasks.length + _doneTasks.length;
    
    return RefreshIndicator(
      onRefresh: _loadProjectData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProgressCard(),
              const SizedBox(height: 24),
              const Text(
                'Task Board',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              if (totalTasks == 0)
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.assignment_outlined,
                            size: 48,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No tasks have been created for this project yet',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                SizedBox(
                  height: 500,
                  child: KanbanBoard(
                    projectId: widget.project.id!,
                    isConsultantMode: false, // Read-only for clients
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressCard() {
    final totalTasks = _todoTasks.length + _inProgressTasks.length + _doneTasks.length;
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Project Progress',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${(_completionPercentage * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: _completionPercentage,
                minHeight: 10,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildTaskCountChip('To Do', _todoTasks.length, Colors.orange),
                _buildTaskCountChip('In Progress', _inProgressTasks.length, Colors.blue),
                _buildTaskCountChip('Completed', _doneTasks.length, Colors.green),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Project Description:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.project.description,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskCountChip(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$label: $count',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color.withOpacity(0.8),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpdatesTab() {
    return RefreshIndicator(
      onRefresh: _loadProjectData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Project Updates',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              if (_announcements.isEmpty)
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.announcement_outlined,
                            size: 48,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No updates have been posted for this project yet',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _announcements.length,
                  itemBuilder: (context, index) {
                    return ReportCard(
                      announcement: _announcements[index],
                      isConsultantMode: false,
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}