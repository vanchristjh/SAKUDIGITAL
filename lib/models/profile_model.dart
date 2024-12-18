class Profile {
  final String id;
  final String name;
  final String email;
  final num balance;
  final int rewards;
  final String role;
  final DateTime? lastTransaction;
  final DateTime createdAt;

  Profile({
    required this.id,
    required this.name,
    required this.email,
    this.balance = 0,
    this.rewards = 0,
    this.role = 'standard',
    this.lastTransaction,
    required this.createdAt,
  });

  factory Profile.fromMap(String id, Map<String, dynamic> map) {
    return Profile(
      id: id,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      balance: map['balance'] ?? 0,
      rewards: map['rewards'] ?? 0,
      role: map['role'] ?? 'standard',
      lastTransaction: map['lastTransaction']?.toDate(),
      createdAt: map['createdAt']?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'balance': balance,
      'rewards': rewards,
      'role': role,
      'lastTransaction': lastTransaction,
      'createdAt': createdAt,
    };
  }
}