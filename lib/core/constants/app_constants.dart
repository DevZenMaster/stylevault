class AppConstants {
  // Collection names in Firestore
  static const String usersCollection = 'users';
  static const String productsCollection = 'products';
  static const String ordersCollection = 'orders';
  static const String cartCollection = 'cart';

  // Categories
  static const List<String> categories = [
    'All',
    'Men',
    'Women',
    'Kids',
    'Accessories',
    'Footwear',
    'Sports',
  ];

  // Firestore fields
  static const String fieldName = 'name';
  static const String fieldEmail = 'email';
  static const String fieldPrice = 'price';
  static const String fieldCategory = 'category';
  static const String fieldStock = 'stock';
  static const String fieldImageUrl = 'imageUrl';
  static const String fieldDescription = 'description';
  static const String fieldCreatedAt = 'createdAt';
  static const String fieldUserId = 'userId';
  static const String fieldStatus = 'status';
  static const String fieldTotal = 'total';
  static const String fieldItems = 'items';

  // Order statuses
  static const String orderPending = 'Pending';
  static const String orderProcessing = 'Processing';
  static const String orderShipped = 'Shipped';
  static const String orderDelivered = 'Delivered';

  // Padding
  static const double paddingXS = 4;
  static const double paddingS = 8;
  static const double paddingM = 16;
  static const double paddingL = 24;
  static const double paddingXL = 32;
  static const double paddingXXL = 48;

  // Border radius
  static const double radiusS = 4;
  static const double radiusM = 8;
  static const double radiusL = 16;
}
