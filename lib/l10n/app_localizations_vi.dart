// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class AppLocalizationsVi extends AppLocalizations {
  AppLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String get appTitle => 'Quản Lý Tài Chính';

  @override
  String get login => 'Đăng nhập';

  @override
  String get loginPin => 'Nhập PIN';

  @override
  String get loginEmail => 'Email';

  @override
  String get loginPassword => 'Mật khẩu';

  @override
  String get loginButton => 'Đăng nhập';

  @override
  String get home => 'Trang chủ';

  @override
  String get transactions => 'Giao dịch';

  @override
  String get addTransaction => 'Thêm giao dịch';

  @override
  String get editTransaction => 'Sửa giao dịch';

  @override
  String get transactionDetail => 'Chi tiết giao dịch';

  @override
  String get budgets => 'Hũ chi tiêu';

  @override
  String get addBudget => 'Thêm hũ chi tiêu';

  @override
  String get editBudget => 'Sửa hũ chi tiêu';

  @override
  String get budgetDetail => 'Chi tiết hũ chi tiêu';

  @override
  String get categories => 'Danh mục';

  @override
  String get addCategory => 'Thêm danh mục';

  @override
  String get editCategory => 'Sửa danh mục';

  @override
  String get reports => 'Báo cáo';

  @override
  String get settings => 'Cài đặt';

  @override
  String get amount => 'Số tiền';

  @override
  String get date => 'Ngày';

  @override
  String get category => 'Danh mục';

  @override
  String get account => 'Tài khoản';

  @override
  String get type => 'Loại';

  @override
  String get expense => 'Chi tiêu';

  @override
  String get income => 'Thu nhập';

  @override
  String get note => 'Ghi chú';

  @override
  String get receipt => 'Hóa đơn';

  @override
  String get save => 'Lưu';

  @override
  String get cancel => 'Hủy';

  @override
  String get delete => 'Xóa';

  @override
  String get edit => 'Sửa';

  @override
  String get confirmDelete => 'Bạn có chắc muốn xóa?';

  @override
  String get name => 'Tên';

  @override
  String get icon => 'Biểu tượng';

  @override
  String get color => 'Màu sắc';

  @override
  String get limit => 'Giới hạn';

  @override
  String get period => 'Chu kỳ';

  @override
  String get monthly => 'Hàng tháng';

  @override
  String get yearly => 'Hàng năm';

  @override
  String get custom => 'Tùy chỉnh';

  @override
  String get consumed => 'Đã dùng';

  @override
  String get remaining => 'Còn lại';

  @override
  String get overdraft => 'Vượt quá';

  @override
  String get allowOverdraft => 'Cho phép vượt quá';

  @override
  String get balance => 'Số dư';

  @override
  String get currency => 'Tiền tệ';

  @override
  String get cash => 'Tiền mặt';

  @override
  String get card => 'Thẻ';

  @override
  String get month => 'Tháng';

  @override
  String get year => 'Năm';

  @override
  String get total => 'Tổng';

  @override
  String get byCategory => 'Theo danh mục';

  @override
  String get topCategories => 'Danh mục hàng đầu';

  @override
  String get language => 'Ngôn ngữ';

  @override
  String get theme => 'Giao diện';

  @override
  String get light => 'Sáng';

  @override
  String get dark => 'Tối';

  @override
  String get logout => 'Đăng xuất';

  @override
  String get budgetExceeded => 'Vượt quá ngân sách';

  @override
  String budgetExceededMessage(String remaining) {
    return 'Giao dịch này sẽ vượt quá ngân sách. Còn lại: $remaining';
  }

  @override
  String get categoryInUse => 'Danh mục đang được sử dụng bởi các giao dịch';

  @override
  String get budgetOverlap => 'Hũ chi tiêu trùng với hũ chi tiêu hiện có';

  @override
  String get required => 'Trường này là bắt buộc';

  @override
  String get invalidAmount => 'Số tiền không hợp lệ';

  @override
  String get selectDate => 'Chọn ngày';

  @override
  String get selectCategory => 'Chọn danh mục';

  @override
  String get selectAccount => 'Chọn tài khoản';

  @override
  String get attachReceipt => 'Đính kèm hóa đơn';

  @override
  String get viewReceipt => 'Xem hóa đơn';

  @override
  String get share => 'Chia sẻ';

  @override
  String get export => 'Xuất';

  @override
  String get noTransactions => 'Không có giao dịch';

  @override
  String get noCategories => 'Không có danh mục';

  @override
  String get noBudgets => 'Không có hũ chi tiêu';

  @override
  String get noAccounts => 'Không có tài khoản';
}
