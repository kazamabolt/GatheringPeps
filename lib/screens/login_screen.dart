import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/app_logo.dart';
import 'signup_screen.dart';
import 'home_screen.dart';
import 'settings_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 60),
                    
                    // App Logo and Title
                    _buildAppHeader(),
                    
                    const SizedBox(height: 60),
                    
                    // Email Field
                    _buildEmailField(),
                    
                    const SizedBox(height: 20),
                    
                    // Password Field
                    _buildPasswordField(),
                    
                    const SizedBox(height: 30),
                    
                    // Login Button
                    _buildLoginButton(),
                    
                    const SizedBox(height: 20),
                    
                    // Social Login Options
                    _buildSocialLoginOptions(),
                    
                    const SizedBox(height: 20),
                    
                    // Sign Up Link
                    _buildSignUpLink(),
                    
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppHeader() {
    return AppLogoWithText(
      logoSize: 120,
      title: 'GatheringPeps',
      subtitle: 'Connect, Meet, and Explore Together',
      showShadow: true,
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      decoration: const InputDecoration(
        labelText: 'Email',
        prefixIcon: Icon(Icons.email_outlined),
        hintText: 'Enter your email address',
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter your email';
        }
        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
          return 'Please enter a valid email address';
        }
        return null;
      },
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      decoration: InputDecoration(
        labelText: 'Password',
        prefixIcon: const Icon(Icons.lock_outlined),
        hintText: 'Enter your password',
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword ? Icons.visibility_off : Icons.visibility,
          ),
          onPressed: () {
            setState(() {
              _obscurePassword = !_obscurePassword;
            });
          },
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter your password';
        }
        if (value.length < 6) {
          return 'Password must be at least 6 characters';
        }
        return null;
      },
    );
  }

  Widget _buildLoginButton() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return ElevatedButton(
          onPressed: authProvider.isLoading ? null : _handleLogin,
          child: authProvider.isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text('LOGIN'),
        );
      },
    );
  }

  Widget _buildSocialLoginOptions() {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 10.0),
          child: Row(
            children: [
              Expanded(child: Divider()),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 10.0),
                child: Text('OR'),
              ),
              Expanded(child: Divider()),
            ],
          ),
        ),
        const SizedBox(height: 10),
                 // Google Sign In Button
         _buildSocialButton(
           icon: 'assets/icons/google_logo.svg',
           label: 'Continue with Google',
           onPressed: _handleGoogleSignIn,
           iconWidget: const Icon(Icons.g_mobiledata, size: 30),
         ),
      ],
    );
  }

     Widget _buildSocialButton({
     required String icon,
     required String label,
     required VoidCallback onPressed,
     required Widget iconWidget,
   }) {
     return InkWell(
       onTap: onPressed,
       borderRadius: BorderRadius.circular(12),
       child: Container(
         width: double.infinity,
         padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
         decoration: BoxDecoration(
           border: Border.all(color: Colors.grey.shade300),
           borderRadius: BorderRadius.circular(12),
         ),
         child: Row(
           mainAxisAlignment: MainAxisAlignment.center,
           children: [
             iconWidget,
             const SizedBox(width: 8),
             Text(label),
           ],
         ),
       ),
     );
   }

  Widget _buildSignUpLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Don't have an account? ",
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppTheme.textSecondaryColor,
          ),
        ),
        TextButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const SignupScreen(),
              ),
            );
          },
          child: const Text('Sign up'),
        ),
      ],
    );
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    final success = await authProvider.signIn(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (success && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const HomeScreen(),
        ),
      );
    } else if (mounted) {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage ?? 'Login failed'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }
  
  Future<void> _handleGoogleSignIn() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    final success = await authProvider.signInWithGoogle();

    if (success && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const HomeScreen(),
        ),
      );
    } else if (mounted) {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage ?? 'Google sign in failed'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }
  
  
}
