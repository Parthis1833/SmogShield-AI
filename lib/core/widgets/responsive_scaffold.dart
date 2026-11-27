import 'package:flutter/material.dart';

class ResponsiveScaffold extends StatelessWidget {
  const ResponsiveScaffold({
    required this.child,
    required this.location,
    required this.onNavigate,
    super.key,
  });

  final Widget child;
  final String location;
  final ValueChanged<String> onNavigate;

  static const _routes = [
    '/',
    '/assistant',
    '/routine',
    '/impact',
    '/profile',
    '/indoor-air',
    '/community',
    '/settings',
  ];
  static const _labels = [
    'Overview',
    'AI assistant',
    'Daily routine',
    'Eco impact',
    'Family profile',
    'Indoor air',
    'Community',
    'Settings',
  ];
  static const _icons = [
    Icons.air,
    Icons.auto_awesome,
    Icons.event_note,
    Icons.eco_outlined,
    Icons.person_outline,
    Icons.home_outlined,
    Icons.groups_outlined,
    Icons.settings_outlined,
  ];
  static const _mobileRoutes = [
    '/',
    '/assistant',
    '/routine',
    '/impact',
    '/profile'
  ];
  static const _mobileLabels = ['Home', 'AI', 'Routine', 'Impact', 'Family'];
  static const _mobileIcons = [
    Icons.air,
    Icons.auto_awesome,
    Icons.event_note,
    Icons.eco_outlined,
    Icons.person_outline,
  ];

  int get _selectedRouteIndex => _routes.indexOf(location);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 1024 && constraints.maxHeight >= 640) {
          return _desktop(context);
        }
        if (constraints.maxWidth >= 600 && constraints.maxHeight >= 640) {
          return _tablet(context);
        }
        return _mobile(context);
      },
    );
  }

  Widget _mobile(BuildContext context) {
    final theme = Theme.of(context);
    final brand = theme.colorScheme.primary;
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/images/logo.png',
                width: 32,
                height: 32,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => DecoratedBox(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(7),
                    child: Icon(Icons.shield_outlined, size: 18, color: brand),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'SmogShield',
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'More sections',
            onSelected: onNavigate,
            itemBuilder: (context) => [
              _mobileMenuItem(
                '/indoor-air',
                'Indoor air',
                Icons.home_outlined,
              ),
              _mobileMenuItem(
                '/community',
                'Community',
                Icons.groups_outlined,
              ),
              _mobileMenuItem(
                '/settings',
                'Settings',
                Icons.settings_outlined,
              ),
            ],
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: child,
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _mobileSelectedIndex,
        onDestinationSelected: (index) => onNavigate(_mobileRoutes[index]),
        destinations: List.generate(
          _mobileRoutes.length,
          (index) => NavigationDestination(
            icon: Icon(_mobileIcons[index]),
            label: _mobileLabels[index],
          ),
        ),
      ),
    );
  }

  int get _mobileSelectedIndex {
    final index = _mobileRoutes.indexOf(location);
    if (index >= 0) return index;
    return location == '/indoor-air' || location == '/settings' ? 0 : 4;
  }

  Widget _tablet(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Row(
          children: [
            NavigationRail(
              selectedIndex: _selectedRouteIndex < 0 || _selectedRouteIndex > 4
                  ? 0
                  : _selectedRouteIndex,
              onDestinationSelected: (index) => onNavigate(_routes[index]),
              labelType: NavigationRailLabelType.all,
              leading: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: _brandMark(context),
              ),
              trailing: Expanded(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'Indoor air',
                          onPressed: () => onNavigate('/indoor-air'),
                          icon: const Icon(Icons.home_outlined),
                        ),
                        IconButton(
                          tooltip: 'Community',
                          onPressed: () => onNavigate('/community'),
                          icon: const Icon(Icons.groups_outlined),
                        ),
                        IconButton(
                          tooltip: 'Settings',
                          onPressed: () => onNavigate('/settings'),
                          icon: const Icon(Icons.settings_outlined),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              destinations: List.generate(
                5,
                (index) => NavigationRailDestination(
                  icon: Icon(_icons[index]),
                  label: Text(_labels[index]),
                ),
              ),
            ),
            VerticalDivider(width: 1, thickness: 1, color: theme.dividerColor),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: child,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _desktop(BuildContext context) {
    final theme = Theme.of(context);
    final selectedIndex = _selectedRouteIndex;
    return Scaffold(
      body: SafeArea(
        child: Row(
          children: [
            SizedBox(
              width: 248,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  border: Border(right: BorderSide(color: theme.dividerColor)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(22, 24, 16, 28),
                      child: Row(
                        children: [
                          _brandMark(context),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'SmogShield',
                              style: theme.textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(22, 0, 16, 10),
                      child: Text(
                        'SECTIONS',
                        style: theme.textTheme.labelSmall?.copyWith(
                          letterSpacing: 1.1,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: _routes.length,
                        itemBuilder: (context, index) {
                          final selected = selectedIndex == index;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Material(
                              color: theme.colorScheme.surface,
                              borderRadius: BorderRadius.circular(14),
                              child: ListTile(
                                leading: Icon(
                                  _icons[index],
                                  color: selected
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.onSurfaceVariant,
                                ),
                                title: Text(
                                  _labels[index],
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: selected
                                        ? FontWeight.w600
                                        : FontWeight.w500,
                                    color: selected
                                        ? theme.colorScheme.primary
                                        : null,
                                  ),
                                ),
                                selected: selected,
                                selectedTileColor:
                                    theme.colorScheme.primaryContainer,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14)),
                                onTap: () => onNavigate(_routes[index]),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.public_outlined,
                                color: theme.colorScheme.primary, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Know your air. Protect your day.',
                                style: theme.textTheme.bodySmall,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1280),
                  child: child,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _brandMark(BuildContext context) {
    final theme = Theme.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Image.asset(
        'assets/images/logo.png',
        width: 38,
        height: 38,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => DecoratedBox(
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(9),
            child: Icon(Icons.shield_outlined,
                color: theme.colorScheme.primary, size: 22),
          ),
        ),
      ),
    );
  }

  PopupMenuItem<String> _mobileMenuItem(
    String route,
    String label,
    IconData icon,
  ) {
    return PopupMenuItem(
      value: route,
      child: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 12),
          Text(label),
        ],
      ),
    );
  }
}
