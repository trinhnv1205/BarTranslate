//
//  Localization.swift
//  BarTranslate
//
//  Lightweight in-app localization.
//
//  Translations live in code rather than in .strings/.xcstrings resources so
//  the app localizes consistently regardless of how literals are passed around
//  (many custom views take plain `String`, which SwiftUI renders verbatim).
//  Apply `.loc` to a user-facing English source string to get the translated
//  value for the user's selected/!system language.
//

import Foundation

/// User-facing language choice (Settings ▸ General ▸ Language).
enum AppLanguage: String, CaseIterable, Identifiable {
    case system
    case english
    case vietnamese

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .system:     return "System"
        case .english:    return "English"
        case .vietnamese: return "Tiếng Việt"
        }
    }
}

enum Localization {
    static let storageKey = "appLanguage"

    static var current: AppLanguage {
        AppLanguage(rawValue: UserDefaults.standard.string(forKey: storageKey) ?? "") ?? .system
    }

    /// Whether the UI should render in Vietnamese right now.
    static var isVietnamese: Bool {
        switch current {
        case .vietnamese: return true
        case .english:    return false
        case .system:
            // Locale.preferredLanguages works on all supported macOS versions.
            let pref = Locale.preferredLanguages.first ?? "en"
            return pref.hasPrefix("vi")
        }
    }

    /// Translate an English source string. Unknown strings fall back to English.
    static func string(_ english: String) -> String {
        guard isVietnamese else { return english }
        return viTable[english] ?? english
    }
}

extension String {
    /// Localized value of this English source string for the current language.
    var loc: String { Localization.string(self) }
}

// MARK: - Vietnamese translations

