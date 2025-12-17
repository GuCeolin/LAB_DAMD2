import 'package:flutter/material.dart';
import 'dart:async';
import 'package:task_manager/services/connectivity_service.dart';
import 'package:task_manager/services/sync_service.dart';
import '../models/task.dart';
import '../services/database_service.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  List<Task> _tasks = [];
  List<Task> _filteredTasks = [];
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedPriority = 'medium';
  String _filterStatus = 'todas'; // todas, completas, pendentes
  ConnectionStatus _connectionStatus = ConnectionStatus.unknown;
  StreamSubscription? _connectivitySubscription;
  StreamSubscription? _syncSubscription;

  @override
  void initState() {
    super.initState();
    _loadTasks();
    _connectionStatus = ConnectivityService().currentStatus;
    _connectivitySubscription = ConnectivityService().connectionStatus.listen((
      status,
    ) {
      setState(() {
        _connectionStatus = status;
      });
    });
    _syncSubscription = SyncService().onSyncCompleted.listen((_) {
      _loadTasks();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sincronização concluída!')),
        );
      }
    });
  }

  Future<void> _loadTasks() async {
    final tasks = await DatabaseService.instance.readAll();
    setState(() {
      _tasks = tasks;
      _applyFilter();
    });
  }

  void _applyFilter() {
    setState(() {
      switch (_filterStatus) {
        case 'completas':
          _filteredTasks = _tasks.where((task) => task.completed).toList();
          break;
        case 'pendentes':
          _filteredTasks = _tasks.where((task) => !task.completed).toList();
          break;
        default:
          _filteredTasks = _tasks;
      }
    });
  }

  Future<void> _addTask() async {
    if (_titleController.text.trim().isEmpty) return;

    final task = Task(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      priority: _selectedPriority,
    );
    await DatabaseService.instance.create(task);
    _titleController.clear();
    _descriptionController.clear();
    _loadTasks();
  }

  Future<void> _toggleTask(Task task) async {
    final updated = task.copyWith(completed: !task.completed);
    await DatabaseService.instance.update(updated);
    _loadTasks();
  }

  Future<void> _deleteTask(String id) async {
    await DatabaseService.instance.delete(id);
    _loadTasks();
  }

  Widget _buildCounter(String label, int count, Color color) {
    return Column(
      children: [
        Icon(
          label == 'Total'
              ? Icons.list
              : label == 'Completas'
              ? Icons.check_circle
              : Icons.pending,
          color: color,
          size: 24,
        ),
        const SizedBox(height: 4),
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _getPriorityIcon(String priority) {
    switch (priority) {
      case 'high':
        return const Icon(Icons.circle, color: Colors.red, size: 12);
      case 'medium':
        return const Icon(Icons.circle, color: Colors.orange, size: 12);
      case 'low':
        return const Icon(Icons.circle, color: Colors.green, size: 12);
      default:
        return const Icon(Icons.circle, color: Colors.grey, size: 12);
    }
  }

  String _getPriorityText(String priority) {
    switch (priority) {
      case 'high':
        return 'Alta';
      case 'medium':
        return 'Média';
      case 'low':
        return 'Baixa';
      default:
        return 'Média';
    }
  }

  void _showDeleteConfirmation(Task task) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Excluir Tarefa'),
          content: Text('Tem certeza que deseja excluir "${task.title}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                _deleteTask(task.id);
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Tarefa "${task.title}" excluída!')),
                );
              },
              child: const Text('Excluir', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _connectivitySubscription?.cancel();
    _syncSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Minhas Tarefas'),
            const Spacer(),
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _connectionStatus == ConnectionStatus.online
                    ? Colors.green
                    : Colors.red,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              _connectionStatus == ConnectionStatus.online
                  ? 'Online'
                  : 'Offline',
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Contador de tarefas
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildCounter('Total', _tasks.length, Colors.blue),
                _buildCounter(
                  'Completas',
                  _tasks.where((t) => t.completed).length,
                  Colors.green,
                ),
                _buildCounter(
                  'Pendentes',
                  _tasks.where((t) => !t.completed).length,
                  Colors.orange,
                ),
              ],
            ),
          ),

          // Filtros
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Text('Filtrar: '),
                Expanded(
                  child: SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'todas', label: Text('Todas')),
                      ButtonSegment(
                        value: 'pendentes',
                        label: Text('Pendentes'),
                      ),
                      ButtonSegment(
                        value: 'completas',
                        label: Text('Completas'),
                      ),
                    ],
                    selected: {_filterStatus},
                    onSelectionChanged: (Set<String> selection) {
                      setState(() {
                        _filterStatus = selection.first;
                        _applyFilter();
                      });
                    },
                  ),
                ),
              ],
            ),
          ),

          // Formulário de adicionar tarefa
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.3),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    hintText: 'Título da tarefa...',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.title),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    hintText: 'Descrição (opcional)...',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.description),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text('Prioridade: '),
                    Expanded(
                      child: DropdownButton<String>(
                        value: _selectedPriority,
                        isExpanded: true,
                        items: const [
                          DropdownMenuItem(
                            value: 'low',
                            child: Text('🟢 Baixa'),
                          ),
                          DropdownMenuItem(
                            value: 'medium',
                            child: Text('🟡 Média'),
                          ),
                          DropdownMenuItem(
                            value: 'high',
                            child: Text('🔴 Alta'),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedPriority = value!;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: _addTask,
                      icon: const Icon(Icons.add),
                      label: const Text('Adicionar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Lista de tarefas
          Expanded(
            child: _filteredTasks.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.task_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _tasks.isEmpty
                              ? 'Nenhuma tarefa cadastrada!'
                              : 'Nenhuma tarefa encontrada no filtro atual!',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text(
                          'Adicione uma nova tarefa para começar',
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: _filteredTasks.length,
                    itemBuilder: (context, index) {
                      final task = _filteredTasks[index];
                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        child: ListTile(
                          leading: Checkbox(
                            value: task.completed,
                            onChanged: (_) => _toggleTask(task),
                          ),
                          title: Text(
                            task.title,
                            style: TextStyle(
                              decoration: task.completed
                                  ? TextDecoration.lineThrough
                                  : null,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (task.description.isNotEmpty)
                                Text(task.description),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  _getPriorityIcon(task.priority),
                                  const SizedBox(width: 4),
                                  Text(
                                    _getPriorityText(task.priority),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    '${task.createdAt.day}/${task.createdAt.month}/${task.createdAt.year}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _showDeleteConfirmation(task),
                          ),
                          tileColor: task.completed ? Colors.green[50] : null,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
