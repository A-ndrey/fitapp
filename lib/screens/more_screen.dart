import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/app_preferences.dart';
import '../state/app_store.dart';
import '../state/auth/app_auth_service.dart';
import '../state/sync/app_store_sync_status.dart';
import '../ui/core/forms/form_error_messages.dart';
import '../ui/core/layout/adaptive_page.dart';
import '../ui/core/widgets/app_screen_scaffold.dart';
import '../ui/core/widgets/form_shell.dart';
import '../ui/settings/settings_cards.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({
    super.key,
    required this.store,
    this.syncStatusListenable,
    this.readSyncStatus,
    this.authListenable,
    this.readAuthState,
    this.onSignIn,
    this.onSignUp,
    this.onSignOut,
    this.onDeleteAccount,
  });

  final AppStore store;
  final Listenable? syncStatusListenable;
  final AppStoreSyncStatus? Function()? readSyncStatus;
  final Listenable? authListenable;
  final AppAuthState Function()? readAuthState;
  final Future<void> Function({
    required String email,
    required String password,
  })?
  onSignIn;
  final Future<void> Function({
    required String email,
    required String password,
  })?
  onSignUp;
  final Future<void> Function()? onSignOut;
  final Future<void> Function({required String password})? onDeleteAccount;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        store,
        syncStatusListenable,
        authListenable,
      ]),
      builder: (context, _) {
        final preferences = store.preferences;
        final l10n = AppLocalizations.of(context);
        final authState = readAuthState?.call() ?? const AppAuthState();
        final syncPresentation = _syncCardPresentation(
          readSyncStatus?.call(),
          errorColor: Theme.of(context).colorScheme.error,
        );

        return AppScreenScaffold(
          title: l10n?.destinationMore ?? 'Settings',
          body: AdaptivePage(
            children: [
              _AuthCard(
                authState: authState,
                syncPresentation: syncPresentation,
                onSignIn: onSignIn,
                onSignUp: onSignUp,
                onSignOut: onSignOut,
                onDeleteAccount: onDeleteAccount,
              ),
              const AppPageSectionGap(),
              LayoutBuilder(
                builder: (context, constraints) {
                  final unitsCard = UnitsSettingsCard(
                    workoutWeightUnit: preferences.workoutWeightUnit,
                    dishWeightUnit: preferences.dishWeightUnit,
                    heightUnit: preferences.heightUnit,
                    distanceUnit: preferences.distanceUnit,
                    workoutWeightOptions: [
                      PreferenceChipOption(
                        value: WorkoutWeightUnit.kilograms,
                        label: l10n?.unitKilograms ?? 'Kilograms',
                      ),
                      PreferenceChipOption(
                        value: WorkoutWeightUnit.pounds,
                        label: l10n?.unitPounds ?? 'Pounds',
                      ),
                    ],
                    dishWeightOptions: [
                      PreferenceChipOption(
                        value: DishWeightUnit.grams,
                        label: l10n?.unitGrams ?? 'Grams',
                      ),
                      PreferenceChipOption(
                        value: DishWeightUnit.ounces,
                        label: l10n?.unitOunces ?? 'Ounces',
                      ),
                    ],
                    heightOptions: [
                      PreferenceChipOption(
                        value: HeightUnit.centimeters,
                        label: l10n?.unitCentimeters ?? 'Centimeters',
                      ),
                      PreferenceChipOption(
                        value: HeightUnit.inches,
                        label: l10n?.unitInches ?? 'Inches',
                      ),
                    ],
                    distanceOptions: [
                      PreferenceChipOption(
                        value: DistanceUnit.kilometers,
                        label: l10n?.unitKilometers ?? 'Kilometers',
                      ),
                      PreferenceChipOption(
                        value: DistanceUnit.miles,
                        label: l10n?.unitMiles ?? 'Miles',
                      ),
                    ],
                    onWorkoutWeightChanged: (value) =>
                        store.setWorkoutWeightUnit(value as WorkoutWeightUnit),
                    onDishWeightChanged: (value) =>
                        store.setDishWeightUnit(value as DishWeightUnit),
                    onHeightChanged: (value) =>
                        store.setHeightUnit(value as HeightUnit),
                    onDistanceChanged: (value) =>
                        store.setDistanceUnit(value as DistanceUnit),
                  );
                  final appCards = [
                    MacroTargetsSettingsCard(
                      initialValue: preferences.dailyMacroTargets,
                      subtitle: 'Used across Today and Nutrition.',
                      onApply: store.setDailyMacroTargets,
                    ),
                    PreferenceChipCard<LanguagePreference>(
                      title: l10n?.settingsLanguageTitle ?? 'Language',
                      subtitle:
                          l10n?.settingsLanguageSubtitle ?? 'App language',
                      value: preferences.language,
                      options: [
                        PreferenceChipOption(
                          value: LanguagePreference.english,
                          label: l10n?.languageEnglish ?? 'English',
                        ),
                      ],
                      onChanged: store.setLanguagePreference,
                    ),
                    PreferenceChipCard<AppearancePreference>(
                      title: l10n?.settingsAppearanceTitle ?? 'Appearance',
                      subtitle: l10n?.settingsAppearanceSubtitle ?? 'Theme',
                      value: preferences.appearance,
                      options: [
                        PreferenceChipOption(
                          value: AppearancePreference.system,
                          label: l10n?.appearanceSystem ?? 'System',
                        ),
                        PreferenceChipOption(
                          value: AppearancePreference.light,
                          label: l10n?.appearanceLight ?? 'Light',
                        ),
                        PreferenceChipOption(
                          value: AppearancePreference.dark,
                          label: l10n?.appearanceDark ?? 'Dark',
                        ),
                      ],
                      onChanged: store.setAppearancePreference,
                    ),
                  ];

                  if (constraints.maxWidth < 720) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _SettingsGroup(
                          title: l10n?.settingsUnitsTitle ?? 'Units',
                          children: [unitsCard],
                        ),
                        const AppPageSectionGap(),
                        _SettingsGroup(
                          title: l10n?.settingsAppTitle ?? 'App',
                          children: appCards,
                        ),
                      ],
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _SettingsGroup(
                        title: l10n?.settingsUnitsTitle ?? 'Units',
                        columns: 2,
                        children: [unitsCard],
                      ),
                      const AppPageSectionGap(),
                      _SettingsGroup(
                        title: l10n?.settingsAppTitle ?? 'App',
                        columns: 2,
                        children: appCards,
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AuthCard extends StatefulWidget {
  const _AuthCard({
    required this.authState,
    required this.syncPresentation,
    required this.onSignIn,
    required this.onSignUp,
    required this.onSignOut,
    required this.onDeleteAccount,
  });

  final AppAuthState authState;
  final _SyncCardPresentation syncPresentation;
  final Future<void> Function({
    required String email,
    required String password,
  })?
  onSignIn;
  final Future<void> Function({
    required String email,
    required String password,
  })?
  onSignUp;
  final Future<void> Function()? onSignOut;
  final Future<void> Function({required String password})? onDeleteAccount;

  @override
  State<_AuthCard> createState() => _AuthCardState();
}

class _AuthCardState extends State<_AuthCard> {
  bool _isDeletingAccount = false;
  String? _deleteErrorMessage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final email = widget.authState.email;
    final isSignedIn = widget.authState.isSignedIn;
    final canDeleteAccount = isSignedIn && widget.onDeleteAccount != null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.account_circle_outlined,
                  color: colorScheme.onSurface,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Account',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              isSignedIn
                  ? 'Signed in${email == null ? '' : ' as $email'}.'
                  : 'Sign in to sync your data across devices.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            if (isSignedIn) ...[
              const SizedBox(height: 8),
              Text(
                widget.syncPresentation.message,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color:
                      widget.syncPresentation.messageColor ??
                      colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            if (_deleteErrorMessage != null && isSignedIn) ...[
              const SizedBox(height: 8),
              Text(
                _deleteErrorMessage!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.error,
                ),
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _isDeletingAccount
                    ? null
                    : isSignedIn
                    ? () => widget.onSignOut?.call()
                    : () => _openAuthForm(context),
                child: Text(isSignedIn ? 'Logout' : 'Login'),
              ),
            ),
            if (canDeleteAccount) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: _isDeletingAccount ? null : _confirmDeleteAccount,
                  style: TextButton.styleFrom(
                    foregroundColor: colorScheme.error,
                  ),
                  icon: _isDeletingAccount
                      ? SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: colorScheme.error,
                          ),
                        )
                      : const Icon(Icons.delete_outline),
                  label: const Text('Delete account'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _openAuthForm(BuildContext context) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (context) {
          return _AuthFormScreen(
            onSignIn: widget.onSignIn,
            onSignUp: widget.onSignUp,
          );
        },
      ),
    );
  }

  Future<void> _confirmDeleteAccount() async {
    final password = await showDialog<String>(
      context: context,
      builder: (context) => const _DeleteAccountDialog(),
    );

    if (password == null || !mounted) {
      return;
    }

    setState(() {
      _isDeletingAccount = true;
      _deleteErrorMessage = null;
    });

    try {
      await widget.onDeleteAccount?.call(password: password);
    } on AuthFailure catch (error) {
      if (mounted) {
        setState(() {
          _deleteErrorMessage = humanReadableFormError(
            error.message,
            resourceName: 'account',
            fallback: "We couldn't delete your account. Please try again.",
          );
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _deleteErrorMessage = humanReadableFormError(
            error,
            resourceName: 'account',
            fallback: "We couldn't delete your account. Please try again.",
          );
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDeletingAccount = false;
        });
      }
    }
  }
}

class _DeleteAccountDialog extends StatefulWidget {
  const _DeleteAccountDialog();

  @override
  State<_DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<_DeleteAccountDialog> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Delete account?'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Your account and cloud sync data will be permanently deleted. '
              'Local data on this device will remain.',
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              autofocus: true,
              autofillHints: const [AutofillHints.password],
              autocorrect: false,
              enableSuggestions: false,
              decoration: InputDecoration(
                labelText: 'Password',
                suffixIcon: IconButton(
                  tooltip: _obscurePassword ? 'Show password' : 'Hide password',
                  onPressed: () => setState(() {
                    _obscurePassword = !_obscurePassword;
                  }),
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ),
              ),
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _submit(),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Password is required.';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Delete account')),
      ],
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    Navigator.of(context).pop(_passwordController.text);
  }
}

