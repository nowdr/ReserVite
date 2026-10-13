import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prbd_2526_f01/core/tools/validating_text_editing_controller.dart';
import 'package:prbd_2526_f01/models/user.dart';
import 'package:prbd_2526_f01/providers/current_user_provider.dart';
import 'package:prbd_2526_f01/views/widgets/page_app_bar.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

const _debugPassword = 'Password1,';

class _LoginPageState extends ConsumerState<LoginPage> {
  late ValidatingTextEditingController _emailController;
  late ValidatingTextEditingController _passwordController;

  @override
  void initState() {
    super.initState();
    _emailController = ValidatingTextEditingController(
      validator: User.validateEmail,
    );
    _emailController.onAfterValidated = () => setState(() {});

    _passwordController = ValidatingTextEditingController(
      validator: User.validateLoginPassword,
    );
    _passwordController.onAfterValidated = () => setState(() {});
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final asyncState = ref.watch(currentUserProvider);
    final isLoading = asyncState.isLoading;

    return Scaffold(
      appBar: PageAppBar(
        title: 'Connexion',
        // bouton refresh sans effet, gardé volontairement pour la cohérence visuelle (vidéo de présentation)
        onRefreshPressed: () {},
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: Form(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 32),
                      const Icon(
                        Icons.restaurant,
                        size: 80,
                        color: Colors.blue,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Connectez-vous',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      _emailFormField(),
                      const SizedBox(height: 10),
                      _passwordFormField(),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: isLoading ? null : () => _submit(),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('Se connecter'),
                      ),
                      const SizedBox(height: 6),
                      TextButton(
                        onPressed: isLoading
                            ? null
                            : () => Navigator.pushNamed(context, '/signup'),
                        child: const Text('Pas encore de compte ? S\'inscrire'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Divider(),
                  const SizedBox(height: 8),
                  const Text(
                    'Raccourcis de débogage',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Se connecter directement en tant que :',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: isLoading
                              ? null
                              : () =>
                                    _login('brlacroix@epfc.eu', _debugPassword),
                          icon: const Icon(Icons.person),
                          label: const Text('Client (Bruno)'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: isLoading
                              ? null
                              : () =>
                                    _login('mamichel@epfc.eu', _debugPassword),
                          icon: const Icon(Icons.person),
                          label: const Text('Client (Marc)'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: isLoading
                              ? null
                              : () =>
                                    _login('bepenelle@epfc.eu', _debugPassword),
                          icon: const Icon(Icons.manage_accounts),
                          label: const Text('Manager (Benoît)'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: isLoading
                              ? null
                              : () =>
                                    _login('gedielman@epfc.eu', _debugPassword),
                          icon: const Icon(Icons.manage_accounts),
                          label: const Text('Manager (Geoffrey)'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: isLoading
                          ? null
                          : () async {
                              final confirmed = await showDialog<bool>(
                                context: context,
                                builder: (context) {
                                  return AlertDialog(
                                    title: const Text(
                                      'Réinitialiser la base de données',
                                    ),
                                    content: const Text(
                                      'Êtes-vous sûr de vouloir réinitialiser la base de données ? '
                                      'Cette action supprimera toutes les données et les restaurera aux valeurs par défaut.',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, false),
                                        child: const Text('Annuler'),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, true),
                                        style: TextButton.styleFrom(
                                          backgroundColor: Colors.deepOrange,
                                          foregroundColor: Colors.white,
                                        ),
                                        child: const Text('Réinitialiser'),
                                      ),
                                    ],
                                  );
                                },
                              );

                              if (confirmed != true) return;

                              try {
                                await ref
                                    .read(currentUserProvider.notifier)
                                    .resetDatabase();

                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Base de données réinitialisée avec succès',
                                      ),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                }
                              } catch (_) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Échec de la réinitialisation de la base de données',
                                      ),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Réinitialiser la base de données'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        foregroundColor: isLoading ? null : Colors.red,
                        side: BorderSide(
                          color: isLoading ? Colors.grey.shade300 : Colors.red,
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

  Widget _emailFormField() {
    return TextFormField(
      controller: _emailController,
      autofocus: true,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      keyboardType: TextInputType.emailAddress,
      onFieldSubmitted: (_) => _submit(),
      decoration: InputDecoration(
        labelText: 'Email',
        border: const OutlineInputBorder(),
        prefixIcon: const Icon(Icons.email),
        errorText: _emailController.errorText,
      ),
    );
  }

  Widget _passwordFormField() {
    return TextFormField(
      controller: _passwordController,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      keyboardType: TextInputType.visiblePassword,
      obscureText: true,
      obscuringCharacter: '⦁',
      onFieldSubmitted: (_) => _submit(),
      decoration: InputDecoration(
        labelText: 'Mot de passe',
        border: const OutlineInputBorder(),
        prefixIcon: const Icon(Icons.lock),
        errorText: _passwordController.errorText,
      ),
    );
  }

  Future<void> _submit() async {
    if (!_validateForm()) return;
    await _login(_emailController.text.trim(), _passwordController.text);
  }

  bool _validateForm() {
    _emailController.validate();
    _passwordController.validate();
    return _emailController.isValid == true &&
        _passwordController.isValid == true;
  }

  Future<void> _login(String email, String password) async {
    final currentUserNotifier = ref.read(currentUserProvider.notifier);
    await currentUserNotifier.login(email, password);

    if (!mounted) return;

    ref
        .read(currentUserProvider)
        .whenOrNull(
          data: (token) {
            if (token != null) {
              Navigator.pushReplacementNamed(
                context,
                currentUserNotifier.isManager
                    ? '/manager/restaurants'
                    : '/client/reservations',
              );
            }
          },
          error: (_, _) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Email ou mot de passe incorrect'),
                backgroundColor: Colors.red,
              ),
            );
          },
        );
  }
}
