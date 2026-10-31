import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/api_client.dart';

class LumaAccount {
  final String email;
  String name;
  String username;
  String? profileImagePath;
  String? token;

  LumaAccount({
    required this.email,
    required this.name,
    required this.username,
    this.profileImagePath,
    this.token,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'name': name,
      'username': username,
      'profileImagePath': profileImagePath,
      'token': token,
    };
  }

  factory LumaAccount.fromJson(Map<String, dynamic> json) {
    return LumaAccount(
      email: json['email']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      profileImagePath: json['profileImagePath']?.toString(),
      token: json['token']?.toString(),
    );
  }
}

class AuthStore extends ChangeNotifier {
  AuthStore._();

  static final AuthStore instance = AuthStore._();

  static const String _accountsKey = 'luma_accounts';
  static const String _activeAccountKey = 'luma_active_account';

  List<LumaAccount> _accounts = [];
  String? _activeAccountEmail;

  bool _isLoading = false;

  bool get isLoggedIn => _activeAccount != null;

  bool get isLoading => _isLoading;

  List<LumaAccount> get accounts => List.unmodifiable(_accounts);

  int get accountCount => _accounts.length;

  LumaAccount? get _activeAccount {
    if (_activeAccountEmail == null) {
      return null;
    }

    for (final account in _accounts) {
      if (account.email == _activeAccountEmail) {
        return account;
      }
    }

    return null;
  }

  String get name => _activeAccount?.name ?? '';

  String get username => _activeAccount?.username ?? '';

  String get email => _activeAccount?.email ?? '';

  String? get profileImagePath => _activeAccount?.profileImagePath;

  String? get token => _activeAccount?.token;

  // ============================================================
  // LOAD SESSION
  // ============================================================

  Future<void> loadSession() async {
    final prefs = await SharedPreferences.getInstance();

    final accountsJson = prefs.getString(_accountsKey);

    if (accountsJson != null && accountsJson.isNotEmpty) {
      try {
        final decoded = jsonDecode(accountsJson);

        if (decoded is List) {
          _accounts = decoded
              .whereType<Map>()
              .map(
                (item) => LumaAccount.fromJson(Map<String, dynamic>.from(item)),
              )
              .toList();
        }
      } catch (_) {
        _accounts = [];
      }
    }

    _activeAccountEmail = prefs.getString(_activeAccountKey);

    if (_activeAccountEmail != null &&
        !_accounts.any((account) => account.email == _activeAccountEmail)) {
      _activeAccountEmail = null;
    }

    notifyListeners();
  }

  // ============================================================
  // SAVE LOCAL SESSION
  // ============================================================

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();

    final encodedAccounts = jsonEncode(
      _accounts.map((account) => account.toJson()).toList(),
    );

    await prefs.setString(_accountsKey, encodedAccounts);

