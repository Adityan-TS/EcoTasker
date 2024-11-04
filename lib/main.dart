import 'dart:async';
import 'dart:convert'; // Needed for jsonDecode

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  // Ensure the WidgetsFlutterBinding is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await Supabase.initialize(
    url: 'https://ikkzntpwptxmfhjrjqjv.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imlra3pudHB3cHR4bWZoanJqcWp2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3MjkwNjE3NzIsImV4cCI6MjA0NDYzNzc3Mn0.2GOOUzdOSAYoCPv3qjeSQjWymX5bMoo-qoiwDz8g9lY',
  );


  // Create the Supabase client
  final supabaseClient = Supabase.instance.client;

  // Run the app
  runApp(EcoTasker(supabaseClient: supabaseClient));
}
class EcoTasker extends StatelessWidget {
  final SupabaseClient supabaseClient;

  const EcoTasker({super.key, required this.supabaseClient});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EcoTasker',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        textTheme: GoogleFonts.poppinsTextTheme(),
        scaffoldBackgroundColor: const Color(0xFF1A1A1A),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => FutureBuilder<Map<String, dynamic>?>( 
              future: _getUserDetails(), // Fetch user details
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(
                      body: Center(child: CircularProgressIndicator()));
                } else {
                  if (snapshot.hasData) {
                    final userDetails = snapshot.data;
                    if (userDetails != null) {
                      String accountType = userDetails['Type'] ?? 'Unknown';

                      switch (accountType) {
                        case 'Parent':
                          return ParentDashboard(
                            title: '',
                            parentEmail: userDetails['StudentEmail'] ?? 'default@example.com',
                          );
                        case 'Eco Explorer':
                          return const EcoExplorerScreen();
                        case 'Student':
                          return const MyHomePage(title: '');
                        default:
                          return IntroScreen(supabaseClient: supabaseClient);
                      }
                    }
                  }
                  return IntroScreen(supabaseClient: supabaseClient);
                }
              },
            ),
        '/home': (context) => const MyHomePage(title: ''),
      },
    );
  }

Future<void> _checkUserDetails(BuildContext context) async {
  final userDetails = await _getUserDetails();
  if (userDetails != null) {
    // Navigate to ParentDashboard after user login
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ParentDashboard(
          title: 'Parent Dashboard',
          parentEmail: userDetails['Email ID'], // Pass the parent email
        ),
      ),
    );
  }
}


  Future<Map<String, dynamic>?> _getUserDetails() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? email = prefs.getString('userEmail');

    if (email == null) {
      print('No email found in SharedPreferences.');
      return null; // No email found, not authenticated
    }

    final response = await supabaseClient
        .from('Users')
        .select('Type, StudentEmail')
        .eq('Email ID', email)
        .single();

    print('User details fetched: $response'); // Debug log
    return response as Map<String, dynamic>?; // Return user details
  }
}


class IntroScreen extends StatefulWidget {
  final SupabaseClient supabaseClient;

  const IntroScreen({super.key, required this.supabaseClient});

