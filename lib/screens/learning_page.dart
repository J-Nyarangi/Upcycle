import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

class LearningPage extends StatefulWidget {
  @override
  _LearningPageState createState() => _LearningPageState();
}

class _LearningPageState extends State<LearningPage> with SingleTickerProviderStateMixin {
  final List<Map<String, dynamic>> benefits = [
    {
      'title': 'Reduces Waste',
      'description': 'Upcycling keeps items out of landfills, reducing environmental pollution.',
      'icon': Icons.recycling,
    },
    {
      'title': 'Saves Resources',
      'description': 'It uses existing materials, reducing the need for new raw materials.',
      'icon': Icons.eco,
    },
    {
      'title': 'Promotes Creativity',
      'description': 'Encourages innovative ways to repurpose old items into new products.',
      'icon': Icons.brush,
    },
    {
      'title': 'Supports Sustainability',
      'description': 'Contributes to a circular economy by extending the lifecycle of products.',
      'icon': Icons.autorenew,
    },
  ];

  final List<Map<String, dynamic>> didYouKnowFacts = [
    {
      'fact': 'Upcycling can reduce landfill waste by up to 15% annually if widely adopted.',
      'icon': Icons.landscape,
    },
    {
      'fact': 'Upcycling one ton of materials can save up to 3 cubic yards of landfill space.',
      'icon': Icons.delete,
    },
  ];

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 4,
        shadowColor: Colors.black12,
        title: Text(
          'Learning Center',
          style: TextStyle(
            color: Colors.green[900],
            fontSize: 24,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.1,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.green[100]!, width: 2),
              ),
              child: CircleAvatar(
                radius: 18,
                backgroundImage: const NetworkImage(
                  'https://free-images.com/tn/7497/cherry_tree_blossom_2007.jpg',
                ),
                onBackgroundImageError: (exception, stackTrace) {
                  // Handle image loading error
                  print('Failed to load avatar image: $exception');
                },
                child: const Icon(
                  Icons.person,
                  color: Colors.grey,
                  size: 18,
                ), // Fallback icon if image fails to load
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Benefits Section
              Text(
                'Benefits of Upcycling',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Colors.green[900],
                  letterSpacing: 0.5,
                ),
                semanticsLabel: 'Benefits of Upcycling',
              ),
              const SizedBox(height: 16),
              Text(
                'Tap on a benefit to learn more',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
                semanticsLabel: 'Tap on a benefit to learn more',
              ),
              const SizedBox(height: 24),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: benefits.length,
                itemBuilder: (context, index) {
                  final benefit = benefits[index];
                  return FadeTransition(
                    opacity: _fadeAnimation,
                    child: _buildCollapsibleBenefitCard(benefit),
                  );
                },
              ),
              const SizedBox(height: 32),

              // Did You Know Section
              Text(
                'Did You Know?',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Colors.green[900],
                  letterSpacing: 0.5,
                ),
                semanticsLabel: 'Did You Know?',
              ),
              const SizedBox(height: 16),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: didYouKnowFacts.length,
                itemBuilder: (context, index) {
                  final fact = didYouKnowFacts[index];
                  return _buildDidYouKnowCard(fact);
                },
              ),
              
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(context),
    );
  }

  Widget _buildCollapsibleBenefitCard(Map<String, dynamic> benefit) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        collapsedShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        backgroundColor: Colors.white,
        collapsedBackgroundColor: Colors.white,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.green[50],
                shape: BoxShape.circle,
              ),
              child: Icon(
                benefit['icon'],
                color: Colors.green[800],
                size: 24,
                semanticLabel: '${benefit['title']} icon',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                benefit['title'],
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.green[900],
                ),
              ),
            ),
          ],
        ),
        trailing: CircleAvatar(
          radius: 12,
          backgroundColor: Colors.green[100],
          child: Icon(
            Icons.add,
            size: 16,
            color: Colors.green[800],
            semanticLabel: 'Expand',
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 50.0),
            child: Text(
              benefit['description'],
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
                height: 1.4,
              ),
            ),
          ),
        ],
        onExpansionChanged: (expanded) {
          // Announce expansion state for accessibility
          SemanticsService.announce(
            expanded ? '${benefit['title']} expanded' : '${benefit['title']} collapsed',
            TextDirection.ltr,
          );
        },
      ),
    );
  }

  Widget _buildDidYouKnowCard(Map<String, dynamic> fact) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(
                fact['icon'],
                color: Colors.green[800],
                size: 28,
                semanticLabel: 'Fact icon',
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  fact['fact'],
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[800],
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUpcyclingTipCard(Map<String, dynamic> tip) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: InkWell(
          onTap: () {
            // Show a dialog with more details about the tip
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                title: Text(
                  tip['title'],
                  style: TextStyle(
                    color: Colors.green[900],
                    fontWeight: FontWeight.bold,
                  ),
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (tip['image'] != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          tip['image'],
                          height: 150,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            height: 150,
                            color: Colors.grey[300],
                            child: const Icon(Icons.image_not_supported),
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                    Text(
                      tip['description'],
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[800],
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Close',
                      style: TextStyle(color: Colors.green[800]),
                    ),
                  ),
                ],
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey[300],
                  ),
                  child: tip['image'] != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            tip['image'],
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => const Icon(
                              Icons.image_not_supported,
                              color: Colors.grey,
                            ),
                          ),
                        )
                      : const Icon(
                          Icons.lightbulb_outline,
                          color: Colors.grey,
                          size: 28,
                        ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tip['title'],
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.green[900],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        tip['description'],
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.green[800],
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavBar(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: Colors.green[800],
          unselectedItemColor: Colors.grey[600],
          currentIndex: 3,
          selectedLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          showUnselectedLabels: true,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined, size: 28),
              activeIcon: Icon(Icons.home_filled, size: 28),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.camera_alt_outlined, size: 28),
              activeIcon: Icon(Icons.camera_alt, size: 28),
              label: 'Scan',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.shopping_bag_outlined, size: 28),
              activeIcon: Icon(Icons.shopping_bag, size: 28),
              label: 'Market',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.menu_book_outlined, size: 28),
              activeIcon: Icon(Icons.menu_book, size: 28),
              label: 'Learn',
            ),
          ],
          onTap: (index) {
            switch (index) {
              case 0:
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/home',
                  (Route<dynamic> route) => false,
                );
                break;
              case 1:
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/capture_item',
                  (Route<dynamic> route) => false,
                );
                break;
              case 2:
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/marketplace',
                  (Route<dynamic> route) => false,
                );
                break;
              case 3:
                // no navigation needed
                break;
            }
          },
        ),
      ),
    );
  }
}