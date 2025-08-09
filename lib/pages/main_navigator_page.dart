import 'package:flutter/material.dart';
import 'package:frondend_application_new/pages/profile_page.dart';
import 'package:frondend_application_new/pages/notification_page.dart'; // Import the notification page
import 'cart_page.dart';
import 'dashboard_page.dart';
import 'history_page.dart';
import 'sellers_page.dart';
import 'shop_page.dart';
import 'wishlist_page.dart';
import '../models/user_model.dart';

class MainNavigatorPage extends StatefulWidget {
  final User user;
  final int initialIndex;
  const MainNavigatorPage({
    super.key,
    required this.user,
    this.initialIndex = 0,
  });

  @override
  State<MainNavigatorPage> createState() => _MainNavigatorPageState();
}

class _MainNavigatorPageState extends State<MainNavigatorPage> {
  int _selectedIndex = 0;
  User? _updatedUser;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  Future<void> _navigateToProfile(User currentUser) async {
    // This usage is correct because context is used *before* the await.
    final result = await Navigator.push<User>(
      context,
      MaterialPageRoute(
        builder: (context) => ProfilePage(user: currentUser),
      ),
    );

    // The mounted check correctly guards setState after the await.
    if (result != null && mounted) {
      setState(() {
        _updatedUser = result;
      });
    }
  }

  // FIXED: Removed BuildContext from parameters.
  // The State's own `context` will be used instead.
  Future<void> _showNotifications(User currentUser) async {
    // The await call happens first.
    // FIXED: Changed currentUser.id to currentUser.userId to match the User model.
    List<NotificationItem> fetchedNotifications =
        await fetchNotifications(currentUser.userId);

    // This check ensures the widget is still mounted before using its context.
    if (!mounted) return;

    // Now, it's safe to use the State's `context`.
    await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return NotificationPopUp(
          user: currentUser,
          notifications: fetchedNotifications,
          onMarkAsRead: (notificationId) async {
            final success = await markNotificationAsRead(notificationId);
            if (success && mounted) {
              setState(() {
                final notification = fetchedNotifications.firstWhere(
                    (n) => n.id == notificationId,
                    orElse: () => NotificationItem(
                        id: -1, message: '', timestamp: DateTime.now()));
                if (notification.id != -1) {
                  notification.isRead = true;
                }
              });
            }
          },
          onMarkAllAsRead: () async {
            // FIXED: Changed currentUser.id to currentUser.userId to match the User model.
            final success =
                await markAllNotificationsAsRead(currentUser.userId);
            if (success && mounted) {
              setState(() {
                for (var notification in fetchedNotifications) {
                  notification.isRead = true;
                }
              });
            }
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF667EEA);
    final User currentUser = _updatedUser ?? widget.user;

    final List<Widget> pages = [
      DashboardPage(user: currentUser),
      ShopPage(user: currentUser),
      HistoryPage(user: currentUser),
      SellersPage(user: currentUser),
      WishlistPage(user: currentUser),
    ];

    return Scaffold(
      backgroundColor: primaryColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: primaryColor,
        elevation: 0,
        titleSpacing: 16.0,
        title: InkWell(
          onTap: () => _navigateToProfile(currentUser),
          splashColor: Colors.white.withAlpha(51),
          borderRadius: BorderRadius.circular(8),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.white.withAlpha(77),
                backgroundImage: currentUser.profileImageUrl.isNotEmpty
                    ? NetworkImage(currentUser.profileImageUrl)
                    : null,
                child: currentUser.profileImageUrl.isEmpty
                    ? Text(
                        currentUser.name.isNotEmpty
                            ? currentUser.name[0].toUpperCase()
                            : 'U',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Hi, ${currentUser.name}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Text(
                      'Welcome to Trivo',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.white),
            // FIXED: The call no longer passes `context`.
            onPressed: () => _showNotifications(currentUser),
          ),
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CartPage(user: currentUser),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              blurRadius: 20,
              color: Colors.black.withAlpha(26),
            )
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 8),
            child: BottomNavigationBar(
              items: const <BottomNavigationBarItem>[
                BottomNavigationBarItem(
                  icon: Icon(Icons.home_outlined),
                  activeIcon: Icon(Icons.home),
                  label: 'Home',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.store_outlined),
                  activeIcon: Icon(Icons.store),
                  label: 'Shop',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.history_outlined),
                  activeIcon: Icon(Icons.history),
                  label: 'History',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.storefront_outlined),
                  activeIcon: Icon(Icons.storefront),
                  label: 'Sellers',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.favorite_border),
                  activeIcon: Icon(Icons.favorite),
                  label: 'Wishlist',
                ),
              ],
              currentIndex: _selectedIndex,
              onTap: (index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
              backgroundColor: Colors.white,
              type: BottomNavigationBarType.fixed,
              selectedItemColor: primaryColor,
              unselectedItemColor: Colors.grey[600],
              showUnselectedLabels: true,
              elevation: 0,
            ),
          ),
        ),
      ),
    );
  }
}
