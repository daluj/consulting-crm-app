class User {
  final int? id;
  final String username;
  final String password;
  final bool isConsultant;
  final int? clientId; // Only for client users, links to a Client record

  User({
    this.id,
    required this.username,
    required this.password,
    required this.isConsultant,
    this.clientId,
  });

  // Convert a User into a Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'password': password,
      'isConsultant': isConsultant ? 1 : 0,
      'clientId': clientId,
    };
  }

  // Create a User from a Map
  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      username: map['username'],
      password: map['password'],
      isConsultant: map['isConsultant'] == 1,
      clientId: map['clientId'],
    );
  }
}