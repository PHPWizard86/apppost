import 'dart:convert'; // برای کار با JSON
import 'package:flutter_application_1/admin_panel.dart';
import 'package:flutter_application_1/user.dart';
import 'package:http/http.dart' as http; // برای درخواست‌های HTTP
import 'package:crypto/crypto.dart'; // برای توابع هشینگ مثل MD5
import 'user.dart'; // مدل User را وارد می‌کند
import 'post.dart'; // مدل Post را وارد می‌کند

class ApiService {
  // آدرس پایه API شما
  static const String baseUrl = 'https://gtalk.ir/app/api.php';

  // متد ورود کاربر
  static Future<User?> login(String username, String password) async {
    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'action': 'login',
        'username': username,
        'password': password,
      }),
    );

    // بررسی پاسخ سرور
    if (response.statusCode != 200 || response.body.isEmpty) {
      throw "پاسخ سرور معتبر نیست. لطفاً سرور را بررسی کنید.";
    }

    final data = jsonDecode(response.body);

    // بررسی موفقیت‌آمیز بودن ورود و وجود توکن
    if (data['success'] == true && data['token'] != null) {
      // **تغییر اینجا:** استفاده از User.fromLoginJson
      return User.fromLoginJson(data['user'], data['token']);
    } else {
      // نمایش پیام خطا در صورت ناموفق بودن ورود
      throw data['message'] ?? 'خطا در ورود';
    }
  }

  // متد ایجاد کاربر جدید (فقط برای مدیران)
  static Future<String> createUser({
    required String adminToken,
    required String username,
    required String email,
    required String fullName,
    required String password,
    String role = 'user',
  }) async {
    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization':
            'Bearer $adminToken', // ارسال توکن مدیر برای احراز هویت
      },
      body: jsonEncode({
        'action': 'create_user',
        'username': username,
        'email': email,
        'full_name': fullName,
        'role': role,
        'password': password,
      }),
    );

    // بررسی پاسخ سرور
    if (response.statusCode != 200 || response.body.isEmpty) {
      throw "پاسخ سرور معتبر نیست. لطفاً سرور را بررسی کنید.";
    }

    final data = jsonDecode(response.body);

    // بررسی موفقیت‌آمیز بودن ساخت کاربر
    if (data['success'] == true) {
      return "کاربر با موفقیت ساخته شد";
    } else {
      throw data['message'] ?? 'خطا در ساخت کاربر';
    }
  }

  // متد دریافت لیست کاربران
  static Future<List<User>> getUsers(String adminToken) async {
    final response = await http.get(
      Uri.parse('$baseUrl?action=get_users'),
      headers: {
        'Authorization':
            'Bearer $adminToken', // ارسال توکن مدیر برای احراز هویت
        'Content-Type': 'application/json',
      },
    );

    // بررسی پاسخ سرور
    if (response.statusCode != 200 || response.body.isEmpty) {
      throw "پاسخ سرور معتبر نیست.";
    }

    final data = json.decode(response.body);

    // بررسی موفقیت‌آمیز بودن دریافت لیست کاربران
    if (data['success']) {
      // **تغییر اینجا:** استفاده از User.fromListJson
      return (data['users'] as List)
          .map((userJson) => User.fromListJson(userJson))
          .toList();
    } else {
      throw Exception(data['message']);
    }
  }

  // متد دریافت لیست پست‌ها
  static Future<List<Post>> getPosts() async {
    // این متد نیازی به توکن احراز هویت ندارد، اما اگر پست‌ها نیاز به لاگین برای نمایش دارند، باید توکن را اضافه کنید.
    final response = await http.get(Uri.parse('$baseUrl?action=get_posts'));

    // بررسی پاسخ سرور
    if (response.statusCode != 200 || response.body.isEmpty) {
      throw "پاسخ سرور معتبر نیست.";
    }

    final data = json.decode(response.body);

    // بررسی موفقیت‌آمیز بودن دریافت لیست پست‌ها
    if (data['success']) {
      return (data['posts'] as List)
          .map((post) => Post.fromJson(post)) // Post.fromJson درست است
          .toList();
    } else {
      throw Exception(data['message']);
    }
  }

  // متد ایجاد پست جدید (از پنل مدیریت فلاتر حذف شد اما در API باقی می‌ماند)
  static Future<void> createPost({
    required String token,
    required String title,
    required String content,
    required String category,
  }) async {
    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'action': 'create_post',
        'title': title,
        'content': content,
        'category': category,
      }),
    );

    // بررسی پاسخ سرور
    if (response.statusCode != 200 || response.body.isEmpty) {
      throw "پاسخ سرور معتبر نیست.";
    }

    final data = json.decode(response.body);

    // بررسی موفقیت‌آمیز بودن ایجاد پست
    if (!data['success']) {
      throw Exception(data['message']);
    }
  }

  // متد ویرایش پست
  static Future<void> updatePost({
    required String token,
    required int postId,
    required String title,
    required String content,
    required String category,
  }) async {
    final response = await http.put(
      Uri.parse(baseUrl),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'action': 'update_post',
        'post_id': postId,
        'title': title,
        'content': content,
        'category': category,
      }),
    );

    // بررسی پاسخ سرور
    if (response.statusCode != 200 || response.body.isEmpty) {
      throw "پاسخ سرور معتبر نیست.";
    }

    final data = json.decode(response.body);

    // بررسی موفقیت‌آمیز بودن به‌روزرسانی پست
    if (!data['success']) {
      throw Exception(data['message']);
    }
  }

  // متد دریافت لیست الگوهای آسان‌پوستر از وردپرس
  static Future<List<Map<String, dynamic>>> getWordPressTemplates(
    String siteUrl,
  ) async {
    try {
      final host = Uri.parse(siteUrl).host;
      // ساخت رشته هش برای احراز هویت با پلاگین وردپرس
      final hashString = '1234$host' + '6789';
      final hash = md5.convert(utf8.encode(hashString)).toString();

      final uri = Uri.parse(
        '$siteUrl/wp-admin/admin-ajax.php?action=get_mep_templates&hash=$hash',
      );

      final response = await http.get(uri);

      if (response.statusCode != 200) {
        throw Exception('خطا در دریافت لیست الگوها: ${response.statusCode}');
      }

      final data = jsonDecode(response.body);

      if (data['success'] == true) {
        return List<Map<String, dynamic>>.from(data['templates'] ?? []);
      } else {
        throw Exception(data['message'] ?? 'دریافت الگوها ناموفق بود');
      }
    } catch (e) {
      throw Exception('خطا در دریافت الگوها: $e');
    }
  }

  // متد ارسال پست به وردپرس با انتخاب الگو (ویژه آسان‌پوستر)
  static Future<void> sendPostToWordPressEasyPoster({
    required String siteUrl,
    required String artist,
    required String song,
    required String artistEn,
    required String songEn,
    required String url320,
    required String url128,
    required String urlTeaser,
    required String urlImage,
    required String lyric,
    int? sample, // شناسه الگو
    int? author, // شناسه نویسنده
  }) async {
    final uri = Uri.parse('$siteUrl/wp-admin/admin-ajax.php?action=mep_api');
    final host = Uri.parse(siteUrl).host;
    // ساخت رشته هش برای احراز هویت با پلاگین وردپرس
    final hashString = '1234$host' + '6789';
    final hash = md5.convert(utf8.encode(hashString)).toString();

    try {
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        }, // نوع محتوا برای ارسال فرم URL-encoded
        body: {
          'hash': hash,
          'artist': artist,
          'song': song,
          'artist_en': artistEn,
          'song_en': songEn,
          'url_320': url320,
          'url_128': url128,
          'url_teaser': urlTeaser,
          'url_image': urlImage,
          'lyric': lyric,
          if (sample != null)
            'sample': sample.toString(), // افزودن شناسه الگو در صورت وجود
          if (author != null)
            'author': author.toString(), // افزودن شناسه نویسنده در صورت وجود
        },
      );

      if (response.statusCode != 200) {
        throw Exception('خطا در ارسال پست: ${response.statusCode}');
      }

      final jsonResponse = jsonDecode(response.body);

      // بررسی موفقیت‌آمیز بودن ارسال پست وردپرس
      if (jsonResponse['success'] != true) {
        throw Exception(
          jsonResponse['data']?['text'] ??
              'خطای ناشناخته هنگام ارسال!', // نمایش پیام خطای خاص پلاگین
        );
      }
    } catch (e) {
      throw Exception('خطا در ارسال درخواست: $e');
    }
  }
}
