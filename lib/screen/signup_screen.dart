import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _birthDateController = TextEditingController(); // حقل تاريخ الميلاد
  DateTime? _selectedDate;

  final _formKey = GlobalKey<FormState>();

  void _createAccount() async {
    if (_formKey.currentState?.validate() ?? false) {
      try {
        // إنشاء الحساب باستخدام البريد الإلكتروني وكلمة المرور
        UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        // إضافة بيانات إضافية للمستخدم بعد إنشاء الحساب
        User? user = FirebaseAuth.instance.currentUser;
        user?.updateDisplayName(_nameController.text.trim());

        // إضافة قيمة "role" الافتراضية أثناء حفظ بيانات المستخدم
FirebaseFirestore.instance.collection('Users Collection').doc(userCredential.user!.uid).set({
  'email': _emailController.text.trim(),
  'username': _nameController.text.trim(),
  'phone': _phoneController.text.trim(),
  'birthDate': _selectedDate ?? FieldValue.serverTimestamp(),
  'createdAt': FieldValue.serverTimestamp(),
  'role': 'user', // تعيين دور افتراضي كـ "user"
});


        _showSuccessDialog();
      } on FirebaseAuthException catch (e) {
        _showErrorDialog(_getErrorMessage(e));
      }
    }
  }

  String _getErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'Password is too weak';
      case 'email-already-in-use':
        return 'Email is already in use';
      case 'invalid-email':
        return 'Invalid email format';
      default:
        return 'An unexpected error occurred';
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Account Created'),
        content: const Text('Your account has been successfully created!'),
        actions: [
          TextButton(
            child: const Text('Login'),
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            child: const Text('OK'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
        ],
      ),
    );
  }

  // تحديد تاريخ الميلاد من خلال DatePicker
  Future<void> _selectBirthDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _birthDateController.text = '${picked.toLocal()}'.split(' ')[0]; // تنسيق التاريخ
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Account'),
        centerTitle: true,
        backgroundColor: const Color(0xFF3B5998),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF3B5998), Color(0xFF5D9CEC)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Image.network(
                            'https://cdn-icons-png.flaticon.com/512/3503/3503508.png',
                            width: 120,
                            height: 120,
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'Create Your Account',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 30),

                          // حقل الاسم
                          TextFormField(
                            controller: _nameController,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.white,
                              hintText: 'Full Name',
                              prefixIcon: const Icon(Icons.person, color: Color(0xFF3B5998)),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your full name';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 15),

                          // حقل رقم الهاتف
                          TextFormField(
                            controller: _phoneController,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.white,
                              hintText: 'Phone Number',
                              prefixIcon: const Icon(Icons.phone, color: Color(0xFF3B5998)),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your phone number';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 15),

                          // حقل البريد الإلكتروني
                          TextFormField(
                            controller: _emailController,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.white,
                              hintText: 'Email Address',
                              prefixIcon: const Icon(Icons.email, color: Color(0xFF3B5998)),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your email address';
                              } else if (!RegExp(r"^[a-zA-Z0-9]+@[a-zA-Z0-9]+\.[a-zA-Z]+").hasMatch(value)) {
                                return 'Please enter a valid email';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 15),

                          // حقل كلمة المرور
                          TextFormField(
                            controller: _passwordController,
                            obscureText: true,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.white,
                              hintText: 'Password',
                              prefixIcon: const Icon(Icons.lock, color: Color(0xFF3B5998)),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your password';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 15),

                          // حقل تاريخ الميلاد
                          // حقل تاريخ الميلاد
TextFormField(
  controller: _birthDateController,
  decoration: InputDecoration(
    filled: true,
    fillColor: Colors.white,
    hintText: 'Date of Birth',
    prefixIcon: const Icon(Icons.calendar_today, color: Color(0xFF3B5998)),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(15),
      borderSide: BorderSide.none,
    ),
    contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
  ),
  readOnly: true,
  onTap: _selectBirthDate, // عند الضغط على الحقل سيتم اختيار التاريخ
  validator: (value) {
    if (value == null || value.isEmpty) {
      return 'Please select your birth date';
    }
    return null;
  },
),
                          const SizedBox(height: 30),

                          // زر التسجيل
                          ElevatedButton(
                            onPressed: _createAccount,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF3B5998),
                              padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 40),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            child: const Text(
                              'Sign Up',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
