import 'package:flutter/material.dart';
import '../widgets/bottom_nav_bar.dart';
import '../utils/app_styles.dart';
import '../widgets/app_logo.dart';
import 'blurt_feed_screen.dart';
import 'profile_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  int _currentIndex = 1; // Search is index 1 in the bottom nav bar
  final _searchController = TextEditingController();
  bool _isSearching = false;
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() {
        _isSearching = _focusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onNavBarTap(int index) {
    setState(() {
      _currentIndex = index;
    });
    switch (index) {
      case 0: // Home
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const BlurtFeedScreen()),
        );
        break;
      case 1: // Search
        // Already on search page
        break;
      case 2: // Profile
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ProfileScreen()),
        );
        break;
    }
  }

  void _clearSearch() {
    _searchController.clear();
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppStyles.backgroundColor,
      appBar: _buildAppBar(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildSearchBar(),
            const SizedBox(height: 24),
            _isSearching 
                ? const SizedBox() 
                : _buildSuggestions(),
            if (_searchController.text.isNotEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.search,
                        size: 72,
                        color: Colors.grey[700],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Search results for "${_searchController.text}"',
                        style: AppStyles.subheadingStyle,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No results found',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onNavBarTap,
      ),
    );
  }
  
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.transparent,
      title: Row(
        children: [
          const AppLogo(size: 40),
          const SizedBox(width: 10),
          Text(
            'Search',
            style: AppStyles.headingStyle,
          ),
        ],
      ),
    );
  }
  
  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppStyles.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: _isSearching ? AppStyles.cardShadow : null,
      ),
      child: TextField(
        controller: _searchController,
        focusNode: _focusNode,
        decoration: InputDecoration(
          hintText: 'Search for blurts or users...',
          hintStyle: TextStyle(color: Colors.grey[500]),
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey),
                  onPressed: _clearSearch,
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        ),
        style: AppStyles.bodyStyle,
        onChanged: (value) {
          setState(() {});
        },
      ),
    );
  }
  
  Widget _buildSuggestions() {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Trending',
            style: AppStyles.subheadingStyle,
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildTrendingTag('flutter'),
              _buildTrendingTag('technology'),
              _buildTrendingTag('design'),
              _buildTrendingTag('coding'),
              _buildTrendingTag('dart'),
              _buildTrendingTag('mobiledev'),
            ],
          ),
          const SizedBox(height: 32),
          Text(
            'Recent Searches',
            style: AppStyles.subheadingStyle,
          ),
          const SizedBox(height: 16),
          _buildRecentSearch('User handle'),
          _buildRecentSearch('Mobile app design'),
          _buildRecentSearch('Flutter tutorial'),
        ],
      ),
    );
  }
  
  Widget _buildTrendingTag(String tag) {
    return Container(
      decoration: BoxDecoration(
        color: AppStyles.surfaceColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: InkWell(
        onTap: () {
          _searchController.text = tag;
          setState(() {});
        },
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.tag,
                size: 16,
                color: AppStyles.primaryColor,
              ),
              const SizedBox(width: 4),
              Text(
                tag,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildRecentSearch(String search) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          _searchController.text = search;
          setState(() {});
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Icon(
                Icons.history,
                size: 18,
                color: Colors.grey[500],
              ),
              const SizedBox(width: 12),
              Text(
                search,
                style: AppStyles.bodyStyle,
              ),
              const Spacer(),
              Icon(
                Icons.north_west,
                size: 16,
                color: Colors.grey[500],
              ),
            ],
          ),
        ),
      ),
    );
  }
} 