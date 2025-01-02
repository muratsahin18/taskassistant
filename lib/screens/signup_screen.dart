import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_2/screens/list_screen.dart';
import 'package:fluttertoast/fluttertoast.dart';

class SignupScreen extends StatefulWidget {
  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _passwordControllerConfirm =
      TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> _signIn() async {
    try {
      if (_passwordController.text == _passwordControllerConfirm.text) {
        UserCredential userCredential =
            await _auth.createUserWithEmailAndPassword(
                email: _emailController.text,
                password: _passwordController.text);
        print("Success ${userCredential.user?.email}");

        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (context) => SearchableListView()));
      } else {
        Fluttertoast.showToast(
          msg: "Passwords are not the same!",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.black54,
          textColor: Colors.white,
          fontSize: 16.0,
        );
      }
    } on FirebaseAuthException catch (e) {
      print("Login Error:${e.message}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Signup"),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 40, 20, 0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: "E-mail"),
            ),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: "Password"),
              obscureText: true,
            ),
            TextField(
              controller: _passwordControllerConfirm,
              decoration: InputDecoration(labelText: "Confirm Password"),
              obscureText: true,
            ),
            SizedBox(
              height: 20,
            ),
            ElevatedButton(
              onPressed: _signIn,
              child: Text("Signup"),
            )
          ],
        ),
      ),
    );
  }
}
