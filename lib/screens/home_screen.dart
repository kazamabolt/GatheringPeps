import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/app_theme.dart';
import '../services/firebase_service.dart';
import 'create_event_screen.dart';
import 'event_details_screen.dart';
import '../widgets/event_card.dart';
import '../widgets/app_logo.dart';
import 'login_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  int _currentTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _currentTabIndex = _tabController.index;
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Home'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // TODO: Implement share functionality
            },
          ),
        ],
      ),
      drawer: _buildDrawer(context),
      body: Column(
        children: [
          // Tab Bar
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: _currentTabIndex == 0
                    ? AppTheme.primaryColor
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              labelColor: _currentTabIndex == 0
                  ? Colors.white
                  : AppTheme.textSecondaryColor,
              unselectedLabelColor: AppTheme.textSecondaryColor,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
              tabs: const [
                Tab(text: 'My Events'),
                Tab(text: 'Participating'),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildMyEventsTab(),
                _buildParticipatingTab(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CreateEventScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildMyEventsTab() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        if (authProvider.currentUser == null) {
          return const Center(child: CircularProgressIndicator());
        }

        return StreamBuilder(
          stream: _getFirebaseService().getUserEventsStream(authProvider.currentUser!.uid),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Error loading events: ${snapshot.error}',
                  style: TextStyle(color: AppTheme.errorColor),
                ),
              );
            }

            final events = snapshot.data ?? [];

            if (events.isEmpty) {
              return _buildEmptyState(
                'No events yet',
                'Create your first event to get started!',
                Icons.event_note,
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: events.length,
              itemBuilder: (context, index) {
                final event = events[index];
                return EventCard(
                  event: event,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EventDetailsScreen(
                          eventId: event.id,
                          isOrganizer: true,
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildParticipatingTab() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        if (authProvider.currentUser == null) {
          return const Center(child: CircularProgressIndicator());
        }

        return StreamBuilder(
          stream: _getFirebaseService().getParticipatingEventsStream(authProvider.currentUser!.uid),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Error loading events: ${snapshot.error}',
                  style: TextStyle(color: AppTheme.errorColor),
                ),
              );
            }

            final events = snapshot.data ?? [];

            if (events.isEmpty) {
              return _buildEmptyState(
                'No participating events',
                'Join events to see them here!',
                Icons.group,
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: events.length,
              itemBuilder: (context, index) {
                final event = events[index];
                return EventCard(
                  event: event,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EventDetailsScreen(
                          eventId: event.id,
                          isOrganizer: false,
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState(String title, String subtitle, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              icon,
              size: 40,
              color: AppTheme.textSecondaryColor,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppTheme.textPrimaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondaryColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  FirebaseService _getFirebaseService() {
    // Return a proper FirebaseService instance
    return FirebaseService();
  }
  
  Widget _buildDrawer(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.userModel;
    
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(user?.name ?? 'User'),
            accountEmail: Text(user?.email ?? ''),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: user?.profileImageUrl != null
                ? ClipOval(
                    child: Image.network(
                      user!.profileImageUrl!,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                    ),
                  )
                : const AppLogo(
                    size: 80,
                    showShadow: false,
                    borderRadius: BorderRadius.all(Radius.circular(40)),
                  ),
            ),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: () {
              Navigator.pop(context); // Close drawer
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () async {
              await authProvider.signOut();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
