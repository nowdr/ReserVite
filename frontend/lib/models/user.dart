import 'package:email_validator/email_validator.dart';
import 'package:prbd_2526_f01/models/security.dart';

class User {
  final int id;
  final String? email;
  final String fullName;
  final String? role;
  final String? phone;

  User({
    required this.id,
    this.email,
    required this.fullName,
    this.role,
    this.phone,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      fullName: json['full_name'],
      role: json['role'],
      phone: json['phone'],
    );
  }

  static String? validateFullName(String? fullName) {
    if (fullName == null || fullName.isEmpty) {
      return 'Veuillez entrer votre nom complet';
    } else if (fullName.length < 3) {
      return 'Le nom complet doit contenir au moins 3 caractères';
    } else {
      return null;
    }
  }

  static Future<String?> validateFullNameUnicity(String? value) async {
    var res = await Security.checkFullNameAvailable(fullName: value?.trim());
    return res ? null : 'Ce nom complet est déjà utilisé';
  }

  static String? validateEmail(String? email) {
    if (email == null || email.isEmpty) {
      return 'Veuillez entrer votre adresse email';
    } else if (!EmailValidator.validate(email)) {
      return 'Veuillez entrer une adresse email valide';
    } else {
      return null;
    }
  }

  static Future<String?> validateEmailUnicity(String? value) async {
    var res = await Security.checkEmailAvailable(email: value?.trim());
    return res ? null : 'Cette adresse email est déjà utilisée';
  }

  static String? validateLoginPassword(String? password) {
    if (password == null || password.isEmpty) {
      return 'Veuillez entrer votre mot de passe';
    }
    return null;
  }

  static String? validatePassword(String? password) {
    if (password == null || password.isEmpty) {
      return 'Veuillez entrer un mot de passe';
    } else if (!RegExp(r'^.{8,}$').hasMatch(password)) {
      return 'Le mot de passe doit contenir au moins 8 caractères';
    } else if (!RegExp(r'[a-z]').hasMatch(password)) {
      return 'Le mot de passe doit contenir au moins une lettre minuscule';
    } else if (!RegExp(r'[A-Z]').hasMatch(password)) {
      return 'Le mot de passe doit contenir au moins une lettre majuscule';
    } else if (!RegExp(r'[0-9]').hasMatch(password)) {
      return 'Le mot de passe doit contenir au moins un chiffre';
    } else if (!RegExp(r'[,;.:!?/$%&@#]').hasMatch(password)) {
      return 'Le mot de passe doit contenir au moins un caractère spécial (,;.:!?/\$%&@#)';
    } else {
      return null;
    }
  }

  static String? validatePasswordConfirm(
    String? passwordConfirm,
    String? password,
  ) {
    if (passwordConfirm == null || passwordConfirm.isEmpty) {
      return 'Veuillez confirmer votre mot de passe';
    } else if (passwordConfirm != password) {
      return 'Les deux mots de passe doivent être identiques';
    }
    return null;
  }

  static String? validatePhone(String? phone) {
    if (phone == null || phone.isEmpty) {
      return null;
    }
    return RegExp(
          r'(^[+]?[(]?[0-9]{3}[)]?[-\s.]?[0-9]{3}[-\s.]?[0-9]{4,6}$)',
        ).hasMatch(phone)
        ? null
        : 'Veuillez entrer un numéro de téléphone valide';
  }
}
