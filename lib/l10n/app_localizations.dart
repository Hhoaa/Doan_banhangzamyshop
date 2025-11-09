import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        AppLocalizations(const Locale('vi'));
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static final Map<String, Map<String, String>> _localizedValues = {
    'vi': {
      // Common
      'app_name': 'Zamy Shop',
      'loading': 'Đang tải...',
      'error': 'Lỗi',
      'success': 'Thành công',
      'cancel': 'Hủy',
      'confirm': 'Xác nhận',
      'save': 'Lưu',
      'delete': 'Xóa',
      'edit': 'Sửa',
      'close': 'Đóng',
      'search': 'Tìm kiếm',
      'all_categories': 'Tất cả danh mục',
      'filter': 'Lọc',
      'sort': 'Sắp xếp',
      'apply': 'Áp dụng',
      'reset': 'Đặt lại',
      'take_photo': 'Chụp từ camera',
      'choose_from_gallery': 'Chọn từ thư viện',
      'no_results_try_another':
          'Không tìm thấy kết quả phù hợp. Hãy thử ảnh/ từ khóa khác.',
      'please_login_for_favorites':
          'Vui lòng đăng nhập để sử dụng tính năng yêu thích',
      'back': 'Quay lại',
      'next': 'Tiếp theo',
      'previous': 'Trước',
      'done': 'Hoàn thành',
      'select': 'Chọn',
      'please_select': 'Vui lòng chọn',
      'and': 'và',
      'all': 'Tất cả',
      'none': 'Không có',

      // Auth
      'login': 'Đăng nhập',
      'logout': 'Đăng xuất',
      'register': 'Đăng ký',
      'email': 'Email',
      'password': 'Mật khẩu',
      'confirm_password': 'Xác nhận mật khẩu',
      'forgot_password': 'Quên mật khẩu?',
      'remember_me': 'Nhớ đăng nhập',
      'login_with_google': 'Đăng nhập với Google',
      'login_with_apple': 'Đăng nhập với Apple',
      'login_with_phone': 'Đăng nhập bằng số điện thoại',
      'send_otp': 'Gửi mã OTP',
      'verify_otp': 'Xác thực OTP',
      'enter_otp': 'Nhập mã OTP',
      'resend_otp': 'Gửi lại mã OTP',
      'phone_number': 'Số điện thoại',
      'full_name': 'Họ và tên',
      'birthday': 'Ngày sinh',
      'gender': 'Giới tính',
      'address': 'Địa chỉ',
      'male': 'Nam',
      'female': 'Nữ',
      'other': 'Khác',
      'already_have_account': 'Đã có tài khoản?',
      'dont_have_account': 'Chưa có tài khoản?',
      'login_failed': 'Đăng nhập thất bại',
      'register_failed': 'Đăng ký thất bại',
      'invalid_email': 'Email không hợp lệ',
      'invalid_password': 'Mật khẩu không hợp lệ',
      'password_too_short': 'Mật khẩu phải có ít nhất 6 ký tự',
      'passwords_not_match': 'Mật khẩu không khớp',
      'invalid_phone': 'Số điện thoại không hợp lệ',
      'phone_invalid': 'Số điện thoại không hợp lệ',
      'phone_required': 'Vui lòng nhập số điện thoại',
      'phone_digits_rule':
          'Số điện thoại phải có 10 hoặc 11 số và bắt đầu bằng 0',
      'phone_already_used': 'Số điện thoại này đã được sử dụng',
      'phone_verified_success': 'Xác nhận số điện thoại thành công',
      'phone_required_for_order':
          'Vui lòng cập nhật số điện thoại để hoàn tất đơn hàng',
      'invalid_otp': 'Mã OTP không hợp lệ',
      'otp_expired': 'Mã OTP đã hết hạn',
      'admin_staff_cannot_login_app':
          'Tài khoản Admin và Quản trị viên không thể đăng nhập vào ứng dụng bán hàng. Vui lòng sử dụng tài khoản khách hàng.',
      'only_customer_role_web':
          'Chỉ tài khoản khách hàng (role = 3) mới được truy cập vào web bán hàng.',

      // Home
      'home': 'Trang chủ',
      'categories': 'Danh mục',
      'featured_products': 'Sản phẩm nổi bật',
      'new_products': 'Sản phẩm mới',
      'hot_products': 'Sản phẩm hot',
      'view_all': 'Xem tất cả',
      'see_more': 'Xem thêm',
      'collections': 'Bộ sưu tập',
      'no_banners': 'Chưa có banner nào',
      'coming_soon': 'Sản phẩm sẽ được cập nhật sớm',
      'no_collections': 'Chưa có bộ sưu tập nào',
      'collections_coming_soon': 'Bộ sưu tập sẽ được cập nhật sớm',

      // Products
      'products': 'Sản phẩm',
      'product_detail': 'Chi tiết sản phẩm',
      'add_to_cart': 'Thêm vào giỏ',
      'buy_now': 'Mua ngay',
      'sort_newest': 'Mới nhất',
      'sort_price_low_high': 'Giá: Thấp đến cao',
      'sort_price_high_low': 'Giá: Cao đến thấp',
      'sort_name_az': 'Tên: A-Z',
      'add_to_favorites': 'Thêm vào yêu thích',
      'added_to_favorites_success': 'Đã thêm vào danh mục yêu thích',
      'remove_from_favorites': 'Xóa khỏi yêu thích',
      'favorites': 'Yêu thích',
      'quantity': 'Số lượng',
      'size': 'Kích thước',
      'color': 'Màu sắc',
      'price': 'Giá',
      'product_description': 'Mô tả sản phẩm',
      'no_description': 'Chưa có mô tả sản phẩm',
      'store_location': 'Vị trí cửa hàng',
      'opening_hours': 'Giờ mở cửa',
      'directions': 'Chỉ đường',
      'cannot_open_maps':
          'Không thể mở Google Maps. Vui lòng kiểm tra kết nối internet.',
      'original_price': 'Giá gốc',
      'discount': 'Giảm giá',
      'stock': 'Tồn kho',
      'out_of_stock': 'Hết hàng',
      'in_stock': 'Còn hàng',
      'low_stock': 'Sắp hết hàng',
      'description': 'Mô tả',
      'specifications': 'Thông số kỹ thuật',
      'reviews': 'Đánh giá',
      'related_products': 'Sản phẩm liên quan',
      'no_products': 'Không có sản phẩm',
      'no_products_found': 'Không tìm thấy sản phẩm',
      'delete_all': 'Xóa tất cả',
      // Cart
      'cart': 'Giỏ hàng',
      'my_cart': 'Giỏ hàng của tôi',
      'empty_cart': 'Giỏ hàng trống',
      'cart_empty_message': 'Giỏ hàng của bạn đang trống',
      'continue_shopping': 'Tiếp tục mua sắm',
      'total': 'Tổng cộng',
      'subtotal': 'Tạm tính',
      'shipping_fee': 'Phí vận chuyển',
      'total_amount': 'Tổng tiền',
      'remove_item': 'Xóa sản phẩm',
      'update_cart': 'Cập nhật giỏ hàng',
      'added_to_cart': 'Đã thêm vào giỏ hàng',
      'failed_to_add_cart': 'Lỗi khi thêm vào giỏ hàng',
      'cart_item_not_found':
          'Không tìm thấy sản phẩm trong giỏ hàng. Vui lòng thử lại.',

      // Checkout
      'checkout': 'Thanh toán',
      'order_summary': 'Tóm tắt đơn hàng',
      'shipping_address': 'Địa chỉ giao hàng',
      'payment_method': 'Phương thức thanh toán',
      'payment_methods': 'Phương thức thanh toán',
      'cod': 'Thanh toán khi nhận hàng',
      'bank_transfer': 'Chuyển khoản ngân hàng',
      'vnpay': 'VNPay',
      'order_note': 'Ghi chú đơn hàng',
      'place_order': 'Đặt hàng',
      'processing_payment': 'Đang xử lý thanh toán...',
      'order_placed_success': 'Đặt hàng thành công',
      'order_placed_failed': 'Đặt hàng thất bại',
      'payment_failed': 'Thanh toán thất bại',
      'please_select_address': 'Vui lòng chọn địa chỉ giao hàng',
      'please_select_payment': 'Vui lòng chọn phương thức thanh toán',

      // Orders
      'orders': 'Đơn hàng',
      'my_orders': 'Đơn hàng của tôi',
      'order_history': 'Lịch sử đơn hàng',
      'order_details': 'Chi tiết đơn hàng',
      'order_id': 'Mã đơn hàng',
      'order_date': 'Ngày đặt hàng',
      'order_status': 'Trạng thái đơn hàng',
      'pending': 'Đang chờ',
      'confirmed': 'Đã xác nhận',
      'processing': 'Đang xử lý',
      'shipping': 'Đang giao hàng',
      'delivered': 'Đã giao hàng',
      'cancelled': 'Đã hủy',
      'cancel_order': 'Hủy đơn hàng',
      'reorder': 'Đặt lại',
      'track_order': 'Theo dõi đơn hàng',
      'no_orders': 'Không có đơn hàng',
      'no_orders_found': 'Không tìm thấy đơn hàng',

      // Profile
      'profile': 'Hồ sơ',
      'my_profile': 'Hồ sơ của tôi',
      'account_settings': 'Cài đặt tài khoản',
      'personal_info': 'Thông tin cá nhân',
      'change_password': 'Đổi mật khẩu',
      'current_password': 'Mật khẩu hiện tại',
      'new_password': 'Mật khẩu mới',
      'change_avatar': 'Đổi ảnh đại diện',
      'logout_confirm': 'Bạn có chắc chắn muốn đăng xuất?',

      // Address
      'addresses': 'Địa chỉ',
      'my_addresses': 'Địa chỉ của tôi',
      'add_address': 'Thêm địa chỉ',
      'edit_address': 'Sửa địa chỉ',
      'delete_address': 'Xóa địa chỉ',
      'default_address': 'Địa chỉ mặc định',
      'set_as_default': 'Đặt làm mặc định',
      'receiver_name': 'Tên người nhận',
      'receiver_phone': 'Số điện thoại người nhận',
      'province': 'Tỉnh/Thành phố',
      'district': 'Quận/Huyện',
      'ward': 'Phường/Xã',
      'street': 'Đường/Số nhà',
      'no_addresses': 'Không có địa chỉ',
      'please_add_address': 'Vui lòng thêm địa chỉ',

      // Language
      'language': 'Ngôn ngữ',
      'vietnamese': 'Tiếng Việt',
      'english': 'English',
      'change_language': 'Đổi ngôn ngữ',

      // Notifications
      'notifications': 'Thông báo',
      'no_notifications': 'Không có thông báo',
      'mark_all_read': 'Đánh dấu tất cả đã đọc',
      'notification_settings': 'Cài đặt thông báo',

      // Footer
      'about_us': 'Về chúng tôi',
      'contact': 'Liên hệ',
      'terms': 'Điều khoản',
      'privacy': 'Chính sách bảo mật',
      'follow_us': 'Theo dõi chúng tôi',
      'customer_service': 'Dịch vụ khách hàng',
      'help_center': 'Trung tâm trợ giúp',
      'news': 'Tin tức',
      'store': 'Cửa hàng',
      'shipping_policy': 'Chính sách vận chuyển',
      'return_policy': 'Trả hàng',
      'size_guide': 'Hướng dẫn chọn size',

      // Web Header
      'search_placeholder': 'Tìm kiếm sản phẩm...',
      'cart_count': 'Giỏ hàng',
      'account': 'Tài khoản',
      'tagline': 'Thời trang cho mọi người',
      'nav_dress': 'Đầm',
      'nav_shirt': 'Áo',
      'nav_pants': 'Quần',
      'nav_skirt': 'Chân váy',
      'nav_lookbook': 'Lookbook',
      'nav_about_us': 'Về chúng tôi',

      // Forgot password / Reset
      'reset_password': 'Đặt lại mật khẩu',
      'enter_your_email': 'Nhập email của bạn',
      'send_reset_link': 'Gửi link đặt lại',
      'email_sent': 'Email đã được gửi!',
      'please_check_email': 'Vui lòng kiểm tra email:',
      'back_to_login': 'Quay lại đăng nhập',
      'resend_email': 'Gửi lại email',
      'reset_help':
          'Nếu bạn không nhận được email, vui lòng kiểm tra thư mục spam hoặc liên hệ hỗ trợ.',
      'reset_email_sent_success':
          'Email đặt lại mật khẩu đã được gửi thành công!',
      'account_created_check_email':
          'Tài khoản của bạn đã được tạo. Vui lòng kiểm tra email để xác thực tài khoản.',

      // Messages
      'confirm_delete': 'Bạn có chắc chắn muốn xóa?',
      'delete_success': 'Xóa thành công',
      'delete_failed': 'Xóa thất bại',
      'save_success': 'Lưu thành công',
      'save_failed': 'Lưu thất bại',
      'update_success': 'Cập nhật thành công',
      'update_failed': 'Cập nhật thất bại',
      'network_error': 'Lỗi kết nối mạng',
      'server_error': 'Lỗi máy chủ',
      'unknown_error': 'Lỗi không xác định',
      'update_phone': 'Cập nhật số điện thoại',
      'enter_new_phone': 'Nhập số điện thoại mới',
      // Auth/Login/Register
      'login_title': 'Đăng nhập',
      'username': 'Tên đăng nhập',
      'password': 'Mật khẩu',
      'forgot_password_q': 'Quên mật khẩu?',
      'login_with': 'hoặc đăng nhập với',
      'register_now': 'Đăng ký ngay',
      'no_account_q': 'Chưa có tài khoản? ',
      'have_account_q': 'Đã có tài khoản? ',
      'register_title': 'Đăng ký',
      'full_name': 'Họ và tên',
      'phone_number': 'Số điện thoại',
      'email_or_username': 'Email hoặc tên đăng nhập',
      'confirm_password': 'Xác nhận mật khẩu',
      'create_account': 'Tạo tài khoản',
      'login_failed': 'Đăng nhập thất bại',
      'register_failed': 'Đăng ký thất bại',
      'ok': 'OK',
      'notification': 'Thông báo',
      // Address
      'add_address': 'Thêm địa chỉ',
      'edit_address': 'Chỉnh sửa địa chỉ',
      'receiver_info': 'Thông tin người nhận',
      'enter_full_name': 'Nhập họ và tên người nhận',
      'enter_phone': 'Nhập số điện thoại',
      'address_section': 'Địa chỉ',
      'address_line1': 'Địa chỉ',
      'address_line1_hint': 'Số nhà, tên đường',
      'address_line2': 'Địa chỉ bổ sung',
      'address_line2_hint': 'Tòa nhà, căn hộ, số tầng...',
      'ward': 'Phường/Xã',
      'district': 'Quận/Huyện',
      'city': 'Tỉnh/Thành phố',
      'postal_code': 'Mã bưu điện',
      'address_type': 'Loại địa chỉ',
      'set_default_address': 'Đặt làm địa chỉ mặc định',
      'default_address_note': 'Địa chỉ này sẽ được chọn mặc định khi đặt hàng',
      'save': 'Lưu',
      'update': 'Cập nhật',
      'address_added_success': 'Đã thêm địa chỉ thành công',
      'address_updated_success': 'Đã cập nhật địa chỉ thành công',
      'error': 'Lỗi',
      'login_to_manage_addresses': 'Vui lòng đăng nhập để quản lý địa chỉ',
      'address_deleted_success': 'Đã xóa địa chỉ thành công',
      'set_default_success': 'Đã đặt địa chỉ mặc định',
      'delete_address': 'Xóa địa chỉ',
      'confirm_delete_address': 'Bạn có chắc chắn muốn xóa địa chỉ này?',
      'cancel': 'Hủy',
      'delete': 'Xóa',
      'manage_addresses': 'Quản lý địa chỉ',
      'add_new_address': 'Thêm địa chỉ mới',
      'no_addresses': 'Chưa có địa chỉ nào',
      'add_address_to_continue': 'Thêm địa chỉ để tiếp tục đặt hàng',
      'add_first_address': 'Thêm địa chỉ đầu tiên',
      'select_shipping_address': 'Chọn địa chỉ giao hàng',
      'confirm_address': 'Xác nhận địa chỉ',
      'login_to_select_address': 'Vui lòng đăng nhập để chọn địa chỉ',
      'default': 'Mặc định',
      // AI Chat
      'ai_chat_title': 'AI Tư vấn thời trang',
      'refresh_chat': 'Làm mới cuộc trò chuyện',
      'type_message_hint': 'Nhập tin nhắn...',
      'ai_thinking': 'AI đang suy nghĩ...',
      'just_now': 'Vừa xong',
      'minutes_ago': '{min} phút trước',
      'hours_ago': '{hour} giờ trước',
      'open_product_failed': 'Không thể mở sản phẩm này',
      'added_to_cart_item': 'Đã thêm {name} vào giỏ hàng',
      'welcome_ai': 'Xin chào! Tôi là AI tư vấn thời trang của Zamy Shop...',
      'cannot_analyze_image':
          'Xin lỗi, tôi không thể phân tích hình ảnh này. Vui lòng thử lại.',
      'tech_issue': 'Xin lỗi, tôi gặp sự cố kỹ thuật. Vui lòng thử lại sau.',
      'i_want_find_similar_image':
          'Tôi muốn tìm sản phẩm tương tự như hình này',
      'i_want_find_size': 'Tôi muốn tìm sản phẩm size {size}',
      // About Us
      'about_us_title': 'VỀ CHÚNG TÔI',
      'brand_story': 'CÂU CHUYỆN THƯƠNG HIỆU',
      'core_values': 'GIÁ TRỊ CỐT LÕI',
      'about_intro_1':
          'Tự hào là thương hiệu thời trang cao cấp tiên phong đồng hành cùng phụ nữ Việt, ZaMy là thương hiệu đánh thức sự lôi cuốn của phái đẹp. Với ZaMy mỗi người phụ nữ khi khoác lên mình trang phục của chúng tôi đều tràn đầy một ánh mắt đầy hạnh phúc,',
      'about_intro_2':
          'Tại ZaMy, mỗi "tác phẩm" đều được nâng niu, chăm chút với bao tâm huyết, khơi nguồn từ những nguồn cảm hứng bất tận. Trải qua gần 2 thập kỷ trên chặng đường định hình phong cách trẻ trung và thanh lịch cho người phụ nữ hiện đại,',
      'brand_story_paragraph':
          'Trên hành trình đó, chúng tôi nhận ra thời trang có khả năng trao quyền và thỏa mãn của người phụ nữ ở bất cứ đâu. Vì vậy, bên cạnh các tiêu chuẩn khắt khe về chất lượng được áp dụng theo quy chuẩn quốc tế, các thiết kế của ZAMY hiện tại hướng đến tính ứng dụng cao, giúp vẻ đẹp Việt luôn rạng rỡ và cuốn hút trong mọi hoàn cảnh, phù hợp với bối cảnh năng động của thời đại mới. Trong vòng hơn 15 năm qua, Eva de Eva đã hiện hữu với hệ thống hơn 30 của hàng trên toàn quốc, đồng hành cùng hàng trăm ngàn vẻ đẹp Việt, chúng tôi vẫn đang hưởng tới sự hoàn hảo hơn mỗi ngày để tiếp bước trên hành trình định hình phong cách trẻ trung và thanh lịch cho người phụ nữ hiện đại.',
      'core_values_intro':
          'Để hiện thực hóa tầm nhìn trở thành thương hiệu có ảnh hưởng đến xu hướng thời trang nữ tại Việt Nam và là lựa chọn ưa thích nhất trên thị trường nội địa, ZAMY tập trung phát triển 05 giá trị cốt lõi:',
      'core_value_1_vi': 'Chất lượng',
      'core_value_1_en': 'Quality',
      'core_value_2_vi': 'Thoải mái',
      'core_value_2_en': 'Comfortable',
      'core_value_3_vi': 'Tính ứng dụng cao',
      'core_value_3_en': 'Versatile',
      'core_value_4_vi': 'Hợp thời trang',
      'core_value_4_en': 'Fashionable',
      'core_value_5_vi': 'Thanh lịch',
      'core_value_5_en': 'Elegant',
      'about_overlay_chamo': 'Cham O',
      'about_overlay_just_date': 'JUST DATE',
      // Newsletter
      'newsletter_title': 'ĐĂNG KÍ NHẬN TIN',
      'newsletter_hint_email': 'Nhập email của bạn',
      'newsletter_subscribe': 'ĐĂNG KÝ',
      'newsletter_input_email_required': 'Vui lòng nhập email',
      'newsletter_subscribe_success': 'Đã đăng ký nhận tin với email: {email}',
      'delete_all_confirm': 'Bạn chắc chắn muốn xóa hết thông báo hay không?',
      // Additional
      'items_count': '{count} sản phẩm',
      'no_notifications_subtitle':
          'Chúng tôi sẽ thông báo cho bạn khi có cập nhật mới',
      'edit_profile': 'Chỉnh sửa thông tin',
      'login_to_use_full_features': 'Đăng nhập để sử dụng đầy đủ tính năng',
      'manage_orders_and_more': 'Quản lý đơn hàng, yêu thích và nhiều hơn nữa',
      'update_avatar_success': 'Cập nhật ảnh đại diện thành công',
      'update_avatar_failed': 'Lỗi cập nhật ảnh đại diện: {error}',
      'logout_failed': 'Đăng xuất thất bại: {error}',
      'no_favorites': 'Chưa có sản phẩm yêu thích',
      'no_favorites_subtitle':
          'Hãy thêm sản phẩm vào danh sách yêu thích để dễ dàng mua sắm sau',
      'removed_from_favorites_success': 'Đã xóa khỏi danh sách yêu thích',
    },
    'en': {
      // Common
      'app_name': 'Zamy Shop',
      'loading': 'Loading...',
      'error': 'Error',
      'success': 'Success',
      'cancel': 'Cancel',
      'confirm': 'Confirm',
      'save': 'Save',
      'delete': 'Delete',
      'edit': 'Edit',
      'close': 'Close',
      'search': 'Search',
      'all_categories': 'All categories',
      'filter': 'Filter',
      'sort': 'Sort',
      'apply': 'Apply',
      'reset': 'Reset',
      'take_photo': 'Take photo',
      'choose_from_gallery': 'Choose from gallery',
      'no_results_try_another':
          'No suitable results found. Try another image/keyword.',
      'please_login_for_favorites': 'Please log in to use favorites feature',
      'back': 'Back',
      'next': 'Next',
      'previous': 'Previous',
      'done': 'Done',
      'select': 'Select',
      'please_select': 'Please select',
      'and': 'and',
      'all': 'All',
      'none': 'None',

      // Auth
      'login': 'Login',
      'logout': 'Logout',
      'register': 'Register',
      'email': 'Email',
      'password': 'Password',
      'confirm_password': 'Confirm Password',
      'forgot_password': 'Forgot Password?',
      'remember_me': 'Remember Me',
      'login_with_google': 'Login with Google',
      'login_with_apple': 'Login with Apple',
      'login_with_phone': 'Login with Phone',
      'send_otp': 'Send OTP',
      'verify_otp': 'Verify OTP',
      'enter_otp': 'Enter OTP',
      'resend_otp': 'Resend OTP',
      'phone_number': 'Phone Number',
      'full_name': 'Full Name',
      'birthday': 'Birthday',
      'gender': 'Gender',
      'address': 'Address',
      'male': 'Male',
      'female': 'Female',
      'other': 'Other',
      'already_have_account': 'Already have an account?',
      'dont_have_account': "Don't have an account?",
      'login_failed': 'Login failed',
      'register_failed': 'Registration failed',
      'invalid_email': 'Invalid email',
      'invalid_password': 'Invalid password',
      'password_too_short': 'Password must be at least 6 characters',
      'passwords_not_match': 'Passwords do not match',
      'invalid_phone': 'Invalid phone number',
      'phone_invalid': 'Invalid phone number',
      'phone_required': 'Please enter your phone number',
      'phone_digits_rule':
          'Phone number must contain 10 or 11 digits and start with 0',
      'phone_already_used': 'This phone number is already in use',
      'phone_verified_success': 'Phone number verified successfully',
      'phone_required_for_order':
          'Please add a phone number to complete the order',
      'invalid_otp': 'Invalid OTP',
      'otp_expired': 'OTP expired',
      'admin_staff_cannot_login_app':
          'Admin and Staff accounts cannot login to the sales app. Please use a customer account.',
      'only_customer_role_web':
          'Only customer accounts (role = 3) can access the sales web.',

      // Home
      'home': 'Home',
      'categories': 'Categories',
      'featured_products': 'Featured Products',
      'new_products': 'New Products',
      'hot_products': 'Hot Products',
      'view_all': 'View All',
      'see_more': 'See More',
      'collections': 'Collections',
      'no_banners': 'No banners yet',
      'coming_soon': 'Products will be updated soon',
      'no_collections': 'No collections yet',
      'collections_coming_soon': 'Collections will be updated soon',

      // Products
      'products': 'Products',
      'product_detail': 'Product Detail',
      'add_to_cart': 'Add to Cart',
      'buy_now': 'Buy Now',
      'sort_newest': 'Newest',
      'sort_price_low_high': 'Price: Low to High',
      'sort_price_high_low': 'Price: High to Low',
      'sort_name_az': 'Name: A-Z',
      'add_to_favorites': 'Add to Favorites',
      'added_to_favorites_success': 'Added to favorites',
      'remove_from_favorites': 'Remove from Favorites',
      'favorites': 'Favorites',
      'quantity': 'Quantity',
      'size': 'Size',
      'color': 'Color',
      'price': 'Price',
      'product_description': 'Product description',
      'no_description': 'No description',
      'store_location': 'Store location',
      'opening_hours': 'Opening hours',
      'directions': 'Directions',
      'cannot_open_maps':
          'Cannot open Google Maps. Please check your internet connection.',
      'original_price': 'Original Price',
      'discount': 'Discount',
      'stock': 'Stock',
      'out_of_stock': 'Out of Stock',
      'in_stock': 'In Stock',
      'low_stock': 'Low Stock',
      'description': 'Description',
      'specifications': 'Specifications',
      'reviews': 'Reviews',
      'related_products': 'Related Products',
      'no_products': 'No Products',
      'no_products_found': 'No Products Found',

      // Cart
      'cart': 'Cart',
      'my_cart': 'My Cart',
      'empty_cart': 'Empty Cart',
      'cart_empty_message': 'Your cart is empty',
      'continue_shopping': 'Continue Shopping',
      'total': 'Total',
      'subtotal': 'Subtotal',
      'shipping_fee': 'Shipping Fee',
      'total_amount': 'Total Amount',
      'remove_item': 'Remove Item',
      'update_cart': 'Update Cart',
      'added_to_cart': 'Added to Cart',
      'failed_to_add_cart': 'Failed to add to cart',
      'cart_item_not_found': 'Product not found in cart. Please try again.',

      // Checkout
      'checkout': 'Checkout',
      'order_summary': 'Order Summary',
      'shipping_address': 'Shipping Address',
      'payment_method': 'Payment Method',
      'payment_methods': 'Payment Methods',
      'cod': 'Cash on Delivery',
      'bank_transfer': 'Bank Transfer',
      'vnpay': 'VNPay',
      'order_note': 'Order Note',
      'place_order': 'Place Order',
      'processing_payment': 'Processing Payment...',
      'order_placed_success': 'Order Placed Successfully',
      'order_placed_failed': 'Order Placement Failed',
      'payment_failed': 'Payment Failed',
      'please_select_address': 'Please select shipping address',
      'please_select_payment': 'Please select payment method',

      // Orders
      'orders': 'Orders',
      'my_orders': 'My Orders',
      'order_history': 'Order History',
      'order_details': 'Order Details',
      'order_id': 'Order ID',
      'order_date': 'Order Date',
      'order_status': 'Order Status',
      'pending': 'Pending',
      'confirmed': 'Confirmed',
      'processing': 'Processing',
      'shipping': 'Shipping',
      'delivered': 'Delivered',
      'cancelled': 'Cancelled',
      'cancel_order': 'Cancel Order',
      'reorder': 'Reorder',
      'track_order': 'Track Order',
      'no_orders': 'No Orders',
      'no_orders_found': 'No Orders Found',

      // Profile
      'profile': 'Profile',
      'my_profile': 'My Profile',
      'account_settings': 'Account Settings',
      'personal_info': 'Personal Information',
      'change_password': 'Change Password',
      'current_password': 'Current Password',
      'new_password': 'New Password',
      'change_avatar': 'Change Avatar',
      'logout_confirm': 'Are you sure you want to logout?',
      'delete_all': 'Delete all',
      // Address
      'addresses': 'Addresses',
      'my_addresses': 'My Addresses',
      'add_address': 'Add Address',
      'edit_address': 'Edit Address',
      'delete_address': 'Delete Address',
      'default_address': 'Default Address',
      'set_as_default': 'Set as Default',
      'receiver_name': 'Receiver Name',
      'receiver_phone': 'Receiver Phone',
      'province': 'Province/City',
      'district': 'District',
      'ward': 'Ward',
      'street': 'Street/House Number',
      'no_addresses': 'No Addresses',
      'please_add_address': 'Please add an address',

      // Language
      'language': 'Language',
      'vietnamese': 'Vietnamese',
      'english': 'English',
      'change_language': 'Change Language',

      // Notifications
      'notifications': 'Notifications',
      'no_notifications': 'No Notifications',
      'mark_all_read': 'Mark All as Read',
      'notification_settings': 'Notification Settings',

      // Footer
      'about_us': 'About Us',
      'contact': 'Contact',
      'terms': 'Terms',
      'privacy': 'Privacy Policy',
      'follow_us': 'Follow Us',
      'customer_service': 'Customer Service',
      'help_center': 'Help Center',
      'news': 'News',
      'store': 'Store',
      'shipping_policy': 'Shipping Policy',
      'return_policy': 'Return Policy',
      'size_guide': 'Size Guide',

      // Web Header
      'search_placeholder': 'Search products...',
      'cart_count': 'Cart',
      'account': 'Account',
      'tagline': 'Fashion for everyone',
      'nav_dress': 'Dresses',
      'nav_shirt': 'Tops',
      'nav_pants': 'Pants',
      'nav_skirt': 'Skirts',
      'nav_lookbook': 'Lookbook',
      'nav_about_us': 'About Us',

      // Forgot password / Reset
      'reset_password': 'Reset Password',
      'enter_your_email': 'Enter your email',
      'send_reset_link': 'Send reset link',
      'email_sent': 'Email sent!',
      'please_check_email': 'Please check your email:',
      'back_to_login': 'Back to login',
      'resend_email': 'Resend email',
      'reset_help':
          'If you did not receive the email, check spam or contact support.',
      'reset_email_sent_success': 'Password reset email sent successfully!',
      'account_created_check_email':
          'Your account has been created. Please check your email to verify.',

      // Messages
      'confirm_delete': 'Are you sure you want to delete?',
      'delete_success': 'Deleted successfully',
      'delete_failed': 'Delete failed',
      'save_success': 'Saved successfully',
      'save_failed': 'Save failed',
      'update_success': 'Updated successfully',
      'update_failed': 'Update failed',
      'network_error': 'Network error',
      'server_error': 'Server error',
      'unknown_error': 'Unknown error',
      'update_phone': 'Update phone number',
      'enter_new_phone': 'Enter new phone number',
      // Auth/Login/Register
      'login_title': 'Login',
      'username': 'Username',
      'password': 'Password',
      'forgot_password_q': 'Forgot Password?',
      'login_with': 'or login with',
      'register_now': 'Register now',
      'no_account_q': "Don't have an account? ",
      'have_account_q': 'Already have an account? ',
      'register_title': 'Register',
      'full_name': 'Full name',
      'phone_number': 'Phone number',
      'email_or_username': 'Email or username',
      'confirm_password': 'Confirm Password',
      'create_account': 'Create account',
      'login_failed': 'Login failed',
      'register_failed': 'Registration failed',
      'ok': 'OK',
      'notification': 'Notification',
      // Address
      'add_address': 'Add address',
      'edit_address': 'Edit address',
      'receiver_info': 'Receiver information',
      'enter_full_name': 'Enter receiver full name',
      'enter_phone': 'Enter phone number',
      'address_section': 'Address',
      'address_line1': 'Address',
      'address_line1_hint': 'Street, house number',
      'address_line2': 'Additional address',
      'address_line2_hint': 'Building, apartment, floor...',
      'ward': 'Ward',
      'district': 'District',
      'city': 'City/Province',
      'postal_code': 'Postal code',
      'address_type': 'Address type',
      'set_default_address': 'Set as default address',
      'default_address_note':
          'This address will be selected by default at checkout',
      'save': 'Save',
      'update': 'Update',
      'address_added_success': 'Address added successfully',
      'address_updated_success': 'Address updated successfully',
      'error': 'Error',
      'login_to_manage_addresses': 'Please login to manage addresses',
      'address_deleted_success': 'Address deleted successfully',
      'set_default_success': 'Default address set',
      'delete_address': 'Delete address',
      'confirm_delete_address': 'Are you sure you want to delete this address?',
      'cancel': 'Cancel',
      'delete': 'Delete',
      'manage_addresses': 'Manage addresses',
      'add_new_address': 'Add new address',
      'no_addresses': 'No addresses yet',
      'add_address_to_continue': 'Add an address to continue ordering',
      'add_first_address': 'Add first address',
      'select_shipping_address': 'Select shipping address',
      'confirm_address': 'Confirm address',
      'login_to_select_address': 'Please login to select an address',
      'default': 'Default',
      // AI Chat
      'ai_chat_title': 'AI Fashion Assistant',
      'refresh_chat': 'Refresh conversation',
      'type_message_hint': 'Type a message...',
      'ai_thinking': 'AI is thinking...',
      'just_now': 'Just now',
      'minutes_ago': '{min} minutes ago',
      'hours_ago': '{hour} hours ago',
      'open_product_failed': "Couldn't open this product",
      'added_to_cart_item': 'Added {name} to cart',
      'welcome_ai': 'Hello! I am Zamy Shop\'s fashion AI assistant...',
      'cannot_analyze_image':
          'Sorry, I cannot analyze this image. Please try again.',
      'tech_issue':
          'Sorry, I encountered a technical issue. Please try again later.',
      'i_want_find_similar_image':
          'I want to find products similar to this image',
      'i_want_find_size': 'I want to find size {size}',
      // About Us
      'about_us_title': 'ABOUT US',
      'brand_story': 'BRAND STORY',
      'core_values': 'CORE VALUES',
      'about_intro_1':
          'Proud to be a pioneering premium fashion brand accompanying Vietnamese women, ZaMy awakens the allure of femininity. At ZaMy, every woman in our designs shines with happiness.',
      'about_intro_2':
          'At ZaMy, each "work" is carefully crafted with dedication, inspired by endless sources. For nearly two decades, we have shaped a youthful and elegant style for modern women.',
      'brand_story_paragraph':
          'Along that journey, we realized fashion can empower women anywhere. In addition to strict international quality standards, ZAMY designs emphasize high versatility, helping Vietnamese beauty shine in every context of the modern era. Over the past 15+ years, we have expanded nationwide and continue striving for perfection in defining a youthful and elegant style for modern women.',
      'core_values_intro':
          'To realize our vision of influencing women’s fashion trends in Vietnam and becoming the most preferred local brand, ZAMY focuses on 5 core values:',
      'core_value_1_vi': 'Chất lượng',
      'core_value_1_en': 'Quality',
      'core_value_2_vi': 'Thoải mái',
      'core_value_2_en': 'Comfortable',
      'core_value_3_vi': 'Tính ứng dụng cao',
      'core_value_3_en': 'Versatile',
      'core_value_4_vi': 'Hợp thời trang',
      'core_value_4_en': 'Fashionable',
      'core_value_5_vi': 'Thanh lịch',
      'core_value_5_en': 'Elegant',
      'about_overlay_chamo': 'Cham O',
      'about_overlay_just_date': 'JUST DATE',
      // Newsletter
      'newsletter_title': 'SUBSCRIBE TO NEWSLETTER',
      'newsletter_hint_email': 'Enter your email',
      'newsletter_subscribe': 'SUBSCRIBE',
      'newsletter_input_email_required': 'Please enter your email',
      'newsletter_subscribe_success': 'Subscribed with email: {email}',
      'delete_all_confirm': 'Delete all ?',
      // Additional
      'items_count': '{count} items',
      'no_notifications_subtitle': 'We will notify you when there are updates',
      'edit_profile': 'Edit profile',
      'login_to_use_full_features': 'Log in to use full features',
      'manage_orders_and_more': 'Manage orders, favorites and more',
      'update_avatar_success': 'Avatar updated successfully',
      'update_avatar_failed': 'Failed to update avatar: {error}',
      'logout_failed': 'Logout failed: {error}',
      'no_favorites': 'No favorite products yet',
      'no_favorites_subtitle':
          'Add items to favorites to shop more easily later',
      'removed_from_favorites_success': 'Removed from favorites',
    },
  };

  String translate(String key) {
    return _localizedValues[locale.languageCode]?[key] ?? key;
  }

  // Getters for common strings
  String get appName => translate('app_name');
  String get loading => translate('loading');
  String get error => translate('error');
  String get success => translate('success');
  String get cancel => translate('cancel');
  String get confirm => translate('confirm');
  String get save => translate('save');
  String get delete => translate('delete');
  String get edit => translate('edit');
  String get close => translate('close');
  String get search => translate('search');
  String get back => translate('back');
  String get login => translate('login');
  String get loginFailed => translate('login_failed');
  String get logout => translate('logout');
  String get register => translate('register');
  String get email => translate('email');
  String get password => translate('password');
  String get ok => translate('ok');
  String get phone_number => translate('phone_number');
  String get home => translate('home');
  String get products => translate('products');
  String get cart => translate('cart');
  String get checkout => translate('checkout');
  String get orders => translate('orders');
  String get profile => translate('profile');
  String get favorites => translate('favorites');
  String get language => translate('language');
  String get vietnamese => translate('vietnamese');
  String get english => translate('english');
  String get addToCart => translate('add_to_cart');
  String get buyNow => translate('buy_now');
  String get quantity => translate('quantity');
  String get size => translate('size');
  String get color => translate('color');
  String get price => translate('price');
  String get description => translate('description');
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['vi', 'en'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
