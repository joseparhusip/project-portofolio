import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../api/api_service.dart';
import '../models/order_model.dart';

// --- DIUBAH MENJADI STATEFUL WIDGET ---
class OrderDetailPage extends StatefulWidget {
  final Order order;

  const OrderDetailPage({super.key, required this.order});

  @override
  State<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> {
  final ApiService _apiService = ApiService();
  // --- BARU: State untuk menyimpan ID produk yang sudah diulas di sesi ini ---
  final Set<int> _reviewedProductIds = {};

  // ... (kode _formatCurrency, _formatDate, _getStatusColor, _getStatusIcon, _getStatusText tidak berubah)
  String _formatCurrency(double amount) {
    return NumberFormat.currency(
            locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0)
        .format(amount);
  }

  String _formatDate(DateTime date) {
    // FIX: Menggunakan locale id_ID untuk format tanggal yang lebih sesuai
    return DateFormat('d MMMM yyyy, HH:mm', 'id_ID').format(date);
  }

  Color _getStatusColor(String status) {
    // ... (kode tidak berubah)
    switch (status.toLowerCase()) {
      case 'pending':
        return const Color(0xFFFF9500);
      case 'processing':
        return const Color(0xFF007AFF);
      case 'completed':
        return const Color(0xFF34C759);
      case 'cancelled':
        return const Color(0xFFFF3B30);
      default:
        return const Color(0xFF8E8E93);
    }
  }

  IconData _getStatusIcon(String status) {
    // ... (kode tidak berubah)
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.schedule_rounded;
      case 'processing':
        return Icons.local_shipping_rounded;
      case 'completed':
        return Icons.check_circle_rounded;
      case 'cancelled':
        return Icons.cancel_rounded;
      default:
        return Icons.help_rounded;
    }
  }