class _AuthFormScreen extends StatefulWidget {
  const _AuthFormScreen({required this.onSignIn, required this.onSignUp});

  final Future<void> Function({
    required String email,
    required String password,
  })?
  onSignIn;
  final Future<void> Function({
    required String email,
    required String password,
  })?
  onSignUp;

  @override
  State<_AuthFormScreen> createState() => _AuthFormScreenState();
}

class _AuthFormScreenState extends State<_AuthFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isSignUp = false;
  bool _isSubmitting = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_clearErrorAfterEdit);
    _passwordController.addListener(_clearErrorAfterEdit);
    _confirmPasswordController.addListener(_clearErrorAfterEdit);
  }

  @override
  void dispose() {
    _emailController.removeListener(_clearErrorAfterEdit);
    _passwordController.removeListener(_clearErrorAfterEdit);
    _confirmPasswordController.removeListener(_clearErrorAfterEdit);
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = _isSignUp ? 'Create account' : 'Sign in';
    return FormShellPage(
      title: title,
      showBodyHeader: false,
      primaryActionLabel: title,
      primaryActionChild: _isSubmitting
          ? const SizedBox.square(
              dimension: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : null,
      onPrimaryAction: _isSubmitting ? null : _submit,
      children: [
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                autofocus: true,
                autofillHints: const [AutofillHints.email],
                autocorrect: false,
                enableSuggestions: false,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                validator: (value) {
                  final email = value?.trim() ?? '';
                  if (email.isEmpty) {
                    return 'Email is required.';
                  }
                  if (!_isValidEmail(email)) {
                    return 'Enter a valid email address.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _passwordController,
                autofillHints: [
                  _isSignUp
                      ? AutofillHints.newPassword
                      : AutofillHints.password,
                ],
                autocorrect: false,
                enableSuggestions: false,
                decoration: InputDecoration(
                  labelText: 'Password',
                  helperText: _isSignUp ? 'Use at least 6 characters.' : null,
                  suffixIcon: IconButton(
                    tooltip: _obscurePassword
                        ? 'Show password'
                        : 'Hide password',
                    onPressed: _isSubmitting
                        ? null
                        : () => setState(() {
                            _obscurePassword = !_obscurePassword;
                          }),
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                  ),
                ),
                obscureText: _obscurePassword,
                textInputAction: _isSignUp
                    ? TextInputAction.next
                    : TextInputAction.done,
                onFieldSubmitted: (_) {
                  if (!_isSubmitting && !_isSignUp) {
                    _submit();
                  }
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Password is required.';
                  }
                  if (value.length < 6) {
                    return 'Password must be at least 6 characters.';
                  }
                  return null;
                },
              ),
              if (_isSignUp) ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _confirmPasswordController,
                  autofillHints: const [AutofillHints.newPassword],
                  autocorrect: false,
                  enableSuggestions: false,
                  decoration: InputDecoration(
                    labelText: 'Confirm password',
                    suffixIcon: IconButton(
                      tooltip: _obscureConfirmPassword
                          ? 'Show confirmation password'
                          : 'Hide confirmation password',
                      onPressed: _isSubmitting
                          ? null
                          : () => setState(() {
                              _obscureConfirmPassword =
                                  !_obscureConfirmPassword;
                            }),
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                    ),
                  ),
                  obscureText: _obscureConfirmPassword,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) {
                    if (!_isSubmitting) {
                      _submit();
                    }
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Confirm your password.';
                    }
                    if (value != _passwordController.text) {
                      return 'Passwords do not match.';
                    }
                    return null;
                  },
                ),
              ],
              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(
                  _errorMessage!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: _isSubmitting ? null : _toggleMode,
                  child: Text(
                    _isSignUp
                        ? 'Already have an account? Sign in'
                        : 'New here? Create account',
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;
      if (_isSignUp) {
        await widget.onSignUp?.call(email: email, password: password);
      } else {
        await widget.onSignIn?.call(email: email, password: password);
      }
      if (mounted) {
        Navigator.of(context).pop();
      }
    } on AuthFailure catch (error) {
      if (mounted) {
        setState(() {
          _errorMessage = _authErrorMessage(error.message);
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _errorMessage = _authErrorMessage(
            humanReadableFormError(
              error,
              resourceName: 'account',
              fallback: '',
            ),
          );
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _clearErrorAfterEdit() {
    if (_errorMessage == null || _isSubmitting) {
      return;
    }

    setState(() {
      _errorMessage = null;
    });
  }

  String _authErrorMessage(String rawMessage) {
    final message = rawMessage.trim();
    final normalized = message.toLowerCase();
    final isGeneric =
        message.isEmpty ||
        normalized == 'error' ||
        normalized == 'exception' ||
        normalized == 'unknown error' ||
        normalized == 'authentication failed.' ||
        normalized.startsWith('exception:') ||
        normalized.startsWith('firebaseexception');

    if (!isGeneric) {
      return message;
    }

    if (_isSignUp) {
      return "We couldn't create your account. Check your email and password, then try again.";
    }

    return "We couldn't sign you in. Check your email and password, then try again.";
  }

  void _toggleMode() {
    setState(() {
      _isSignUp = !_isSignUp;
      _errorMessage = null;
      _passwordController.clear();
      _confirmPasswordController.clear();
      _obscurePassword = true;
      _obscureConfirmPassword = true;
    });
  }

  bool _isValidEmail(String value) {
    final atIndex = value.indexOf('@');
    final lastDotIndex = value.lastIndexOf('.');
    return atIndex > 0 &&
        lastDotIndex > atIndex + 1 &&
        lastDotIndex < value.length - 1;
  }
}

_SyncCardPresentation _syncCardPresentation(
  AppStoreSyncStatus? status, {
  required Color errorColor,
}) {
  final resolvedStatus = status ?? const AppStoreSyncStatus();

  return switch (resolvedStatus.phase) {
    AppStoreSyncPhase.idle => const _SyncCardPresentation(
      message: 'Ready to sync.',
    ),
    AppStoreSyncPhase.syncing => const _SyncCardPresentation(
      message: 'Syncing...',
    ),
    AppStoreSyncPhase.synced => _SyncCardPresentation(
      message:
          'Last synced on ${_formatSyncTimestamp(resolvedStatus.lastSyncedAt)}.',
    ),
    AppStoreSyncPhase.error => _SyncCardPresentation(
      message:
          'Sync error: ${resolvedStatus.lastErrorMessage ?? 'Unknown error.'}',
      messageColor: errorColor,
    ),
  };
}

String _formatSyncTimestamp(DateTime? value) {
  if (value == null) {
    return 'an unknown time';
  }

  final localValue = value.toLocal();
  final month = localValue.month.toString().padLeft(2, '0');
  final day = localValue.day.toString().padLeft(2, '0');
  final hour = localValue.hour.toString().padLeft(2, '0');
  final minute = localValue.minute.toString().padLeft(2, '0');
  return '${localValue.year}-$month-$day $hour:$minute';
}

class _SyncCardPresentation {
  const _SyncCardPresentation({required this.message, this.messageColor});

  final String message;
  final Color? messageColor;
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({
    required this.title,
    required this.children,
    this.columns = 1,
  });

  final String title;
  final List<Widget> children;
  final int columns;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final spacing = columns > 1 ? 12.0 : 0.0;
        final itemWidth = columns > 1
            ? (constraints.maxWidth - spacing) / columns
            : constraints.maxWidth;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: spacing,
              runSpacing: 12,
              children: [
                for (final child in children)
                  SizedBox(width: itemWidth, child: child),
              ],
            ),
          ],
        );
      },
    );
  }
}
