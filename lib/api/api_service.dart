import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/product_model.dart';
import '../models/slider_model.dart';
import '../models/cart_model.dart';
import '../models/seller_detail_model.dart';
import '../models/seller_model.dart';
import '../models/order_model.dart'; 
import '../models/product_review_model.dart';

class ApiService {
  static const String _baseUrl =
      'http://172.16.30.251/backend-lapakulbi/api/';

  Future<List<Product>> getProducts({String query = ''}) async {
    try {
      var uri = Uri.parse('${_baseUrl}dashboard.php');
      if (query.isNotEmpty) {
        uri = uri.replace(queryParameters: {'search': query});
      }
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        if (body['status'] == 'success') {
          final List<dynamic> productData = body['data'];
          return productData.map((json) => Product.fromJson(json)).toList();
        } else {
          throw Exception('Gagal memuat produk: ${body['message']}');
        }
      } else {
        throw Exception(
            'Gagal terhubung ke server. Kode: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Terjadi kesalahan: ${e.toString()}');
    }
  }

  Future<List<Product>> getShopProducts({
    String query = '',
    List<String>? categories,
    double? minPrice,
    double? maxPrice,
  }) async {
    try {
      final Map<String, String> queryParameters = {
        if (query.isNotEmpty) 'search': query,
        if (categories != null && categories.isNotEmpty)
          'category': categories.join(','),
        if (minPrice != null) 'min_price': minPrice.toString(),
        if (maxPrice != null) 'max_price': maxPrice.toString(),
      };

      var uri = Uri.parse('${_baseUrl}shop.php').replace(
        queryParameters: queryParameters.isNotEmpty ? queryParameters : null,
      );

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        if (body['status'] == 'success') {
          final List<dynamic> productData = body['data'];
          return productData.map((json) => Product.fromJson(json)).toList();
        } else {
          throw Exception('Gagal memuat produk: ${body['message']}');
        }
      } else {
        throw Exception(
            'Gagal terhubung ke server. Kode: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Terjadi kesalahan: ${e.toString()}');
    }
  }

  Future<Product> getProductDetail(int productId) async {
    try {
      final uri = Uri.parse('${_baseUrl}product_detail.php?id=$productId');
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        if (body['status'] == 'success') {
          return Product.fromJson(body['data']);
        } else {
          throw Exception('Gagal memuat detail produk: ${body['message']}');
        }
      } else {
        throw Exception(
            'Gagal terhubung ke server. Kode: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Terjadi kesalahan: ${e.toString()}');
    }
  }

  Future<SellerDetail> getSellerDetail(int sellerId) async {
    try {
      final uri = Uri.parse('${_baseUrl}seller_detail.php?id=$sellerId');
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        if (body['status'] == 'success') {
          return SellerDetail.fromJson(body['data']);
        } else {
          throw Exception('Gagal memuat detail penjual: ${body['message']}');
        }
      } else {
        throw Exception(
            'Gagal terhubung ke server. Kode: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Terjadi kesalahan: ${e.toString()}');
    }
  }

