import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prbd_2526_f01/core/tools/validating_text_editing_controller.dart';
import 'package:prbd_2526_f01/models/user.dart';
import 'package:prbd_2526_f01/providers/current_user_provider.dart';
import 'package:prbd_2526_f01/views/widgets/page_app_bar.dart';

class SignupPage extends ConsumerStatefulWidget {
  @override
  ConsumerState<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends ConsumerState<SignupPage> {
  late ValidatingTextEditingController _fullNameController;
  late ValidatingTextEditingController _emailController;
  late ValidatingTextEditingController _passwordController;
  late ValidatingTextEditingController _passwordConfirmController;
  late ValidatingTextEditingController _phoneController;

  @override
  void initState() {
    super.initState();

    _fullNameController = ValidatingTextEditingController(
      validator: User.validateFullName,
      asyncValidator: User.validateFullNameUnicity,
    );
    _fullNameController.onAfterValidated = () => setState(() {});

    _emailController = ValidatingTextEditingController(
      validator: User.validateEmail,
      asyncValidator: User.validateEmailUnicity,
    );
    _emailController.onAfterValidated = () => setState(() {});

    _passwordController = ValidatingTextEditingController(
      validator: User.validatePassword,
    );
    _passwordController.onAfterValidated = () => setState(() {});

    _passwordConfirmController = ValidatingTextEditingController(
      validator: (passwordConfirm) => User.validatePasswordConfirm(
        passwordConfirm,
        _passwordController.text,
      ),
    );
    _passwordConfirmController.onAfterValidated = () => setState(() {});

    _phoneController = ValidatingTextEditingController(
      validator: User.validatePhone,
    );
    _phoneController.onAfterValidated = () => setState(() {});
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _passwordConfirmController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PageAppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: 'Inscription',
        // bouton refresh sans effet, gardé volontairement pour la cohérence visuelle (vidéo de présentation)
        onRefreshPressed: () {},
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 32),
                const Icon(Icons.person_add, size: 80, color: Colors.blue),
                const SizedBox(height: 32),
                const Text(
                  'Créez votre compte',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                _fullNameFormField(context, (_) => _submitForm(context)),
                const SizedBox(height: 16),
                _emailFormField(context, (_) => _submitForm(context)),
                const SizedBox(height: 16),
                _passwordFormField(context, (_) => _submitForm(context)),
                const SizedBox(height: 16),
                _passwordConfirmFormField(context, (_) => _submitForm(context)),
                const SizedBox(height: 16),
                _phoneFormField(context, (_) => _submitForm(context)),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () async => await _submitForm(context),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('S\'inscrire'),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/login'),
                  child: const Text('Déjà un compte ? Se connecter'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _fullNameFormField(
    BuildContext context,
    Future<void> Function(String) onFieldSubmitted,
  ) {
    return TextFormField(
      controller: _fullNameController,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      keyboardType: TextInputType.name,
      onFieldSubmitted: onFieldSubmitted,
      decoration: InputDecoration(
        labelText: 'Nom complet',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.person),
        errorText: _fullNameController.errorText,
      ),
    );
  }

  Widget _emailFormField(
    BuildContext context,
    Future<void> Function(String) onFieldSubmitted,
  ) {
    return TextFormField(
      controller: _emailController,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      keyboardType: TextInputType.emailAddress,
      onFieldSubmitted: onFieldSubmitted,
      decoration: InputDecoration(
        labelText: 'Email',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.email),
        errorText: _emailController.errorText,
      ),
    );
  }

  Widget _passwordFormField(
    BuildContext context,
    Future<void> Function(String) onFieldSubmitted,
  ) {
    return TextFormField(
      controller: _passwordController,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      keyboardType: TextInputType.visiblePassword,
      obscureText: true,
      obscuringCharacter: '⦁',
      onFieldSubmitted: onFieldSubmitted,
      decoration: InputDecoration(
        labelText: 'Mot de passe',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.lock),
        errorText: _passwordController.errorText,
      ),
    );
  }

  Widget _passwordConfirmFormField(
    BuildContext context,
    Future<void> Function(String) onFieldSubmitted,
  ) {
    return TextFormField(
      controller: _passwordConfirmController,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      keyboardType: TextInputType.visiblePassword,
      obscureText: true,
      obscuringCharacter: '⦁',
      onFieldSubmitted: onFieldSubmitted,
      decoration: InputDecoration(
        labelText: 'Confirmer le mot de passe',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.lock_outline),
        errorText: _passwordConfirmController.errorText,
      ),
    );
  }

  Widget _phoneFormField(
    BuildContext context,
    Future<void> Function(String) onFieldSubmitted,
  ) {
    return TextFormField(
      controller: _phoneController,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      keyboardType: TextInputType.phone,
      onFieldSubmitted: onFieldSubmitted,
      decoration: InputDecoration(
        labelText: 'Téléphone (optionnel)',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.phone),
        errorText: _phoneController.errorText,
      ),
    );
  }

  Future<void> _submitForm(BuildContext context) async {
    if (!await _validateForm()) return;

    final currentUserNotifier = ref.read(currentUserProvider.notifier);
    await currentUserNotifier.signup(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      fullName: _fullNameController.text.trim(),
      phone: _phoneController.text.trim(),
    );

    if (context.mounted) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        currentUserNotifier.isManager
            ? '/manager/restaurants'
            : '/client/reservations',
        (route) => false,
      );
    }
  }

  Future<bool> _validateForm() async {
    await _fullNameController.validateAndWait();
    await _emailController.validateAndWait();
    await _passwordController.validateAndWait();
    await _passwordConfirmController.validateAndWait();
    await _phoneController.validateAndWait();
    return _isFormValid;
  }

  bool get _isFormValid =>
      _fullNameController.isValid == true &&
      _emailController.isValid == true &&
      _passwordController.isValid == true &&
      _passwordConfirmController.isValid == true &&
      _phoneController.isValid == true;
}
