import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../utils/notification_service.dart';
import 'authentication/auth_viewmodel.dart';
import 'companies/company_list_screen.dart';
import 'menu/menu_screen.dart';

class HomeScreen extends StatefulWidget {
  final bool isDark;
  final VoidCallback onThemeToggle;
  const HomeScreen({
    super.key,
    required this.isDark,
    required this.onThemeToggle,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _checkingAuth = true;

  @override
  void initState() {
    super.initState();
    _checkAndSignInAnonymously();
  }

  Future<void> _checkAndSignInAnonymously() async {
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    if (authViewModel.user == null) {
      await authViewModel.signInAnonymously();
    }
    setState(() {
      _checkingAuth = false;
    });
  }

  int _selectedIndex = 0;

  void _showLogoutConfirmationSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.logout, size: 40, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                'Are you sure you want to log out?',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      onPressed: () async {
                        Navigator.of(ctx).pop();
                        await Provider.of<AuthViewModel>(context, listen: false).signOut();

                      },
                      child: const Text('Logout', style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Medicine Tracker'),
        centerTitle: false,
        actions: [
          IconButton(
            icon: Icon(isDark ? Icons.wb_sunny : Icons.nights_stay),
            tooltip: isDark ? 'Switch to Light Theme' : 'Switch to Dark Theme',
            onPressed: widget.onThemeToggle,
          ),
          Consumer<AuthViewModel>(
            builder: (context, authViewModel, _) {
              if (!_checkingAuth && authViewModel.isAuthenticated) {
                return IconButton(
                  icon: const Icon(Icons.logout),
                  tooltip: 'Logout',
                  onPressed: () {
                    _showLogoutConfirmationSheet(context);
                  },
                );
              } else {
                return const SizedBox.shrink();
              }
            },
          ),
        ],
      ),
      body: Consumer<AuthViewModel>(
        builder: (context, authViewModel, _) => Column(
          children: [
            if (!_checkingAuth && !authViewModel.isAuthenticated)
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
                child: GestureDetector(
                  onTap: () {
                    // Navigator.of(context).push(
                    //   MaterialPageRoute(
                    //     builder: (context) => SignInScreen(),
                    //   ),
                    // );
                  },
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.yellow[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                    child: RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Colors.black),
                        children: [
                          const TextSpan(text: '🔐 To save and recover your data, please '),
                          TextSpan(
                            text: 'sign in',
                            style: const TextStyle(
                              color: Colors.blue,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                          const TextSpan(text: '!'),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          Expanded(
            child: _getSelectedScreen(_selectedIndex),
          ),
        ],
      )),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2_outlined),
            activeIcon: Icon(Icons.inventory_2),
            label: 'Out of Stock',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.medication_outlined),
            activeIcon: Icon(Icons.medication),
            label: 'Medicines',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            activeIcon: Icon(Icons.people),
            label: 'Representatives',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.business_outlined),
            activeIcon: Icon(Icons.business),
            label: 'Companies',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_outlined),
            activeIcon: Icon(Icons.menu),
            label: 'Menu',
          ),
        ],
      ),
    );
  }

  Widget _getSelectedScreen(int index) {
    switch (index) {
      case 0:
        return const CompanyListScreen();
      case 1:
        return const MenuScreen();
      case 2:
        return const MenuScreen();
      case 3:
        return const MenuScreen();
      case 4:
        return const MenuScreen();
      default:
        return const MenuScreen();
    }
  }
}
