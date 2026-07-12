import 'package:flutter/material.dart';
import 'package:TwiC/utils/app_colors.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';

// Shop item category definitions
enum ShopCategory { habitat, colors, accessories }
 
class ShopItem {
  final String id;
  final String name;
  final String emoji;
  final int price;
  final bool owned;
 
  const ShopItem({
    required this.id,
    required this.name,
    required this.emoji,
    required this.price,
    this.owned = false,
  });
}

// Available shop items grouped by category
const _habitats = [
  ShopItem(id: 'habitat_0', name: 'Grassland', emoji: '🌿', price: 0, owned: true),
  ShopItem(id: 'habitat_1', name: 'Desert', emoji: '🏜️', price: 1500),
  ShopItem(id: 'habitat_2', name: 'Forest', emoji: '🌲', price: 1500),
  ShopItem(id: 'habitat_3', name: 'Beach', emoji: '🏖️', price: 3000),
];

const _colorsItems = [
  ShopItem(id: 'color_0', name: 'Yellow', emoji: '🟡', price: 0, owned: true),
  ShopItem(id: 'color_1', name: 'Red', emoji: '🔴', price: 20),
  ShopItem(id: 'color_2', name: 'Blue', emoji: '🔵', price: 30),
  ShopItem(id: 'color_3', name: 'Green', emoji: '🟢', price: 40),
];

const _accessoriesItems = [
  ShopItem(id: 'accessory_1', name: 'Summer Hat', emoji: '👒', price: 500),
  ShopItem(id: 'accessory_2', name: 'Sunglasses', emoji: '🕶️', price: 600),
];

// Shop screen widget
class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

// State of the shop screen
class _ShopScreenState extends State<ShopScreen> {
  ShopCategory _currentCategory = ShopCategory.habitat; // Default selected category
  ShopItem? _selectedItem;  
 
  List<ShopItem> get _items => switch (_currentCategory) {
        ShopCategory.habitat   => _habitats,
        ShopCategory.colors    => _colorsItems,
        ShopCategory.accessories => _accessoriesItems,
      };

