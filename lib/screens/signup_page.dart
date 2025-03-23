import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'login_page.dart';

class SignUpPage extends StatefulWidget {
  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _auth = FirebaseAuth.instance;
  bool _agreeToTerms = false;
  final _formKey = GlobalKey<FormState>();

  String? _email;
  String? _password;
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_agreeToTerms) {
      setState(() => _errorMessage = "You must agree to the Terms & Privacy Policy.");
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _auth.createUserWithEmailAndPassword(email: _email!, password: _password!);
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LoginPage()));
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = e.message;
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 30),
                  Center(
                    child: Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(color: Colors.green[50], shape: BoxShape.circle),
                      child: Icon(Icons.recycling, size: 40, color: Colors.green[800]),
                    ),
                  ),
                  SizedBox(height: 30),
                  Center(
                    child: Text(
                      'Welcome to Upcycle',
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.green[900]),
                    ),
                  ),
                  SizedBox(height: 12),
                  Text('Create your account to start transforming waste into wonder', style: TextStyle(fontSize: 16, color: Colors.grey[700])),
                  SizedBox(height: 40),
                  
                  // Email field
                  _buildTextField(
                    icon: Icons.email_outlined,
                    label: 'Email Address',
                    onChanged: (value) => _email = value,
                    validator: (value) => value!.contains('@') ? null : 'Enter a valid email',
                  ),
                  SizedBox(height: 20),

                  // Password field
                  _buildTextField(
                    icon: Icons.lock_outline,
                    label: 'Password',
                    isPassword: true,
                    onChanged: (value) => _password = value,
                    validator: (value) => value!.length >= 6 ? null : 'Minimum 6 characters',
                  ),
                  SizedBox(height: 24),

                  // Terms checkbox
                  _buildTermsCheckbox(),
                  SizedBox(height: 20),

                  // Error message
                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.red, fontWeight: FontWeight.w500),
                      ),
                    ),

                  // Sign Up button
                  AnimatedContainer(
                    duration: Duration(milliseconds: 200),
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _signUp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[800],
                        disabledBackgroundColor: Colors.grey[300],
                        padding: EdgeInsets.symmetric(vertical: 18),
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                      child: _isLoading
                          ? CircularProgressIndicator(color: Colors.white)
                          : Text('Get Started', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
                    ),
                  ),
                  SizedBox(height: 25),

                  // Login link
                  Center(
                    child: GestureDetector(
                      onTap: () => Navigator.pushNamed(context, '/login'),
                      child: RichText(
                        text: TextSpan(
                          text: 'Already have an account? ',
                          style: TextStyle(color: Colors.grey[700], fontSize: 15),
                          children: [
                            TextSpan(
                              text: 'Log In',
                              style: TextStyle(color: Colors.green[800], fontWeight: FontWeight.w600, decoration: TextDecoration.underline),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required IconData icon,
    required String label,
    bool isPassword = false,
    required void Function(String) onChanged,
    required FormFieldValidator<String?> validator,
  }) {
    return TextFormField(
      obscureText: isPassword,
      onChanged: onChanged,
      validator: validator,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.grey[600]),
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey[600]),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.green[800]!, width: 1.5)),
        contentPadding: EdgeInsets.symmetric(vertical: 18, horizontal: 20),
        floatingLabelBehavior: FloatingLabelBehavior.never,
      ),
    );
  }

  Widget _buildTermsCheckbox() {
    return GestureDetector(
      onTap: () => setState(() => _agreeToTerms = !_agreeToTerms),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(
            value: _agreeToTerms,
            onChanged: (value) => setState(() => _agreeToTerms = value ?? false),
            activeColor: Colors.green[800],
            checkColor: Colors.white,
          ),
          SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                text: 'By creating an account, I agree to the ',
                style: TextStyle(color: Colors.grey[700], fontSize: 14),
                children: [
                  TextSpan(text: 'Terms of Service', style: TextStyle(color: Colors.green[800], fontWeight: FontWeight.w600, decoration: TextDecoration.underline)),
                  TextSpan(text: ' and '),
                  TextSpan(text: 'Privacy Policy', style: TextStyle(color: Colors.green[800], fontWeight: FontWeight.w600, decoration: TextDecoration.underline)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
