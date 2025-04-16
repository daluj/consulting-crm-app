# ConsultCRM - Consulting CRM Application

A comprehensive CRM (Customer Relationship Management) application designed for small consulting businesses. This Flutter-based application helps consultants manage clients, projects, tasks, and invoices efficiently.

## Project Overview

ConsultCRM is a cross-platform application built with Flutter that provides separate interfaces for consultants and clients. Consultants can manage their business operations while clients can access their project information through a dedicated portal.

## Technical Specifications

### Environment Requirements

- Dart SDK: >=3.0.0 <4.0.0
- Flutter SDK: Compatible with the latest stable version
- Supports multiple platforms (Android, iOS, Web)

### Dependencies

```yaml
dependencies:
  drag_and_drop_lists: 0.4.2  # For Kanban board functionality
  printing: ^5.0.0           # For generating printable documents
  pdf: ^3.0.0                # For PDF generation
  flutter_slidable: ^3.0.0   # For slidable list items
  path: ^1.0.0               # For file path operations
  intl: 0.20.2               # For date/time formatting
  sqflite: ^2.0.0            # For local SQLite database
  flutter:                   # Flutter framework
    sdk: flutter
  cupertino_icons: ^1.0.0    # iOS-style icons
  fl_chart: ^0.68.0          # For data visualization
  google_fonts: 6.1.0        # For custom fonts
  shared_preferences: 2.3.2   # For local storage
  path_provider: 2.1.4       # For file system access
  provider: 6.1.2            # For state management
  http: '>=1.0.0'            # For network requests
  uuid: '>=3.0.0'            # For generating unique IDs
```

## Project Structure

```
lib/
├── main.dart                # Application entry point
├── models/                  # Data models
│   ├── database_models.dart # Database entity models
│   └── user_model.dart      # User authentication model
├── screens/                 # UI screens
│   ├── auth/                # Authentication screens
│   │   └── login_screen.dart
│   ├── client/              # Client portal screens
│   │   └── client_portal_screen.dart
│   └── consultant/          # Consultant dashboard screens
│       └── dashboard_screen.dart
├── services/                # Business logic services
│   ├── auth_service.dart    # Authentication service
│   └── database_service.dart # Database operations
├── theme.dart               # App theming
└── widgets/                 # Reusable UI components
    ├── kanban_board.dart    # Drag-and-drop task board
    └── report_card.dart     # Report visualization
```

## Database Schema

The application uses SQLite for local data storage with the following tables:

### Clients
```sql
CREATE TABLE clients(
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  email TEXT NOT NULL,
  phone TEXT NOT NULL,
  company TEXT NOT NULL,
  notes TEXT
)
```

### Projects
```sql
CREATE TABLE projects(
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  clientId INTEGER NOT NULL,
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  startDate TEXT NOT NULL,
  endDate TEXT,
  status TEXT NOT NULL,
  budget REAL NOT NULL,
  FOREIGN KEY (clientId) REFERENCES clients (id) ON DELETE CASCADE
)
```

### Users
```sql
CREATE TABLE users(
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  username TEXT NOT NULL UNIQUE,
  password TEXT NOT NULL,
  isConsultant INTEGER NOT NULL,
  clientId INTEGER,
  FOREIGN KEY (clientId) REFERENCES clients (id) ON DELETE CASCADE
)
```

### Tasks
```sql
CREATE TABLE tasks(
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  projectId INTEGER NOT NULL,
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  status TEXT NOT NULL,
  dueDate TEXT,
  completedDate TEXT,
  FOREIGN KEY (projectId) REFERENCES projects (id) ON DELETE CASCADE
)
```

### Invoices
```sql
CREATE TABLE invoices(
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  clientId INTEGER NOT NULL,
  projectId INTEGER NOT NULL,
  invoiceNumber TEXT NOT NULL,
  issueDate TEXT NOT NULL,
  dueDate TEXT NOT NULL,
  status TEXT NOT NULL,
  amount REAL NOT NULL,
  taxRate REAL NOT NULL,
  notes TEXT,
  FOREIGN KEY (clientId) REFERENCES clients (id) ON DELETE CASCADE,
  FOREIGN KEY (projectId) REFERENCES projects (id) ON DELETE CASCADE
)
```

## Key Features

### Authentication System
- Separate login for consultants and clients
- Persistent login using SharedPreferences
- User registration with role-based access control

### Consultant Dashboard
- Overview of active projects and tasks
- Client management (add, edit, delete)
- Project tracking with status updates
- Invoice generation and management
- Task management with Kanban board interface

### Client Portal
- View assigned projects and their status
- Access project tasks and timelines
- View and download invoices
- Limited interaction based on permissions

### Kanban Board
- Drag-and-drop task management
- Tasks organized by status (Todo, In Progress, Done)
- Visual workflow management

## Implementation Details

### State Management
- Provider pattern for application state
- ChangeNotifier for reactive UI updates

### Database Operations
- Singleton pattern for database service
- CRUD operations for all entities
- Foreign key relationships for data integrity

### UI/UX
- Material Design 3 implementation
- Responsive layout for multiple screen sizes
- Light and dark theme support
- Custom card designs for data visualization

### Data Visualization
- Charts for financial reporting
- Progress indicators for project status
- Timeline views for project planning

## Getting Started

1. Ensure Flutter SDK is installed and configured
2. Clone the repository
3. Run `flutter pub get` to install dependencies
4. Run `flutter run` to start the application

## Development Notes

- The application initializes with a default consultant user for testing
- Database is automatically created on first run
- Authentication credentials are stored locally
- The app follows a service-based architecture for separation of concerns