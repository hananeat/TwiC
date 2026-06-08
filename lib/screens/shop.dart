import 'package:flutter/material.dart';
import 'package:TwiC/utils/app_colors.dart';

// Definizione categorie oggetti del negozio
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

//Acquisti disponibili nel negozio
const _habitats = [
  ShopItem(id: 'habitat_0', name: 'Grassland', emoji: '🌿', price: 0, owned: true),
  ShopItem(id: 'habitat_1', name: 'Desert', emoji: '🏜️', price: 100),
  ShopItem(id: 'habitat_2', name: 'Forest', emoji: '🌲', price: 150),
  ShopItem(id: 'habitat_3', name: 'Beach', emoji: '🏖️', price: 200),
];

const _colorsItems = [
  ShopItem(id: 'color_0', name: 'Yellow', emoji: '🟡', price: 0, owned: true),
  ShopItem(id: 'color_1', name: 'Red', emoji: '🔴', price: 20),
  ShopItem(id: 'color_2', name: 'Blue', emoji: '🔵', price: 30),
  ShopItem(id: 'color_3', name: 'Green', emoji: '🟢', price: 40),
];

const _accessoriesItems = [
  ShopItem(id: 'accessory_1', name: 'Summer Hat', emoji: '👒', price: 30),
  ShopItem(id: 'accessory_2', name: 'Sunglasses', emoji: '🕶️', price: 50),
];

//pagina shop
class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  ShopCategory _currentCategory = ShopCategory.habitat;
  ShopItem? _selectedItem;
  final int _coins = 47;    //sostituire con valore dinamico
 
  List<ShopItem> get _items => switch (_currentCategory) {
        ShopCategory.habitat   => _habitats,
        ShopCategory.colors    => _colorsItems,
        ShopCategory.accessories => _accessoriesItems,
      };
  
  String get _statusMessage {
    final item = _selectedItem;
    if (item == null) return 'Select an item to see details';
    if (item.owned) return 'You already own this item';
    if (item.price <= _coins) return 'You can afford ${item.name}';
    return 'You need ${item.price - _coins} more coins to buy ${item.name}';
  }

  bool get _statusIsPositive {
    final item = _selectedItem;
    if (item == null) return false;
    return item.owned || item.price <= _coins;
  }

  @override
  Widget build(BuildContext context) {
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
                    _buildHeader(),
                    const SizedBox(height: 20),
                    _buildTabs(),
                    const SizedBox(height: 24),
                    _buildGrid(),
                    const SizedBox(height: 12),
                    _buildStatusBar(),
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

  //nome negozio + contatore monete
  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'SHOP',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2,
                color: AppColors.green,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'TwiC\'s Shop',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
              ),
            ),
          ],
        ),
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
                '$_coins',
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
  
  //tabs per categorie
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

  //griglia oggetti
  Widget _buildGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 14,
      mainAxisSpacing: 14,
      childAspectRatio: 1.1,
      children: _items.map((item) => _buildItemCard(item)).toList(),
    );
  }

  //per ogni oggetto, mostra nome, icona, prezzo e stato (acquistato/non)
  Widget _buildItemCard(ShopItem item) {
    final bool isSelected = _selectedItem?.id == item.id;
    final bool locked = !item.owned && item.price > _coins;
 
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
              if (item.owned)
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

  //compare stato dell'oggetto selezionato 
  Widget _buildStatusBar() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: _statusIsPositive ? AppColors.green.withOpacity(0.1) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4),
        ],
      ),
      child: Text(
        _statusMessage,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: _statusIsPositive ? AppColors.green : AppColors.textDark,
        ),
      ),
    );
  }
}