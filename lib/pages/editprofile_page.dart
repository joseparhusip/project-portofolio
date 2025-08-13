// editprofile_page.dart (FIXED VERSION)

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart'; // TAMBAHKAN INI
import 'dart:io';
import '../models/user_model.dart';
import '../api/api_service.dart';

class EditProfilePage extends StatefulWidget {
  final User user;

  const EditProfilePage({super.key, required this.user});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  String _selectedGender = 'Laki-laki';
  File? _selectedImage;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _hasChanges = false;

  final ImagePicker _picker = ImagePicker();
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.user.name;
    _usernameController.text = widget.user.username;
    _emailController.text = widget.user.email;
    _setupChangeListeners();
  }

  void _setupChangeListeners() {
    _nameController.addListener(_checkForChanges);
    _usernameController.addListener(_checkForChanges);
    _emailController.addListener(_checkForChanges);
    _passwordController.addListener(_checkForChanges);
  }

  void _checkForChanges() {
    final hasChanges = _nameController.text.trim() != widget.user.name ||
        _usernameController.text.trim() != widget.user.username ||
        _emailController.text.trim() != widget.user.email ||
        _passwordController.text.isNotEmpty ||
        _selectedImage != null;

    if (hasChanges != _hasChanges) {
      setState(() {
        _hasChanges = hasChanges;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _onAttemptToPop() async {
    if (_isLoading) return;

    if (_hasChanges) {
      final bool? shouldLeave = await _showUnsavedChangesDialog();
      if (shouldLeave == true && mounted) {
        Navigator.of(context).pop();
      }
    } else {
      Navigator.of(context).pop();
    }
  }

  Future<bool?> _showUnsavedChangesDialog() async {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Perubahan Belum Disimpan'),
          content: const Text(
              'Anda memiliki perubahan yang belum disimpan. Apakah Anda yakin ingin keluar?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Tetap di Sini'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Keluar Tanpa Menyimpan'),
            ),
          ],
        );
      },
    );
  }

  void _navigateBackToProfile([User? updatedUser]) {
    // Remove hero animation to prevent conflicts
    Navigator.of(context).pop(updatedUser);
  }

  // FUNGSI BARU UNTUK CEK PERMISSION
  Future<bool> _checkCameraPermission() async {
    var status = await Permission.camera.status;
    if (status.isDenied || status.isPermanentlyDenied) {
      status = await Permission.camera.request();
    }
    return status.isGranted;
  }

  Future<bool> _checkStoragePermission() async {
    if (Platform.isAndroid) {
      var status = await Permission.storage.status;
      if (status.isDenied) {
        status = await Permission.storage.request();
      }
      
      // For Android 13+ (API 33+), check photos permission
      if (status.isDenied || status.isPermanentlyDenied) {
        var photosStatus = await Permission.photos.status;
        if (photosStatus.isDenied) {
          photosStatus = await Permission.photos.request();
        }
        return photosStatus.isGranted;
      }
      return status.isGranted;
    }
    return true; // iOS handles permissions automatically
  }

  // FUNGSI PICK IMAGE YANG DIPERBAIKI
  Future<void> _pickImage() async {
    try {
      final ImageSource? source = await _showImageSourceDialog();
      if (source == null) return;

      // Check permissions berdasarkan source yang dipilih
      bool hasPermission = false;
      
      if (source == ImageSource.camera) {
        hasPermission = await _checkCameraPermission();
        if (!hasPermission) {
          if (mounted) {
            _showSnackBar('Izin kamera diperlukan untuk mengambil foto.', isError: true);
          }
          return;
        }
      } else {
        hasPermission = await _checkStoragePermission();
        if (!hasPermission) {
          if (mounted) {
            _showSnackBar('Izin storage diperlukan untuk mengakses galeri.', isError: true);
          }
          return;
        }
      }

      // Show loading indicator
      if (mounted) {
        _showSnackBar('Membuka ${source == ImageSource.camera ? 'kamera' : 'galeri'}...');
      }

      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
        preferredCameraDevice: CameraDevice.front, // TAMBAHKAN INI
      );

      if (image != null) {
        final File imageFile = File(image.path);
        
        // Check if file exists
        if (!await imageFile.exists()) {
          if (mounted) {
            _showSnackBar('File gambar tidak ditemukan.', isError: true);
          }
          return;
        }

        final int fileSizeInBytes = await imageFile.length();
        final double fileSizeInMB = fileSizeInBytes / (1024 * 1024);

        if (fileSizeInMB > 5) {
          if (mounted) {
            _showSnackBar('Ukuran file terlalu besar. Maksimal 5MB.', isError: true);
          }
          return;
        }
        
        setState(() {
          _selectedImage = imageFile;
        });
        _checkForChanges();
        
        if (mounted) {
          _showSnackBar('Gambar berhasil dipilih!');
        }
      } else {
        if (mounted) {
          _showSnackBar('Tidak ada gambar yang dipilih.');
        }
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Error memilih gambar: $e';
        
        // Handle specific error cases
        if (e.toString().contains('camera_access_denied')) {
          errorMessage = 'Akses kamera ditolak. Silakan berikan izin kamera di pengaturan.';
        } else if (e.toString().contains('photo_access_denied')) {
          errorMessage = 'Akses galeri ditolak. Silakan berikan izin storage di pengaturan.';
        } else if (e.toString().contains('MissingPluginException')) {
          errorMessage = 'Plugin kamera tidak tersedia. Coba restart aplikasi.';
        }
        
        _showSnackBar(errorMessage, isError: true);
      }
    }
  }

  Future<ImageSource?> _showImageSourceDialog() async {
    return showDialog<ImageSource>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Pilih Sumber Gambar'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Color(0xFF36067e)),
                title: const Text('Kamera'),
                subtitle: const Text('Ambil foto baru'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Color(0xFF36067e)),
                title: const Text('Galeri'),
                subtitle: const Text('Pilih dari galeri'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            )
          ],
        );
      },
    );
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;
    final bool? confirm = await _showConfirmDialog();
    if (confirm != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _apiService.updateProfile(
        userId: widget.user.userId,
        name: _nameController.text.trim(),
        username: _usernameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        gender: _selectedGender,
        imageFile: _selectedImage,
        authToken: widget.user.authToken,
      );

      if (mounted) {
        if (result['status'] == 'success') {
          _showSnackBar('Profile berhasil diupdate!');

          final updatedData = result['data'];

          final updatedUser = User(
            userId: updatedData['user_id'] ?? widget.user.userId,
            name: updatedData['nama'] ?? widget.user.name,
            username: updatedData['username'] ?? widget.user.username,
            email: updatedData['email'] ?? widget.user.email,
            authToken: updatedData['auth_token'] ?? widget.user.authToken,
            profileImageUrl:
                updatedData['profile_image_url'] ?? widget.user.profileImageUrl,
          );

          setState(() {
            _hasChanges = false;
          });

          await Future.delayed(const Duration(seconds: 1));
          if (mounted) {
            _navigateBackToProfile(updatedUser);
          }
        } else {
          _showSnackBar(result['message'] ?? 'Gagal mengupdate profile',
              isError: true);
        }
      }
    } catch (e) {
      if (mounted) _showSnackBar('Error: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<bool?> _showConfirmDialog() async {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Konfirmasi'),
          content: const Text('Apakah Anda yakin ingin menyimpan perubahan?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF36067e),
              ),
              child: const Text('Ya, Simpan',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                isError ? Icons.error : Icons.check_circle,
                color: Colors.white,
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: isError ? Colors.red[600] : Colors.green[600],
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light.copyWith(
      statusBarColor: Colors.transparent,
    ));
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (!didPop) {
          _onAttemptToPop();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        body: Stack(
          children: [
            _buildHeader(),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: _isLoading ? null : _onAttemptToPop,
                ),
              ),
            ),
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(top: 120),
                child: Column(
                  children: [
                    _buildProfileImageSection(),
                    const SizedBox(height: 20),
                    _buildFormSection(),
                    const SizedBox(height: 30),
                    _buildSaveButton(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
            if (_isLoading)
              Container(
                color: Colors.black54,
                child: const Center(
                  child: Card(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Menyimpan perubahan...'),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 160,
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF667EEA), Color(0xFF36067e)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: const Center(
        child: Padding(
          padding: EdgeInsets.only(top: 40),
          child: Text(
            'Edit Profile',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileImageSection() {
    ImageProvider? backgroundImage;

    if (_selectedImage != null) {
      backgroundImage = FileImage(_selectedImage!);
    } else if (widget.user.profileImageUrl.isNotEmpty) {
      backgroundImage = NetworkImage(widget.user.profileImageUrl);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Card(
        elevation: 5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Stack(
                children: [
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        )
                      ],
                    ),
                    // REMOVE HERO - LANGSUNG CIRCLEAVATAR TANPA HERO WRAPPER
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.grey[200],
                      backgroundImage: backgroundImage,
                      child: backgroundImage == null
                          ? Text(
                              widget.user.name.isNotEmpty
                                  ? widget.user.name[0].toUpperCase()
                                  : 'U',
                              style: const TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF36067e),
                              ),
                            )
                          : null,
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Color(0xFF36067e),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 5,
                            offset: Offset(0, 2),
                          )
                        ],
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.camera_alt, color: Colors.white),
                        onPressed: _isLoading ? null : _pickImage,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                _selectedImage != null
                    ? 'Gambar siap diupload'
                    : 'Ketuk ikon kamera untuk mengubah foto profil',
                style: TextStyle(
                  fontSize: 12,
                  color: _selectedImage != null ? Colors.green : Colors.grey,
                  fontWeight: _selectedImage != null
                      ? FontWeight.w500
                      : FontWeight.normal,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Card(
        elevation: 5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTextField(
                  controller: _nameController,
                  label: 'Nama Lengkap',
                  icon: Icons.person,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Nama tidak boleh kosong';
                    }
                    if (value.trim().length < 2) {
                      return 'Nama minimal 2 karakter';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _usernameController,
                  label: 'Username',
                  icon: Icons.account_circle,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Username tidak boleh kosong';
                    }
                    if (value.trim().length < 3) {
                      return 'Username minimal 3 karakter';
                    }
                    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value.trim())) {
                      return 'Username hanya boleh mengandung huruf, angka, dan underscore';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _emailController,
                  label: 'Email',
                  icon: Icons.email,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Email tidak boleh kosong';
                    }
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                        .hasMatch(value.trim())) {
                      return 'Format email tidak valid';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _passwordController,
                  label: 'Password Baru (opsional)',
                  icon: Icons.lock,
                  obscureText: _obscurePassword,
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword
                        ? Icons.visibility
                        : Icons.visibility_off),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                  validator: (value) {
                    if (value != null && value.isNotEmpty && value.length < 6) {
                      return 'Password minimal 6 karakter';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _buildGenderDropdown(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      obscureText: obscureText,
      enabled: !_isLoading,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF36067e)),
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF36067e), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        filled: true,
        fillColor: _isLoading ? Colors.grey[100] : Colors.grey[50],
      ),
    );
  }

  Widget _buildGenderDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Jenis Kelamin',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(10),
            color: _isLoading ? Colors.grey[100] : Colors.grey[50],
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedGender,
              isExpanded: true,
              icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF36067e)),
              items: ['Laki-laki', 'Perempuan'].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Row(
                    children: [
                      Icon(
                        value == 'Laki-laki' ? Icons.male : Icons.female,
                        color: const Color(0xFF36067e),
                      ),
                      const SizedBox(width: 10),
                      Text(value),
                    ],
                  ),
                );
              }).toList(),
              onChanged: _isLoading
                  ? null
                  : (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _selectedGender = newValue;
                        });
                        _checkForChanges();
                      }
                    },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          onPressed: _isLoading ? null : _updateProfile,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF36067e),
            disabledBackgroundColor: Colors.grey[400],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
            ),
            elevation: _isLoading ? 0 : 5,
          ),
          child: _isLoading
              ? const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Menyimpan...',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ],
                )
              : const Text(
                  'Simpan Perubahan',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
        ),
      ),
    );
  }
}