import 'dart:async';
import 'dart:convert'; // Needed for jsonDecode

import 'package:flutter/material.dart';
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
        textTheme: GoogleFonts.poppinsTextTheme(), // Set Poppins font
        scaffoldBackgroundColor:
            const Color(0xFF1A1A1A), // Set background color to hex #1a1a1a
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => FutureBuilder<bool>(
              future: checkAuthStatus(), // Check authentication status
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(
                      body: Center(child: CircularProgressIndicator()));
                } else {
                  if (snapshot.data == true) {
                    return MyHomePage(
                        title:
                            ''); // User is logged in, show home page
                  } else {
                    return IntroScreen(
                        supabaseClient:
                            supabaseClient); // User not logged in, show intro screen
                  }
                }
              },
            ),
        '/home': (context) => MyHomePage(title: ''),
        // '/calendar': (context) => EventCalender()
      },
    );
  }

  Future<bool> checkAuthStatus() async {
    final user = supabaseClient.auth.currentUser;
    return user !=
        null; // Return true if user is authenticated, false otherwise
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
  final _studentEmailController = TextEditingController(); // Controller for student's email

  String selectedRole = 'Student'; // Default role is 'Student'

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
            Navigator.pop(context); // Navigate back to the previous screen
          },
        ),
        title: Text(
          'Sign Up',
          style: GoogleFonts.poppins(), // Poppins font for app bar title
        ),
        backgroundColor: Colors.white, // Set app bar background color to white
      ),
      backgroundColor: Colors.white, // Set scaffold background color to white
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0).add(
          const EdgeInsets.only(top: 25.0), // Add padding at the top
        ),
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
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters long';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Show Student's Email field if "Parent" is selected
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
                            contentPadding: const EdgeInsets.symmetric(
                                vertical: 16.0, horizontal: 12.0),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10.0),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          style: GoogleFonts.poppins(),
                          validator: (value) {
                            if (selectedRole == 'Parent' &&
                                (value == null || value.isEmpty)) {
                              return 'Please enter the student\'s email address';
                            }
                            if (selectedRole == 'Parent' &&
                                !RegExp(r'^[^@]+@[^@]+\.[a-zA-Z]{2,}$')
                                    .hasMatch(value!)) {
                              return 'Please enter a valid student email address';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),

                  // Role selection with toggle buttons
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
                              color: selectedRole == 'Student'
                                  ? Colors.black
                                  : Colors.grey.shade200,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(10),
                                bottomLeft: Radius.circular(10),
                              ),
                            ),
                            child: Text(
                              'Student',
                              style: GoogleFonts.poppins(
                                color: selectedRole == 'Student'
                                    ? Colors.white
                                    : Colors.black,
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
                              color: selectedRole == 'Parent'
                                  ? Colors.black
                                  : Colors.grey.shade200,
                              borderRadius: const BorderRadius.only(
                                topRight: Radius.circular(10),
                                bottomRight: Radius.circular(10),
                              ),
                            ),
                            child: Text(
                              'Parent',
                              style: GoogleFonts.poppins(
                                color: selectedRole == 'Parent'
                                    ? Colors.white
                                    : Colors.black,
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

                        // Perform the signup process
                        try {
                          final response = await widget.supabaseClient.auth
                              .signUp(email: email, password: password);

                          // Check if signup was successful
                          if (response.user != null) {
                            // Insert the new user details into the Users table
                            final role = selectedRole;
                            await widget.supabaseClient.from('Users').insert({
                              'Email ID': email, // Column A
                              'Type': role, // Column B
                              'StudentEmail': role == 'Parent' ? studentEmail : null, // Column C
                            });

                            // Insert initial score into the Scores table only if the user is a Student
                            if (role == 'Student') {
                              await widget.supabaseClient.from('Scores').insert({
                                'Email ID': email, // Column A
                                'Score': 0, // Column B
                              });
                            }

                            Navigator.pop(context); // Navigate back on successful sign up
                          } else {
                            // No error handling, as per your request
                          }
                        } catch (e) {
                          // Handle any exceptions that occur during signup
                          _showErrorDialog('An error occurred: $e');
                        }
                      }
                    },
                    style: ButtonStyle(
                      minimumSize: MaterialStateProperty.all<Size>(
                          const Size(double.infinity, 50)), // Full width button
                      backgroundColor: MaterialStateProperty.all<Color>(
                          const Color(0xFF1A1A1A)), // Black background color
                      shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0), // Rounded corners
                        ),
                      ),
                    ),
                    child: Container(
                      alignment: Alignment.center,
                      height: 55, // Set a fixed height for consistency
                      child: const Text(
                        'Sign Up',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white, // White text color
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

  // Function to show error dialog
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
                Navigator.of(context).pop(); // Close the dialog
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
  String userEmail = ''; // Full email
  String userEmailPrefix = ''; // Display prefix
  int userScore = 0;
  double _rotation = 0;
  List<Map<String, dynamic>> events = [];
  List<String> requestedTasks = [];
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
    _fetchUserScore(userEmail);
    await _checkForTaskRefresh();
    await _loadRequestedTasks(); // Load previously requested tasks
  }

  Future<void> _loadRequestedTasks() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? storedRequestedTasks = prefs.getString('requestedTasks');
    if (storedRequestedTasks != null) {
      requestedTasks = List<String>.from(jsonDecode(storedRequestedTasks));
      // Update event statuses based on requested tasks
      for (var event in events) {
        if (requestedTasks.contains(event['title'])) {
          event['status'] = 'Requested'; // Update status to 'Requested'
        }
      }
    }
  }

  Future<void> _fetchUserScore(String? email) async {
    if (email != null) {
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
        print('Failed to fetch user score.');
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
    final apiKey = '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';

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': 'liquid/lfm-40b',
          'messages': [
            {
              'role': 'A Task Generator That Generates Exactly 5 Tasks in A List that is numbered without any extra spaces or extra lines,The Tasks Must Be UAE Appropriate',
              'content': 'Generate EXACTLY 5 tasks which encourages 5-10 year olds to do something eco-friendly in a list preferably supporting SDG 13. Don\'t type any responses apart from the list. Don\'t give any text before or after the list. It should not be numbered. It should be less than 7 words and must be completable in max 30 mins. Eg: Turn off lights when they aren\'t used, go around the house looking for electronic appliances that aren\'t used and unplug them. Must be sensible or something preferably done at home. THIS RESPONSE IS PARSED TO A MOBILE APPLICATION THAT ONLY ACCEPTS THE FORMAT OF A LIST WITH NO EXTRA TEXT.',
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

        // Store the tasks and current date in Shared Preferences
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('tasks', jsonEncode(events));
        await prefs.setString('lastFetchDate', DateFormat('yyyy-MM-dd').format(DateTime.now()));
      } else {
        print('Failed to fetch tasks: ${response.statusCode}');
      }
    } catch (error) {
      print('Error fetching tasks: $error');
    }
  }

    Future<void> _saveTaskToRequests(String email, String task) async {
    try {
      final response = await Supabase.instance.client
          .from('Requests')
          .insert({'StudentEmail': email, 'Task': task, 'Status': 'Requested'});

      if (response.error == null) {
        print('Task successfully saved to Requests.');
      } else {
        print('Failed to save task: ${response.error!.message}');
      }
    } catch (error) {
      print('Error saving task to Requests: $error');
    }
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
        _sendRequest(events[index]['title'], userEmail); // Use full email here
        events[index]['status'] = 'Requested';
        requestedTasks.add(events[index]['title']);
        _saveRequestedTasks();
      }
    });
  }

  Future<void> _sendRequest(String task, String studentEmail) async {
    final response = await Supabase.instance.client
        .from('Requests')
        .insert({
          'StudentEmail': studentEmail,
          'Task': task,
          'Status': 'Requested',
        });
  }

  Future<void> _saveRequestedTasks() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('requestedTasks', jsonEncode(requestedTasks));
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _refreshData();
        },
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
                    events[index]['title'],
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${events[index]['status']}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.check_box, color: Colors.white),
              onPressed: () {
                _toggleEventStatus(index);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreBox() {
    return GestureDetector(
      onTap: _openLeaderboard, // Open leaderboard on tap
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
              '$userScore points',
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

  void _openLeaderboard() {
    // Open leaderboard screen
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => LeaderboardScreen()),
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

    if (response != null && response.isNotEmpty) {
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
  final String parentEmail; // Add parentEmail as a parameter

  const ParentDashboard({Key? key, required this.title, required this.parentEmail}) : super(key: key);

  @override
  _ParentDashboardState createState() => _ParentDashboardState();
}

class _ParentDashboardState extends State<ParentDashboard> {
  String childEmail = ''; // Email of the child
  String childEmailPrefix = '';
  int childScore = 0;
  double _rotation = 0;
  List<Map<String, dynamic>> taskRequests = [];

  @override
  void initState() {
    super.initState();
    // Use the parent's email passed from the login screen
    _fetchChildEmail(widget.parentEmail);
  }

  // Fetch child's email using the parent's email
  Future<void> _fetchChildEmail(String? parentEmail) async {
    if (parentEmail != null && parentEmail.isNotEmpty) {
      try {
        final response = await Supabase.instance.client
            .from('Users') // Assuming Users is your table name
            .select('StudentEmail') // Change 'childEmail' to your actual column name for child's email
            .eq('Email ID', parentEmail) // Use the parent's email here
            .single();

        if (response != null && response['StudentEmail'] != null) {
          setState(() {
            childEmail = response['StudentEmail']; // Update the child's email
            childEmailPrefix = childEmail.split('@').first; // Display child's email prefix
          });

          // Fetch the child's score and task requests after fetching the child email
          _fetchChildScore(childEmail);
          await _fetchTaskRequests();
        } else {
          print('No child email found for the provided parent email.');
        }
      } catch (error) {
        print('Error fetching child email: $error');
      }
    } else {
      print('Invalid parent email.');
    }
  }

  // Fetch child's score using the child's email
  Future<void> _fetchChildScore(String? email) async {
    if (email != null && email.isNotEmpty) {
      try {
        final response = await Supabase.instance.client
            .from('Scores')
            .select('Score')
            .eq('Email ID', email) // Use the child's email here
            .single();

        if (response != null && response['Score'] != null) {
          setState(() {
            childScore = response['Score']; // Update the child's score
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

  // Fetch task requests for the child
  Future<void> _fetchTaskRequests() async {
  if (childEmail.isNotEmpty) {
    try {
      final response = await Supabase.instance.client
          .from('Requests')
          .select()
          .eq('StudentEmail', childEmail)  // Use the child's email
          .eq('Status', 'Requested');  // Fetch only tasks with status 'Requested'

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

  // Refresh task requests
  void _refreshData() {
    setState(() {
      _rotation += 45;
    });

    // Refresh the task requests
    _fetchTaskRequests();

    Future.delayed(const Duration(milliseconds: 300), () {
      setState(() {
        _rotation = 0;
      });
    });
  }

  // Approve the task and update the score
// Approve the task and update the score
void _approveTask(int index) async {
  final taskId = taskRequests[index]['id']; // Get the task ID

  // Update the task status in the database
  await _updateTaskStatus(taskId, 'Approved');

  // Increment the child's score after task approval
  await _incrementChildScore();

  // Remove the task from the list after approval
  setState(() {
    taskRequests.removeAt(index);
  });
}


  // Update task status in the database
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

  // Increment child's score
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
    );
  }

  // Build each task request card
  // Build each task request card
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
                onPressed: () => _rejectTask(index), // Call the reject function
              ),
            ],
          ),
        ],
      ),
    ),
  );
}


// Reject the task and update the UI
void _rejectTask(int index) async {
  final taskId = taskRequests[index]['id']; // Get the task ID

  // Update the database to change the status to 'Rejected'
  await _updateTaskStatus(taskId, 'Rejected');

  // Remove the task from the list after rejection
  setState(() {
    taskRequests.removeAt(index);
  });
}


  // Build the score box displaying the child's score
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
}