  String _getStatusText(String status) {
    // ... (kode tidak berubah)
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Tertunda';
      case 'processing':
        return 'Diproses';
      case 'completed':
        return 'Selesai';
      case 'cancelled':
        return 'Dibatalkan';
      default:
        return status;
    }
  }

  // ... (kode _showReviewDialog tidak berubah)
  void _showReviewDialog(OrderItem item) {
    int rating = 0;
    final commentController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              title: const Text('Beri Ulasan',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.productName,
                          style: const TextStyle(
                              fontSize: 14, color: Colors.black87)),
                      const SizedBox(height: 16),
                      const Text('Rating Anda:',
                          style:
                              TextStyle(fontSize: 13, color: Colors.black54)),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(5, (index) {
                          return IconButton(
                            onPressed: () =>
                                setDialogState(() => rating = index + 1),
                            icon: Icon(
                              index < rating
                                  ? Icons.star_rounded
                                  : Icons.star_border_rounded,
                              color: Colors.amber,
                              size: 32,
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: commentController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: 'Tulis komentar Anda (opsional)...',
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (rating == 0) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Harap berikan minimal 1 bintang.'),
                        backgroundColor: Colors.red,
                      ));
                      return;
                    }
                    _submitReview(
                      productId: item.productId,
                      rating: rating,
                      comment: commentController.text,
                    );
                    Navigator.pop(context);
                  },
                  child: const Text('Kirim'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // --- FUNGSI _submitReview DIMODIFIKASI ---
  Future<void> _submitReview({
    required int productId,
    required int rating,
    required String comment,
  }) async {
    // <-- PERBAIKAN 1: Tambahkan pengecekan `mounted` sebelum menggunakan `context` -->
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Mengirim ulasan...'),
      backgroundColor: Colors.blueGrey,
    ));

    final response = await _apiService.addProductReview(
      userId: widget.order.userId,
      productId: productId,
      rating: rating,
      comment: comment,
    );

    // <-- PERBAIKAN 1: Tambahkan lagi pengecekan `mounted` karena ada `await` di atasnya -->
    if (!mounted) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    // <-- DIUBAH: Tambahkan logika untuk memperbarui state jika berhasil -->
    if (response['status'] == 'success') {
      setState(() {
        _reviewedProductIds.add(productId);
      });
    }

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(response['message'] ?? 'Terjadi kesalahan.'),
      backgroundColor:
          response['status'] == 'success' ? Colors.green : Colors.red,
    ));
  }

  @override
  Widget build(BuildContext context) {
    // ... (kode build tidak berubah sampai _buildProductItem)
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Detail Pesanan',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF667EEA),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isTablet ? 24.0 : 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Item Dipesan'),
            const SizedBox(height: 12),
            _buildItemsCard(isTablet),
            const SizedBox(height: 24),
            _buildSectionHeader('Ringkasan Pesanan'),
            const SizedBox(height: 12),
            _buildSummaryCard(isTablet),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    // ... (kode tidak berubah)
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: Color(0xFF1A1A1A),
      ),
    );
  }

  Widget _buildItemsCard(bool isTablet) {
    // ... (kode tidak berubah)
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          ...widget.order.items.asMap().entries.map((entry) {
            final isLast = entry.key == widget.order.items.length - 1;
            return Column(
              children: [
                _buildProductItem(entry.value, isTablet),
                if (!isLast)
                  Container(
                    height: 1,
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    color: const Color(0xFFF1F1F1),
                  ),
              ],
            );
          }),
        ],
      ),
    );
  }

  // --- WIDGET _buildProductItem DIMODIFIKASI TOTAL ---
  Widget _buildProductItem(OrderItem item, bool isTablet) {
    final imageSize = isTablet ? 80.0 : 60.0;
    // Cek apakah pesanan selesai
    final bool canReview =
        widget.order.orderStatus.toLowerCase() == 'completed';
    // <-- BARU: Cek apakah produk ini sudah diulas dalam sesi ini -->
    final bool isReviewed = _reviewedProductIds.contains(item.productId);

    return Padding(
      padding: EdgeInsets.all(isTablet ? 20.0 : 16.0),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ... (kode untuk menampilkan gambar dan detail produk tidak berubah)
              ClipRRect(
                borderRadius: BorderRadius.circular(12.0),
                child: Image.network(
                  item.productImageUrl,
                  width: imageSize,
                  height: imageSize,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: imageSize,
                    height: imageSize,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F1F1),
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: Icon(
                      Icons.image_not_supported_rounded,
                      size: imageSize * 0.4,
                      color: const Color(0xFF8E8E93),
                    ),
                  ),
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      width: imageSize,
                      height: imageSize,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F1F1),
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: const Color(0xFF667EEA),
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              SizedBox(width: isTablet ? 20 : 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.productName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F1F1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${item.quantity} ${item.quantity > 1 ? 'items' : 'item'}',
                        style: const TextStyle(
                          color: Color(0xFF555555),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Harga Satuan',
                              style: TextStyle(
                                fontSize: 10,
                                color: Color(0xFF8E8E93),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _formatCurrency(item.priceAtPurchase),
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF555555),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text(
                              'Subtotal',
                              style: TextStyle(
                                fontSize: 10,
                                color: Color(0xFF8E8E93),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _formatCurrency(
                                  item.priceAtPurchase * item.quantity),
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                color: Color(0xFF667EEA),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          // --- BAGIAN BARU: TOMBOL ULASAN DENGAN LOGIKA BARU ---
          if (canReview)
            Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  // <-- DIUBAH: onPressed menjadi null jika sudah diulas -->
                  onPressed: isReviewed ? null : () => _showReviewDialog(item),
                  // <-- DIUBAH: Ganti ikon dan teks berdasarkan status ulasan -->
                  icon: Icon(
                    isReviewed
                        ? Icons.check_circle_outline_rounded
                        : Icons.rate_review_outlined,
                    size: 18,
                    // <-- DIUBAH: Ganti warna ikon jika nonaktif -->
                    color: isReviewed ? Colors.grey : const Color(0xFF667EEA),
                  ),
                  label: Text(isReviewed ? 'Sudah Diulas' : 'Beri Ulasan'),
                  style: OutlinedButton.styleFrom(
                    // <-- DIUBAH: Atur style untuk kondisi nonaktif (disabled) -->
                    foregroundColor: const Color(0xFF667EEA),
                    side: BorderSide(
                        color: isReviewed
                            ? Colors.grey.shade300
                            : const Color(0xFF667EEA)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    // <-- PERBAIKAN 2: Baris `disabledForegroundColor` dihapus karena sudah usang -->
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ... (kode _buildSummaryCard, _buildStatusChip, _buildInfoRow tidak berubah)
  Widget _buildSummaryCard(bool isTablet) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(isTablet ? 20.0 : 16.0),
            child: Column(
              children: [
                _buildInfoRow(
                  icon: Icons.receipt_long_outlined,
                  label: 'ID Pesanan',
                  value: '#${widget.order.orderId}',
                ),
                const SizedBox(height: 16),
                _buildInfoRow(
                  icon: Icons.calendar_today_outlined,
                  label: 'Tanggal Pesan',
                  value: _formatDate(widget.order.orderDate),
                ),
                const SizedBox(height: 16),
                _buildInfoRow(
                  icon: Icons.info_outline,
                  label: 'Status',
                  customValue: _buildStatusChip(widget.order.orderStatus),
                ),
              ],
            ),
          ),
          Container(
            height: 1,
            color: const Color(0xFFF1F1F1),
          ),
          Padding(
            padding: EdgeInsets.all(isTablet ? 20.0 : 16.0),
            child: Column(
              children: [
                _buildInfoRow(
                  icon: Icons.shopping_cart_outlined,
                  label: 'Subtotal',
                  value: _formatCurrency(widget.order.subtotalAmount),
                ),
                const SizedBox(height: 16),
                _buildInfoRow(
                  icon: Icons.calculate_outlined,
                  label: 'Pajak',
                  value: _formatCurrency(widget.order.taxAmount),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.all(isTablet ? 20.0 : 16.0),
            decoration: BoxDecoration(
              color: const Color(0xFF667EEA).withAlpha(20),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: _buildInfoRow(
              icon: Icons.account_balance_wallet_outlined,
              label: 'Total Bayar',
              value: _formatCurrency(widget.order.totalAmount),
              isTotal: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    final color = _getStatusColor(status);
    final icon = _getStatusIcon(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 6),
          Text(
            _getStatusText(status),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    String? value,
    Widget? customValue,
    bool isTotal = false,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          color: isTotal ? const Color(0xFF667EEA) : const Color(0xFF8E8E93),
          size: 18,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color:
                  isTotal ? const Color(0xFF667EEA) : const Color(0xFF555555),
              fontSize: 13,
              fontWeight: isTotal ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
        customValue ??
            Text(
              value ?? '',
              style: TextStyle(
                fontSize: isTotal ? 15 : 13,
                fontWeight: isTotal ? FontWeight.w700 : FontWeight.w600,
                color:
                    isTotal ? const Color(0xFF667EEA) : const Color(0xFF1A1A1A),
              ),
            ),
      ],
    );
  }
}
