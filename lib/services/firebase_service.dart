import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Authentication methods
  Future<UserCredential> signIn(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      throw _handleAuthError(e);
    }
  }

  Future<UserCredential> signUp(String email, String password, String pin) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Create user data with PIN after successful registration
      await createUserData(userCredential.user!.uid, {
        'email': email,
        'pin': pin,
        'balance': 0.0,
      });
      
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

  Future<void> createUserWithPin(String uid, String pin) async {
    try {
      await _firestore.collection('users').doc(uid).set({
        'pin': pin,
        'pin_created_at': FieldValue.serverTimestamp(),
        'pin_attempts': 0,
        'last_pin_attempt': null,
      }, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to set PIN: ${e.toString()}');
    }
  }

  Future<bool> verifyPin(String enteredPin) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final docRef = _firestore.collection('users').doc(user.uid);
      
      return await _firestore.runTransaction<bool>((transaction) async {
        final docSnap = await transaction.get(docRef);
        if (!docSnap.exists) throw Exception('User data not found');
        
        final userData = docSnap.data()!;
        final attempts = (userData['pin_attempts'] ?? 0) as int;
        
        // Update attempt counter
        transaction.update(docRef, {
          'last_pin_attempt': FieldValue.serverTimestamp(),
          'pin_attempts': attempts + 1,
        });

        // Check if PIN matches
        if (userData['pin'] == enteredPin) {
          // Reset attempts on successful verification
          transaction.update(docRef, {'pin_attempts': 0});
          return true;
        }
        
        // Optional: Add security delay after multiple failed attempts
        if (attempts >= 3) {
          throw Exception('Too many failed attempts. Please try again later.');
        }
        
        return false;
      });
    } catch (e) {
      throw Exception('PIN verification failed: ${e.toString()}');
    }
  }

  Future<void> updatePin(String currentPin, String newPin) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Verify current PIN first
      final isValid = await verifyPin(currentPin);
      if (!isValid) throw Exception('Current PIN is incorrect');

      // Update to new PIN
      await _firestore.collection('users').doc(user.uid).update({
        'pin': newPin,
        'pin_updated_at': FieldValue.serverTimestamp(),
        'pin_attempts': 0,
      });
    } catch (e) {
      throw Exception('Failed to update PIN: ${e.toString()}');
    }
  }

  Future<bool> verifyPinForTransaction(String pin, double amount) async {
    try {
      final isValidPin = await verifyPin(pin);
      if (!isValidPin) throw Exception('Invalid PIN');

      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final docSnapshot = await _firestore.collection('users').doc(user.uid).get();
      final balance = (docSnapshot.data()?['balance'] ?? 0.0) as double;

      if (balance < amount) throw Exception('Insufficient balance');
      return true;
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<void> setUserPin(String pin) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');
      
      await _firestore.collection('users').doc(user.uid).update({
        'pin': pin,
      });
    } catch (e) {
      throw FirebaseException(
        plugin: 'firestore',
        message: 'Failed to set PIN: ${e.toString()}',
      );
    }
  }

  Future<Map<String, dynamic>> validatePinAndGetUserData(String pin) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final docSnapshot = await _firestore.collection('users').doc(user.uid).get();
      if (!docSnapshot.exists) throw Exception('User data not found');
      
      final userData = docSnapshot.data()!;
      final storedPin = userData['pin'] as String?;
      
      if (storedPin == null) throw Exception('PIN not set');
      if (storedPin != pin) throw Exception('Invalid PIN');
      
      return userData;
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<bool> validateTransactionPin(String pin, double amount) async {
    try {
      final userData = await validatePinAndGetUserData(pin);
      final balance = (userData['balance'] ?? 0.0) as double;
      
      if (balance < amount) throw Exception('Insufficient balance');
      return true;
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<void> processTransaction(double amount, String description) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      await _firestore.runTransaction((transaction) async {
        final userDoc = await transaction.get(_firestore.collection('users').doc(user.uid));
        final currentBalance = (userDoc.data()?['balance'] ?? 0.0) as double;
        final newBalance = currentBalance - amount;
        
        if (newBalance < 0) throw Exception('Insufficient balance');
        
        transaction.update(_firestore.collection('users').doc(user.uid), {
          'balance': newBalance,
        });

        // Record transaction history
        transaction.set(_firestore.collection('transactions').doc(), {
          'userId': user.uid,
          'amount': amount,
          'description': description,
          'timestamp': FieldValue.serverTimestamp(),
          'type': 'debit'
        });
      });
    } catch (e) {
      throw Exception('Transaction failed: ${e.toString()}');
    }
  }

  Future<void> setSecurityPin(String pin) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');
      
      await _firestore.collection('users').doc(user.uid).update({
        'security_pin': pin,
        'security_pin_created_at': FieldValue.serverTimestamp(),
        'pin_attempts': 0
      });
    } catch (e) {
      throw Exception('Failed to set security PIN: ${e.toString()}');
    }
  }

  Future<bool> validateSecurityPin(String pin) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final docRef = _firestore.collection('users').doc(user.uid);
      
      return await _firestore.runTransaction<bool>((transaction) async {
        final doc = await transaction.get(docRef);
        if (!doc.exists) throw Exception('User data not found');
        
        final userData = doc.data()!;
        final storedPin = userData['security_pin'];
        final attempts = (userData['pin_attempts'] ?? 0) as int;
        
        if (attempts >= 3) {
          throw Exception('Too many failed attempts. Please try again later.');
        }

        if (storedPin != pin) {
          transaction.update(docRef, {
            'pin_attempts': attempts + 1,
            'last_failed_attempt': FieldValue.serverTimestamp()
          });
          return false;
        }

        // Reset attempts on successful validation
        transaction.update(docRef, {'pin_attempts': 0});
        return true;
      });
    } catch (e) {
      throw Exception('PIN validation failed: ${e.toString()}');
    }
  }

  Future<void> processSecuredTransaction(String pin, double amount, String description) async {
    try {
      final isValid = await validateSecurityPin(pin);
      if (!isValid) throw Exception('Invalid security PIN');
      
      // Proceed with the transaction if PIN is valid
      await processTransaction(amount, description);
    } catch (e) {
      throw Exception('Secured transaction failed: ${e.toString()}');
    }
  }

  Future<void> processSecureTransaction(String pin, double amount, String description) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final userDoc = _firestore.collection('users').doc(user.uid);
      
      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(userDoc);
        if (!snapshot.exists) throw Exception('User document not found');

        // Verify PIN
        final userData = snapshot.data()!;
        final storedPin = userData['pin'];
        if (storedPin != pin) throw Exception('Invalid PIN');

        final currentBalance = (userData['balance'] ?? 0.0) as double;
        final newBalance = currentBalance + amount;

        transaction.update(userDoc, {'balance': newBalance});

        // Add transaction record
        final historyRef = userDoc.collection('transactions').doc();
        transaction.set(historyRef, {
          'amount': amount,
          'description': description,
          'timestamp': FieldValue.serverTimestamp(),
          'type': amount > 0 ? 'credit' : 'debit',
        });
      });
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // Error handling
  Exception _handleAuthError(dynamic e) {
    if (e is FirebaseAuthException) {
      return Exception(e.message ?? 'Authentication failed');
    }
    if (e is FirebaseException) {
      return Exception(e.message ?? 'Firebase operation failed');
    }
    return Exception(e.toString());
  }
}