private let viTable: [String: String] = [
    // Pro / paywall
    "Upgrade": "Nâng cấp",
    "Upgrade to Pro": "Nâng cấp lên Pro",
    "Enter license key": "Nhập mã bản quyền",
    "Deactivate this Mac": "Hủy kích hoạt máy này",
    "Thank you for your support!": "Cảm ơn bạn đã ủng hộ!",
    "Trial active": "Đang dùng thử",
    "Unlock unlimited history, iCloud sync & export":
        "Mở khóa lịch sử không giới hạn, đồng bộ iCloud & xuất dữ liệu",
    "Activate BarTranslate Pro": "Kích hoạt BarTranslate Pro",
    "Enter the license key from your purchase confirmation email.":
        "Nhập mã bản quyền từ email xác nhận mua hàng.",
    "Buy a license": "Mua bản quyền",
    "Cancel": "Hủy",
    "Activate": "Kích hoạt",
    "That license key is not valid. Check for typos and try again.":
        "Mã bản quyền không hợp lệ. Vui lòng kiểm tra lại và thử lần nữa.",
    "Deactivate": "Hủy kích hoạt",

    // Onboarding
    "Translate from your menu bar": "Dịch ngay từ thanh menu",
    "BarTranslate keeps Google Translate one click — or one hotkey — away, anywhere on your Mac.":
        "BarTranslate giúp bạn mở Google Dịch chỉ với một cú nhấp — hoặc một phím tắt — ở bất kỳ đâu trên máy Mac.",
    "Fast by default": "Nhanh ngay từ đầu",
    "Open with ⌥; , translate the clipboard instantly, and auto-paste results back into the app you were using.":
        "Mở bằng ⌥; , dịch nội dung clipboard tức thì, và tự động dán kết quả trở lại ứng dụng bạn đang dùng.",
    "Learn as you go": "Học khi sử dụng",
    "Save translations to history and review them as spaced-repetition flashcards to build vocabulary.":
        "Lưu bản dịch vào lịch sử và ôn lại bằng thẻ ghi nhớ lặp lại ngắt quãng để xây vốn từ.",
    "Try Pro free for 14 days": "Dùng thử Pro miễn phí 14 ngày",
    "Every premium feature — unlimited history, iCloud sync and CSV export — is unlocked during your trial.":
        "Mọi tính năng cao cấp — lịch sử không giới hạn, đồng bộ iCloud và xuất CSV — đều được mở khóa trong thời gian dùng thử.",
    "Continue": "Tiếp tục",
    "Get Started": "Bắt đầu",
    "Translate into": "Dịch sang",

    // Trial expiry
    "Your BarTranslate Pro trial has ended": "Thời gian dùng thử BarTranslate Pro đã kết thúc",
    "You can keep using BarTranslate for free. Upgrade to Pro to restore unlimited history, iCloud sync, and export/backup.":
        "Bạn vẫn có thể tiếp tục dùng BarTranslate miễn phí. Nâng cấp lên Pro để khôi phục lịch sử không giới hạn, đồng bộ iCloud và xuất/sao lưu dữ liệu.",
    "Maybe Later": "Để sau",

    // Settings sections & rows
    "Provider": "Nhà cung cấp",
    "Translation engine": "Công cụ dịch",
    "Keyboard Shortcut": "Phím tắt",
    "Toggle app": "Bật/tắt ứng dụng",
    "Translate now": "Dịch ngay",
    "Swap languages": "Đổi ngôn ngữ",
    "Translate clipboard": "Dịch clipboard",
    "Copy result": "Sao chép kết quả",
    "Clipboard": "Clipboard",
    "Auto paste on open": "Tự dán khi mở",
    "Auto translate clipboard": "Tự dịch clipboard",
    "History": "Lịch sử",
    "Saved items": "Số mục lưu",
    "In-Place": "Tại chỗ",
    "After translation": "Sau khi dịch",
    "Do nothing": "Không làm gì",
    "Copy result ": "Sao chép kết quả",
    "Paste to previous app": "Dán vào ứng dụng trước",
    "Appearance": "Giao diện",
    "Web theme": "Chủ đề trang web",
    "System": "Hệ thống",
    "Light": "Sáng",
    "Dark": "Tối",
    "Popover size": "Kích thước cửa sổ",
    "Compact": "Nhỏ gọn",
    "Normal": "Bình thường",
    "Wide": "Rộng",
    "Pin popover": "Ghim cửa sổ",
    "General": "Chung",
    "Language": "Ngôn ngữ",
    "Launch at login": "Mở khi đăng nhập",
    "iCloud sync": "Đồng bộ iCloud",
    "Check for updates": "Kiểm tra cập nhật",
    "About": "Giới thiệu",
    "Version": "Phiên bản",
    "Updates": "Cập nhật",
    "Check now": "Kiểm tra ngay",
    "Support & Legal": "Hỗ trợ & Pháp lý",
    "Send feedback": "Gửi phản hồi",
    "Rate BarTranslate": "Đánh giá BarTranslate",
    "Website": "Trang web",
    "Privacy Policy": "Chính sách bảo mật",
    "Terms of Use": "Điều khoản sử dụng",
    "Sponsor this project": "Ủng hộ dự án này",
    "Quit BarTranslate": "Thoát BarTranslate",

    // Navigation tabs
    "Translate": "Dịch",
    "Flashcards": "Thẻ ghi nhớ",
    "Settings": "Cài đặt",

    // Translate view
    "Loading…": "Đang tải…",
    "Can't reach Google Translate": "Không kết nối được Google Dịch",
    "Check your internet connection and try again.": "Kiểm tra kết nối mạng và thử lại.",
    "Retry": "Thử lại",
    "Copy": "Sao chép",
    "Copied!": "Đã sao chép!",

    // History view
    "Search source, result, or language": "Tìm theo nguồn, kết quả hoặc ngôn ngữ",
    "All": "Tất cả",
    "No translations yet": "Chưa có bản dịch nào",
    "Use Translate tab or clipboard auto translate to build history":
        "Dùng tab Dịch hoặc tự dịch clipboard để tạo lịch sử",
    "No matches": "Không có kết quả",
    "Try a different search or filter": "Thử từ khóa hoặc bộ lọc khác",
    "Export CSV": "Xuất CSV",
    "Backup": "Sao lưu",
    "Restore": "Khôi phục",
    "Clear non-favorites": "Xóa mục không yêu thích",

    // Flashcards
    "Search flashcards": "Tìm thẻ ghi nhớ",
    "Due only": "Chỉ thẻ đến hạn",
    "Deck": "Bộ thẻ",
    "Due": "Đến hạn",
    "Mastered": "Đã thuộc",
    "Front": "Mặt trước",
    "Back": "Mặt sau",
    "Prev": "Trước",
    "Flip": "Lật",
    "Hide": "Ẩn",
    "Again": "Lại",
    "Remembered": "Đã nhớ",
    "No flashcards available": "Chưa có thẻ ghi nhớ",
    "Add cards from History, or disable Due only to review everything":
        "Thêm thẻ từ Lịch sử, hoặc tắt 'Chỉ thẻ đến hạn' để ôn tất cả",
]
