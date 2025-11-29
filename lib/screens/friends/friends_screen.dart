import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/themes.dart';
import '../../config/routes.dart';
import '../../models/friend.dart';
import '../../providers/auth_provider.dart';
import '../../providers/friend_provider.dart';
import '../../providers/loan_provider.dart';
import '../../utils/formatters.dart';
import '../../widgets/common/common.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.userId;
    if (userId == null) return;

    final friendProvider = Provider.of<FriendProvider>(context, listen: false);
    await friendProvider.loadFriends(userId);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.darkBg,
              Color(0xFF1A1F3A),
              AppColors.darkBg,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _buildSearchBar(),
              Expanded(child: _buildFriendsList()),
            ],
          ),
        ),
      ),
      floatingActionButton: GradientIconButton(
        icon: Icons.person_add,
        size: 56,
        onPressed: () => Navigator.pushNamed(context, Routes.addFriend),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Friends',
            style: TextStyle(
              color: AppColors.textLight,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          Consumer<FriendProvider>(
            builder: (context, friendProvider, child) {
              return Text(
                '${friendProvider.friends.length} friends',
                style: const TextStyle(
                  color: AppColors.textLightSecondary,
                  fontSize: 14,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SearchTextField(
        controller: _searchController,
        hint: 'Search friends...',
        onChanged: (value) => setState(() => _searchQuery = value),
        onClear: () => setState(() => _searchQuery = ''),
      ),
    );
  }

  Widget _buildFriendsList() {
    return Consumer2<FriendProvider, LoanProvider>(
      builder: (context, friendProvider, loanProvider, child) {
        var friends = friendProvider.friends;

        if (_searchQuery.isNotEmpty) {
          friends = friends
              .where((f) =>
                  f.name.toLowerCase().contains(_searchQuery.toLowerCase()))
              .toList();
        }

        if (friends.isEmpty) {
          if (_searchQuery.isNotEmpty) {
            return const NoDataWidget(type: 'search');
          }
          return NoDataWidget(
            type: 'friends',
            onAdd: () => Navigator.pushNamed(context, Routes.addFriend),
          );
        }

        return RefreshIndicator(
          onRefresh: _loadData,
          color: AppColors.accent,
          child: ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: friends.length,
            itemBuilder: (context, index) {
              final friend = friends[index];
              final balance = friendProvider.getNetBalanceForFriend(friend.id!);
              return _buildFriendCard(friend, balance);
            },
          ),
        );
      },
    );
  }

  Widget _buildFriendCard(Friend friend, double balance) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(
        context,
        Routes.friendDetail,
        arguments: friend.id,
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.darkCard,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(
                  friend.name.substring(0, 1).toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.textLight,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    friend.name,
                    style: const TextStyle(
                      color: AppColors.textLight,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (friend.phone != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      friend.phone!,
                      style: const TextStyle(
                        color: AppColors.textLightSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (balance != 0)
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    formatCurrency(balance.abs()),
                    style: TextStyle(
                      color: balance > 0 ? AppColors.income : AppColors.expense,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    balance > 0 ? 'to receive' : 'to pay',
                    style: const TextStyle(
                      color: AppColors.textLightSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