  @override
  Widget build(BuildContext context) {
    // Reads values from the provider and automatically rebuilds when they change
    final userProvider = context.watch<UserProvider>();
    final int coins = userProvider.stars; 

    // Build the shop screen UI
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    _buildHeader(userProvider.chickName, coins),
                    const SizedBox(height: 20),
                    _buildTabs(),
                    const SizedBox(height: 24),
                    _buildGrid(coins, userProvider),
                    const SizedBox(height: 12),
                    _buildActionBar(coins, userProvider),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Shop name + coin counter
  Widget _buildHeader(String chickName, int coins) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              const Text(
                'TwiC\'s Shop',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                ), 
              ),
              Text(
                'Personalize $chickName and make it unique as you are!',
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF7A78A0),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.yellow.withOpacity(0.25),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.yellow),
          ),
          child: Row(
            children: [
              const Text('⭐', style: TextStyle(fontSize: 15)),
              const SizedBox(width: 4),
              Text(
                '$coins',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  // Tab bar with the available shop categories; highlights the selected one
  Widget _buildTabs() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.yellow,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: ShopCategory.values.map((cat) {
          final bool active = _currentCategory == cat;
          final label = switch (cat) {
            ShopCategory.habitat   => 'Habitat',
            ShopCategory.colors    => 'Colors',
            ShopCategory.accessories => 'Accessories',
          };
          return Expanded(
            child: GestureDetector(
              // Updates the selected category and deselects the current item
              // to prevent an item from one category staying selected when switching to another
              onTap: () => setState(() {
                _currentCategory = cat;
                _selectedItem = null;
              }),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: active ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(11),
                  boxShadow: active
                      ? const [BoxShadow(color: Colors.black12, blurRadius: 4)]
                      : const [],
                ),
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: active ? AppColors.textDark : const Color(0xFF7A6800),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // Grid displaying the available items in the selected category
  Widget _buildGrid(int coins, UserProvider userProvider) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(), // Grid delegates scrolling entirely to the parent container
      crossAxisSpacing: 14,
      mainAxisSpacing: 14,
      childAspectRatio: 1.1,
      children: _items.map((item) => _buildItemCard(item, coins, userProvider)).toList(),
    );
  }

  // Checks if the item is owned by default or has been purchased by the user
  bool _isOwned(ShopItem item, UserProvider userProvider) {
    return item.owned || userProvider.ownedItems.contains(item.id);
  }
  
  // For each item, displays name, icon, price, and status (owned/not owned)
  Widget _buildItemCard(ShopItem item, int coins, UserProvider userProvider) {
    final bool isSelected = _selectedItem?.id == item.id;
    final bool isOwned = _isOwned(item, userProvider);
    final bool locked = !isOwned && item.price > coins;
 
    return GestureDetector(
      onTap: () => setState(() => _selectedItem = item),
      child: Opacity(
        opacity: locked ? 0.5 : 1.0,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.green.withOpacity(0.1) : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isSelected ? AppColors.green : Colors.transparent,
              width: isSelected ? 1.5 : 0,
            ),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 6),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text( item.emoji, style: const TextStyle(fontSize: 40) ),
              const Spacer(),
              Text(
                item.name,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.green,
                ),
              ),
              const SizedBox(height: 3),
              // If the item belongs to the colors category (and is not yellow) show "coming soon"
              if (_currentCategory == ShopCategory.colors && !isOwned)
                const Text(
                  '🔒 Coming Soon',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey,
                  ),
                )
              else if (isOwned)
                const Text(
                  '✓ Unlocked',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                )
              else
                Row(
                  children: [
                    const Text(
                      '⭐ ',
                      style: TextStyle(color: AppColors.yellow, fontSize: 14),
                    ),
                    Text(
                      '${item.price}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  // Shows the status of the selected item
  Widget _buildActionBar(int coins, UserProvider userProvider) {
  final item = _selectedItem;
  if (_currentCategory == ShopCategory.colors && _selectedItem != null && !_isOwned(_selectedItem!, userProvider)) {
    return _actionContainer(
      color: Colors.grey.withOpacity(0.1),
      child: const Text(
        '🔒 Coming Soon',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.grey),
      ),
    );
  }
  
  // Shows a message based on the selected item's status and available coins
  if (item == null) {
    return _actionContainer(
        color: Colors.white,
        child: const Text(
          'Select an item to see details',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark),
        ),
    );
  }
  final bool isOwned = _isOwned(item, userProvider);
  // Determines if the item is equipped by checking the corresponding provider property
  bool isEquipped = false;
  if (_currentCategory == ShopCategory.habitat) {
    isEquipped = userProvider.equippedBackground == item.id;
  } else if (_currentCategory == ShopCategory.accessories) {
    isEquipped = userProvider.equippedAccessory == item.id;
  } else if (_currentCategory == ShopCategory.colors) {
    final effectiveColor = userProvider.equippedColor ?? 'color_0';
    isEquipped = effectiveColor == item.id;
  }
  if (isEquipped) {
    // Default items (habitat_0 and color_0) cannot be unequipped
    final bool isDefault = item.id == 'habitat_0' || item.id == 'color_0';
    return _actionContainer(
      color: AppColors.green.withOpacity(0.12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle_rounded, color: AppColors.green, size: 18),
          const SizedBox(width: 8),
          const Text('Equipped', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.green)),
          if (!isDefault) ...[
            const SizedBox(width: 16),
            GestureDetector(
              onTap: () {
                if (_currentCategory == ShopCategory.accessories) {
                  userProvider.equipAccessory(null);
                } else if (_currentCategory == ShopCategory.colors) {
                  userProvider.equipColor('color_0');
                } else if (_currentCategory == ShopCategory.habitat) {
                  userProvider.equipBackground('habitat_0');
                }
                setState(() {});
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: const Text(
                  'Unequip',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.red),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
  if (isOwned) {
    return GestureDetector(
      onTap: () {
        if (_currentCategory == ShopCategory.habitat) {
          userProvider.equipBackground(item.id);
        } else if (_currentCategory == ShopCategory.accessories) {
          userProvider.equipAccessory(item.id);
        } else if (_currentCategory == ShopCategory.colors) {
          userProvider.equipColor(item.id);
        }
        setState(() {});
      },
      child: _actionContainer(
        color: AppColors.purple.withOpacity(0.1),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.checkroom_rounded, color: AppColors.purple, size: 18),
            SizedBox(width: 8),
            Text('Equip', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.purple)),
          ],
        ),
      ),
    );
  }
  if (item.price <= coins) {
    return GestureDetector(
      onTap: () async {
        await userProvider.buyItem(item.id, item.price);
        setState(() {});
      },
      child: _actionContainer(
        color: AppColors.yellow.withOpacity(0.2),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('⭐', style: TextStyle(fontSize: 16)),
            const SizedBox(width: 6),
            Text('Buy for ${item.price}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textDark)),
          ],
        ),
      ),
    );
  }
  return _actionContainer(
    color: Colors.white,
    child: Text(
      'Need ${item.price - coins} more ⭐ to buy ${item.name}',
      textAlign: TextAlign.center,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey),
    ),
  );
}

// Container widget for the selected item's status message
Widget _actionContainer({required Color color, required Widget child}) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)],
    ),
    child: child,
  );
}
}