    if (_activeAccountEmail == null) {
      await prefs.remove(_activeAccountKey);
    } else {
      await prefs.setString(_activeAccountKey, _activeAccountEmail!);
    }
  }

  // ============================================================
  // BACKEND REGISTRATION
  // ============================================================

  Future<Map<String, dynamic>> registerWithApi({
    required String name,
    required String username,
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiClient.instance.post(
        '/auth/register',
        body: {
          'email': email.trim().toLowerCase(),
          'username': username.trim().toLowerCase(),
          'displayName': name.trim(),
          'password': password,
        },
      );

      final accountData = response['account'] as Map<String, dynamic>?;

      if (accountData == null) {
        throw ApiException(
          statusCode: 500,
          message: 'Account information was not returned.',
        );
      }

      final accountEmail =
          accountData['email']?.toString() ?? email.trim().toLowerCase();

      final accountUsername =
          accountData['username']?.toString() ?? username.trim();

      final displayName = accountData['displayName']?.toString() ?? name.trim();

      final existingIndex = _accounts.indexWhere(
        (account) => account.email == accountEmail,
      );

      final account = LumaAccount(
        email: accountEmail,
        name: displayName,
        username: accountUsername,
        profileImagePath: accountData['profileImage']?.toString(),
      );

      if (existingIndex >= 0) {
        _accounts[existingIndex] = account;
      } else {
        _accounts.add(account);
      }

      _activeAccountEmail = accountEmail;

      await _save();

      return response;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ============================================================
  // BACKEND LOGIN
  // ============================================================

  Future<Map<String, dynamic>> loginWithApi({
    required String identifier,
    required String password,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiClient.instance.post(
        '/auth/login',
        body: {
          'identifier': identifier.trim().toLowerCase(),
          'password': password,
        },
      );

      final accountData = response['account'] as Map<String, dynamic>?;

      final sessionData = response['session'] as Map<String, dynamic>?;

      if (accountData == null || sessionData == null) {
        throw ApiException(
          statusCode: 500,
          message: 'Login response is incomplete.',
        );
      }

      final accountEmail =
          accountData['email']?.toString() ?? identifier.trim().toLowerCase();

      final accountUsername = accountData['username']?.toString() ?? '';

      final displayName = accountData['displayName']?.toString() ?? '';

      final token = sessionData['token']?.toString();

      final profileImage = accountData['profileImage']?.toString();

      final existingIndex = _accounts.indexWhere(
        (account) => account.email == accountEmail,
      );

      if (existingIndex >= 0) {
        final existing = _accounts[existingIndex];

        existing.name = displayName;
        existing.username = accountUsername;
        existing.profileImagePath = profileImage;

        if (token != null && token.isNotEmpty) {
          existing.token = token;
        }
      } else {
        _accounts.add(
          LumaAccount(
            email: accountEmail,
            name: displayName,
            username: accountUsername,
            profileImagePath: profileImage,
            token: token,
          ),
        );
      }

      _activeAccountEmail = accountEmail;

      await _save();

      return response;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ============================================================
  // CHECK CURRENT BACKEND SESSION
  // ============================================================

  Future<bool> validateCurrentSession() async {
    final account = _activeAccount;

    if (account == null || account.token == null || account.token!.isEmpty) {
      return false;
    }

    try {
      final response = await ApiClient.instance.get(
        '/auth/me',
        token: account.token,
      );

      final accountData = response['account'] as Map<String, dynamic>?;

      if (accountData == null) {
        return false;
      }

      account.name = accountData['displayName']?.toString() ?? account.name;

      account.username =
          accountData['username']?.toString() ?? account.username;

      account.profileImagePath =
          accountData['profileImage']?.toString() ?? account.profileImagePath;

      await _save();
      notifyListeners();

      return true;
    } on ApiException {
      account.token = null;

      await _save();
      notifyListeners();

      return false;
    } catch (_) {
      return false;
    }
  }

  // ============================================================
  // REFRESH CURRENT ACCOUNT FROM BACKEND
  // ============================================================

  Future<void> refreshCurrentAccount() async {
    final account = _activeAccount;

    if (account == null) {
      return;
    }

    if (account.token == null || account.token!.isEmpty) {
      return;
    }

    try {
      final response = await ApiClient.instance.get(
        '/auth/me',
        token: account.token,
      );

      final accountData = response['account'] as Map<String, dynamic>?;

      if (accountData == null) {
        return;
      }

      account.name = accountData['displayName']?.toString() ?? account.name;

      account.username =
          accountData['username']?.toString() ?? account.username;

      account.profileImagePath =
          accountData['profileImage']?.toString() ?? account.profileImagePath;

      await _save();

      notifyListeners();
    } on ApiException catch (error) {
      // Do not delete the local account if the session
      // temporarily fails. The existing session handling
      // can deal with expired sessions.
      if (error.statusCode == 401) {
        return;
      }

      rethrow;
    }
  }

  // ============================================================
  // LOCAL REGISTER
  // ============================================================

  Future<void> register({
    required String name,
    required String username,
    required String email,
    String? token,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();

    final existingIndex = _accounts.indexWhere(
      (account) => account.email == normalizedEmail,
    );

    final account = LumaAccount(
      email: normalizedEmail,
      name: name.trim(),
      username: username.trim(),
      token: token,
    );

    if (existingIndex >= 0) {
      _accounts[existingIndex] = account;
    } else {
      _accounts.add(account);
    }

    _activeAccountEmail = normalizedEmail;

    await _save();

    notifyListeners();
  }

  // ============================================================
  // LOCAL LOGIN
  // ============================================================

  Future<void> login({
    required String email,
    required String name,
    required String username,
    String? token,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();

    final existingIndex = _accounts.indexWhere(
      (account) => account.email == normalizedEmail,
    );

    if (existingIndex >= 0) {
      final existing = _accounts[existingIndex];

      existing.name = name.trim();
      existing.username = username.trim();

      if (token != null) {
        existing.token = token;
      }
    } else {
      _accounts.add(
        LumaAccount(
          email: normalizedEmail,
          name: name.trim(),
          username: username.trim(),
          token: token,
        ),
      );
    }

    _activeAccountEmail = normalizedEmail;

    await _save();

    notifyListeners();
  }

  // ============================================================
  // ADD ACCOUNT
  // ============================================================

  Future<void> addAccount({
    required String name,
    required String username,
    required String email,
    String? token,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();

    final alreadyExists = _accounts.any(
      (account) => account.email == normalizedEmail,
    );

    if (alreadyExists) {
      await switchAccount(normalizedEmail);
      return;
    }

    _accounts.add(
      LumaAccount(
        email: normalizedEmail,
        name: name.trim(),
        username: username.trim(),
        token: token,
      ),
    );

    _activeAccountEmail = normalizedEmail;

    await _save();

    notifyListeners();
  }

  // ============================================================
  // SWITCH ACCOUNT
  // ============================================================

  Future<void> switchAccount(String email) async {
    final normalizedEmail = email.trim().toLowerCase();

    final exists = _accounts.any((account) => account.email == normalizedEmail);

    if (!exists) {
      return;
    }

    _activeAccountEmail = normalizedEmail;

    await _save();

    notifyListeners();
  }

  // ============================================================
  // LOGOUT FROM BACKEND + LOCAL ACCOUNT
  // ============================================================

  Future<void> logout() async {
    final account = _activeAccount;

    if (account == null) {
      return;
    }

    final token = account.token;

    if (token != null && token.isNotEmpty) {
      try {
        await ApiClient.instance.post('/auth/logout', token: token);
      } catch (_) {
        // Continue with local logout.
      }
    }

    _accounts.removeWhere((item) => item.email == account.email);

    if (_accounts.isEmpty) {
      _activeAccountEmail = null;
    } else {
      _activeAccountEmail = _accounts.first.email;
    }

    await _save();

    notifyListeners();
  }

  // ============================================================
  // REMOVE ACCOUNT FROM DEVICE
  // ============================================================

  Future<void> removeAccount(String email) async {
    final normalizedEmail = email.trim().toLowerCase();

    _accounts.removeWhere((account) => account.email == normalizedEmail);

    if (_activeAccountEmail == normalizedEmail) {
      if (_accounts.isEmpty) {
        _activeAccountEmail = null;
      } else {
        _activeAccountEmail = _accounts.first.email;
      }
    }

    await _save();

    notifyListeners();
  }

  // ============================================================
  // UPDATE PROFILE
  // BACKEND VERSION
  // ============================================================

  Future<void> updateProfile({String? name, String? username}) async {
    final account = _activeAccount;

    if (account == null) {
      return;
    }

    if (account.token == null || account.token!.isEmpty) {
      throw ApiException(
        statusCode: 401,
        message: 'Your session has expired. Please log in again.',
      );
    }

    final response = await ApiClient.instance.patch(
      '/users/me',
      token: account.token,
      body: {
        if (name != null) 'displayName': name.trim(),
        if (username != null) 'username': username.trim().toLowerCase(),
      },
    );

    final accountData = response['account'];

    if (accountData is Map) {
      account.name = accountData['displayName']?.toString() ?? account.name;

      account.username =
          accountData['username']?.toString() ?? account.username;

      account.profileImagePath =
          accountData['profileImage']?.toString() ?? account.profileImagePath;
    } else {
      if (name != null) {
        account.name = name.trim();
      }

      if (username != null) {
        account.username = username.trim().toLowerCase();
      }
    }

    await _save();

    notifyListeners();
  }

  // ============================================================
  // PROFILE IMAGE
  // ============================================================

  Future<void> updateProfileImage(String imagePath) async {
    final account = _activeAccount;

    if (account == null) {
      return;
    }

    account.profileImagePath = imagePath;

    await _save();

    notifyListeners();
  }

  Future<void> removeProfileImage() async {
    final account = _activeAccount;

    if (account == null) {
      return;
    }

    account.profileImagePath = null;

    await _save();

    notifyListeners();
  }
}