  @override
  _IntroScreenState createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  @override
  void initState() {
    super.initState();
    checkAuthAndNavigate(); // Check authentication status when screen initializes
  }

Future<void> checkAuthAndNavigate() async {
  final user = widget.supabaseClient.auth.currentUser;

  if (user != null && user.email != null) {
    final String userEmail = user.email!; // Force unwrap since we know it's non-null at this point

    // Fetch the user's role (parent or student) from the Users table
    final response = await widget.supabaseClient
        .from('Users')
        .select('Role')
        .eq('Email ID', userEmail)  // Ensure this matches your database column name
        .single();

    // Based on the role, navigate to the respective dashboard
    if (response['Role'] == 'Parent') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => ParentDashboard(title: '',parentEmail: userEmail,)),
      );
    } else if (response['Role'] == 'Student') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => MyHomePage(title: '')),
      );
    }
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Align(
        alignment: Alignment.centerLeft, // Align to the center left
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
              35.0, 100.0, 35.0, 0), // Adjust position with padding
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center, // Center vertically
            crossAxisAlignment:
                CrossAxisAlignment.start, // Align children to the start (left)
            children: [
              Text(
                "Let's Get",
                style: GoogleFonts.poppins(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
                // Use Poppins font and set color to white
              ),
              Text(
                'Started',
                style: GoogleFonts.poppins(
                  fontSize: 40,
                  fontWeight: FontWeight.bold, // Set fontWeight to bold
                  color:
                      Colors.white, // Use Poppins font and set color to white
                ),
              ),
              Text(
                'Our Future, Our Choice.',
                style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors
                        .white), // Use Poppins font and set color to white
              ),
              const SizedBox(height: 24),
              Container(
                width: double.infinity, // Full width button
                padding: const EdgeInsets.symmetric(
                    vertical: 7.5), // Smaller vertical padding
                margin: const EdgeInsets.only(bottom: 16.0), // Margin between buttons
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10.0), // Rounded corners
                  color: Colors.white, // Background color of the button
                ),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => LoginScreen(
                              supabaseClient: widget
                                  .supabaseClient)), // Navigate to LoginScreen
                    );
                  },
                  style: ButtonStyle(
                    minimumSize: WidgetStateProperty.all<Size>(
                        const Size(double.infinity, 0)), // Smaller height
                    backgroundColor: WidgetStateProperty.all<Color>(Colors
                        .transparent), // Transparent background for ElevatedButton
                    shadowColor: WidgetStateProperty.all<Color>(
                        Colors.transparent), // Transparent shadow
                    shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                      RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(10.0), // Rounded corners
                      ),
                    ),
                  ),
                  child: Container(
                    alignment: Alignment.center,
                    child: const Text(
                      'Login',
                      style: TextStyle(
                        color: Color(
                            0xFF1A1A1A), // Set button text color to #1a1a1a
                        fontSize: 16.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              Container(
                width: double.infinity, // Full width button
                padding: const EdgeInsets.symmetric(
                    vertical: 7.5), // Smaller vertical padding
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10.0), // Rounded corners
                  color: const Color(0xFF1A1A1A), // Dark background color
                  border: Border.all(
                      color: Colors.white, width: 2.0), // White border
                ),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => SignUpScreen(
                              supabaseClient: widget
                                  .supabaseClient)), // Navigate to SignUpScreen
                    );
                  },
                  style: ButtonStyle(
                    minimumSize: WidgetStateProperty.all<Size>(
                        const Size(double.infinity, 0)), // Smaller height
                    backgroundColor: WidgetStateProperty.all<Color>(Colors
                        .transparent), // Transparent background for ElevatedButton
                    shadowColor: WidgetStateProperty.all<Color>(
                        Colors.transparent), // Transparent shadow
                    shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                      RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(10.0), // Rounded corners
                      ),
                    ),
                  ),
                  child: Container(
                    alignment: Alignment.center,
                    child: const Text(
                      'Sign Up',
                      style: TextStyle(
                        color: Colors.white, // White text color
                        fontSize: 16.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


class SignUpScreen extends StatefulWidget {
  final SupabaseClient supabaseClient;

  const SignUpScreen({super.key, required this.supabaseClient});

  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _studentEmailController = TextEditingController();

  String selectedRole = 'Student';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _studentEmailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          '',
          style: GoogleFonts.poppins(),
        ),
        backgroundColor: Colors.white,
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0).add(const EdgeInsets.only(top: 25.0)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sign Up',
              style: GoogleFonts.poppins(
                fontSize: 25,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Please enter an email address and password to create your account.',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 20),
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: 'Email Address',
                      hintStyle: const TextStyle(color: Colors.grey),
                      fillColor: const Color(0xFFf1f5f9),
                      filled: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 12.0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    style: GoogleFonts.poppins(),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email address';
                      }
                      if (!RegExp(r'^[^@]+@[^@]+\.[a-zA-Z]{2,}$').hasMatch(value)) {
                        return 'Please enter a valid email address';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      hintStyle: const TextStyle(color: Colors.grey),
                      fillColor: const Color(0xFFf1f5f9),
                      filled: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 12.0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    style: GoogleFonts.poppins(),
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters long';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  if (selectedRole == 'Parent')
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextFormField(
                          controller: _studentEmailController,
                          decoration: InputDecoration(
                            labelText: "Student's Email",
                            hintStyle: const TextStyle(color: Colors.grey),
                            fillColor: const Color(0xFFf1f5f9),
                            filled: true,
                            contentPadding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 12.0),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10.0),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          style: GoogleFonts.poppins(),
                          validator: (value) {
                            if (selectedRole == 'Parent' && (value == null || value.isEmpty)) {
                              return 'Please enter the student\'s email address';
                            }
                            if (selectedRole == 'Parent' && !RegExp(r'^[^@]+@[^@]+\.[a-zA-Z]{2,}$').hasMatch(value!)) {
                              return 'Please enter a valid student email address';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedRole = 'Student';
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: selectedRole == 'Student' ? Colors.black : Colors.grey.shade200,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(10),
                                bottomLeft: Radius.circular(10),
                              ),
                            ),
                            child: Text(
                              'Student',
                              style: GoogleFonts.poppins(
                                color: selectedRole == 'Student' ? Colors.white : Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedRole = 'Parent';
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: selectedRole == 'Parent' ? Colors.black : Colors.grey.shade200,
                            ),
                            child: Text(
                              'Parent',
                              style: GoogleFonts.poppins(
                                color: selectedRole == 'Parent' ? Colors.white : Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedRole = 'Eco Explorer';
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: selectedRole == 'Eco Explorer' ? Colors.black : Colors.grey.shade200,
                              borderRadius: const BorderRadius.only(
                                topRight: Radius.circular(10),
                                bottomRight: Radius.circular(10),
                              ),
                            ),
                            child: Text(
                              'Eco Explorer',
                              style: GoogleFonts.poppins(
                                color: selectedRole == 'Eco Explorer' ? Colors.white : Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        final email = _emailController.text.trim();
                        final password = _passwordController.text.trim();
                        final studentEmail = _studentEmailController.text.trim();

                        try {
                          final response = await widget.supabaseClient.auth
                              .signUp(email: email, password: password);

                          if (response.user != null) {
                            final role = selectedRole;
                            await widget.supabaseClient.from('Users').insert({
                              'Email ID': email,
                              'Type': role,
                              'StudentEmail': role == 'Parent' ? studentEmail : null,
                            });

                            if (role == 'Student') {
                              await widget.supabaseClient.from('Scores').insert({
                                'Email ID': email,
                                'Score': 0,
                              });
                            }

                            Navigator.pop(context);
                          }
                        } catch (e) {
                          _showErrorDialog('An error occurred: $e');
                        }
                      }
                    },
                    style: ButtonStyle(
                      minimumSize: MaterialStateProperty.all<Size>(
                          const Size(double.infinity, 50)),
                      backgroundColor: MaterialStateProperty.all<Color>(
                          const Color(0xFF1A1A1A)),
                      shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                      ),
                    ),
                    child: Container(
                      alignment: Alignment.center,
                      height: 55,
                      child: const Text(
                        'Sign Up',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Error'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}

class LoginScreen extends StatefulWidget {
  final SupabaseClient supabaseClient;

  const LoginScreen({super.key, required this.supabaseClient});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _loginError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void storeUserEmailLocally(String email) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('userEmail', email);
  }

  // Fetch user type and student email from the database using email ID
  Future<Map<String, dynamic>?> fetchUserDetails(String email) async {
    final response = await widget.supabaseClient
        .from('Users')
        .select('Type, StudentEmail')
        .eq('Email ID', email)
        .single();

    return response; // Return the details as a map or null if not found
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          '',
          style: GoogleFonts.poppins(),
        ),
        backgroundColor: Colors.white,
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0).add(
          const EdgeInsets.only(top: 60.0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Login',
              style: GoogleFonts.poppins(
                fontSize: 30,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              'Please enter an email address and password to log in to your account.',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 15),
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: 'Email Address',
                      hintStyle: const TextStyle(color: Colors.grey),
                      fillColor: const Color(0xFFf1f5f9),
                      filled: true,
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 16.0, horizontal: 12.0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    style: GoogleFonts.poppins(),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email address';
                      }
                      if (!RegExp(r'^[^@]+@[^@]+\.[a-zA-Z]{2,}$')
                          .hasMatch(value)) {
                        return 'Please enter a valid email address';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      hintStyle: const TextStyle(color: Colors.grey),
                      fillColor: const Color(0xFFf1f5f9),
                      filled: true,
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 16.0, horizontal: 12.0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    style: GoogleFonts.poppins(),
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  if (_loginError != null)
                    Text(
                      _loginError!,
                      style: TextStyle(color: Colors.red),
                    ),
                  const SizedBox(height: 16),
                  ElevatedButton(
  onPressed: () async {
    if (_formKey.currentState!.validate()) {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      try {
        // Perform login
        final response = await widget.supabaseClient.auth.signInWithPassword(
          email: email,
          password: password,
        );

        if (response.user != null) {
          storeUserEmailLocally(email); // Store email locally

          // Fetch user type and student email using the entered email
          Map<String, dynamic>? userDetails = await fetchUserDetails(email);
          if (userDetails != null) {
            String userType = userDetails['Type'];
            String? studentEmail = userDetails['StudentEmail'];

            if (userType == 'Parent') {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => ParentDashboard(title: '', parentEmail: email),
                ),
              );
            } else if (userType == 'Eco Explorer') {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => EcoExplorerScreen(),
                ),
              );
            } else {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => MyHomePage(title: ''),
                ),
              );
            }
          } else {
            setState(() {
              _loginError = 'User details not found. Please try again.';
            });
          }
        } else {
          setState(() {
            _loginError = 'Email and password don\'t match. Please try again.';
          });
        }
      } on AuthApiException catch (e) {
        setState(() {
          _loginError = e.message; // Display specific auth error message
        });
      }
    }
  },
                    style: ButtonStyle(
                      minimumSize: MaterialStateProperty.all<Size>(const Size(double.infinity, 50)),
                      backgroundColor: MaterialStateProperty.all<Color>(const Color(0xFF1A1A1A)),
                      shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                      ),
                    ),
                    child: Container(
                      alignment: Alignment.center,
                      height: 55,
                      child: const Text(
                        'Login',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SignUpScreen(supabaseClient: widget.supabaseClient),
                  ),
                );
              },
              child: RichText(
                text: TextSpan(
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    color: Colors.black,
                  ),
                  children: const [
                    TextSpan(
                      text: "Don't have an account? ",
                    ),
                    TextSpan(
                      text: 'Sign Up',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class MyHomePage extends StatefulWidget {
  final String title;

  const MyHomePage({Key? key, required this.title}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String userEmail = '';
  String userEmailPrefix = '';
  int userScore = 0;
  double _rotation = 0;
  List<Map<String, dynamic>> events = [];
  List<Map<String, dynamic>> requestedTasks = [];
  DateTime? lastFetchDate;

  @override
  void initState() {
    super.initState();
    _loadUserEmail();
  }

  Future<void> _loadUserEmail() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? email = prefs.getString('userEmail');
    setState(() {
      userEmail = email ?? '';
      userEmailPrefix = email != null ? email.split('@').first : '';
    });
    await _fetchUserScore(userEmail);
    await _checkForTaskRefresh();
    await _fetchRequestedTasks();
  }

  Future<void> _fetchUserScore(String? email) async {
    if (email != null && email.isNotEmpty) {
      final response = await Supabase.instance.client
          .from('Scores')
          .select('Score')
          .eq('Email ID', email)
          .single();

      if (response != null && response['Score'] != null) {
        setState(() {
          userScore = response['Score'];
        });
      } else {
        setState(() {
          userScore = 0;
        });
      }
    }
  }

  Future<void> _fetchRequestedTasks() async {
    if (userEmail.isNotEmpty) {
      try {
        final response = await Supabase.instance.client
            .from('Requests')
            .select('Task, Status')
            .eq('StudentEmail', userEmail);

        if (response != null && response is List) {
          setState(() {
            requestedTasks = List<Map<String, dynamic>>.from(response.map((task) {
              return {
                'task': task['Task'] ?? 'Unknown Task',
                'status': task['Status'] ?? 'Unknown Status',
              };
            }));
          });
        }
      } catch (error) {
        print("Supabase fetch error: $error");
      }
    }
  }

  Future<void> _checkForTaskRefresh() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? storedTasks = prefs.getString('tasks');
    String? storedDate = prefs.getString('lastFetchDate');

    if (storedTasks == null || (storedDate != null && DateFormat('yyyy-MM-dd').format(DateTime.now()) != storedDate)) {
      await _fetchTasksFromOpenRouter();
    } else {
      setState(() {
        events = List<Map<String, dynamic>>.from(jsonDecode(storedTasks));
      });
    }
  }

  Future<void> _fetchTasksFromOpenRouter() async {
    const apiUrl = 'https://openrouter.ai/api/v1/chat/completions';
    const apiKey = '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';

    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': 'liquid/lfm-40b:free',
        'messages': [
          {
            'role': 'A Task Generator That Generates Exactly 5 Tasks in A List that is numbered without any extra spaces or **EXTRA LINES IN BETWEEN THE TASKS**, The Tasks Must Be UAE Appropriate',
            'content': 'Generate EXACTLY 5 tasks which encourage 5-10 year olds to do something eco-friendly in a list preferably supporting SDG 13.',
          },
        ],
      }),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      String taskString = data['choices'][0]['message']['content'];

      List<String> taskList = taskString.split('\n').map((task) => task.trim()).toList();

      setState(() {
        events = List.generate(taskList.length, (index) {
          return {
            'title': taskList[index],
            'status': 'Not Done',
          };
        });
      });

      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('tasks', jsonEncode(events));
      await prefs.setString('lastFetchDate', DateFormat('yyyy-MM-dd').format(DateTime.now()));
    }
  }

  Future<void> _saveTaskToRequests(String email, String task) async {
    await Supabase.instance.client
        .from('Requests')
        .insert({'StudentEmail': email, 'Task': task, 'Status': 'Requested'});
  }

  void _refreshData() {
    setState(() {
      _rotation += 45;
    });

    _fetchTasksFromOpenRouter();

    Future.delayed(const Duration(milliseconds: 300), () {
      setState(() {
        _rotation = 0;
      });
    });
  }

  void _toggleEventStatus(int index) {
    setState(() {
      if (events[index]['status'] == 'Not Done') {
        _sendRequest(events[index]['title'], userEmail);
        events[index]['status'] = 'Requested';
        _saveRequestedTasks(events[index]['title']);
      }
    });
  }

  Future<void> _sendRequest(String task, String studentEmail) async {
    await Supabase.instance.client
        .from('Requests')
        .insert({
          'StudentEmail': studentEmail,
          'Task': task,
          'Status': 'Requested',
        });
  }

  Future<void> _saveRequestedTasks(String task) async {
    requestedTasks.add({
      'task': task,
      'status': 'Requested',
    });
    await _fetchRequestedTasks();
  }

  void _removeTask(String task) {
    setState(() {
      events.removeWhere((event) => event['title'] == task);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.white,
        width: double.infinity,
        height: double.infinity,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Hi, $userEmailPrefix',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                _buildScoreBox(),
              ],
            ),
            const SizedBox(height: 0),
            Expanded(
              child: ListView.builder(
                itemCount: events.length,
                itemBuilder: (context, index) {
                  return _buildEventCard(index);
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Stack(
        children: [
          Positioned(
            bottom: 16,
            left: 25,
            child: FloatingActionButton(
              onPressed: _openHistoryBottomSheet,
              backgroundColor: const Color(0xFF1A1A1A),
              child: const Icon(Icons.history, color: Colors.white),
            ),
          ),
          Positioned(
            bottom: 16,
            right: 16,
            child: FloatingActionButton(
              onPressed: _refreshData,
              backgroundColor: const Color(0xFF1A1A1A),
              child: AnimatedRotation(
                turns: _rotation / 360,
                duration: const Duration(milliseconds: 300),
                child: const Icon(Icons.refresh, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventCard(int index) {
  return Card(
    margin: const EdgeInsets.symmetric(vertical: 8.0),
    color: const Color(0xFF1A1A1A),
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  events[index]['title'] ?? 'No Title',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  events[index]['status'] ?? 'Unknown',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
          Column( // Stack icons vertically
            children: [
              IconButton(
                icon: const Icon(Icons.check, color: Colors.white),
                onPressed: () {
                  _toggleEventStatus(index);
                },
              ),
              IconButton(
                icon: const Icon(Icons.chat, color: Colors.white),
                onPressed: () {
                  _openChatSheet(context, events[index]['title'] ?? 'No Title');
                },
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

void _openChatSheet(BuildContext context, String task) {
  List<String> chatMessages = [];
  TextEditingController chatInputController = TextEditingController();

  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true, // Enable scrolling when keyboard opens
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom, // Space for keyboard
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)), // Rounded corners
              child: Container(
                padding: const EdgeInsets.all(16),
                // Set height to a fraction of the screen height but allow it to expand when the keyboard is visible
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.6, // Maximum height
                ),
                color: Colors.white,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Chat about "$task"',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),
                    // Adjust the height of the ListView to take remaining space
                    Expanded(
                      child: ListView.builder(
                        itemCount: chatMessages.length,
                        itemBuilder: (context, index) {
                          bool isUserMessage = chatMessages[index].startsWith('You:');
                          return ListTile(
                            title: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (isUserMessage)
                                  Icon(Icons.person, color: Colors.blue, size: 24)
                                else
                                  Icon(Icons.smart_toy, color: Colors.green, size: 24),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    chatMessages[index].substring(4), // Removes "You:" or "AI:"
                                    textAlign: TextAlign.left,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20), // Default spacing
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: chatInputController,
                            decoration: const InputDecoration(
                              hintText: 'Type your message...',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.send),
                          onPressed: () async {
                            String userInput = chatInputController.text;
                            if (userInput.isNotEmpty) {
                              setState(() {
                                chatMessages.add('You: $userInput');
                              });

                              String response = await _getChatResponse(userInput, task); // Pass task here
                              setState(() {
                                chatMessages.add('AI: $response');
                              });

                              chatInputController.clear();
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}

// Modify _getChatResponse to accept task as a parameter
Future<String> _getChatResponse(String query, String task) async {
  const apiUrl = 'https://openrouter.ai/api/v1/chat/completions';
  const apiKey = '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'; // Replace with actual API key

  final response = await http.post(
    Uri.parse(apiUrl),
    headers: {
      'Authorization': 'Bearer $apiKey',
      'Content-Type': 'application/json',
    },
    body: jsonEncode({
      'model': 'liquid/lfm-40b:free',
      'messages': [
        {
          'role': 'system',
          'content': 'You are a helpful assistant providing insights and suggestions to teenagers about the task : $task.'
        },
        {
          'role': 'user',
          'content': query,
        },
      ],
    }),
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    return data['choices'][0]['message']['content'];
  } else {
    return 'Error fetching response. Please try again later.';
  }
}

  Widget _buildScoreBox() {
  return GestureDetector(
    onTap: () {
      // Navigate to the Leaderboard screen
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => LeaderboardScreen()),
      );
    },
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(20.0),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.star,
            color: Colors.white,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            '$userScore',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    ),
  );
}

void _navigateToLeaderboard() {
  Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => LeaderboardScreen()), // Replace LeaderboardScreen with your actual leaderboard screen widget
  );
}

  void _openHistoryBottomSheet() {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(20),
      ),
    ),
    builder: (context) {
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.9, // Takes up 80% of the screen height
        minChildSize: 0.6,
        maxChildSize: 1.0,
        builder: (context, scrollController) {
          return ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(20),
            ),
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Center(
                    child: Text(
                      'History',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController, // Attach controller here
                      itemCount: requestedTasks.length,
                      itemBuilder: (context, index) {
                        return Card(
                          color: const Color(0xFF1A1A1A),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          margin: const EdgeInsets.symmetric(vertical: 8.0),
                          child: ListTile(
                            title: Text(
                              requestedTasks[index]['task'] ?? '',
                              style: const TextStyle(color: Colors.white),
                            ),
                            subtitle: Text(
                              requestedTasks[index]['status'] ?? '',
                              style: const TextStyle(color: Colors.white70),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}
}

class LeaderboardScreen extends StatelessWidget {
  Future<List<Map<String, dynamic>>> _fetchLeaderboardData() async {
    final response = await Supabase.instance.client
        .from('Scores')
        .select('"Email ID", Score') // Enclose "Email ID" in quotes if it has spaces
        .order('Score', ascending: false)
        .limit(10);

    List<Map<String, dynamic>> leaderboardData = [];

    if (response.isNotEmpty) {
      for (var row in response) {
        leaderboardData.add({
          'email': row['Email ID'],
          'points': row['Score'],
        });
      }
    }

    return leaderboardData;
  }

  String _getEmailPrefix(String email) {
    // Split the email at "@" and return the first part
    return email.split('@').first;
  }

  Icon _getCupIcon(int index) {
    // Return different cup icons based on the player's rank
    switch (index) {
      case 0:
        return Icon(Icons.emoji_events, color: Colors.yellow); // Gold cup
      case 1:
        return Icon(Icons.emoji_events, color: Colors.grey); // Silver cup
      case 2:
        return Icon(Icons.emoji_events, color: Colors.brown); // Bronze cup
      default:
        return Icon(Icons.circle, color: Colors.transparent); // Transparent icon for ranks below 3
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Leaderboard',
          style: GoogleFonts.poppins(
            fontSize: 24,
          ),
        ),
        backgroundColor: Colors.grey[100],
        leading: BackButton(), // Adds back arrow
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 0), // Adds a 0px gap at the top
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _fetchLeaderboardData(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                    final leaderboardData = snapshot.data!;
                    return ListView.builder(
                      itemCount: leaderboardData.length,
                      itemBuilder: (context, index) {
                        final player = leaderboardData[index];
                        return Container(
                          margin: EdgeInsets.symmetric(vertical: 8),
                          padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[300]!),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  _getCupIcon(index), // Show the cup icon based on rank
                                  SizedBox(width: 12),
                                  Text(
                                    '${_getEmailPrefix(player['email'])}', // Display email prefix
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                player['points'].toString(),
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  }
                  return Center(child: Text('No leaderboard data available.'));
                },
              ),
            ),
          ],
        ),
      ),
      backgroundColor: Colors.grey[100],
    );
  }
}
// Define the ParentDashboard class (ALFIE YOU DO YOU)
class ParentDashboard extends StatefulWidget {
  final String title;
  final String parentEmail;

  const ParentDashboard({Key? key, required this.title, required this.parentEmail}) : super(key: key);

  @override
  _ParentDashboardState createState() => _ParentDashboardState();
}

class _ParentDashboardState extends State<ParentDashboard> {
  String childEmail = '';
  String childEmailPrefix = '';
  int childScore = 0;
  double _rotation = 0;
  List<Map<String, dynamic>> taskRequests = [];
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _fetchParentEmail(); // Initiate fetch using _fetchParentEmail
  }

  Future<void> _fetchParentEmail() async {
    String? parentEmail = widget.parentEmail.isNotEmpty
        ? widget.parentEmail
        : (await SharedPreferences.getInstance()).getString('userEmail');

    if (parentEmail != null && parentEmail.isNotEmpty) {
      print("Parent email used for fetching child details: $parentEmail");
      await _fetchChildEmail(parentEmail);
    } else {
      print('No valid parent email found.');
    }
  }

Future<void> _fetchChildEmail(String parentEmail) async {
  if (parentEmail.isNotEmpty) {
    try {
      // Fetch the account type and student email (if parent)
      final response = await Supabase.instance.client
          .from('Users')
          .select('Type, StudentEmail')
          .eq('Email ID', parentEmail)
          .maybeSingle();

      print('Fetched Account Type for parentEmail: $response');

      if (response != null) {
        // If account type is Student, set childEmail to parentEmail directly
        if (response['Type'] == 'Student') {
          setState(() {
            childEmail = parentEmail;
            childEmailPrefix = childEmail.split('@').first;
            print('Set childEmail directly to: $childEmail');
          });
          await _fetchChildScore(childEmail);
          await _fetchTaskRequests();
          
        // If account type is Parent, fetch and set the StudentEmail as childEmail
        } else if (response['Type'] == 'Parent' && response['StudentEmail'] != null) {
          setState(() {
            childEmail = response['StudentEmail'];
            childEmailPrefix = childEmail.split('@').first;
            print('Set childEmail from StudentEmail: $childEmail');
          });
          await _fetchChildScore(childEmail);
          await _fetchTaskRequests();
          
        } else {
          print('No associated StudentEmail found for the parent account.');
        }
      } else {
        print('No user found for the provided email.');
      }

    } catch (error) {
      print('Error fetching account type: $error');
    }
  } else {
    print('Invalid parent email.');
  }
}


  Future<void> _fetchChildScore(String? email) async {
    if (email != null && email.isNotEmpty) {
      try {
        final response = await Supabase.instance.client
            .from('Scores')
            .select('Score')
            .eq('Email ID', email)
            .single();

        if (response != null && response['Score'] != null) {
          setState(() {
            childScore = response['Score'];
          });
        } else {
          print('No score found for the provided child email.');
        }
      } catch (error) {
        print('Error fetching child score: $error');
      }
    } else {
      print('Invalid child email.');
    }
  }

  Future<void> _fetchTaskRequests() async {
    if (childEmail.isNotEmpty) {
      try {
        final response = await Supabase.instance.client
            .from('Requests')
            .select()
            .eq('StudentEmail', childEmail)
            .eq('Status', 'Requested');

        if (response != null) {
          setState(() {
            taskRequests = List<Map<String, dynamic>>.from(response);
          });
        }
      } catch (error) {
        print('Error fetching task requests: $error');
      }
    }
  }

  void _refreshData() {
    setState(() {
      _rotation += 45;
    });

    _fetchTaskRequests();

    Future.delayed(const Duration(milliseconds: 300), () {
      setState(() {
        _rotation = 0;
      });
    });
  }

  void _approveTask(int index) async {
    final taskId = taskRequests[index]['id'];
    await _updateTaskStatus(taskId, 'Approved');
    await _incrementChildScore();

    setState(() {
      taskRequests.removeAt(index);
    });
  }

  Future<void> _updateTaskStatus(int taskId, String status) async {
    try {
      await Supabase.instance.client
          .from('Requests')
          .update({'Status': status})
          .eq('id', taskId);
    } catch (error) {
      print('Error updating task status: $error');
    }
  }

  Future<void> _incrementChildScore() async {
    setState(() {
      childScore += 10;
    });

    try {
      await Supabase.instance.client
          .from('Scores')
          .update({'Score': childScore})
          .eq('Email ID', childEmail);
    } catch (error) {
      print('Error updating child score: $error');
    }
  }

  void _rejectTask(int index) async {
    final taskId = taskRequests[index]['id'];
    await _updateTaskStatus(taskId, 'Rejected');

    setState(() {
      taskRequests.removeAt(index);
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    if (index == 1) {
      Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EcoExplorerScreen(showNavBar: true), // Pass showNavBar as true
      ),
    );
  }
}

  Widget _buildScoreBox() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(20.0),
      ),
      child: Row(
        children: [
          const Icon(Icons.star, color: Colors.white),
          const SizedBox(width: 8),
          Text(
            '$childScore',
            style: const TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskRequestCard(int index) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      color: const Color(0xFF1A1A1A),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    taskRequests[index]['Task'],
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    taskRequests[index]['Status'],
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.check_box, color: Colors.white),
                  onPressed: taskRequests[index]['Status'] == 'Requested'
                      ? () => _approveTask(index)
                      : null,
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => _rejectTask(index),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.white,
        width: double.infinity,
        height: double.infinity,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Hi, $childEmailPrefix's Parent",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                _buildScoreBox(),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: taskRequests.length,
                itemBuilder: (context, index) {
                  return _buildTaskRequestCard(index);
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _refreshData,
        backgroundColor: const Color(0xFF1A1A1A),
        child: AnimatedRotation(
          turns: _rotation / 360,
          duration: const Duration(milliseconds: 300),
          child: const Icon(
            Icons.refresh,
            color: Colors.white,
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.explore),
            label: 'Eco Explorer',
          ),
        ],
      ),
    );
  }
}
class EcoExplorerScreen extends StatefulWidget {
  final bool showNavBar;

  const EcoExplorerScreen({Key? key, this.showNavBar = false}) : super(key: key);

  @override
  _EcoExplorerScreenState createState() => _EcoExplorerScreenState();
}

class _EcoExplorerScreenState extends State<EcoExplorerScreen> {
  double age = 1;
  double weight = 1;
  double height = 50;
  double commuteDistance = 0.0;
  double electricityConsumption = 0.0;
  double wasteGenerated = 0.0;
  double mealsPerDay = 0.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E7D6A),
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: const Text(
            'Hi, EcoExplorer',
            style: TextStyle(
              fontSize: 20,
              color: Colors.white,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: const Text(
                  'Eco Achievers',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              GridView.count(
                shrinkWrap: true,
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 0.8,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildCard(
                    context,
                    title: 'BMI Calculator',
                    imagePath: 'assets/images/BMI.png',
                    bgColor: const Color(0xFF5BC0EB),
                    onTap: () => _showBMICalculator(context),
                  ),
                  _buildCard(
                    context,
                    title: 'Carbon Footprint Tracker',
                    imagePath: 'assets/images/Carbon.png',
                    bgColor: const Color(0xFFB7E036),
                    onTap: () => _showCarbonFootprintTracker(context),
                  ),
                  _buildCard(
                    context,
                    title: 'Food Guide',
                    imagePath: 'assets/images/Food.png',
                    bgColor: const Color(0xFFB5651D),
                    onTap: () => _showFoodGuide(context),
                  ),
                  _buildCard(
                    context,
                    title: 'Business Directory',
                    imagePath: 'assets/images/Business.png',
                    bgColor: const Color(0xFF5BC0EB),
                    onTap: () => _showBusinessDirectory(context),
                  ),
                  _buildCard(
                    context,
                    title: 'Waste Guide',
                    imagePath: 'assets/images/Waste.png',
                    bgColor: const Color(0xFF70C1B3),
                    onTap: () => _showWasteGuide(context),
                  ),
                  _buildCard(
                    context,
                    title: 'Sustainable Bot',
                    imagePath: 'assets/images/Sustainable.png',
                    bgColor: const Color(0xFF70C1B3),
                    onTap: () => _showSustainableBot(context),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: widget.showNavBar // Display bottom nav bar only if showNavBar is true
          ? BottomNavigationBar(
              items: const <BottomNavigationBarItem>[
                BottomNavigationBarItem(
                  icon: Icon(Icons.home),
                  label: 'Home',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.explore),
                  label: 'Eco Explorer',
                ),
              ],
              selectedItemColor: Colors.grey,
              onTap: (index) {
                if (index == 0) {
                  Navigator.pop(context); // Navigate back to the Parent Dashboard
                }
                // Add additional actions if needed for the Eco Explorer tab
              },
            )
          : null, // No bottom nav bar if showNavBar is false
    );
  }

  Widget _buildCard(BuildContext context,
      {required String title, required String imagePath, required Color bgColor, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              spreadRadius: 2,
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Container(
                  height: 100,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                    child: Image.asset(
                      imagePath,
                      height: 100,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.favorite_border,
                      color: Colors.grey,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


void _showBMICalculator(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return ClipRRect(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)), // Rounded top corners
            child: Container(
              padding: EdgeInsets.all(16),
              color: Colors.white,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'BMI Calculator',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 20),
                  Text('Age: ${age.toInt()} years'),
                  Slider(
                    value: age,
                    min: 1,
                    max: 100,
                    divisions: 99,
                    label: age.toInt().toString(),
                    activeColor: Color(0xFF227C70),
                    onChanged: (value) {
                      setState(() {
                        age = value;
                      });
                    },
                  ),
                  Text('Weight: ${weight.toInt()} kg'),
                  Slider(
                    value: weight,
                    min: 1,
                    max: 200,
                    divisions: 199,
                    label: weight.toInt().toString(),
                    activeColor: Color(0xFF227C70),
                    onChanged: (value) {
                      setState(() {
                        weight = value;
                      });
                    },
                  ),
                  Text('Height: ${height.toInt()} cm'),
                  Slider(
                    value: height,
                    min: 50,
                    max: 250,
                    divisions: 200,
                    label: height.toInt().toString(),
                    activeColor: Color(0xFF227C70),
                    onChanged: (value) {
                      setState(() {
                        height = value;
                      });
                    },
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF227C70),
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      double bmi = weight / ((height / 100) * (height / 100));
                      String category;

                      if (bmi < 18.5) {
                        category = 'Underweight';
                      } else if (bmi < 24.9) {
                        category = 'Normal weight';
                      } else if (bmi < 29.9) {
                        category = 'Overweight';
                      } else if (bmi < 39.9) {
                        category = 'Obese';
                      } else {
                        category = 'Extremely Obese';
                      }

                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: Text('Your BMI'),
                            content: Text('Your BMI is ${bmi.toStringAsFixed(2)}\nCategory: $category'),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                child: Text('OK'),
                              ),
                            ],
                          );
                        },
                      );
                    },
                    child: Text('Calculate'),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}


  void _showCarbonFootprintTracker(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true, // Enables full-screen height if needed
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return ClipRRect(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)), // Rounded top corners
            child: Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              height: MediaQuery.of(context).size.height * 0.8, // Increased height
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Carbon Footprint Tracker',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),

                  // Daily Commute Distance Input
                  Text('Daily Commute Distance (in km): ${commuteDistance.toStringAsFixed(2)}'),
                  Slider(
                    value: commuteDistance,
                    min: 0,
                    max: 100,
                    divisions: 100,
                    label: commuteDistance.toStringAsFixed(2),
                    activeColor: const Color(0xFF227C70),
                    onChanged: (value) {
                      setState(() {
                        commuteDistance = value;
                      });
                    },
                  ),

                  // Weekly Waste Generated Input
                  Text('Waste Generated per Week (in kg): ${wasteGenerated.toStringAsFixed(2)}'),
                  Slider(
                    value: wasteGenerated,
                    min: 0,
                    max: 50,
                    divisions: 100,
                    label: wasteGenerated.toStringAsFixed(2),
                    activeColor: const Color(0xFF227C70),
                    onChanged: (value) {
                      setState(() {
                        wasteGenerated = value;
                      });
                    },
                  ),

                  // Monthly Electricity Consumption Input
                  Text('Monthly Electricity Consumption (in kWh): ${electricityConsumption.toStringAsFixed(2)}'),
                  Slider(
                    value: electricityConsumption,
                    min: 0,
                    max: 1000,
                    divisions: 100,
                    label: electricityConsumption.toStringAsFixed(2),
                    activeColor: const Color(0xFF227C70),
                    onChanged: (value) {
                      setState(() {
                        electricityConsumption = value;
                      });
                    },
                  ),

                  // Meals Consumed per Day Input
                  Text('Meals Consumed per Day: ${mealsPerDay.toStringAsFixed(2)}'),
                  Slider(
                    value: mealsPerDay,
                    min: 0,
                    max: 10,
                    divisions: 10,
                    label: mealsPerDay.toStringAsFixed(2),
                    activeColor: const Color(0xFF227C70),
                    onChanged: (value) {
                      setState(() {
                        mealsPerDay = value;
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF227C70),
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      // Carbon footprint calculations
                      double commuteFootprint = commuteDistance * 365 * 0.404;
                      double wasteFootprint = wasteGenerated * 52 * 1.0;
                      double electricityFootprint = electricityConsumption * 12 * 0.5;
                      double mealsFootprint = mealsPerDay * 365 * 0.75;

                      // Convert to tonnes
                      double totalFootprint = (commuteFootprint + wasteFootprint + electricityFootprint + mealsFootprint) / 1000;

                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text('Your Annual Carbon Footprint Breakdown'),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Commute: ${(commuteFootprint / 1000).toStringAsFixed(2)} tonnes CO2/year'),
                                Text('Waste: ${(wasteFootprint / 1000).toStringAsFixed(2)} tonnes CO2/year'),
                                Text('Electricity: ${(electricityFootprint / 1000).toStringAsFixed(2)} tonnes CO2/year'),
                                Text('Meals: ${(mealsFootprint / 1000).toStringAsFixed(2)} tonnes CO2/year'),
                                const SizedBox(height: 10),
                                Text('Total: ${totalFootprint.toStringAsFixed(2)} tonnes CO2/year'),
                              ],
                            ),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                child: const Text('OK'),
                              ),
                            ],
                          );
                        },
                      );
                    },
                    child: const Text('Calculate'),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}
}

void _showWasteGuide(BuildContext context) {
  List<String> chatMessages = [];
  TextEditingController wasteInputController = TextEditingController();

  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true, // Enable scrolling when keyboard opens
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom, // Space for keyboard
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)), // Rounded corners
                child: Container(
                  padding: const EdgeInsets.all(16),
                  height: MediaQuery.of(context).size.height * 0.5, // Adjust height if needed
                  color: Colors.white,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Waste Guide',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 20),
                      Expanded(
                        child: ListView.builder(
                          itemCount: chatMessages.length,
                          itemBuilder: (context, index) {
                            bool isUserMessage = chatMessages[index].startsWith('You:');
                            return ListTile(
                              title: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (isUserMessage)
                                    const Icon(
                                      Icons.person,
                                      color: Colors.red,
                                      size: 24,
                                    )
                                  else
                                    SvgPicture.asset(
                                      'assets/icons/smart_toy.svg',
                                      width: 24,
                                      height: 24,
                                    ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      chatMessages[index].substring(4),
                                      textAlign: TextAlign.left,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: wasteInputController,
                              decoration: const InputDecoration(
                                hintText: 'Enter waste item',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.send),
                            onPressed: () async {
                              String userInput = wasteInputController.text;
                              if (userInput.isNotEmpty) {
                                setState(() {
                                  chatMessages.add('You: $userInput');
                                });

                                String response = await _getWasteGuideResponse(userInput);
                                
                                setState(() {
                                  chatMessages.add('AI: $response');
                                });

                                wasteInputController.clear();
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
    },
  );
}


Future<String> _getWasteGuideResponse(String wasteItem) async {
  const apiUrl = 'https://openrouter.ai/api/v1/chat/completions';
  const apiKey = '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';

  final response = await http.post(
    Uri.parse(apiUrl),
    headers: {
      'Authorization': 'Bearer $apiKey',
      'Content-Type': 'application/json',
    },
    body: jsonEncode({
      'model': 'liquid/lfm-40b:free',
      'messages': [
        {
          'role': 'system',
          'content': 'You are a waste guide assistant. Provide a breakdown of the specified waste item and information on how it can be disposed of in an eco-friendly manner.'
        },
        {
          'role': 'user',
          'content': 'Please provide a detailed breakdown and eco-friendly disposal methods for "$wasteItem".',
        },
      ],
    }),
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    return data['choices'][0]['message']['content'];
  } else {
    print('Error: ${response.statusCode}');
    return 'Error fetching response. Please try again later.';
  }
}



void _showFoodGuide(BuildContext context) {
  List<String> chatMessages = [];
  TextEditingController foodInputController = TextEditingController();

  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true, // Enable scrolling when the keyboard is open
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom, // Space for keyboard
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)), // Rounded top corners
                child: Container(
                  padding: const EdgeInsets.all(16),
                  height: MediaQuery.of(context).size.height * 0.5, // Adjust height as needed
                  color: Colors.white,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Food Guide',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 20),
                      Expanded(
                        child: ListView.builder(
                          itemCount: chatMessages.length,
                          itemBuilder: (context, index) {
                            bool isUserMessage = chatMessages[index].startsWith('You:');
                            return ListTile(
                              title: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (isUserMessage)
                                    const Icon(
                                      Icons.person,
                                      color: Colors.red,
                                      size: 24,
                                    )
                                  else
                                    SvgPicture.asset(
                                      'assets/icons/smart_toy.svg',
                                      width: 24,
                                      height: 24,
                                    ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      chatMessages[index].substring(4),
                                      textAlign: TextAlign.left,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: foodInputController,
                              decoration: const InputDecoration(
                                hintText: 'Ask about healthy food',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.send),
                            onPressed: () async {
                              String userInput = foodInputController.text;
                              if (userInput.isNotEmpty) {
                                setState(() {
                                  chatMessages.add('You: $userInput');
                                });

                                String response = await _getFoodGuideResponse(userInput);
                                
                                setState(() {
                                  chatMessages.add('AI: $response');
                                });

                                foodInputController.clear();
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
    },
  );
}


Future<String> _getFoodGuideResponse(String foodQuery) async {
  const apiUrl = 'https://openrouter.ai/api/v1/chat/completions';
  const apiKey = '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'; // Replace with your actual API key

  final response = await http.post(
    Uri.parse(apiUrl),
    headers: {
      'Authorization': 'Bearer $apiKey',
      'Content-Type': 'application/json',
    },
    body: jsonEncode({
      'model': 'liquid/lfm-40b:free',
      'messages': [
        {
          'role': 'system',
          'content': 'You are a health guide assistant. Provide healthy food suggestions and nutritional advice based on user input.'
        },
        {
          'role': 'user',
          'content': 'Please give healthy food recommendations and nutritional guidance for: "$foodQuery".',
        },
      ],
    }),
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    return data['choices'][0]['message']['content'];
  } else {
    print('Error: ${response.statusCode}');
    return 'Error fetching response. Please try again later.';
  }
}

void _showBusinessDirectory(BuildContext context) {
  List<String> chatMessages = [];
  TextEditingController productInputController = TextEditingController();

  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true, // Enables scrolling with keyboard open
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom, // Space for keyboard
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)), // Rounded top corners
                child: Container(
                  padding: const EdgeInsets.all(16),
                  height: MediaQuery.of(context).size.height * 0.5, // Set height for sheet
                  color: Colors.white,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Business Directory',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 20),
                      Expanded(
                        child: ListView.builder(
                          itemCount: chatMessages.length,
                          itemBuilder: (context, index) {
                            bool isUserMessage = chatMessages[index].startsWith('You:');
                            return ListTile(
                              title: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (isUserMessage)
                                    const Icon(
                                      Icons.person,
                                      color: Colors.red,
                                      size: 24,
                                    )
                                  else
                                    SvgPicture.asset(
                                      'assets/icons/smart_toy.svg',
                                      width: 24,
                                      height: 24,
                                    ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      chatMessages[index].substring(4),
                                      textAlign: TextAlign.left,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: productInputController,
                              decoration: const InputDecoration(
                                hintText: 'Enter a product',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.send),
                            onPressed: () async {
                              String userInput = productInputController.text;
                              if (userInput.isNotEmpty) {
                                setState(() {
                                  chatMessages.add('You: $userInput');
                                });

                                String response = await _getBusinessDirectoryResponse(userInput);
                                
                                setState(() {
                                  chatMessages.add('AI: $response');
                                });

                                productInputController.clear();
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
    },
  );
}

void _showSustainableBot(BuildContext context) {
  List<String> chatMessages = [];
  TextEditingController sustainabilityInputController = TextEditingController();

  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true, // Ensures the sheet is scrollable when keyboard appears
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom, // Adds space for keyboard
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)), // Rounded top corners
                child: Container(
                  padding: const EdgeInsets.all(16),
                  height: MediaQuery.of(context).size.height * 0.5, // Controls height
                  color: Colors.white,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Sustainable Bot',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 20),
                      Expanded(
                        child: ListView.builder(
                          itemCount: chatMessages.length,
                          itemBuilder: (context, index) {
                            bool isUserMessage = chatMessages[index].startsWith('You:');
                            return ListTile(
                              title: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (isUserMessage)
                                    const Icon(
                                      Icons.person,
                                      color: Colors.red,
                                      size: 24,
                                    )
                                  else
                                    SvgPicture.asset(
                                      'assets/icons/smart_toy.svg',
                                      width: 24,
                                      height: 24,
                                    ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      chatMessages[index].substring(4),
                                      textAlign: TextAlign.left,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: sustainabilityInputController,
                              decoration: const InputDecoration(
                                hintText: 'Ask about sustainability',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.send),
                            onPressed: () async {
                              String userInput = sustainabilityInputController.text;
                              if (userInput.isNotEmpty) {
                                setState(() {
                                  chatMessages.add('You: $userInput');
                                });

                                String response = await _getSustainableBotResponse(userInput);

                                setState(() {
                                  chatMessages.add('AI: $response');
                                });

                                sustainabilityInputController.clear();
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
    },
  );
}

Future<String> _getBusinessDirectoryResponse(String productName) async {
    const apiUrl = 'https://openrouter.ai/api/v1/chat/completions';
    const apiKey = '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'; // Replace with your actual API key

    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': 'liquid/lfm-40b:free',
        'messages': [
          {
            'role': 'system',
            'content': 'You are a business directory assistant. Suggest Sustaimable alternative companies that make similar products but more sustainable to promote the environment as requested.'
          },
          {
            'role': 'user',
            'content': 'Please provide alternative companies for: "$productName".',
          },
        ],
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['choices'][0]['message']['content']; // Assuming the response has this structure
    } else {
      return "Sorry, I couldn't find any alternatives.";
    }
  }

  Future<String> _getSustainableBotResponse(String question) async {
    const apiUrl = 'https://openrouter.ai/api/v1/chat/completions';
    const apiKey = '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'; // Replace with your actual API key

    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': 'liquid/lfm-40b:free',
        'messages': [
          {
            'role': 'system',
            'content': 'You are a sustainability assistant. Answer questions related to sustainability practices and provide guidance based on user input.'
          },
          {
            'role': 'user',
            'content': 'Please provide information on sustainability for: "$question".',
          },
        ],
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['choices'][0]['message']['content']; // Assuming the response has this structure
    } else {
      return "I'm not sure about that.";
    }
  }