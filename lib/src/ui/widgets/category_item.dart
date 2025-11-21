// path: lib/src/ui/widgets/category_item.dart
import 'package:flutter/material.dart';
import '../../models/category.dart';

class CategoryItem extends StatelessWidget {
  final Category category;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const CategoryItem({
    super.key,
    required this.category,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'shopping_cart':
        return Icons.shopping_cart;
      case 'restaurant':
        return Icons.restaurant;
      case 'directions_car':
        return Icons.directions_car;
      case 'home':
        return Icons.home;
      case 'local_hospital':
        return Icons.local_hospital;
      case 'school':
        return Icons.school;
      case 'flight':
        return Icons.flight;
      case 'movie':
        return Icons.movie;
      case 'fitness_center':
        return Icons.fitness_center;
      case 'attach_money':
        return Icons.attach_money;
      default:
        return Icons.category;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: category.colorHex != null
            ? Color(int.parse('0xFF${category.colorHex!.replaceFirst('#', '')}'))
            : Colors.grey,
        child: Icon(
          category.iconName != null
              ? _getIconData(category.iconName!)
              : Icons.category,
          color: Colors.white,
        ),
      ),
      title: Text(category.name),
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
}

