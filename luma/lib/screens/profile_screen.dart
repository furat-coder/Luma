import 'dart:io';
import 'dart:math';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../auth/auth_store.dart';
import '../theme/theme_store.dart';
import 'verification_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with TickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

    _animationController.forward();

    // Load the latest profile information from the backend.
    _refreshProfile();
  }

  // ============================================================
  // REFRESH PROFILE FROM BACKEND
  // ============================================================

  Future<void> _refreshProfile() async {
    try {
      await AuthStore.instance.refreshCurrentAccount();

      if (!mounted) return;

      setState(() {});
    } catch (_) {
      // Keep the locally saved profile if the backend
      // cannot be reached.
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _selectProfilePicture() async {
    try {
      final file = await FilePicker.pickFile(type: FileType.image);

      if (file == null || file.path == null || file.path!.isEmpty) {
        return;
      }

      await AuthStore.instance.updateProfileImage(file.path!);

      if (!mounted) return;

      setState(() {});

      _showMessage('Profile picture updated.');
    } catch (error) {
      if (!mounted) return;

      _showMessage('Could not select the image.', isError: true);
    }
  }

  Future<void> _removeProfilePicture() async {
    await AuthStore.instance.removeProfileImage();

    if (!mounted) return;

    setState(() {});

    _showMessage('Profile picture removed.');
  }

  void _showProfilePictureOptions() {
    final imagePath = AuthStore.instance.profileImagePath;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);

        return Container(
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 45,
                    height: 5,
                    decoration: BoxDecoration(
                      color: theme.dividerColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Profile Picture',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 18),
                  _bottomSheetOption(
                    context: sheetContext,
                    icon: Icons.photo_library_rounded,
                    title: 'Choose from device',
                    subtitle: 'Select a new profile picture',
                    onTap: () {
                      Navigator.pop(sheetContext);
                      _selectProfilePicture();
                    },
                  ),
                  if (imagePath != null && imagePath.isNotEmpty)
                    _bottomSheetOption(
                      context: sheetContext,
                      icon: Icons.delete_outline_rounded,
                      title: 'Remove picture',
                      subtitle: 'Use the default Luma avatar',
                      isDestructive: true,
                      onTap: () {
                        Navigator.pop(sheetContext);
                        _removeProfilePicture();
                      },
                    ),
                  _bottomSheetOption(
                    context: sheetContext,
                    icon: Icons.close_rounded,
                    title: 'Cancel',
                    subtitle: 'Close this menu',
                    onTap: () {
                      Navigator.pop(sheetContext);
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _bottomSheetOption({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final theme = Theme.of(context);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      leading: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: isDestructive
              ? Colors.red.withValues(alpha: 0.10)
              : theme.colorScheme.primary.withValues(alpha: 0.10),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: isDestructive ? Colors.red : theme.colorScheme.primary,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w700,
          color: isDestructive ? Colors.red : null,
        ),
      ),
      subtitle: Text(subtitle),
      onTap: onTap,
    );
  }

  Future<void> _editProfile() async {
    final auth = AuthStore.instance;

    final nameController = TextEditingController(text: auth.name);

    final usernameController = TextEditingController(text: auth.username);

    final formKey = GlobalKey<FormState>();

    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Edit Profile'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    prefixIcon: Icon(Icons.person_outline_rounded),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Enter your name.';
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: usernameController,
                  decoration: const InputDecoration(
                    labelText: 'Username',
                    prefixIcon: Icon(Icons.alternate_email_rounded),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Enter a username.';
                    }

                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.pop(dialogContext, true);
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (shouldSave != true) {
      nameController.dispose();
      usernameController.dispose();
      return;
    }

    final newName = nameController.text.trim();
    final newUsername = usernameController.text.trim();

    nameController.dispose();
    usernameController.dispose();

    if (!mounted) return;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: SizedBox(
                width: 45,
                height: 45,
                child: CircularProgressIndicator(),
              ),
            ),
          ),
        );
      },
    );

    try {
      await AuthStore.instance.updateProfile(
        name: newName,
        username: newUsername,
      );

      if (!mounted) return;

      Navigator.of(context).pop();

      setState(() {});

      _showMessage('Profile updated successfully.');
    } catch (error) {
      if (!mounted) return;

      Navigator.of(context).pop();

      String message = 'Could not update your profile.';

      if (error is ApiException) {
        message = error.message;
      }

      _showMessage(message, isError: true);
    }
  }

  void _showAccountSwitcher() {
    final accounts = AuthStore.instance.accounts;
    final currentEmail = AuthStore.instance.email;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);

        return Container(
          constraints: const BoxConstraints(maxHeight: 620),
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 45,
                    height: 5,
                    decoration: BoxDecoration(
                      color: theme.dividerColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Switch Account',
                    style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 16),
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: accounts.length,
                      separatorBuilder: (_, index) {
                        return const SizedBox(height: 8);
                      },
                      itemBuilder: (_, index) {
                        final account = accounts[index];

                        final isCurrent =
                            account.email.toLowerCase() ==
                            currentEmail.toLowerCase();

                        return Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(18),
                            onTap: () async {
                              if (isCurrent) {
                                Navigator.pop(sheetContext);
                                return;
                              }

                              Navigator.pop(sheetContext);

                              await AuthStore.instance.switchAccount(
                                account.email,
                              );

                              // Load the selected account's
                              // latest data from PostgreSQL.
                              await _refreshProfile();

                              if (!mounted) return;

                              _showMessage(
                                'Switched to @${AuthStore.instance.username}',
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: Row(
                                children: [
                                  _accountAvatar(
                                    account.profileImagePath,
                                    account.name,
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          account.name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '@${account.username}',
                                          style: TextStyle(
                                            color: theme
                                                .textTheme
                                                .bodySmall
                                                ?.color,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (isCurrent)
                                    Icon(
                                      Icons.check_circle_rounded,
                                      color: theme.colorScheme.primary,
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(sheetContext);
                        _showAddAccountDialog();
                      },
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Add another account'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _accountAvatar(String? imagePath, String name, {double radius = 25}) {
    final hasImage =
        imagePath != null &&
        imagePath.isNotEmpty &&
        File(imagePath).existsSync();

    final firstLetter = name.trim().isNotEmpty
        ? name.trim()[0].toUpperCase()
        : 'L';

    return CircleAvatar(
      radius: radius,
      backgroundColor: Theme.of(context).colorScheme.primary,
      backgroundImage: hasImage ? FileImage(File(imagePath)) : null,
      child: hasImage
          ? null
          : Text(
              firstLetter,
              style: TextStyle(
                color: Colors.white,
                fontSize: radius * 0.8,
                fontWeight: FontWeight.w800,
              ),
            ),
    );
  }

  Future<void> _showAddAccountDialog() async {
    final nameController = TextEditingController();
    final usernameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();

    bool obscurePassword = true;

    final formKey = GlobalKey<FormState>();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Add another account'),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nameController,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Name',
                          prefixIcon: Icon(Icons.person_outline_rounded),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Enter your name.';
                          }

                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: usernameController,
                        decoration: const InputDecoration(
                          labelText: 'Username',
                          prefixIcon: Icon(Icons.alternate_email_rounded),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Enter a username.';
                          }

                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        validator: (value) {
                          final email = value?.trim() ?? '';

                          if (email.isEmpty) {
                            return 'Enter your email.';
                          }

                          if (!email.contains('@') || !email.contains('.')) {
                            return 'Enter a valid email.';
                          }

                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: passwordController,
                        obscureText: obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock_outline_rounded),
                          suffixIcon: IconButton(
                            onPressed: () {
                              setDialogState(() {
                                obscurePassword = !obscurePassword;
                              });
                            },
                            icon: Icon(
                              obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.length < 6) {
                            return 'Use at least 6 characters.';
                          }

                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    if (!formKey.currentState!.validate()) {
                      return;
                    }

                    _startAddAccountVerification(
                      name: nameController.text.trim(),
                      username: usernameController.text.trim(),
                      email: emailController.text.trim(),
                      password: passwordController.text,
                    );

                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Continue'),
                ),
              ],
            );
          },
        );
      },
    );

    nameController.dispose();
    usernameController.dispose();
    emailController.dispose();
    passwordController.dispose();
  }

  Future<void> _startAddAccountVerification({
    required String name,
    required String username,
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.toLowerCase();

    final existingAccount = AuthStore.instance.accounts.where(
      (account) => account.email.toLowerCase() == normalizedEmail,
    );

    if (existingAccount.isNotEmpty) {
      _showMessage('An account with this email already exists.', isError: true);
      return;
    }

    final verificationCode = (100000 + Random().nextInt(900000)).toString();

    if (!mounted) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) {
          return VerificationScreen(
            name: name,
            username: username,
            email: email,
            password: password,
            verificationCode: verificationCode,
            isAddingAccount: true,
          );
        },
      ),
    );

    if (!mounted) return;

    setState(() {});
  }

  Future<void> _removeCurrentAccount() async {
    final accounts = AuthStore.instance.accounts;

    if (accounts.length <= 1) {
      _showMessage('You cannot remove your only account.', isError: true);
      return;
    }

    final email = AuthStore.instance.email;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Remove account?'),
          content: const Text(
            'This will remove the account from this device. '
            'Your Luma account itself will not be permanently deleted.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Remove'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    await AuthStore.instance.removeAccount(email);

    if (!mounted) return;

    setState(() {});

    _showMessage('Account removed from this device.');
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Log out?'),
          content: const Text('You can log back in whenever you want.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Log out'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    await AuthStore.instance.logout();

    if (!mounted) return;

    setState(() {});
  }

  void _showThemeSelector() {
    final currentMode = ThemeStore.instance.mode;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);

        return Container(
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 45,
                    height: 5,
                    decoration: BoxDecoration(
                      color: theme.dividerColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Appearance',
                    style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Choose how Luma should look.',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  RadioGroup<LumaThemeMode>(
                    groupValue: currentMode,
                    onChanged: (value) {
                      if (value == null) return;

                      ThemeStore.instance.setMode(value);
                      Navigator.pop(sheetContext);

                      if (mounted) {
                        setState(() {});
                      }
                    },
                    child: Column(
                      children: [
                        _themeOption(
                          context: sheetContext,
                          title: 'System',
                          subtitle: 'Follow your device settings',
                          icon: Icons.settings_suggest_rounded,
                          mode: LumaThemeMode.system,
                          selected: currentMode == LumaThemeMode.system,
                        ),
                        _themeOption(
                          context: sheetContext,
                          title: 'Light',
                          subtitle: 'Use light mode',
                          icon: Icons.light_mode_rounded,
                          mode: LumaThemeMode.light,
                          selected: currentMode == LumaThemeMode.light,
                        ),
                        _themeOption(
                          context: sheetContext,
                          title: 'Dark',
                          subtitle: 'Use dark mode',
                          icon: Icons.dark_mode_rounded,
                          mode: LumaThemeMode.dark,
                          selected: currentMode == LumaThemeMode.dark,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _themeOption({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required LumaThemeMode mode,
    required bool selected,
  }) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          ThemeStore.instance.setMode(mode);
          Navigator.pop(context);

          if (mounted) {
            setState(() {});
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: theme.colorScheme.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(subtitle, style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
              Radio<LumaThemeMode>(value: mode),
            ],
          ),
        ),
      ),
    );
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: isError
              ? Colors.red
              : Theme.of(context).colorScheme.primary,
        ),
      );
  }

  String _initial(String name) {
    final trimmed = name.trim();

    if (trimmed.isEmpty) {
      return 'L';
    }

    return trimmed[0].toUpperCase();
  }

  Widget _profileAvatar({
    required String name,
    required String? imagePath,
    double radius = 55,
  }) {
    final hasImage =
        imagePath != null &&
        imagePath.isNotEmpty &&
        File(imagePath).existsSync();

    return CircleAvatar(
      radius: radius,
      backgroundColor: Theme.of(context).colorScheme.primary,
      backgroundImage: hasImage ? FileImage(File(imagePath)) : null,
      child: hasImage
          ? null
          : Text(
              _initial(name),
              style: TextStyle(
                color: Colors.white,
                fontSize: radius * 0.65,
                fontWeight: FontWeight.w900,
              ),
            ),
    );
  }

  Widget _settingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? iconColor,
    Widget? trailing,
  }) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        leading: Container(
          width: 45,
          height: 45,
          decoration: BoxDecoration(
            color: (iconColor ?? theme.colorScheme.primary).withValues(
              alpha: 0.10,
            ),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor ?? theme.colorScheme.primary),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(subtitle),
        trailing: trailing ?? const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = AuthStore.instance;
    final theme = Theme.of(context);

    final name = auth.name;
    final username = auth.username;
    final email = auth.email;
    final profileImagePath = auth.profileImagePath;

    final accounts = auth.accounts;

    return Scaffold(
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: RefreshIndicator(
              onRefresh: _refreshProfile,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverAppBar(
                    pinned: true,
                    floating: true,
                    elevation: 0,
                    backgroundColor: theme.scaffoldBackgroundColor,
                    title: const Text(
                      'Profile',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    actions: [
                      IconButton(
                        tooltip: 'Settings',
                        onPressed: _showThemeSelector,
                        icon: const Icon(Icons.settings_outlined),
                      ),
                    ],
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        Center(
                          child: GestureDetector(
                            onTap: _showProfilePictureOptions,
                            child: Stack(
                              alignment: Alignment.bottomRight,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: theme.colorScheme.primary
                                          .withValues(alpha: 0.35),
                                      width: 2,
                                    ),
                                  ),
                                  child: _profileAvatar(
                                    name: name,
                                    imagePath: profileImagePath,
                                    radius: 58,
                                  ),
                                ),
                                Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: theme.scaffoldBackgroundColor,
                                      width: 3,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt_rounded,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Center(
                          child: Text(
                            name.isEmpty ? 'Luma User' : name,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Center(
                          child: Text(
                            '@$username',
                            style: TextStyle(
                              fontSize: 15,
                              color: theme.textTheme.bodyMedium?.color
                                  ?.withValues(alpha: 0.65),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Center(
                          child: Text(
                            email,
                            style: TextStyle(
                              fontSize: 13,
                              color: theme.textTheme.bodyMedium?.color
                                  ?.withValues(alpha: 0.55),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _editProfile,
                                icon: const Icon(Icons.edit_outlined),
                                label: const Text('Edit profile'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: _showAccountSwitcher,
                                icon: const Icon(Icons.switch_account_rounded),
                                label: const Text('Accounts'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 28),
                        Row(
                          children: [
                            Expanded(
                              child: _statCard(value: '0', label: 'Posts'),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _statCard(value: '0', label: 'Followers'),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _statCard(value: '0', label: 'Following'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 28),
                        const Text(
                          'Account',
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _settingsTile(
                          icon: Icons.switch_account_rounded,
                          title: 'Switch account',
                          subtitle:
                              '${accounts.length} account${accounts.length == 1 ? '' : 's'} on this device',
                          onTap: _showAccountSwitcher,
                        ),
                        _settingsTile(
                          icon: Icons.add_circle_outline_rounded,
                          title: 'Add another account',
                          subtitle: 'Create another Luma account',
                          onTap: _showAddAccountDialog,
                        ),
                        _settingsTile(
                          icon: Icons.palette_outlined,
                          title: 'Appearance',
                          subtitle: _themeModeLabel(ThemeStore.instance.mode),
                          onTap: _showThemeSelector,
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          'Manage',
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _settingsTile(
                          icon: Icons.delete_outline_rounded,
                          iconColor: Colors.red,
                          title: 'Remove current account',
                          subtitle: 'Remove this account from this device',
                          onTap: _removeCurrentAccount,
                        ),
                        _settingsTile(
                          icon: Icons.logout_rounded,
                          iconColor: Colors.red,
                          title: 'Log out',
                          subtitle: 'Log out of the current account',
                          onTap: _logout,
                        ),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _statCard({required String value, required String label}) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: theme.textTheme.bodySmall?.color,
            ),
          ),
        ],
      ),
    );
  }

  String _themeModeLabel(LumaThemeMode mode) {
    switch (mode) {
      case LumaThemeMode.system:
        return 'System';
      case LumaThemeMode.light:
        return 'Light';
      case LumaThemeMode.dark:
        return 'Dark';
    }
  }
}
