#!/bin/bash

# Script để test tính năng thêm ngân sách

echo "========================================="
echo "TEST TÍNH NĂNG THÊM NGÂN SÁCH"
echo "========================================="
echo ""

cd "$(dirname "$0")"

echo "1. Cleaning project..."
flutter clean > /dev/null 2>&1

echo "2. Getting dependencies..."
flutter pub get > /dev/null 2>&1

echo "3. Running code generation..."
flutter pub run build_runner build --delete-conflicting-outputs > /dev/null 2>&1

echo "4. Analyzing code..."
flutter analyze --no-pub 2>&1 | head -20

echo ""
echo "5. Running budget creation tests..."
flutter test test/budget_create_test.dart

echo ""
echo "========================================="
echo "Hướng dẫn kiểm tra thủ công:"
echo "========================================="
echo "1. Chạy ứng dụng: flutter run"
echo "2. Vào màn hình 'Ngân Sách'"
echo "3. Nhấn nút (+) ở góc trên bên phải"
echo "4. Màn hình 'Thêm Ngân Sách' sẽ mở"
echo "5. Điền thông tin và nhấn 'Lưu'"
echo ""
echo "Lưu ý: Cần có ít nhất 1 danh mục trước khi thêm ngân sách"
echo "========================================="

