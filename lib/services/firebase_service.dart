import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Authentication methods
  Future<UserCredential> signIn(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final userDoc = await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();
          
      if (!userDoc.exists) {
        await _auth.signOut();
        throw Exception('User data not found. Please register again.');
      }

      final userData = userDoc.data()!;
      if (userData['account_status'] != 'active') {
        await _auth.signOut();
        throw Exception('This account has been deactivated.');
      }

      // Update last login
      await userDoc.reference.update({
        'last_login': FieldValue.serverTimestamp(),
      });

      return userCredential;
    } catch (e) {
      throw _handleAuthError(e);
    }
  }

  Future<UserCredential> signUp(String email, String password, String pin) async {
    try {
      // Check if email exists
      final methods = await _auth.fetchSignInMethodsForEmail(email);
      if (methods.isNotEmpty) {
        throw Exception('An account already exists with this email');
      }

      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Initial user data
      final userData = {
        'email': email,
        'pin': pin,
        'balance': 0.0,
        'pin_attempts': 0,
        'account_status': 'active',
        'created_at': FieldValue.serverTimestamp(),
        'last_login': FieldValue.serverTimestamp(),
      };

      await createUserData(userCredential.user!.uid, userData);
      return userCredential;
    } catch (e) {
      throw _handleAuthError(e);
    }
  }

  // Firestore methods
  Future<void> createUserData(String uid, Map<String, dynamic> userData) async {
    if (uid.isEmpty) throw Exception('User ID cannot be empty');
    try {
      await _firestore.collection('users').doc(uid).set(userData);
    } on FirebaseException catch (e) {
      throw Exception('Failed to create user data: ${e.message}');
    }
  }

  Future<void> updateUserBalance(String uid, double amount) async {
    if (uid.isEmpty) throw Exception('User ID cannot be empty');
    try {
      final userDoc = await _firestore.collection('users').doc(uid).get();
      if (!userDoc.exists) throw Exception('User not found');
      
      final currentBalance = (userDoc.data()?['balance'] ?? 0.0) as double;
      final newBalance = currentBalance + amount;
      
      if (newBalance < 0) throw Exception('Insufficient balance');
      
      await _firestore.collection('users').doc(uid).update({
        'balance': newBalance,
      });
    } on FirebaseException catch (e) {
      throw Exception('Failed to update balance: ${e.message}');
    }
  }

  Future<void> updateUserData(String uid, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('users').doc(uid).update(data);
    } catch (e) {
      throw _handleFirestoreError(e);
    }
  }

  Future<List<TransactionData>> getUserTransactions(String uid) async {
    try {
      final snapshot = await _firestore
          .collection('transactions')
          .where('userId', isEqualTo: uid)
          .orderBy('timestamp', descending: true)
          .limit(10)
          .get();

      return snapshot.docs.map((doc) => TransactionData.fromFirestore(doc)).toList();
    } catch (e) {
      throw _handleFirestoreError(e);
    }
  }

  Exception _handleFirestoreError(dynamic e) {
    if (e is FirebaseException) {
      switch (e.code) {
        case 'permission-denied':
          return Exception('You do not have permission to perform this action');
        case 'not-found':
          return Exception('The requested data does not exist');
        default:
          return Exception(e.message ?? 'Database operation failed');
      }
    }
    return Exception(e.toString());
  }

  // PIN verification and transaction handling
  Future<Map<String, dynamic>> validatePIN(String pin, {double? amount}) async {
    try {
      if (pin.isEmpty || pin.length != 6) {
        throw Exception('PIN must be 6 digits');
      }

      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final docRef = _firestore.collection('users').doc(user.uid);
      
      return await _firestore.runTransaction<Map<String, dynamic>>((transaction) async {
        final docSnap = await transaction.get(docRef);
        if (!docSnap.exists) throw Exception('User data not found');
        
        final userData = docSnap.data()!;
        final storedPin = userData['pin']?.toString();  // Ensure PIN is string
        final attempts = (userData['pin_attempts'] ?? 0) as int;
        
        if (storedPin == null) throw Exception('Security PIN not set');
        
        // Check PIN attempts
        if (attempts >= 3) {
          final lastAttempt = userData['last_pin_attempt'] as Timestamp?;
          if (lastAttempt != null) {
            final cooldownPeriod = DateTime.now().difference(lastAttempt.toDate());
            if (cooldownPeriod.inMinutes < 30) {
              throw Exception('Too many failed attempts. Please try again after ${30 - cooldownPeriod.inMinutes} minutes.');
            }
          }
        }

        // Validate PIN
        if (storedPin != pin) {
          await docRef.update({
            'pin_attempts': attempts + 1,
            'last_pin_attempt': FieldValue.serverTimestamp(),
          });
          throw Exception('Invalid PIN');
        }

        // Reset attempts on successful validation
        await docRef.update({'pin_attempts': 0});
        
        return {
          'valid': true,
          'balance': userData['balance'] ?? 0.0,
          'userData': userData,
        };
      });
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<void> processSecuredTransaction({
    required String pin,
    required double amount,
    required String description,
    required bool isDebit,
  }) async {
    try {
      final validation = await validatePIN(
        pin,
        amount: isDebit ? amount : null,
      );

      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      await _firestore.runTransaction((transaction) async {
        final userDoc = _firestore.collection('users').doc(user.uid);
        final currentBalance = validation['balance'] as double;
        final newBalance = isDebit ? currentBalance - amount : currentBalance + amount;
        
        transaction.update(userDoc, {'balance': newBalance});

        // Record transaction
        transaction.set(_firestore.collection('transactions').doc(), {
          'userId': user.uid,
          'amount': amount,
          'type': isDebit ? 'debit' : 'credit',
          'description': description,
          'timestamp': FieldValue.serverTimestamp(),
        });
      });
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // PIN management
  Future<void> updatePIN(String currentPin, String newPin) async {
    try {
      await validatePIN(currentPin);
      
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      await _firestore.collection('users').doc(user.uid).update({
        'pin': newPin,
        'pin_updated_at': FieldValue.serverTimestamp(),
        'pin_attempts': 0,
      });
    } catch (e) {
      throw Exception('Failed to update PIN: ${e.toString()}');
    }
  }

  // Add method to check auth state
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Method to deactivate account (instead of deleting)
  Future<void> deactivateAccount() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).update({
          'account_active': false,
          'deactivated_at': FieldValue.serverTimestamp(),
        });
        await _auth.signOut();
      }
    } catch (e) {
      throw Exception('Failed to deactivate account: ${e.toString()}');
    }
  }

  // Add method to verify account status
  Future<bool> verifyAccountStatus(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      return doc.exists && doc.data()?['account_status'] == 'active';
    } catch (e) {
      return false;
    }
  }

  // Add auto-login check
  Future<User?> autoLogin() async {
    final user = _auth.currentUser;
    if (user != null) {
      final isActive = await verifyAccountStatus(user.uid);
      if (!isActive) {
        await _auth.signOut();
        return null;
      }
      return user;
    }
    return null;
  }

  // Error handling
  Exception _handleAuthError(dynamic e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'wrong-password':
          return Exception('Invalid password. Please try again.');
        case 'user-not-found':
          return Exception('No account exists with this email. Please register first.');
        case 'user-disabled':
          return Exception('This account has been disabled. Please contact support.');
        case 'too-many-requests':
          return Exception('Too many failed attempts. Please try again later.');
        default:
          return Exception(e.message ?? 'Authentication failed');
      }
    }
    return Exception(e.toString());
  }

  Future<Map<String, dynamic>> validateBillAccount({
    required String billType,
    required String accountNumber,
  }) async {
    // For testing, accept any account number with length >= 8
    await Future.delayed(const Duration(milliseconds: 500)); // Simulate network delay
    final isValid = accountNumber.length >= 8;
    
    return {
      'isValid': isValid,
      'message': isValid ? 'Account valid' : 'Invalid account number',
      'details': isValid ? {
        'accountName': 'Test Account',
        'accountNumber': accountNumber,
        'type': billType.toLowerCase(),
      } : null,
    };
  }

  Future<Map<String, dynamic>> getMockBillDetailsSimple({
    required String billType,
    required String accountNumber,
  }) async {
    // For testing, return mock bill details
    await Future.delayed(const Duration(milliseconds: 500));
    
    return {
      'billId': 'MOCK-${DateTime.now().millisecondsSinceEpoch}',
      'accountName': 'Test Account',
      'amount': 150000.0,
      'dueDate': DateTime.now().add(const Duration(days: 7)),
      'description': '$billType Bill',
    };
  }

  Future<Map<String, dynamic>> getBillDetails({
    required String billType,
    required String accountNumber,
  }) async {
    try {
      final billsRef = _firestore.collection('bills');
      final doc = await billsRef
          .where('type', isEqualTo: billType.toLowerCase())
          .where('accountNumber', isEqualTo: accountNumber)
          .where('status', isEqualTo: 'unpaid')
          .get();

      if (doc.docs.isEmpty) {
        return {
          'amount': 0.0,
          'message': 'No pending bills',
          'dueDate': DateTime.now(),
        };
      }

      final billData = doc.docs.first.data();
      return {
        'billId': doc.docs.first.id,
        'accountName': billData['accountName'] ?? '',
        'amount': billData['amount'] ?? 0.0,
        'dueDate': billData['dueDate']?.toDate() ?? DateTime.now(),
        'description': billData['description'] ?? '',
      };
    } catch (e) {
      throw Exception('Failed to fetch bill details: ${e.toString()}');
    }
  }

  Future<String> processBillPayment({
    required String billType,
    required String accountNumber,
    required double amount,
    required String pin,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    return _firestore.runTransaction((transaction) async {
      try {
        // Create payment record first with pending status
        final paymentRef = _firestore.collection('transactions').doc();
        final paymentData = {
          'userId': user.uid,
          'type': 'bill_payment',
          'category': billType.toLowerCase(),
          'accountNumber': accountNumber,
          'amount': amount,
          'timestamp': FieldValue.serverTimestamp(),
          'status': 'pending',
          'description': '$billType Payment - $accountNumber',
        };

        transaction.set(paymentRef, paymentData);

        // Validate PIN and check balance
        final pinValidation = await validatePIN(pin, amount: amount);
        final currentBalance = pinValidation['balance'] as double;
        if (currentBalance < amount) {
          // Update transaction status to failed
          transaction.update(paymentRef, {'status': 'failed'});
          throw Exception('Insufficient balance');
        }

        // Update user balance
        final userRef = _firestore.collection('users').doc(user.uid);
        transaction.update(userRef, {
          'balance': currentBalance - amount,
        });

        // Update transaction status to completed
        transaction.update(paymentRef, {'status': 'completed'});

        return paymentRef.id;
      } catch (e) {
        rethrow;
      }
    });
  }

  Future<Map<String, dynamic>> getMockBillDetails({
    required String billType,
    required String accountNumber,
  }) async {
    try {
      // Simulate fetching bill details
      await Future.delayed(const Duration(seconds: 1));
      
      // In production, this should fetch actual bill details
      return {
        'accountName': 'John Doe',
        'billType': billType,
        'accountNumber': accountNumber,
        'amount': 150000.0,
        'dueDate': DateTime.now().add(const Duration(days: 7)),
      };
    } catch (e) {
      throw Exception('Failed to fetch bill details: ${e.toString()}');
    }
  }

  // Add method to process bill payment
  Future<void> processMockBillPayment({
    required String billType,
    required String accountNumber,
    required double amount,
    required String pin,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    return _firestore.runTransaction((transaction) async {
      // Validate PIN first
      await validatePIN(pin, amount: amount);

      // Create payment record
      final paymentRef = _firestore.collection('transactions').doc();
      transaction.set(paymentRef, {
        'userId': user.uid,
        'type': 'bill_payment',
        'category': billType.toLowerCase(),
        'accountNumber': accountNumber,
        'amount': amount,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'completed',
      });

      // Update user balance
      final userRef = _firestore.collection('users').doc(user.uid);
      final userDoc = await transaction.get(userRef);
      final currentBalance = userDoc.data()?['balance'] as double? ?? 0.0;
      
      if (currentBalance < amount) {
        throw Exception('Insufficient balance');
      }

      transaction.update(userRef, {
        'balance': currentBalance - amount,
      });
    });
  }

  Stream<DocumentSnapshot> getUserStream() {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();
    
    return _firestore.collection('users').doc(user.uid).snapshots();
  }

  // Validate user session
  Future<bool> validateSession() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    
    try {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      return userDoc.exists;
    } catch (e) {
      print('Session validation error: $e');
      return false;
    }
  }

  // Process transaction with validation
  Future<void> processTransaction({
    required String type,
    required double amount,
    required String description,
    Map<String, dynamic>? additionalData,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw 'User not authenticated';

    try {
      await _firestore.runTransaction((transaction) async {
        final userDoc = await _firestore.collection('users').doc(user.uid).get();
        if (!userDoc.exists) throw 'User account not found';

        final currentBalance = (userDoc.data()?['balance'] ?? 0.0) as double;
        if (type == 'debit' && currentBalance < amount) {
          throw 'Insufficient balance';
        }

        final newBalance = type == 'debit' 
            ? currentBalance - amount 
            : currentBalance + amount;

        // Update user balance
        transaction.update(userDoc.reference, {
          'balance': newBalance,
          'lastUpdated': FieldValue.serverTimestamp(),
        });

        // Create transaction record
        transaction.set(
          _firestore.collection('transactions').doc(),
          {
            'userId': user.uid,
            'type': type,
            'amount': amount,
            'description': description,
            'timestamp': FieldValue.serverTimestamp(),
            'status': 'completed',
            ...?additionalData,
          },
        );
      });
    } catch (e) {
      print('Transaction error: $e');
      throw 'Transaction failed: ${e.toString()}';
    }
  }

  // Process bill payment with validation
  Future<void> processValidatedBillPayment({
    required String billType,
    required String accountNumber,
    required double amount,
    required String pin,
  }) async {
    // Validate PIN first
    if (!await validatePin(pin)) {
      throw 'Invalid PIN';
    }

    try {
      await processTransaction(
        type: 'bill_payment',
        amount: amount,
        description: '$billType Payment',
        additionalData: {
          'billType': billType,
          'accountNumber': accountNumber,
        },
      );
    } catch (e) {
      throw 'Payment failed: ${e.toString()}';
    }
  }

  // Validate PIN
  Future<bool> validatePin(String pin) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      return userDoc.data()?['pin'] == pin;
    } catch (e) {
      print('PIN validation error: $e');
      return false;
    }
  }

  // Get transaction history
  Stream<QuerySnapshot> getTransactionHistory() {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();

    return _firestore
        .collection('transactions')
        .where('userId', isEqualTo: user.uid)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  Future<void> validateTransaction({
    required double amount,
    required String type,
    required String description,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw 'Please login to continue';

    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    if (!userDoc.exists) throw 'Account not found';

    final currentBalance = (userDoc.data()?['balance'] ?? 0.0) as double;
    if (type == 'debit' && currentBalance < amount) {
      throw 'insufficient-balance';
    }

    if (amount <= 0) throw 'invalid-amount';
  }

  Future<void> processValidatedBillPaymentWithVerification({
    required String billType,
    required String accountNumber,
    required double amount,
    required String pin,
  }) async {
    try {
      await validateTransaction(
        amount: amount,
        type: 'debit',
        description: '$billType payment',
      );

      if (!await validatePin(pin)) {
        throw 'invalid-pin';
      }

      final validationResult = await validateBillAccount(
        billType: billType,
        accountNumber: accountNumber,
      );

      if (!validationResult['isValid']) {
        throw 'invalid-account';
      }

      await processTransaction(
        amount: amount,
        type: 'bill_payment',
        description: '$billType payment for $accountNumber',
        additionalData: {
          'billType': billType,
          'accountNumber': accountNumber,
          'recipientName': validationResult['name'],
        },
      );
    } catch (e) {
      print('Bill payment error: $e');
      rethrow;
    }
  }
}

class TransactionData {
  final String id;
  final double amount;
  final String type;
  final String description;
  final DateTime timestamp;

  TransactionData.fromFirestore(DocumentSnapshot doc) 
    : id = doc.id,
      amount = doc['amount']?.toDouble() ?? 0.0,
      type = doc['type'] ?? 'unknown',
      description = doc['description'] ?? '',
      timestamp = (doc['timestamp'] as Timestamp).toDate();
}