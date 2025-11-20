// path: lib/src/ui/widgets/category_item.dart

import 'package:flutter/material.dart';
import '../../models/category.dart';

class CategoryItem extends StatelessWidget {
  final Category category;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const CategoryItem({
    Key? key,
    required this.category,
    this.onTap,
    this.onEdit,
    this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final color = Color(category.colorValue);

    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: color.withOpacity(0.1),
        child: Icon(
          _getIconData(category.iconName),
          color: color,
        ),
      ),
      title: Text(
        category.name,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (onEdit != null)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: onEdit,
            ),
          if (onDelete != null)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: onDelete,
            ),
        ],
      ),
    );
  }

  IconData _getIconData(String iconName) {
    final iconMap = {
      'shopping_cart': Icons.shopping_cart,
      'restaurant': Icons.restaurant,
      'directions_car': Icons.directions_car,
      'home': Icons.home,
      'local_hospital': Icons.local_hospital,
      'school': Icons.school,
      'movie': Icons.movie,
      'flight': Icons.flight,
      'phone': Icons.phone,
      'fitness_center': Icons.fitness_center,
      'attach_money': Icons.attach_money,
      'card_giftcard': Icons.card_giftcard,
    };

    return iconMap[iconName] ?? Icons.category;
  }
}

