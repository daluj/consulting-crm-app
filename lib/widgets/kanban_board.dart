import 'package:flutter/material.dart';
import 'package:drag_and_drop_lists/drag_and_drop_lists.dart';
import '../models/database_models.dart';
import '../services/database_service.dart';

class KanbanBoard extends StatefulWidget {
  final int projectId;
  final bool isConsultantMode;
  final Function? onTasksUpdated;

  const KanbanBoard({
    Key? key,
    required this.projectId,
    this.isConsultantMode = true,
    this.onTasksUpdated,
  }) : super(key: key);

  @override
  State<KanbanBoard> createState() => _KanbanBoardState();
}

class _KanbanBoardState extends State<KanbanBoard> {
  final DatabaseService _databaseService = DatabaseService();
  List<Task> _todoTasks = [];
  List<Task> _inProgressTasks = [];
  List<Task> _doneTasks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    setState(() {
      _isLoading = true;
    });

    try {
      _todoTasks = await _databaseService.getProjectTasksByStatus(
          widget.projectId, 'todo');
      _inProgressTasks = await _databaseService.getProjectTasksByStatus(
          widget.projectId, 'in-progress');
      _doneTasks = await _databaseService.getProjectTasksByStatus(
          widget.projectId, 'done');
    } catch (e) {
      // Handle error
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _updateTaskStatus(Task task, String newStatus) async {
    final updatedTask = task.copyWith(status: newStatus);
    await _databaseService.updateTask(updatedTask);
    
    if (widget.onTasksUpdated != null) {
      widget.onTasksUpdated!();
    }
    
    _loadTasks();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (widget.isConsultantMode) {
      return _buildDraggableKanban();
    } else {
      return _buildReadOnlyKanban();
    }
  }

  Widget _buildDraggableKanban() {
    final List<DragAndDropList> lists = [
      _buildDragList('To Do', _todoTasks, Colors.orange),
      _buildDragList('In Progress', _inProgressTasks, Colors.blue),
      _buildDragList('Done', _doneTasks, Colors.green),
    ];

    return DragAndDropLists(
      children: lists,
      onItemReorder: _onItemReorder,
      onListReorder: (int oldListIndex, int newListIndex) {
        // Not allowing reordering of the lists
      },
      listPadding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      listInnerDecoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      lastListTargetSize: 0,
      addLastItemTargetHeightToTop: true,
      lastItemTargetHeight: 8,
      axis: Axis.horizontal,
      listWidth: MediaQuery.of(context).size.width * 0.31,
      contentsWhenEmpty: const Center(child: Text('No tasks')),
    );
  }

  DragAndDropList _buildDragList(String title, List<Task> tasks, Color headerColor) {
    return DragAndDropList(
      header: Container(
        decoration: BoxDecoration(
          color: headerColor.withOpacity(0.2),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: headerColor.withOpacity(0.8),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: headerColor.withOpacity(0.4),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${tasks.length}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
      children: tasks.map((task) {
        return DragAndDropItem(
          child: _buildTaskCard(task, headerColor),
        );
      }).toList(),
      contentsWhenEmpty: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'No tasks in $title',
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ),
      ),
    );
  }

  void _onItemReorder(int oldItemIndex, int oldListIndex, int newItemIndex, int newListIndex) {
    setState(() {
      // Get the task that was dragged
      Task movedTask;
      String newStatus;
      
      // Determine which list the task is moving from
      if (oldListIndex == 0) {
        movedTask = _todoTasks[oldItemIndex];
        newStatus = 'todo';
      } else if (oldListIndex == 1) {
        movedTask = _inProgressTasks[oldItemIndex];
        newStatus = 'in-progress';
      } else {
        movedTask = _doneTasks[oldItemIndex];
        newStatus = 'done';
      }
      
      // Determine the new status based on destination list
      if (newListIndex == 0) {
        newStatus = 'todo';
      } else if (newListIndex == 1) {
        newStatus = 'in-progress';
      } else {
        newStatus = 'done';
      }
      
      // Update the task status in the database
      _updateTaskStatus(movedTask, newStatus);
    });
  }

  Widget _buildReadOnlyKanban() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildColumn('To Do', _todoTasks, Colors.orange),
          const SizedBox(width: 16),
          _buildColumn('In Progress', _inProgressTasks, Colors.blue),
          const SizedBox(width: 16),
          _buildColumn('Done', _doneTasks, Colors.green),
        ],
      ),
    );
  }

  Widget _buildColumn(String title, List<Task> tasks, Color headerColor) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.8,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              color: headerColor.withOpacity(0.2),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: headerColor.withOpacity(0.8),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: headerColor.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${tasks.length}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (tasks.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: Text(
                  'No tasks in $title',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: tasks.length,
              padding: const EdgeInsets.all(8.0),
              itemBuilder: (context, index) {
                return _buildTaskCard(tasks[index], headerColor);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildTaskCard(Task task, Color statusColor) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    task.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (widget.isConsultantMode)
                  IconButton(
                    icon: const Icon(Icons.more_vert, size: 18),
                    onPressed: () => _showTaskOptions(task),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),
            if (task.description.isNotEmpty) ...[  
              const SizedBox(height: 8),
              Text(
                task.description,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            if (task.dueDate != null) ...[  
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 14,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Due: ${_formatDate(task.dueDate!)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: _isTaskOverdue(task) ? Colors.red : Colors.grey[600],
                      fontWeight: _isTaskOverdue(task) ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showTaskOptions(Task task) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Edit Task'),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Implement edit task functionality
                },
              ),
              if (task.status != 'todo')
                ListTile(
                  leading: const Icon(Icons.undo),
                  title: const Text('Move to To Do'),
                  onTap: () {
                    Navigator.pop(context);
                    _updateTaskStatus(task, 'todo');
                  },
                ),
              if (task.status != 'in-progress')
                ListTile(
                  leading: const Icon(Icons.pending_actions),
                  title: const Text('Move to In Progress'),
                  onTap: () {
                    Navigator.pop(context);
                    _updateTaskStatus(task, 'in-progress');
                  },
                ),
              if (task.status != 'done')
                ListTile(
                  leading: const Icon(Icons.check_circle),
                  title: const Text('Move to Done'),
                  onTap: () {
                    Navigator.pop(context);
                    _updateTaskStatus(task, 'done');
                  },
                ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Delete Task', style: TextStyle(color: Colors.red)),
                onTap: () async {
                  Navigator.pop(context);
                  final confirmed = await _showDeleteConfirmation();
                  if (confirmed) {
                    await _databaseService.deleteTask(task.id!);
                    _loadTasks();
                    if (widget.onTasksUpdated != null) {
                      widget.onTasksUpdated!();
                    }
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<bool> _showDeleteConfirmation() async {
    return await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Task'),
        content: const Text('Are you sure you want to delete this task?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    ) ?? false;
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }

  bool _isTaskOverdue(Task task) {
    if (task.dueDate == null || task.status == 'done') return false;
    final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    final dueDate = DateTime(task.dueDate!.year, task.dueDate!.month, task.dueDate!.day);
    return dueDate.isBefore(today);
  }
}