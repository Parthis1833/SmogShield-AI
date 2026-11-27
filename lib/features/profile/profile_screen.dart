import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/data/family_members_repository.dart';
import '../../core/models/user_profile.dart';
import '../../core/services/firebase_service.dart';
import '../../core/widgets/section_card.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Controllers for personal profile
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _countryController = TextEditingController(text: 'India');
  DateTime? _selectedDob;
  String? _selectedGender;
  bool _isSavingPersonal = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  void _populatePersonalForm(UserPersonalProfile? profile, User? user) {
    if (profile != null) {
      if (_nameController.text.isEmpty && profile.name.isNotEmpty) {
        _nameController.text = profile.name;
      }
      if (_phoneController.text.isEmpty && profile.phone.isNotEmpty) {
        _phoneController.text = profile.phone;
      }
      if (_cityController.text.isEmpty && profile.city.isNotEmpty) {
        _cityController.text = profile.city;
      }
      if (_stateController.text.isEmpty && profile.state.isNotEmpty) {
        _stateController.text = profile.state;
      }
      if (profile.country.isNotEmpty) {
        _countryController.text = profile.country;
      }
      _selectedDob ??= profile.dateOfBirth;
      _selectedGender ??= profile.gender;
    } else if (user != null) {
      if (_nameController.text.isEmpty && (user.displayName?.isNotEmpty ?? false)) {
        _nameController.text = user.displayName!;
      }
    }
  }

  Future<void> _savePersonalProfile(String uid, String email) async {
    setState(() => _isSavingPersonal = true);
    try {
      final updated = UserPersonalProfile(
        uid: uid,
        name: _nameController.text.trim(),
        email: email,
        phone: _phoneController.text.trim(),
        dateOfBirth: _selectedDob,
        gender: _selectedGender,
        city: _cityController.text.trim(),
        state: _stateController.text.trim(),
        country: _countryController.text.trim(),
      );
      await ref.read(familyMembersRepositoryProvider).saveUserProfile(updated);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Personal profile updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save profile: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSavingPersonal = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authUser = ref.watch(authStateProvider).value;
    final isGuest = authUser == null || authUser.isAnonymous;
    final profileAsync = ref.watch(userPersonalProfileProvider);
    final userProfile = profileAsync.value;

    _populatePersonalForm(userProfile, authUser);

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PageHeading(
                    'Profile & Family Health',
                    'Personal details, family members, and health protection',
                    trailing: isGuest
                        ? null
                        : IconButton(
                            tooltip: 'Sign out',
                            icon: const Icon(Icons.logout),
                            onPressed: () async {
                              await ref.read(authServiceProvider).signOut();
                            },
                          ),
                  ),
                  const SizedBox(height: 12),
                  // User Session Overview Card
                  _buildAccountHeader(context, authUser, isGuest, userProfile),
                  const SizedBox(height: 16),
                  TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    tabAlignment: TabAlignment.start,
                    labelColor: theme.colorScheme.primary,
                    unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
                    indicatorColor: theme.colorScheme.primary,
                    indicatorWeight: 3,
                    tabs: const [
                      Tab(icon: Icon(Icons.family_restroom), text: 'Family Members'),
                      Tab(icon: Icon(Icons.person_outline), text: 'Personal Info'),
                      Tab(icon: Icon(Icons.health_and_safety_outlined), text: 'Health & Air'),
                      Tab(icon: Icon(Icons.shield_outlined), text: 'Privacy & Data'),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            // Tab 1: Family Members
            _FamilyMembersTab(isGuest: isGuest, authUser: authUser),

            // Tab 2: Personal Information Form
            _PersonalInfoTab(
              isGuest: isGuest,
              authUser: authUser,
              nameController: _nameController,
              phoneController: _phoneController,
              cityController: _cityController,
              stateController: _stateController,
              countryController: _countryController,
              selectedDob: _selectedDob,
              selectedGender: _selectedGender,
              isSaving: _isSavingPersonal,
              onDobSelected: (dob) => setState(() => _selectedDob = dob),
              onGenderSelected: (gender) => setState(() => _selectedGender = gender),
              onSave: () {
                if (authUser != null && !authUser.isAnonymous) {
                  _savePersonalProfile(authUser.uid, authUser.email ?? '');
                }
              },
            ),

            // Tab 3: Health & Air Guidance Overview
            _HealthAirGuidanceTab(authUser: authUser),

            // Tab 4: Privacy & Data Management
            _PrivacyTab(authUser: authUser, isGuest: isGuest),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountHeader(
    BuildContext context,
    User? user,
    bool isGuest,
    UserPersonalProfile? profile,
  ) {
    final theme = Theme.of(context);
    final displayName = profile?.name.isNotEmpty == true
        ? profile!.name
        : (user?.displayName ?? (isGuest ? 'Guest User' : 'SmogShield Member'));
    final email = user?.email ?? (isGuest ? 'Guest session' : 'Authenticated');
    final ageText = profile?.age != null && profile!.age > 0 ? ' • ${profile.age} yrs' : '';
    final locationText = [profile?.city, profile?.state, profile?.country]
        .where((s) => s != null && s.isNotEmpty)
        .join(', ');

    final avatar = CircleAvatar(
      radius: 28,
      backgroundColor: theme.colorScheme.primaryContainer,
      backgroundImage: user?.photoURL != null ? NetworkImage(user!.photoURL!) : null,
      child: user?.photoURL == null
          ? Icon(
              isGuest ? Icons.person_outline : Icons.person,
              size: 28,
              color: theme.colorScheme.primary,
            )
          : null,
    );

    final userInfo = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                displayName,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (!isGuest) ...[
              const SizedBox(width: 6),
              Icon(Icons.verified, size: 16, color: theme.colorScheme.primary),
            ],
          ],
        ),
        const SizedBox(height: 2),
        Text(
          '$email$ageText',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        if (locationText.isNotEmpty) ...[
          const SizedBox(height: 2),
          Row(
            children: [
              Icon(Icons.location_on, size: 12, color: theme.colorScheme.primary),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  locationText,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 420;
        return SectionCard(
          child: isNarrow
              ? Column(
                  children: [
                    Row(
                      children: [
                        avatar,
                        const SizedBox(width: 14),
                        Expanded(child: userInfo),
                      ],
                    ),
                    if (isGuest) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.tonal(
                          onPressed: () => context.go('/login'),
                          child: const Text('Sign In'),
                        ),
                      ),
                    ],
                  ],
                )
              : Row(
                  children: [
                    avatar,
                    const SizedBox(width: 14),
                    Expanded(child: userInfo),
                    if (isGuest)
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: FilledButton.tonal(
                          onPressed: () => context.go('/login'),
                          child: const Text('Sign In'),
                        ),
                      ),
                  ],
                ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 1: Family Members List & Management
// ─────────────────────────────────────────────────────────────────────────────
class _FamilyMembersTab extends ConsumerWidget {
  final bool isGuest;
  final User? authUser;

  const _FamilyMembersTab({required this.isGuest, required this.authUser});

  void _showAddEditMemberDialog(BuildContext context, WidgetRef ref, [FamilyMember? existing]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _FamilyMemberFormDialog(
        userId: authUser?.uid ?? '',
        existingMember: existing,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final familyAsync = ref.watch(familyMembersStreamProvider);

    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        if (isGuest) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.colorScheme.outline),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Sign in with Google or Email to save family member health profiles securely to Firestore.',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () => context.go('/login'),
                  child: const Text('Sign in'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Header with Add Button
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          runSpacing: 10,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Household Members',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Manage individual health & air-sensitivity profiles',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            FilledButton.icon(
              onPressed: isGuest ? () => context.go('/login') : () => _showAddEditMemberDialog(context, ref),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Member'),
            ),
          ],
        ),
        const SizedBox(height: 16),

        familyAsync.when(
          data: (members) {
            if (members.isEmpty) {
              return SectionCard(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Column(
                    children: [
                      Icon(
                        Icons.group_add_outlined,
                        size: 48,
                        color: theme.colorScheme.primary.withValues(alpha: 0.6),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No family members added yet',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Add children, parents, or spouse with health conditions (like asthma) to get personalized AI smog alerts and routine guidance.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall,
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: isGuest ? () => context.go('/login') : () => _showAddEditMemberDialog(context, ref),
                        icon: const Icon(Icons.add),
                        label: const Text('Add First Family Member'),
                      ),
                    ],
                  ),
                ),
              );
            }

            return Column(
              children: members.map((member) {
                return _FamilyMemberCard(
                  member: member,
                  onEdit: () => _showAddEditMemberDialog(context, ref, member),
                  onDelete: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Delete Member Profile?'),
                        content: Text('Permanently remove ${member.name} and their health data? This cannot be undone.'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                          FilledButton(
                            style: FilledButton.styleFrom(backgroundColor: theme.colorScheme.error),
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true && authUser != null) {
                      await ref.read(familyMembersRepositoryProvider).deleteFamilyMember(authUser!.uid, member.id);
                    }
                  },
                );
              }).toList(),
            );
          },
          loading: () => const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator())),
          error: (e, _) => SectionCard(child: Text('Error loading family members: $e')),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Family Member Card with Health Badge
// ─────────────────────────────────────────────────────────────────────────────
class _FamilyMemberCard extends StatelessWidget {
  final FamilyMember member;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _FamilyMemberCard({
    required this.member,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasAsthma = member.health.hasAsthma;
    final otherConditions = member.health.otherRespiratoryConditions.isNotEmpty ||
        member.health.otherHealthConditions.isNotEmpty;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: hasAsthma ? Colors.amber.shade700 : theme.colorScheme.outlineVariant,
          width: hasAsthma ? 1.5 : 1.0,
        ),
      ),
      elevation: 0,
      color: theme.colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Icon(
                    _iconForRelationship(member.relationship),
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          Text(
                            member.name,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.secondaryContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              member.relationship,
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onSecondaryContainer,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Age: ${member.age} yrs${member.gender != null ? ' • ${member.gender}' : ''}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.edit_outlined, size: 20),
                      onPressed: onEdit,
                      tooltip: 'Edit member',
                    ),
                    IconButton(
                      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                      padding: EdgeInsets.zero,
                      icon: Icon(Icons.delete_outline, size: 20, color: theme.colorScheme.error),
                      onPressed: onDelete,
                      tooltip: 'Delete member',
                    ),
                  ],
                ),
              ],
            ),

            // Health badges section
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                if (hasAsthma)
                  Chip(
                    avatar: const Icon(Icons.air, size: 16, color: Colors.amber),
                    label: Text('Asthma (${member.health.asthmaSeverity})'),
                    backgroundColor: Colors.amber.withValues(alpha: 0.15),
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.amber.shade900,
                    ),
                    side: BorderSide(color: Colors.amber.shade600),
                  ),
                if (member.health.otherRespiratoryConditions.isNotEmpty)
                  Chip(
                    avatar: const Icon(Icons.medical_services_outlined, size: 16),
                    label: Text(member.health.otherRespiratoryConditions),
                    labelStyle: const TextStyle(fontSize: 12),
                  ),
                if (member.health.otherHealthConditions.isNotEmpty)
                  Chip(
                    avatar: const Icon(Icons.healing_outlined, size: 16),
                    label: Text(member.health.otherHealthConditions),
                    labelStyle: const TextStyle(fontSize: 12),
                  ),
                if (!hasAsthma && !otherConditions)
                  Text(
                    'No chronic respiratory conditions declared',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
            ),

            if (member.health.healthNotes.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Notes: ${member.health.healthNotes}',
                  style: theme.textTheme.bodySmall,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _iconForRelationship(String rel) {
    switch (rel.toLowerCase()) {
      case 'father':
      case 'mother':
      case 'grandparent':
        return Icons.elderly;
      case 'son':
      case 'daughter':
        return Icons.child_care;
      case 'spouse':
        return Icons.favorite_border;
      default:
        return Icons.person_outline;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Add / Edit Family Member BottomSheet Dialog
// ─────────────────────────────────────────────────────────────────────────────
class _FamilyMemberFormDialog extends StatefulWidget {
  final String userId;
  final FamilyMember? existingMember;

  const _FamilyMemberFormDialog({
    required this.userId,
    this.existingMember,
  });

  @override
  State<_FamilyMemberFormDialog> createState() => _FamilyMemberFormDialogState();
}

class _FamilyMemberFormDialogState extends State<_FamilyMemberFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _otherRespCtrl;
  late TextEditingController _otherHealthCtrl;
  late TextEditingController _notesCtrl;

  late String _relationship;
  DateTime? _dob;
  String? _gender;
  late bool _hasAsthma;
  late String _asthmaSeverity;
  bool _isSaving = false;

  static const _relationships = [
    'Father',
    'Mother',
    'Spouse',
    'Son',
    'Daughter',
    'Brother',
    'Sister',
    'Grandparent',
    'Other'
  ];

  static const _severities = ['Mild', 'Moderate', 'Severe', 'Unknown'];

  @override
  void initState() {
    super.initState();
    final m = widget.existingMember;
    _nameCtrl = TextEditingController(text: m?.name ?? '');
    _otherRespCtrl = TextEditingController(text: m?.health.otherRespiratoryConditions ?? '');
    _otherHealthCtrl = TextEditingController(text: m?.health.otherHealthConditions ?? '');
    _notesCtrl = TextEditingController(text: m?.health.healthNotes ?? '');
    _relationship = m?.relationship ?? 'Son';
    _dob = m?.dateOfBirth;
    _gender = m?.gender;
    _hasAsthma = m?.health.hasAsthma ?? false;
    _asthmaSeverity = m?.health.asthmaSeverity == 'None' ? 'Mild' : (m?.health.asthmaSeverity ?? 'Mild');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _otherRespCtrl.dispose();
    _otherHealthCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit(BuildContext context) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isSaving = true);

    try {
      final repo = FirestoreFamilyMembersRepository();
      final health = FamilyMemberHealth(
        hasAsthma: _hasAsthma,
        asthmaSeverity: _hasAsthma ? _asthmaSeverity : 'None',
        otherRespiratoryConditions: _otherRespCtrl.text.trim(),
        otherHealthConditions: _otherHealthCtrl.text.trim(),
        healthNotes: _notesCtrl.text.trim(),
        updatedAt: DateTime.now(),
      );

      final member = FamilyMember(
        id: widget.existingMember?.id ?? '',
        name: _nameCtrl.text.trim(),
        relationship: _relationship,
        dateOfBirth: _dob,
        gender: _gender,
        health: health,
        createdAt: widget.existingMember?.createdAt,
      );

      await repo.saveFamilyMember(widget.userId, member);
      if (context.mounted) Navigator.pop(context);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving member: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEdit = widget.existingMember != null;

    return Padding(
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isEdit ? 'Edit Family Member' : 'Add Family Member',
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                ],
              ),
              const SizedBox(height: 16),

              // Full Name
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Full Name *',
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter a name' : null,
              ),
              const SizedBox(height: 14),

              // Relationship Dropdown
              DropdownButtonFormField<String>(
                value: _relationships.contains(_relationship) ? _relationship : 'Other',
                decoration: const InputDecoration(
                  labelText: 'Relationship *',
                  prefixIcon: Icon(Icons.family_restroom),
                  border: OutlineInputBorder(),
                ),
                items: _relationships.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                onChanged: (v) => setState(() => _relationship = v ?? 'Other'),
              ),
              const SizedBox(height: 14),

              // Date of Birth & Gender
              LayoutBuilder(
                builder: (context, constraints) {
                  final isCompact = constraints.maxWidth < 360;
                  final dobButton = OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    ),
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _dob ?? DateTime.now().subtract(const Duration(days: 365 * 10)),
                        firstDate: DateTime(1900),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) setState(() => _dob = picked);
                    },
                    icon: const Icon(Icons.cake_outlined, size: 18),
                    label: Text(
                      _dob != null ? DateFormat('dd MMM yyyy').format(_dob!) : 'Select DOB',
                      overflow: TextOverflow.ellipsis,
                    ),
                  );

                  final genderDropdown = DropdownButtonFormField<String>(
                    value: _gender,
                    decoration: const InputDecoration(
                      labelText: 'Gender',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Male', child: Text('Male')),
                      DropdownMenuItem(value: 'Female', child: Text('Female')),
                      DropdownMenuItem(value: 'Other', child: Text('Other')),
                    ],
                    onChanged: (v) => setState(() => _gender = v),
                  );

                  if (isCompact) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        dobButton,
                        const SizedBox(height: 12),
                        genderDropdown,
                      ],
                    );
                  }

                  return Row(
                    children: [
                      Expanded(child: dobButton),
                      const SizedBox(width: 12),
                      Expanded(child: genderDropdown),
                    ],
                  );
                },
              ),
              const SizedBox(height: 20),

              // ── Health Information Section ──
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: theme.colorScheme.outlineVariant),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.health_and_safety, color: theme.colorScheme.primary, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Health & Respiratory Information',
                          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Optional. Used strictly to provide proactive smog precautions and air purifier recommendations.',
                      style: theme.textTheme.bodySmall,
                    ),
                    const Divider(height: 20),

                    // Asthma Switch
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Does this person have asthma?'),
                      subtitle: const Text('Enables high-AQI respiratory protection alerts'),
                      value: _hasAsthma,
                      activeColor: theme.colorScheme.primary,
                      onChanged: (v) => setState(() => _hasAsthma = v),
                    ),

                    if (_hasAsthma) ...[
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _severities.contains(_asthmaSeverity) ? _asthmaSeverity : 'Mild',
                        decoration: const InputDecoration(
                          labelText: 'Asthma Severity',
                          border: OutlineInputBorder(),
                        ),
                        items: _severities.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                        onChanged: (v) => setState(() => _asthmaSeverity = v ?? 'Mild'),
                      ),
                      const SizedBox(height: 12),
                    ],

                    TextFormField(
                      controller: _otherRespCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Other Respiratory Conditions (optional)',
                        hintText: 'e.g. Bronchitis, Dust Allergy, COPD',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _otherHealthCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Other Relevant Conditions (optional)',
                        hintText: 'e.g. Cardiovascular, Hypertension',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _notesCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Health Notes (optional)',
                        hintText: 'e.g. Sensitive to early morning cold smog',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: _isSaving ? null : () => _submit(context),
                  child: _isSaving
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(isEdit ? 'Save Changes' : 'Add Member'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 2: Personal Information Form
// ─────────────────────────────────────────────────────────────────────────────
class _PersonalInfoTab extends StatelessWidget {
  final bool isGuest;
  final User? authUser;
  final TextEditingController nameController;
  final TextEditingController phoneController;
  final TextEditingController cityController;
  final TextEditingController stateController;
  final TextEditingController countryController;
  final DateTime? selectedDob;
  final String? selectedGender;
  final bool isSaving;
  final ValueChanged<DateTime?> onDobSelected;
  final ValueChanged<String?> onGenderSelected;
  final VoidCallback onSave;

  const _PersonalInfoTab({
    required this.isGuest,
    required this.authUser,
    required this.nameController,
    required this.phoneController,
    required this.cityController,
    required this.stateController,
    required this.countryController,
    required this.selectedDob,
    required this.selectedGender,
    required this.isSaving,
    required this.onDobSelected,
    required this.onGenderSelected,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        if (isGuest) ...[
          SectionCard(
            child: Row(
              children: [
                Icon(Icons.lock_outline, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Sign in to link and persist your personal profile on Firestore cloud storage.',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],

        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Account Information', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('UID: ${authUser?.uid ?? 'guest-local'}', style: theme.textTheme.labelSmall),
              Text('Email: ${authUser?.email ?? 'Not linked'}', style: theme.textTheme.labelSmall),
              const Divider(height: 24),

              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Full Name', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 14),

              TextFormField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Phone Number', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 14),

              // Date of Birth & Gender
              LayoutBuilder(
                builder: (context, constraints) {
                  final isCompact = constraints.maxWidth < 360;
                  final dobBtn = OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    ),
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDob ?? DateTime.now().subtract(const Duration(days: 365 * 25)),
                        firstDate: DateTime(1900),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) onDobSelected(picked);
                    },
                    icon: const Icon(Icons.cake_outlined, size: 18),
                    label: Text(
                      selectedDob != null ? DateFormat('dd MMM yyyy').format(selectedDob!) : 'Select DOB',
                      overflow: TextOverflow.ellipsis,
                    ),
                  );

                  final genderDropdown = DropdownButtonFormField<String>(
                    value: selectedGender,
                    decoration: const InputDecoration(
                      labelText: 'Gender',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Male', child: Text('Male')),
                      DropdownMenuItem(value: 'Female', child: Text('Female')),
                      DropdownMenuItem(value: 'Other', child: Text('Other')),
                    ],
                    onChanged: onGenderSelected,
                  );

                  if (isCompact) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        dobBtn,
                        const SizedBox(height: 12),
                        genderDropdown,
                      ],
                    );
                  }

                  return Row(
                    children: [
                      Expanded(child: dobBtn),
                      const SizedBox(width: 12),
                      Expanded(child: genderDropdown),
                    ],
                  );
                },
              ),
              const SizedBox(height: 14),

              // City, State, Country
              TextFormField(
                controller: cityController,
                decoration: const InputDecoration(labelText: 'City', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 14),
              LayoutBuilder(
                builder: (context, constraints) {
                  final isCompact = constraints.maxWidth < 360;
                  final stateField = TextFormField(
                    controller: stateController,
                    decoration: const InputDecoration(labelText: 'State', border: OutlineInputBorder()),
                  );
                  final countryField = TextFormField(
                    controller: countryController,
                    decoration: const InputDecoration(labelText: 'Country', border: OutlineInputBorder()),
                  );

                  if (isCompact) {
                    return Column(
                      children: [
                        stateField,
                        const SizedBox(height: 12),
                        countryField,
                      ],
                    );
                  }

                  return Row(
                    children: [
                      Expanded(child: stateField),
                      const SizedBox(width: 12),
                      Expanded(child: countryField),
                    ],
                  );
                },
              ),
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: isGuest || isSaving ? null : onSave,
                  child: isSaving
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Save Personal Profile'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 3: Health & Air Guidance Overview
// ─────────────────────────────────────────────────────────────────────────────
class _HealthAirGuidanceTab extends ConsumerWidget {
  final User? authUser;

  const _HealthAirGuidanceTab({required this.authUser});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final familyAsync = ref.watch(familyMembersStreamProvider);

    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.shield_outlined, color: theme.colorScheme.primary),
                  const SizedBox(width: 10),
                  Text(
                    'Family Health Vulnerability Assessment',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'SmogShield AI evaluates family member vulnerability to high PM2.5, ground thermal inversions, and high AQI levels based strictly on declared health information.',
                style: theme.textTheme.bodySmall,
              ),
              const Divider(height: 24),

              familyAsync.when(
                data: (members) {
                  final asthmaticMembers = members.where((m) => m.health.hasAsthma).toList();
                  final seniorMembers = members.where((m) => m.isSenior).toList();
                  final childMembers = members.where((m) => m.isChild).toList();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _vulnerabilityRow(
                        context,
                        'Asthma Risk Protection',
                        asthmaticMembers.isEmpty
                            ? 'No household members have asthma declared.'
                            : '${asthmaticMembers.length} member(s) have declared asthma (${asthmaticMembers.map((m) => m.name).join(", ")}). SmogShield will prioritize N95 and HEPA filtration guidance.',
                        asthmaticMembers.isNotEmpty,
                      ),
                      const SizedBox(height: 12),
                      _vulnerabilityRow(
                        context,
                        'Children (< 18 yrs)',
                        childMembers.isEmpty
                            ? 'No children registered in family profile.'
                            : '${childMembers.length} child(ren) registered. Deep mouth-breathing during recess and sports requires caution when AQI > 150.',
                        childMembers.isNotEmpty,
                      ),
                      const SizedBox(height: 12),
                      _vulnerabilityRow(
                        context,
                        'Seniors (60+ yrs)',
                        seniorMembers.isEmpty
                            ? 'No elderly members registered.'
                            : '${seniorMembers.length} senior member(s) registered. Avoid morning walks between 6–9 AM during winter thermal inversions.',
                        seniorMembers.isNotEmpty,
                      ),
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text('Error loading assessment: $e'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Medical Non-diagnosis disclaimer
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, size: 20, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Important Disclaimer: SmogShield AI provides environmental precautions and indoor clean-air guidance. It does not provide medical diagnoses or prescribe medication. Consult a licensed physician for personal clinical management.',
                  style: theme.textTheme.bodySmall?.copyWith(height: 1.4),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _vulnerabilityRow(BuildContext context, String title, String description, bool isElevated) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          isElevated ? Icons.warning_amber_rounded : Icons.check_circle_outline,
          color: isElevated ? Colors.amber.shade800 : Colors.teal,
          size: 20,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              Text(description, style: theme.textTheme.bodySmall),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 4: Privacy & Security Management
// ─────────────────────────────────────────────────────────────────────────────
class _PrivacyTab extends StatelessWidget {
  final User? authUser;
  final bool isGuest;

  const _PrivacyTab({required this.authUser, required this.isGuest});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.privacy_tip_outlined, color: theme.colorScheme.primary),
                  const SizedBox(width: 10),
                  Text('Data Privacy & Security', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 12),
              _privacyPoint(
                'Strict Ownership Access',
                'Your family health information is stored in private subcollections under users/{userId}/family_members and protected by Firestore Security Rules. Only your authenticated UID can read or modify them.',
              ),
              _privacyPoint(
                'Zero Cross-User Sharing',
                'Family records, asthma statuses, and member ages are never exposed to community challenges or other users.',
              ),
              _privacyPoint(
                'Right to Erasure (Delete)',
                'You can edit or permanently delete any family member record at any time using the trash icon on each card.',
              ),
              _privacyPoint(
                'Voluntary Consent',
                'Entering health details is strictly optional. Health data is only utilized to ground SmogShield AI in protecting your vulnerable loved ones.',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _privacyPoint(String heading, String detail) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(heading, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 2),
          Text(detail, style: const TextStyle(fontSize: 12, height: 1.4)),
        ],
      ),
    );
  }
}
