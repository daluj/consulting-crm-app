import 'package:intl/intl.dart';

// Client model for storing client information
class Client {
  final int? id;
  final String name;
  final String email;
  final String phone;
  final String company;
  final String notes;

  Client({
    this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.company,
    this.notes = '',
  });

  // Convert a Client into a Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'company': company,
      'notes': notes,
    };
  }

  // Create a Client from a Map
  factory Client.fromMap(Map<String, dynamic> map) {
    return Client(
      id: map['id'],
      name: map['name'],
      email: map['email'],
      phone: map['phone'],
      company: map['company'],
      notes: map['notes'] ?? '',
    );
  }

  // Create a copy of this Client with the given changes
  Client copyWith({
    int? id,
    String? name,
    String? email,
    String? phone,
    String? company,
    String? notes,
  }) {
    return Client(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      company: company ?? this.company,
      notes: notes ?? this.notes,
    );
  }
}

// Project model for storing project details
class Project {
  final int? id;
  final int clientId;
  final String title;
  final String description;
  final DateTime startDate;
  final DateTime? endDate;
  final String status; // "active", "completed", "on-hold"
  final double budget;

  Project({
    this.id,
    required this.clientId,
    required this.title,
    required this.description,
    required this.startDate,
    this.endDate,
    required this.status,
    required this.budget,
  });

  // Convert a Project into a Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'clientId': clientId,
      'title': title,
      'description': description,
      'startDate': DateFormat('yyyy-MM-dd').format(startDate),
      'endDate': endDate != null ? DateFormat('yyyy-MM-dd').format(endDate!) : null,
      'status': status,
      'budget': budget,
    };
  }

  // Create a Project from a Map
  factory Project.fromMap(Map<String, dynamic> map) {
    return Project(
      id: map['id'],
      clientId: map['clientId'],
      title: map['title'],
      description: map['description'],
      startDate: DateFormat('yyyy-MM-dd').parse(map['startDate']),
      endDate: map['endDate'] != null ? DateFormat('yyyy-MM-dd').parse(map['endDate']) : null,
      status: map['status'],
      budget: map['budget'],
    );
  }
}

// Task model for tracking project tasks
class Task {
  final int? id;
  final int projectId;
  final String title;
  final String description;
  final String status; // "todo", "in-progress", "done"
  final DateTime? dueDate;
  final DateTime? completedDate;

  Task({
    this.id,
    required this.projectId,
    required this.title,
    required this.description,
    required this.status,
    this.dueDate,
    this.completedDate,
  });

  // Convert a Task into a Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'projectId': projectId,
      'title': title,
      'description': description,
      'status': status,
      'dueDate': dueDate != null ? DateFormat('yyyy-MM-dd').format(dueDate!) : null,
      'completedDate': completedDate != null ? DateFormat('yyyy-MM-dd').format(completedDate!) : null,
    };
  }

  // Create a Task from a Map
  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'],
      projectId: map['projectId'],
      title: map['title'],
      description: map['description'],
      status: map['status'],
      dueDate: map['dueDate'] != null ? DateFormat('yyyy-MM-dd').parse(map['dueDate']) : null,
      completedDate: map['completedDate'] != null ? DateFormat('yyyy-MM-dd').parse(map['completedDate']) : null,
    );
  }

  // Create a copy of this Task with the given changes
  Task copyWith({
    int? id,
    int? projectId,
    String? title,
    String? description,
    String? status,
    DateTime? dueDate,
    DateTime? completedDate,
  }) {
    return Task(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      dueDate: dueDate ?? this.dueDate,
      completedDate: completedDate ?? this.completedDate,
    );
  }
}

// Invoice model for billing clients
class Invoice {
  final int? id;
  final int clientId;
  final int projectId;
  final String invoiceNumber;
  final DateTime issueDate;
  final DateTime dueDate;
  final String status; // "draft", "sent", "paid", "overdue"
  final double amount;
  final double taxRate;
  final String notes;

  Invoice({
    this.id,
    required this.clientId,
    required this.projectId,
    required this.invoiceNumber,
    required this.issueDate,
    required this.dueDate,
    required this.status,
    required this.amount,
    this.taxRate = 0.0,
    this.notes = '',
  });

  // Calculate total amount including tax
  double get totalAmount => amount + (amount * taxRate / 100);

  // Convert an Invoice into a Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'clientId': clientId,
      'projectId': projectId,
      'invoiceNumber': invoiceNumber,
      'issueDate': DateFormat('yyyy-MM-dd').format(issueDate),
      'dueDate': DateFormat('yyyy-MM-dd').format(dueDate),
      'status': status,
      'amount': amount,
      'taxRate': taxRate,
      'notes': notes,
    };
  }

  // Create an Invoice from a Map
  factory Invoice.fromMap(Map<String, dynamic> map) {
    return Invoice(
      id: map['id'],
      clientId: map['clientId'],
      projectId: map['projectId'],
      invoiceNumber: map['invoiceNumber'],
      issueDate: DateFormat('yyyy-MM-dd').parse(map['issueDate']),
      dueDate: DateFormat('yyyy-MM-dd').parse(map['dueDate']),
      status: map['status'],
      amount: map['amount'],
      taxRate: map['taxRate'],
      notes: map['notes'] ?? '',
    );
  }
}

// Announcement model for weekly reports
class Announcement {
  final int? id;
  final int projectId;
  final String title;
  final String content;
  final DateTime datePosted;
  final bool isPublished;

  Announcement({
    this.id,
    required this.projectId,
    required this.title,
    required this.content,
    required this.datePosted,
    this.isPublished = false,
  });

  // Convert an Announcement into a Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'projectId': projectId,
      'title': title,
      'content': content,
      'datePosted': DateFormat('yyyy-MM-dd').format(datePosted),
      'isPublished': isPublished ? 1 : 0,
    };
  }

  // Create an Announcement from a Map
  factory Announcement.fromMap(Map<String, dynamic> map) {
    return Announcement(
      id: map['id'],
      projectId: map['projectId'],
      title: map['title'],
      content: map['content'],
      datePosted: DateFormat('yyyy-MM-dd').parse(map['datePosted']),
      isPublished: map['isPublished'] == 1,
    );
  }
}