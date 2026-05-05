import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/context/user_profile_context.dart';
import '../../../../shared/dialogs/app_dialog.dart';
import '../../../../shared/dialogs/app_snackbar.dart';
import '../../../../shared/cache/sync_status_controller.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_sync_status_text.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../auth/presentation/bloc/auth_state.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  static const String _deleteAccountPhrase = 'DELETE ACCOUNT';
  Set<String> _credentialTypes = <String>{};
  bool _hasLoadedCredentialSnapshot = false;
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _taxCodeController = TextEditingController();
  String? _avatarUrl;
  bool _isEditingProfile = false;
  bool _isUploadingAvatar = false;

  @override
  void initState() {
    super.initState();
    SyncStatusController().setManualRefreshCallback(_refreshProfileManually);
    context.read<AuthBloc>().add(const LoadCredentialsRequested());
    context.read<AuthBloc>().add(const LoadProfileRequested());
    final profile = UserProfileContext();
    _fullNameController.text = profile.fullName ?? '';
    _avatarUrl = profile.avatarUrl;
  }

  void _refreshProfileManually() {
    context.read<AuthBloc>().add(const LoadCredentialsRequested());
    context.read<AuthBloc>().add(const LoadProfileRequested());
  }

  @override
  void dispose() {
    SyncStatusController().setManualRefreshCallback(null);
    _fullNameController.dispose();
    _taxCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final profile = UserProfileContext();

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is CredentialsLoaded) {
          setState(() {
            _credentialTypes = state.credentialTypes.toSet();
            _hasLoadedCredentialSnapshot = true;
          });
        } else if (state is ProfileLoaded) {
          setState(() {
            if (!_isEditingProfile) {
              _fullNameController.text = state.fullName ?? '';
              _taxCodeController.text = state.taxCode ?? '';
            }
            _avatarUrl = state.avatarUrl;
          });
        } else if (state is ProfileUpdateSuccess) {
          setState(() {
            _isEditingProfile = false;
            _isUploadingAvatar = false;
          });
          AppSnackBar.success(context, state.message);
        } else if (state is ProfileUpdateFailure) {
          setState(() {
            _isUploadingAvatar = false;
          });
          AppSnackBar.error(context, state.message);
        } else if (state is LinkCredentialSuccess) {
          setState(() {
            _credentialTypes = {..._credentialTypes, state.linkedType};
            _hasLoadedCredentialSnapshot = true;
          });
          AppSnackBar.success(context, l10n.translate('profile.link_success'));
          context.read<AuthBloc>().add(const LoadCredentialsRequested());
        } else if (state is LinkPhoneOtpCodeSent) {
          _showPhoneOtpDialog(context, state.phone);
        } else if (state is LinkCredentialFailure) {
          AppSnackBar.error(context, state.message);
        } else if (state is ChangePasswordSuccess) {
          AppSnackBar.success(context, state.message);
        } else if (state is ChangePasswordFailure) {
          AppSnackBar.error(context, state.message);
        } else if (state is DeleteAccountSuccess) {
          AppSnackBar.success(context, state.message);
        } else if (state is DeleteAccountFailure) {
          AppSnackBar.error(context, state.message);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(l10n.translate('profile.title')),
          backgroundColor: AppColors.white,
          foregroundColor: AppColors.textPrimary,
          systemOverlayStyle: SystemUiOverlayStyle.dark,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
            color: Colors.black,
          ),
          bottom: const AppSyncStatusText(),
        ),
        body: SafeArea(
          child: BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              final credentialTypes = _credentialTypes;

              final hasGoogle = credentialTypes.contains('google');
              final hasPhone = credentialTypes.contains('phone');

              return ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: AppSpacing.borderRadiusMd,
                    ),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 32,
                          backgroundColor: AppColors.secondary.withValues(
                            alpha: 0.1,
                          ),
                          backgroundImage:
                              (_avatarUrl != null && _avatarUrl!.isNotEmpty)
                              ? NetworkImage(_avatarUrl!)
                              : null,
                          child: (_avatarUrl == null || _avatarUrl!.isEmpty)
                              ? Text(
                                  ((_fullNameController.text.trim().isNotEmpty
                                              ? _fullNameController.text.trim()
                                              : (profile.fullName ?? 'U'))
                                          .substring(0, 1))
                                      .toUpperCase(),
                                  style: AppTextStyles.titleLarge.copyWith(
                                    color: AppColors.secondary,
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          _fullNameController.text.trim().isEmpty
                              ? (profile.fullName ??
                                    l10n.translate('profile.unknown_user'))
                              : _fullNameController.text.trim(),
                          style: AppTextStyles.titleLarge,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: AppButton(
                          label: l10n.translate('profile.update_avatar'),
                          type: AppButtonType.outlined,
                          isFullWidth: true,
                          isLoading: _isUploadingAvatar,
                          onPressed: _isUploadingAvatar
                              ? null
                              : () => _pickAndUploadAvatar(context),
                        ),
                      ),
                      if ((_avatarUrl ?? '').isNotEmpty) ...[
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: AppButton(
                            label: l10n.translate('profile.remove_avatar'),
                            type: AppButtonType.outlined,
                            isFullWidth: true,
                            onPressed: () {
                              context.read<AuthBloc>().add(
                                const RemoveAvatarRequested(),
                              );
                            },
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10n.translate('profile.edit_profile'),
                          style: AppTextStyles.titleMedium,
                        ),
                      ),
                      if (!_isEditingProfile)
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _isEditingProfile = true;
                            });
                          },
                          child: Text(l10n.translate('common.edit')),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  if (_isEditingProfile) ...[
                    AppTextField(
                      controller: _fullNameController,
                      label: l10n.translate('auth.name'),
                      hintText: l10n.translate('auth.enter_name'),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppTextField(
                      controller: _taxCodeController,
                      label: l10n.translate('profile.tax_code'),
                      hintText: l10n.translate('profile.tax_code_hint'),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        Expanded(
                          child: AppButton(
                            label: l10n.translate('common.cancel'),
                            type: AppButtonType.outlined,
                            isFullWidth: true,
                            onPressed: () {
                              setState(() {
                                _isEditingProfile = false;
                                _fullNameController.text =
                                    profile.fullName ?? '';
                                _taxCodeController.text = profile.taxCode ?? '';
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: AppButton(
                            label: l10n.translate('common.save'),
                            isFullWidth: true,
                            onPressed: () {
                              context.read<AuthBloc>().add(
                                UpdateProfileRequested(
                                  fullName: _fullNameController.text.trim(),
                                  taxCode: _taxCodeController.text.trim(),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    _buildInfoView(
                      label: l10n.translate('auth.name'),
                      value: _fullNameController.text.trim().isEmpty
                          ? l10n.translate('profile.unknown_user')
                          : _fullNameController.text.trim(),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _buildInfoView(
                      label: l10n.translate('profile.tax_code'),
                      value: _taxCodeController.text.trim().isEmpty
                          ? l10n.translate('common.no_data')
                          : _taxCodeController.text.trim(),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    l10n.translate('profile.linked_credentials'),
                    style: AppTextStyles.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  if (!_hasLoadedCredentialSnapshot &&
                      state is CredentialsLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                      child: Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  else ...[
                    _CredentialTile(
                      title: l10n.translate('profile.credential_google'),
                      isLinked: hasGoogle,
                      onLink: hasGoogle
                          ? null
                          : () {
                              context.read<AuthBloc>().add(
                                const LinkGoogleRequested(),
                              );
                            },
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _CredentialTile(
                      title: l10n.translate('profile.credential_phone'),
                      isLinked: hasPhone,
                      onLink: hasPhone
                          ? null
                          : () => _showLinkPhoneSheet(context),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    l10n.translate('profile.security'),
                    style: AppTextStyles.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppButton(
                    label: l10n.translate('profile.change_password'),
                    isFullWidth: true,
                    type: AppButtonType.outlined,
                    onPressed: () => _showChangePasswordSheet(context),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  AppButton(
                    label: l10n.translate('profile.delete_account'),
                    isFullWidth: true,
                    type: AppButtonType.danger,
                    onPressed: () => _showDeleteAccountFlow(context),
                  ),
                  if ((state is CredentialsLoading &&
                          !_hasLoadedCredentialSnapshot) ||
                      state is ProfileLoading ||
                      state is LinkCredentialInProgress ||
                      state is ChangePasswordInProgress ||
                      state is DeleteAccountInProgress)
                    const Padding(
                      padding: EdgeInsets.only(top: AppSpacing.lg),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _pickAndUploadAvatar(BuildContext context) async {
    final picker = ImagePicker();
    final l10n = AppLocalizations.of(context);
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (sheetCtx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: Text(l10n.translate('common.source_camera')),
              onTap: () => Navigator.of(sheetCtx).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(l10n.translate('common.source_gallery')),
              onTap: () => Navigator.of(sheetCtx).pop(ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;

    final selected = await picker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1600,
    );

    if (selected == null || !context.mounted) return;

    setState(() {
      _isUploadingAvatar = true;
    });

    context.read<AuthBloc>().add(
      UpdateAvatarRequested(avatarPath: selected.path),
    );
  }

  Widget _buildInfoView({required String label, required String value}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: AppSpacing.borderRadiusSm,
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.labelMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(value, style: AppTextStyles.bodyMedium),
        ],
      ),
    );
  }

  void _showChangePasswordSheet(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final currentController = TextEditingController();
    final newController = TextEditingController();
    final confirmController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    var autoValidate = false;
    var isSubmitting = false;
    String? serverError;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        final mediaQuery = MediaQuery.of(sheetContext);
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return BlocListener<AuthBloc, AuthState>(
              listenWhen: (previous, current) =>
                  current is ChangePasswordSuccess ||
                  current is ChangePasswordFailure,
              listener: (context, state) {
                if (state is ChangePasswordSuccess) {
                  if (!sheetContext.mounted) return;
                  Navigator.of(sheetContext).pop();
                  return;
                }

                if (state is ChangePasswordFailure) {
                  if (!sheetContext.mounted) return;
                  setSheetState(() {
                    isSubmitting = false;
                    serverError = state.message;
                  });
                }
              },
              child: SafeArea(
                top: false,
                child: SingleChildScrollView(
                  padding: EdgeInsets.only(
                    left: AppSpacing.lg,
                    right: AppSpacing.lg,
                    top: AppSpacing.lg,
                    bottom:
                        mediaQuery.viewInsets.bottom +
                        mediaQuery.padding.bottom +
                        AppSpacing.xl,
                  ),
                  child: Form(
                    key: formKey,
                    autovalidateMode: autoValidate
                        ? AutovalidateMode.onUserInteraction
                        : AutovalidateMode.disabled,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          l10n.translate('profile.change_password'),
                          style: AppTextStyles.titleMedium,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        AppPasswordField(
                          controller: currentController,
                          label: l10n.translate('auth.current_password'),
                          hintText: l10n.translate('auth.enter_password'),
                          onChanged: (_) {
                            if (serverError != null) {
                              setSheetState(() {
                                serverError = null;
                              });
                            }
                          },
                          validator: (value) {
                            if ((value ?? '').trim().isEmpty) {
                              return l10n.translate('auth.password_required');
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppSpacing.md),
                        AppPasswordField(
                          controller: newController,
                          label: l10n.translate('auth.new_password'),
                          hintText: l10n.translate('auth.enter_password'),
                          onChanged: (_) {
                            if (serverError != null) {
                              setSheetState(() {
                                serverError = null;
                              });
                            }
                            if (autoValidate) {
                              formKey.currentState?.validate();
                            }
                          },
                          validator: (value) {
                            final trimmed = (value ?? '').trim();
                            if (trimmed.isEmpty) {
                              return l10n.translate('auth.password_required');
                            }
                            if (trimmed.length < 8) {
                              return l10n.translate(
                                'auth.password_min_length_8',
                              );
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppSpacing.md),
                        AppPasswordField(
                          controller: confirmController,
                          label: l10n.translate('auth.confirm_password'),
                          hintText: l10n.translate('auth.confirm_password'),
                          onChanged: (_) {
                            if (serverError != null) {
                              setSheetState(() {
                                serverError = null;
                              });
                            }
                            if (autoValidate) {
                              formKey.currentState?.validate();
                            }
                          },
                          validator: (value) {
                            final confirm = (value ?? '').trim();
                            if (confirm.isEmpty) {
                              return l10n.translate('auth.password_required');
                            }
                            if (confirm != newController.text.trim()) {
                              return l10n.translate('auth.passwords_not_match');
                            }
                            return null;
                          },
                        ),
                        if (serverError != null) ...[
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            serverError!,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.danger,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                        const SizedBox(height: AppSpacing.lg),
                        AppButton(
                          label: l10n.translate('common.confirm'),
                          isFullWidth: true,
                          isLoading: isSubmitting,
                          onPressed: isSubmitting
                              ? null
                              : () {
                                  setSheetState(() {
                                    autoValidate = true;
                                    serverError = null;
                                  });
                                  final valid =
                                      formKey.currentState?.validate() ?? false;
                                  if (!valid) return;

                                  final current = currentController.text.trim();
                                  final next = newController.text.trim();

                                  setSheetState(() {
                                    isSubmitting = true;
                                  });

                                  context.read<AuthBloc>().add(
                                    ChangePasswordRequested(
                                      currentPassword: current,
                                      newPassword: next,
                                    ),
                                  );
                                },
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
    ).whenComplete(() {
      // Delay dispose to next frame so TextFormField listeners are fully detached.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        currentController.dispose();
        newController.dispose();
        confirmController.dispose();
      });
    });
  }

  Future<void> _showDeleteAccountFlow(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final passwordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final phraseController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    var autoValidate = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        final mediaQuery = MediaQuery.of(sheetContext);
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              top: false,
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  left: AppSpacing.lg,
                  right: AppSpacing.lg,
                  top: AppSpacing.lg,
                  bottom:
                      mediaQuery.viewInsets.bottom +
                      mediaQuery.padding.bottom +
                      AppSpacing.xl,
                ),
                child: Form(
                  key: formKey,
                  autovalidateMode: autoValidate
                      ? AutovalidateMode.onUserInteraction
                      : AutovalidateMode.disabled,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.translate('profile.delete_account'),
                        style: AppTextStyles.titleMedium.copyWith(
                          color: AppColors.danger,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        l10n.translate('profile.delete_account_password_note'),
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppPasswordField(
                        controller: passwordController,
                        label: l10n.translate('auth.password'),
                        hintText: l10n.translate('auth.enter_password'),
                        onChanged: (_) {
                          if (autoValidate) {
                            formKey.currentState?.validate();
                          }
                        },
                        validator: (value) {
                          if ((value ?? '').trim().isEmpty) {
                            return l10n.translate('auth.password_required');
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppPasswordField(
                        controller: confirmPasswordController,
                        label: l10n.translate('auth.confirm_password'),
                        hintText: l10n.translate('auth.confirm_password'),
                        onChanged: (_) {
                          if (autoValidate) {
                            formKey.currentState?.validate();
                          }
                        },
                        validator: (value) {
                          final confirm = (value ?? '').trim();
                          if (confirm.isEmpty) {
                            return l10n.translate('auth.password_required');
                          }
                          if (confirm != passwordController.text.trim()) {
                            return l10n.translate('auth.passwords_not_match');
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppTextField(
                        controller: phraseController,
                        label: _deleteAccountPhrase,
                        hintText: _deleteAccountPhrase,
                        helperText: l10n
                            .translate('profile.delete_account_phrase_hint')
                            .replaceAll('{phrase}', _deleteAccountPhrase),
                        textInputAction: TextInputAction.done,
                        onChanged: (_) {
                          if (autoValidate) {
                            formKey.currentState?.validate();
                          }
                        },
                        validator: (value) {
                          final phrase = (value ?? '').trim().toUpperCase();
                          if (phrase.isEmpty) {
                            return l10n.translate(
                              'profile.delete_account_phrase_invalid',
                            );
                          }
                          if (phrase != _deleteAccountPhrase) {
                            return l10n.translate(
                              'profile.delete_account_phrase_invalid',
                            );
                          }
                          return null;
                        },
                        onSubmitted: (_) {
                          setSheetState(() {
                            autoValidate = true;
                          });
                          final valid =
                              formKey.currentState?.validate() ?? false;
                          if (!valid) return;

                          Navigator.of(sheetContext).pop();
                        },
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      AppButton(
                        label: l10n.translate(
                          'profile.delete_account_final_action',
                        ),
                        isFullWidth: true,
                        type: AppButtonType.danger,
                        onPressed: () {
                          setSheetState(() {
                            autoValidate = true;
                          });
                          final valid =
                              formKey.currentState?.validate() ?? false;
                          if (!valid) return;

                          Navigator.of(sheetContext).pop();
                        },
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

    final password = passwordController.text.trim();
    final phrase = phraseController.text.trim().toUpperCase();
    passwordController.dispose();
    confirmPasswordController.dispose();
    phraseController.dispose();
    if (password.isEmpty ||
        phrase != _deleteAccountPhrase ||
        !context.mounted) {
      return;
    }

    context.read<AuthBloc>().add(DeleteAccountRequested(password: password));
  }

  void _showLinkPhoneSheet(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final phoneController = TextEditingController();
    final passwordController = TextEditingController();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        final mediaQuery = MediaQuery.of(sheetContext);
        return SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.only(
              left: AppSpacing.lg,
              right: AppSpacing.lg,
              top: AppSpacing.lg,
              bottom:
                  mediaQuery.viewInsets.bottom +
                  mediaQuery.padding.bottom +
                  AppSpacing.xl,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.translate('profile.link_phone'),
                  style: AppTextStyles.titleMedium,
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  controller: phoneController,
                  label: l10n.translate('auth.phone'),
                  hintText: l10n.translate('auth.enter_phone'),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  controller: passwordController,
                  label: l10n.translate('auth.password'),
                  hintText: l10n.translate('auth.enter_password'),
                  obscureText: true,
                ),
                const SizedBox(height: AppSpacing.lg),
                AppButton(
                  label: l10n.translate('common.confirm'),
                  isFullWidth: true,
                  onPressed: () {
                    final phone = phoneController.text.trim();
                    final password = passwordController.text.trim();
                    if (phone.isEmpty) {
                      AppSnackBar.warning(
                        context,
                        l10n.translate('common.required_field'),
                      );
                      return;
                    }

                    context.read<AuthBloc>().add(
                      StartLinkPhoneRequested(
                        phone: phone,
                        password: password.isEmpty ? null : password,
                      ),
                    );
                    Navigator.of(sheetContext).pop();
                  },
                ),
              ],
            ),
          ),
        );
      },
    ).whenComplete(() {
      phoneController.dispose();
      passwordController.dispose();
    });
  }

  void _showPhoneOtpDialog(BuildContext context, String phone) {
    final l10n = AppLocalizations.of(context);
    final controllers = List.generate(6, (_) => TextEditingController());
    final focusNodes = List.generate(6, (_) => FocusNode());

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        final mediaQuery = MediaQuery.of(sheetContext);
        return SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
              left: AppSpacing.lg,
              right: AppSpacing.lg,
              top: AppSpacing.lg,
              bottom:
                  mediaQuery.viewInsets.bottom +
                  mediaQuery.padding.bottom +
                  AppSpacing.xl,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.translate('auth.verify_otp_title'),
                  style: AppTextStyles.titleMedium,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  l10n
                      .translate('auth.otp_sent_to')
                      .replaceAll('{phone}', phone),
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(6, (index) {
                    return SizedBox(
                      width: 46,
                      child: TextField(
                        controller: controllers[index],
                        focusNode: focusNodes[index],
                        maxLength: 1,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        textDirection: TextDirection.ltr,
                        style: AppTextStyles.titleLarge.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                        inputFormatters: [
                          ...?AppInputFormatters.withSqlInjectionGuard(
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                          ),
                        ],
                        decoration: const InputDecoration(counterText: ''),
                        onChanged: (value) {
                          if (value.isNotEmpty && index < 5) {
                            focusNodes[index + 1].requestFocus();
                          } else if (value.isEmpty && index > 0) {
                            focusNodes[index - 1].requestFocus();
                          }
                        },
                      ),
                    );
                  }),
                ),
                const SizedBox(height: AppSpacing.lg),
                AppButton(
                  label: l10n.translate('common.confirm'),
                  isFullWidth: true,
                  onPressed: () {
                    final otp = controllers.map((e) => e.text).join().trim();
                    if (otp.length != 6) {
                      AppSnackBar.warning(
                        context,
                        l10n.translate('auth.otp_incomplete'),
                      );
                      return;
                    }

                    context.read<AuthBloc>().add(
                      SubmitLinkPhoneOtpRequested(smsCode: otp),
                    );
                    Navigator.of(sheetContext).pop();
                  },
                ),
                const SizedBox(height: AppSpacing.sm),
                TextButton(
                  onPressed: () {
                    context.read<AuthBloc>().add(
                      const ResendLinkPhoneOtpRequested(),
                    );
                  },
                  child: Text(l10n.translate('auth.resend_otp')),
                ),
              ],
            ),
          ),
        );
      },
    ).whenComplete(() {
      for (final c in controllers) {
        c.dispose();
      }
      for (final node in focusNodes) {
        node.dispose();
      }
    });
  }
}

class _CredentialTile extends StatelessWidget {
  final String title;
  final bool isLinked;
  final VoidCallback? onLink;

  const _CredentialTile({
    required this.title,
    required this.isLinked,
    required this.onLink,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: AppSpacing.borderRadiusMd,
      ),
      child: Row(
        children: [
          Expanded(child: Text(title, style: AppTextStyles.bodyMedium)),
          Text(
            isLinked
                ? l10n.translate('profile.already_linked')
                : l10n.translate('profile.not_linked'),
            style: AppTextStyles.labelSmall.copyWith(
              color: isLinked ? AppColors.success : AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          if (!isLinked && onLink != null)
            TextButton(
              onPressed: onLink,
              child: Text(l10n.translate('profile.link_now')),
            ),
        ],
      ),
    );
  }
}