  Future<List<SliderModel>> getSliders() async {
    try {
      final uri = Uri.parse('${_baseUrl}sliders.php');
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        if (body['status'] == 'success') {
          final List<dynamic> sliderData = body['data'];
          return sliderData.map((json) => SliderModel.fromJson(json)).toList();
        } else {
          throw Exception('Gagal memuat sliders: ${body['message']}');
        }
      } else {
        throw Exception(
            'Gagal terhubung ke server. Kode: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Terjadi kesalahan: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('${_baseUrl}signin.php'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({'email': email, 'password': password}),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      throw 'Gagal terhubung ke server. Kode: ${response.statusCode}';
    } catch (e) {
      return {'status': 'error', 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> register(
      String name, String username, String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('${_baseUrl}register.php'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({
          'name': name,
          'username': username,
          'email': email,
          'password': password,
        }),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      throw 'Gagal terhubung ke server. Kode: ${response.statusCode}';
    } catch (e) {
      return {'status': 'error', 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> updateProfile({
    required int userId,
    required String name,
    required String username,
    required String email,
    required String password,
    required String gender,
    required String authToken,
    File? imageFile,
  }) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${_baseUrl}editprofile.php'),
      );

      request.fields['user_id'] = userId.toString();
      request.fields['name'] = name;
      request.fields['username'] = username;
      request.fields['email'] = email;
      request.fields['gender'] = gender;
      request.fields['auth_token'] = authToken;

      if (password.isNotEmpty) {
        request.fields['password'] = password;
      }

      if (imageFile != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'profile_image',
            imageFile.path,
          ),
        );
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw 'Gagal terhubung ke server. Kode: ${response.statusCode}';
      }
    } catch (e) {
      return {'status': 'error', 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> deleteAccount({
    required int userId,
    required String authToken,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${_baseUrl}delete_account.php'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({
          'user_id': userId,
          'auth_token': authToken,
        }),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      throw 'Failed to connect to the server. Code: ${response.statusCode}';
    } catch (e) {
      return {'status': 'error', 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> addToCart({
    required int userId,
    required int productId,
    int quantity = 1,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${_baseUrl}add_to_cart.php'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({
          'user_id': userId,
          'product_id': productId,
          'quantity': quantity,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        try {
          final errorBody = jsonDecode(response.body);
          return {
            'status': 'error',
            'message': errorBody['message'] ??
                'Gagal terhubung ke server. Kode: ${response.statusCode}'
          };
        } catch (e) {
          throw 'Gagal terhubung ke server. Kode: ${response.statusCode}';
        }
      }
    } catch (e) {
      return {
        'status': 'error',
        'message': 'Terjadi kesalahan: ${e.toString()}'
      };
    }
  }

  Future<Cart> getCart(int userId) async {
    try {
      final uri =
          Uri.parse('${_baseUrl}get_cart.php').replace(queryParameters: {
        'user_id': userId.toString(),
      });
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        if (body['status'] == 'success') {
          return Cart.fromJson(body['data']);
        } else {
          throw Exception('Gagal memuat keranjang: ${body['message']}');
        }
      } else {
        throw Exception(
            'Gagal terhubung ke server. Kode: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception(
          'Terjadi kesalahan saat memuat keranjang: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> updateCartQuantity({
    required int cartItemId,
    required String type,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${_baseUrl}update_cart_quantity.php'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({
          'cart_item_id': cartItemId,
          'type': type,
        }),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'status': 'error', 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> removeFromCart({
    required int cartItemId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${_baseUrl}remove_from_cart.php'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({'cart_item_id': cartItemId}),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'status': 'error', 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> createOrder({
    required int userId,
    required List<CartItem> items,
    required double subtotal,
    required double tax,
    required double total,
    required File paymentProof,
  }) async {
    try {
      var uri = Uri.parse('${_baseUrl}create_order.php');
      var request = http.MultipartRequest('POST', uri);

      request.fields['user_id'] = userId.toString();
      request.fields['subtotal'] = subtotal.toString();
      request.fields['tax'] = tax.toString();
      request.fields['total'] = total.toString();

      List<Map<String, dynamic>> itemsJson = items
          .map((item) => {
                'cart_item_id': item.cartItemId,
                'product_id': item.productId,
                'quantity': item.quantity,
                'price': item.price,
              })
          .toList();
      request.fields['items'] = jsonEncode(itemsJson);

      request.files.add(
        await http.MultipartFile.fromPath(
          'payment_proof',
          paymentProof.path,
          filename: paymentProof.path.split('/').last,
        ),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        try {
          final errorBody = jsonDecode(response.body);
          return {
            'status': 'error',
            'message': errorBody['message'] ??
                'Gagal terhubung ke server. Kode: ${response.statusCode}'
          };
        } catch (e) {
          throw 'Gagal terhubung ke server. Kode: ${response.statusCode}';
        }
      }
    } catch (e) {
      return {
        'status': 'error',
        'message': 'Terjadi kesalahan: ${e.toString()}'
      };
    }
  }

  Future<List<SellerModel>> getAllSellers({String query = ''}) async {
    try {
      var uri = Uri.parse('${_baseUrl}get_all_sellers.php');

      if (query.isNotEmpty) {
        uri = uri.replace(queryParameters: {'search': query});
      }

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        if (body['status'] == 'success') {
          final List<dynamic> sellerData = body['data'];
          return sellerData.map((json) => SellerModel.fromJson(json)).toList();
        } else {
          throw Exception('Gagal memuat daftar penjual: ${body['message']}');
        }
      } else {
        throw Exception(
            'Gagal terhubung ke server. Kode: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Terjadi kesalahan: ${e.toString()}');
    }
  }

  Future<List<Product>> getWishlist(int userId) async {
    final uri = Uri.parse('${_baseUrl}get_wishlist.php?user_id=$userId');
    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        if (body['status'] == 'success') {
          final List<dynamic> data = body['data'];
          return data.map((json) => Product.fromJson(json)).toList();
        } else {
          throw Exception('Gagal memuat wishlist: ${body['message']}');
        }
      } else {
        throw Exception(
            'Gagal terhubung ke server. Kode: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception(
          'Terjadi kesalahan saat mengambil wishlist: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> toggleWishlist({
    required int userId,
    required int productId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${_baseUrl}toggle_wishlist.php'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({
          'user_id': userId,
          'product_id': productId,
        }),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      throw 'Gagal terhubung ke server. Kode: ${response.statusCode}';
    } catch (e) {
      return {'status': 'error', 'message': e.toString()};
    }
  }

  Future<Set<int>> getWishlistProductIds(int userId) async {
    try {
      final uri = Uri.parse('${_baseUrl}get_wishlist_status.php').replace(
        queryParameters: {'user_id': userId.toString()},
      );
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        if (body['status'] == 'success') {
          final List<dynamic> ids = body['data'];
          return ids.map((id) => id as int).toSet();
        } else {
          throw Exception('Gagal memuat status wishlist: ${body['message']}');
        }
      } else {
        throw Exception(
            'Gagal terhubung ke server. Kode: ${response.statusCode}');
      }
    } catch (e) {
      // PERBAIKAN: Menghapus print()
      return {};
    }
  }

  // --- FUNGSI YANG DIPERBAIKI ---
  Future<List<Order>> getOrders(int userId) async {
    // PERBAIKAN: Menggunakan _baseUrl
    final response = await http.get(
      Uri.parse('${_baseUrl}get_orders.php?user_id=$userId'),
    );

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      if (jsonResponse['status'] == 'success' && jsonResponse['data'] != null) {
        List<dynamic> data = jsonResponse['data'];
        // PERBAIKAN: Tipe Order sekarang dikenali karena sudah di-import
        return data.map((orderJson) => Order.fromJson(orderJson)).toList();
      } else {
        if (jsonResponse['data'] == null ||
            (jsonResponse['data'] is List && jsonResponse['data'].isEmpty)) {
          return [];
        }
        throw Exception(
            jsonResponse['message'] ?? 'Gagal mengambil data pesanan.');
      }
    } else {
      throw Exception(
          'Gagal terhubung ke server. Status code: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> forgotPassword({
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${_baseUrl}forgot_password.php'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({
          'email': email,
          'password': password,
          'confirm_password': confirmPassword,
        }),
      );

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 200 && responseBody['status'] == 'success') {
        return responseBody;
      } else {
        // Mengembalikan pesan error dari server jika ada
        return {
          'status': 'error',
          'message': responseBody['message'] ?? 'Gagal mengubah password.'
        };
      }
    } catch (e) {
      return {
        'status': 'error',
        'message': 'Terjadi kesalahan: ${e.toString()}'
      };
    }
  }

  Future<List<ProductReview>> getProductReviews(int productId) async {
    try {
      final uri =
          Uri.parse('${_baseUrl}get_product_reviews.php?product_id=$productId');
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        if (body['status'] == 'success') {
          // Jika data null atau kosong, kembalikan list kosong
          if (body['data'] == null || (body['data'] is! List)) {
            return [];
          }
          final List<dynamic> reviewData = body['data'];
          return reviewData
              .map((json) => ProductReview.fromJson(json))
              .toList();
        } else {
          // Tetap kembalikan list kosong jika ada pesan error dari API
          return [];
        }
      } else {
        // Gagal terhubung ke server, kembalikan list kosong
        return [];
      }
    } catch (e) {
      // <-- PERBAIKAN: Baris print() yang menyebabkan error telah dihapus -->
      // Terjadi kesalahan lain, kembalikan list kosong
      return [];
    }
  }

  Future<Map<String, dynamic>> addProductReview({
    required int userId,
    required int productId,
    required int rating,
    String? comment,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${_baseUrl}add_product_review.php'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({
          'user_id': userId,
          'product_id': productId,
          'rating': rating,
          'comment': comment ?? '',
        }),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {
        'status': 'error',
        'message': 'Terjadi kesalahan: ${e.toString()}'
      };
    }
  }
}
