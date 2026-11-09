import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Categorías predefinidas de artículos para PresuCompra.
enum ProductCategory {
  alimentos,
  higiene,
  farmacia,
  cosmeticos,
  tecnologia,
  papeleria,
  transporte,
  restaurante,
  otros,
}

/// Metadatos de UI para cada categoría.
class CategoryMeta {
  final ProductCategory category;
  final String label;
  final String emoji;
  final Color color;

  const CategoryMeta({
    required this.category,
    required this.label,
    required this.emoji,
    required this.color,
  });
}

/// Registro central de categorías con sus metadatos visuales.
class Categories {
  Categories._();

  static const List<CategoryMeta> all = [
    CategoryMeta(
      category: ProductCategory.alimentos,
      label: 'Alimentos & Víveres',
      emoji: '🛒',
      color: AppColors.catAlimentos,
    ),
    CategoryMeta(
      category: ProductCategory.higiene,
      label: 'Higiene & Aseo',
      emoji: '🧴',
      color: AppColors.catHigiene,
    ),
    CategoryMeta(
      category: ProductCategory.farmacia,
      label: 'Farmacia & Salud',
      emoji: '💊',
      color: AppColors.catFarmacia,
    ),
    CategoryMeta(
      category: ProductCategory.cosmeticos,
      label: 'Cosméticos & Cuidado',
      emoji: '💄',
      color: AppColors.catCosmeticos,
    ),
    CategoryMeta(
      category: ProductCategory.tecnologia,
      label: 'Tecnología & Hogar',
      emoji: '📱',
      color: AppColors.catTecnologia,
    ),
    CategoryMeta(
      category: ProductCategory.papeleria,
      label: 'Papelería & Estudios',
      emoji: '📚',
      color: AppColors.catPapeleria,
    ),
    CategoryMeta(
      category: ProductCategory.transporte,
      label: 'Transporte & Pasajes',
      emoji: '🚌',
      color: AppColors.catTransporte,
    ),
    CategoryMeta(
      category: ProductCategory.restaurante,
      label: 'Comida & Restaurantes',
      emoji: '🍽️',
      color: AppColors.catRestaurante,
    ),
    CategoryMeta(
      category: ProductCategory.otros,
      label: 'Otros Gastos',
      emoji: '📝',
      color: AppColors.catOtros,
    ),
  ];

  /// Retorna los metadatos de una categoría por enum.
  static CategoryMeta metaOf(ProductCategory category) {
    return all.firstWhere((m) => m.category == category);
  }

  /// Convierte un string a enum (para persistencia DB).
  static ProductCategory fromString(String value) {
    return ProductCategory.values.firstWhere(
      (c) => c.name == value,
      orElse: () => ProductCategory.otros,
    );
  }

  /// Retorna la categoría predeterminada sugerida según el tipo de presupuesto.
  /// Permite que al abrir AddProductModal en "Estudios" se pre-seleccione
  /// Papelería en vez de Alimentos, mejorando la experiencia del usuario.
  static ProductCategory defaultForTipo(dynamic tipo) {
    // tipo es TipoPresupuesto — usamos el nombre del enum para evitar import circular
    switch (tipo.toString().split('.').last) {
      case 'listaMercado':
        return ProductCategory.alimentos;
      case 'estudios':
        return ProductCategory.papeleria;
      case 'viaje':
        return ProductCategory.transporte;
      case 'gastosPersonales':
        return ProductCategory.otros;
      case 'otros':
        return ProductCategory.otros;
      default:
        return ProductCategory.alimentos;
    }
  }

  /// Detecta automáticamente la categoría más adecuada basándose en el nombre
  /// del producto o en el tipo de presupuesto actual.
  static ProductCategory detect({required String productName, dynamic tipoPresupuesto}) {
    final lower = productName.toLowerCase().trim();
    if (lower.isNotEmpty) {
      if (lower.contains('libret') ||
          lower.contains('cuaderno') ||
          lower.contains('lapiz') ||
          lower.contains('lápiz') ||
          lower.contains('boligrafo') ||
          lower.contains('bolígrafo') ||
          lower.contains('libro') ||
          lower.contains('borrador') ||
          lower.contains('sacapunta') ||
          lower.contains('resma') ||
          lower.contains('cartulina') ||
          lower.contains('carpeta') ||
          lower.contains('regla') ||
          lower.contains('marcador') ||
          lower.contains('colores') ||
          lower.contains('tijera') ||
          lower.contains('pega') ||
          lower.contains('estudio') ||
          lower.contains('matricula') ||
          lower.contains('matrícula') ||
          lower.contains('mensualidad') ||
          lower.contains('universidad') ||
          lower.contains('colegio') ||
          lower.contains('fotocopia') ||
          lower.contains('copia')) {
        return ProductCategory.papeleria;
      }
      if (lower.contains('pasaje') ||
          lower.contains('gasolina') ||
          lower.contains('taxi') ||
          lower.contains('metro') ||
          lower.contains('boleto') ||
          lower.contains('peaje') ||
          lower.contains('estacionamiento') ||
          lower.contains('transporte') ||
          lower.contains('vuelo')) {
        return ProductCategory.transporte;
      }
      if (lower.contains('pastilla') ||
          lower.contains('medicina') ||
          lower.contains('jarabe') ||
          lower.contains('remedio') ||
          lower.contains('farmacia') ||
          lower.contains('acetaminof') ||
          lower.contains('ibuprofen') ||
          lower.contains('alcohol') ||
          lower.contains('vitamina') ||
          lower.contains('inyeccion') ||
          lower.contains('inyección')) {
        return ProductCategory.farmacia;
      }
      if (lower.contains('shampoo') ||
          lower.contains('champu') ||
          lower.contains('champú') ||
          lower.contains('jabon') ||
          lower.contains('jabón') ||
          lower.contains('desodorante') ||
          lower.contains('dental') ||
          lower.contains('cloro') ||
          lower.contains('detergente') ||
          lower.contains('higienico') ||
          lower.contains('higiénico')) {
        return ProductCategory.higiene;
      }
      if (lower.contains('maquillaje') ||
          lower.contains('perfume') ||
          lower.contains('labial') ||
          lower.contains('esmalte') ||
          lower.contains('cosmetic')) {
        return ProductCategory.cosmeticos;
      }
      if (lower.contains('cargador') ||
          lower.contains('cable') ||
          lower.contains('audifono') ||
          lower.contains('audífono') ||
          lower.contains('mouse') ||
          lower.contains('teclado') ||
          lower.contains('bateria') ||
          lower.contains('batería') ||
          lower.contains('bombillo') ||
          lower.contains('usb') ||
          lower.contains('celular') ||
          lower.contains('telefono') ||
          lower.contains('teléfono')) {
        return ProductCategory.tecnologia;
      }
      if (lower.contains('almuerzo') ||
          lower.contains('cena') ||
          lower.contains('desayuno') ||
          lower.contains('hamburguesa') ||
          lower.contains('pizza') ||
          lower.contains('restaurante') ||
          lower.contains('empanada') ||
          lower.contains('perro caliente') ||
          lower.contains('combo') ||
          lower.contains('cafe ') ||
          lower.contains('café ')) {
        return ProductCategory.restaurante;
      }
    }

    if (tipoPresupuesto != null) {
      return defaultForTipo(tipoPresupuesto);
    }
    return ProductCategory.alimentos;
  }
}

