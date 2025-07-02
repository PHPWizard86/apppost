import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'user.dart';
import 'api_service.dart';

// مدل Post
class Post {
  final int id;
  final String title;
  final String content;
  final String category;
  final String authorName;
  final String authorFullName;
  final DateTime createdAt;
  final DateTime updatedAt;

  Post({
    required this.id,
    required this.title,
    required this.content,
    required this.category,
    required this.authorName,
    required this.authorFullName,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: int.parse(json['id'].toString()),
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      category: json['category'] ?? '',
      authorName: json['author_name'] ?? '',
      authorFullName: json['author_full_name'] ?? '',
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at'] ?? '') ?? DateTime.now(),
    );
  }
}

class AdminPanel extends StatefulWidget {
  final User currentUser;
  final VoidCallback onLogout;

  const AdminPanel({
    required this.currentUser,
    required this.onLogout,
    super.key,
  });

  @override
  State<AdminPanel> createState() => _AdminPanelState();
}

class _AdminPanelState extends State<AdminPanel>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<User> _users = [];
  List<Post> _posts = [];
  bool _loadingUsers = false;
  bool _loadingPosts = false;
  int _currentTabIndex = 0;
  late final String _adminToken;

  @override
  void initState() {
    super.initState();
    // رفع ارور با استفاده از ?? برای مقدار پیش‌فرض
    _adminToken = widget.currentUser.token ?? '';
    if (_adminToken.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showErrorSnackBar('توکن احراز هویت یافت نشد. لطفا دوباره وارد شوید.');
        widget.onLogout();
      });
    }

    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabSelection);
    _loadUsers();
    _loadPosts();
  }

  void _handleTabSelection() {
    setState(() {
      _currentTabIndex = _tabController.index;
    });
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabSelection);
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() => _loadingUsers = true);
    try {
      final users = await ApiService.getUsers(_adminToken);
      setState(() => _users = users);
    } catch (e) {
      _showErrorSnackBar('خطا در بارگذاری کاربران: ${e.toString()}');
      setState(() => _users = []);
    } finally {
      setState(() => _loadingUsers = false);
    }
  }

  Future<void> _loadPosts() async {
    setState(() => _loadingPosts = true);
    try {
      final posts = await ApiService.getPosts();
      setState(() => _posts = posts.cast<Post>());
    } catch (e) {
      _showErrorSnackBar('خطا در بارگذاری پست‌ها: ${e.toString()}');
      setState(() => _posts = []);
    } finally {
      setState(() => _loadingPosts = false);
    }
  }

  void _showCreateUserDialog() {
    final formKey = GlobalKey<FormState>();
    final usernameController = TextEditingController();
    final passwordController = TextEditingController();
    final emailController = TextEditingController();
    final fullNameController = TextEditingController();
    String selectedRole = 'user';
    String? error;
    bool loading = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Icon(Icons.person_add, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                const Text('افزودن کاربر جدید'),
              ],
            ),
            content: SizedBox(
              width: 400,
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildTextField(
                        controller: usernameController,
                        label: 'نام کاربری',
                        icon: Icons.person,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'نام کاربری الزامی است';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: emailController,
                        label: 'ایمیل',
                        icon: Icons.email,
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value != null && value.isNotEmpty) {
                            if (!RegExp(
                              r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                            ).hasMatch(value)) {
                              return 'فرمت ایمیل صحیح نیست';
                            }
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: fullNameController,
                        label: 'نام کامل',
                        icon: Icons.badge,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: passwordController,
                        label: 'رمز عبور',
                        icon: Icons.lock,
                        obscureText: true,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'رمز عبور الزامی است';
                          }
                          if (value.length < 6) {
                            return 'رمز عبور باید حداقل ۶ کاراکتر باشد';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: selectedRole,
                        decoration: InputDecoration(
                          labelText: 'نقش کاربر',
                          prefixIcon: const Icon(Icons.admin_panel_settings),
                          filled: true,
                          fillColor: Colors.grey[50],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'user',
                            child: Text('کاربر عادی'),
                          ),
                          DropdownMenuItem(value: 'admin', child: Text('مدیر')),
                        ],
                        onChanged: (value) {
                          if (value != null) selectedRole = value;
                        },
                      ),
                      if (error != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red[200]!),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.error_outline,
                                color: Colors.red[700],
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  error!,
                                  style: TextStyle(
                                    color: Colors.red[700],
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: loading ? null : () => Navigator.pop(context),
                child: const Text('انصراف'),
              ),
              ElevatedButton(
                onPressed: loading
                    ? null
                    : () async {
                        if (!formKey.currentState!.validate()) return;

                        setState(() {
                          loading = true;
                          error = null;
                        });

                        try {
                          await ApiService.createUser(
                            adminToken: _adminToken,
                            username: usernameController.text.trim(),
                            email: emailController.text.trim(),
                            fullName: fullNameController.text.trim(),
                            password: passwordController.text.trim(),
                            role: selectedRole,
                          );

                          HapticFeedback.mediumImpact();
                          if (mounted) Navigator.pop(context);
                          _showSuccessSnackBar('کاربر با موفقیت ایجاد شد');
                          await _loadUsers();
                        } catch (e) {
                          HapticFeedback.heavyImpact();
                          setState(() => error = e.toString());
                        } finally {
                          setState(() => loading = false);
                        }
                      },
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: loading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('ایجاد کاربر'),
              ),
            ],
          ),
        );
      },
    );
  }

  // فرم ارسال پست به وردپرس آسان‌پوستر با انتخاب الگوی پویا
  void _showWordPressPostDialog() async {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    List<Map<String, dynamic>> templates = [];
    String? errorMessage;

    try {
      templates = await ApiService.getWordPressTemplates(
        'https://kingmusics.ir',
      );
    } catch (e) {
      errorMessage = e.toString();
    }

    if (mounted) Navigator.pop(context);

    if (errorMessage != null || templates.isEmpty) {
      if (mounted) {
        _showErrorSnackBar(errorMessage ?? 'هیچ الگویی یافت نشد');
      }
      return;
    }

    // --- نکته مهم: اگر index کلید عددی نیست (مثلا uuid است)، باید به صورت درست مقداردهی کنی
    // اگر index کلید رشته‌ای است، مقدار اولیه را اینگونه بردار:
    // final firstTemplateKey = templates[0]['index'];

    dynamic selectedTemplateIndex = templates[0]['index'];
    int? authorId;

    final formKey = GlobalKey<FormState>();
    final artistController = TextEditingController();
    final artistEnController = TextEditingController();
    final songController = TextEditingController();
    final songEnController = TextEditingController();
    final url320Controller = TextEditingController();
    final url128Controller = TextEditingController();
    final urlTeaserController = TextEditingController();
    final urlImageController = TextEditingController();
    final lyricController = TextEditingController();

    String? error;
    bool loading = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Icon(Icons.send, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                const Text('ارسال پست به وردپرس'),
              ],
            ),
            content: SizedBox(
              width: 500,
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField(
                        value: selectedTemplateIndex,
                        decoration: InputDecoration(
                          labelText: 'انتخاب الگو',
                          prefixIcon: const Icon(Icons.layers),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                        ),
                        items: templates.map((template) {
                          return DropdownMenuItem(
                            value: template['index'],
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  template['name'] ??
                                      'الگو ${template['index']}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (template['description'] != null &&
                                    template['description'].isNotEmpty)
                                  Text(
                                    template['description'],
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedTemplateIndex = value;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(
                        controller: artistController,
                        label: 'نام خواننده (فارسی)',
                        icon: Icons.person,
                        validator: (v) => v == null || v.isEmpty
                            ? 'خواننده الزامی است'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(
                        controller: artistEnController,
                        label: 'نام خواننده (انگلیسی)',
                        icon: Icons.person_outline,
                        validator: (v) => v == null || v.isEmpty
                            ? 'خواننده انگلیسی الزامی است'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(
                        controller: songController,
                        label: 'نام آهنگ (فارسی)',
                        icon: Icons.music_note,
                        validator: (v) => v == null || v.isEmpty
                            ? 'نام آهنگ الزامی است'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(
                        controller: songEnController,
                        label: 'نام آهنگ (انگلیسی)',
                        icon: Icons.music_video,
                        validator: (v) => v == null || v.isEmpty
                            ? 'نام آهنگ انگلیسی الزامی است'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(
                        controller: url320Controller,
                        label: 'لینک فایل ۳۲۰',
                        icon: Icons.link,
                        validator: (v) => v == null || v.isEmpty
                            ? 'لینک ۳۲۰ الزامی است'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(
                        controller: url128Controller,
                        label: 'لینک فایل ۱۲۸',
                        icon: Icons.link,
                        validator: (v) => v == null || v.isEmpty
                            ? 'لینک ۱۲۸ الزامی است'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(
                        controller: urlTeaserController,
                        label: 'لینک تیزر تصویری',
                        icon: Icons.video_library,
                        validator: (v) => v == null || v.isEmpty
                            ? 'لینک تیزر الزامی است'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(
                        controller: urlImageController,
                        label: 'لینک کاور',
                        icon: Icons.image,
                        validator: (v) => v == null || v.isEmpty
                            ? 'لینک کاور الزامی است'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(
                        controller: lyricController,
                        label: 'متن ترانه',
                        icon: Icons.lyrics,
                        validator: (v) => v == null || v.isEmpty
                            ? 'متن ترانه الزامی است'
                            : null,
                        maxLines: 3,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        decoration: InputDecoration(
                          labelText: 'شناسه نویسنده (اختیاری)',
                          hintText: 'مثلاً 1',
                          prefixIcon: const Icon(Icons.person),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          authorId = int.tryParse(value);
                        },
                      ),
                      if (error != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red[200]!),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.error_outline,
                                color: Colors.red[700],
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  error!,
                                  style: TextStyle(
                                    color: Colors.red[700],
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: loading ? null : () => Navigator.pop(context),
                child: const Text('انصراف'),
              ),
              ElevatedButton(
                onPressed: loading
                    ? null
                    : () async {
                        if (!formKey.currentState!.validate()) return;

                        setState(() {
                          loading = true;
                          error = null;
                        });

                        try {
                          await ApiService.sendPostToWordPressEasyPoster(
                            siteUrl: 'https://kingmusics.ir',
                            artist: artistController.text.trim(),
                            song: songController.text.trim(),
                            artistEn: artistEnController.text.trim(),
                            songEn: songEnController.text.trim(),
                            url320: url320Controller.text.trim(),
                            url128: url128Controller.text.trim(),
                            urlTeaser: urlTeaserController.text.trim(),
                            urlImage: urlImageController.text.trim(),
                            lyric: lyricController.text.trim(),
                            sample: selectedTemplateIndex,
                            author: authorId,
                          );
                          HapticFeedback.mediumImpact();
                          if (mounted) Navigator.pop(context);
                          _showSuccessSnackBar(
                            'پست با موفقیت به وردپرس ارسال شد',
                          );
                        } catch (e) {
                          HapticFeedback.heavyImpact();
                          setState(() => error = e.toString());
                        } finally {
                          setState(() => loading = false);
                        }
                      },
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: loading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('ارسال پست'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Theme.of(context).primaryColor,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showEditPostDialog(Post post) {
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController(text: post.title);
    final contentController = TextEditingController(text: post.content);
    String selectedCategory = post.category;
    String? error;
    bool loading = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Icon(Icons.edit, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                const Text('ویرایش پست'),
              ],
            ),
            content: SizedBox(
              width: 500,
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildTextField(
                        controller: titleController,
                        label: 'عنوان پست',
                        icon: Icons.title,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'عنوان پست الزامی است';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: contentController,
                        maxLines: 5,
                        decoration: InputDecoration(
                          labelText: 'محتوای پست',
                          prefixIcon: const Icon(Icons.description),
                          filled: true,
                          fillColor: Colors.grey[50],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'محتوای پست الزامی است';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: selectedCategory,
                        decoration: InputDecoration(
                          labelText: 'دسته‌بندی',
                          prefixIcon: const Icon(Icons.category),
                          filled: true,
                          fillColor: Colors.grey[50],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'general',
                            child: Text('عمومی'),
                          ),
                          DropdownMenuItem(
                            value: 'tech',
                            child: Text('فناوری'),
                          ),
                          DropdownMenuItem(value: 'news', child: Text('اخبار')),
                          DropdownMenuItem(
                            value: 'sport',
                            child: Text('ورزشی'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) selectedCategory = value;
                        },
                      ),
                      if (error != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red[200]!),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.error_outline,
                                color: Colors.red[700],
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  error!,
                                  style: TextStyle(
                                    color: Colors.red[700],
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: loading ? null : () => Navigator.pop(context),
                child: const Text('انصراف'),
              ),
              ElevatedButton(
                onPressed: loading
                    ? null
                    : () async {
                        if (!formKey.currentState!.validate()) return;

                        setState(() {
                          loading = true;
                          error = null;
                        });

                        try {
                          await ApiService.updatePost(
                            token: _adminToken,
                            postId: post.id,
                            title: titleController.text.trim(),
                            content: contentController.text.trim(),
                            category: selectedCategory,
                          );

                          HapticFeedback.mediumImpact();
                          if (mounted) Navigator.pop(context);
                          _showSuccessSnackBar('پست با موفقیت به‌روزرسانی شد');
                          await _loadPosts();
                        } catch (e) {
                          HapticFeedback.heavyImpact();
                          setState(() => error = e.toString());
                        } finally {
                          setState(() => loading = false);
                        }
                      },
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: loading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('به‌روزرسانی'),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: theme.primaryColor.withOpacity(0.1),
              child: Icon(
                Icons.admin_panel_settings,
                color: theme.primaryColor,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'پنل مدیریت',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  widget.currentUser.username,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: theme.primaryColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              if (_tabController.index == 1) {
                _loadUsers();
              } else if (_tabController.index == 2) {
                _loadPosts();
              } else {
                _loadUsers();
                _loadPosts();
              }
              _showSuccessSnackBar('اطلاعات بروزرسانی شد.');
            },
            tooltip: 'بروزرسانی',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: widget.onLogout,
            tooltip: 'خروج',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: theme.primaryColor,
          unselectedLabelColor: Colors.grey,
          indicatorColor: theme.primaryColor,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'داشبورد'),
            Tab(icon: Icon(Icons.people), text: 'کاربران'),
            Tab(icon: Icon(Icons.article), text: 'پست‌ها'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildDashboardTab(), _buildUsersTab(), _buildPostsTab()],
      ),
      floatingActionButton: _getFloatingActionButton(),
    );
  }

  Widget? _getFloatingActionButton() {
    if (_currentTabIndex == 1) {
      return FloatingActionButton.extended(
        onPressed: _showCreateUserDialog,
        icon: const Icon(Icons.person_add),
        label: const Text('افزودن کاربر'),
      );
    } else if (_currentTabIndex == 2) {
      return FloatingActionButton.extended(
        heroTag: 'send_wp',
        onPressed: _showWordPressPostDialog,
        icon: const Icon(Icons.send),
        label: const Text('ارسال به وردپرس'),
        backgroundColor: Colors.green,
      );
    }
    return null;
  }

  Widget _buildDashboardTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'خلاصه سیستم',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildStatsCard(
                  title: 'تعداد کاربران',
                  value: '${_users.length}',
                  icon: Icons.people,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatsCard(
                  title: 'تعداد پست‌ها',
                  value: '${_posts.length}',
                  icon: Icons.article,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildStatsCard(
                  title: 'کاربران فعال',
                  value: '${_users.where((user) => user.isActive == 1).length}',
                  icon: Icons.check_circle,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatsCard(
                  title: 'مدیران سیستم',
                  value:
                      '${_users.where((user) => user.role == 'admin').length}',
                  icon: Icons.admin_panel_settings,
                  color: Colors.purple,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 32),
                Text(
                  value,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUsersTab() {
    if (_loadingUsers) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('در حال بارگذاری کاربران...'),
          ],
        ),
      );
    }

    if (_users.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'هیچ کاربری یافت نشد',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'اولین کاربر را با استفاده از دکمه پایین اضافه کنید',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadUsers,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _users.length,
        itemBuilder: (context, index) {
          final user = _users[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: CircleAvatar(
                backgroundColor: user.role == 'admin'
                    ? Colors.red.withOpacity(0.1)
                    : Colors.blue.withOpacity(0.1),
                child: Icon(
                  user.role == 'admin'
                      ? Icons.admin_panel_settings
                      : Icons.person,
                  color: user.role == 'admin' ? Colors.red : Colors.blue,
                ),
              ),
              title: Row(
                children: <Widget>[
                  Text(
                    user.username,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 8),
                  if (user.isActive == 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'غیرفعال',
                        style: TextStyle(color: Colors.red[700], fontSize: 12),
                      ),
                    ),
                  if (user.isActive == 1)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'فعال',
                        style: TextStyle(
                          color: Colors.green[700],
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (user.fullName.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(user.fullName),
                  ],
                  if (user.email.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(user.email, style: TextStyle(color: Colors.grey[600])),
                  ],
                ],
              ),
              trailing: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: user.role == 'admin'
                      ? Colors.red[50]
                      : Colors.blue[50],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: user.role == 'admin'
                        ? Colors.red[200]!
                        : Colors.blue[200]!,
                  ),
                ),
                child: Text(
                  user.role == 'admin' ? 'مدیر' : 'کاربر',
                  style: TextStyle(
                    color: user.role == 'admin'
                        ? Colors.red[700]
                        : Colors.blue[700],
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPostsTab() {
    if (_loadingPosts) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('در حال بارگذاری پست‌ها...'),
          ],
        ),
      );
    }

    if (_posts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.article_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'هیچ پستی یافت نشد',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'اولین پست را با استفاده از دکمه "ارسال به وردپرس" ایجاد کنید',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadPosts,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _posts.length,
        itemBuilder: (context, index) {
          final post = _posts[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          post.title,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'edit') {
                            _showEditPostDialog(post);
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit, size: 18),
                                SizedBox(width: 8),
                                Text('ویرایش'),
                              ],
                            ),
                          ),
                        ],
                        child: const Icon(Icons.more_vert),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (post.category.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        post.category,
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),
                  Text(
                    post.content,
                    style: Theme.of(context).textTheme.bodyMedium,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.person, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        post.authorFullName.isNotEmpty
                            ? post.authorFullName
                            : post.authorName,
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                      const Spacer(),
                      Icon(
                        Icons.access_time,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatDate(post.createdAt),
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays} روز پیش';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ساعت پیش';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} دقیقه پیش';
    } else {
      return 'همین الان';
    }
  }
}
