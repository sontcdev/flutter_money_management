# Upload key 2026 (reset key)

Keystore mới được tạo ngày 2026-08-04 để thay thế upload key gốc đã bị mất
(không có backup), dùng cho quá trình "Request upload key reset" trên
Google Play Console.

## Thông tin key

- File keystore: `upload-keystore.jks`
- Alias: `upload-key-2026`
- Thuật toán: RSA 2048, SHA256withRSA
- Hiệu lực: 10000 ngày (~27 năm), kể từ 2026-08-04
- Store password / key password: xem trong password manager cá nhân
  (không lưu plaintext trong repo)

## File chứng chỉ

- `upload_certificate.pem`: chứng chỉ public (định dạng RFC/PEM), dùng để
  đính kèm vào form "Request upload key reset" trên Play Console
  (Setup → App integrity → App signing → Request upload key reset).

## Trạng thái

- [x] Đã tạo keystore mới + xuất PEM
- [ ] Đã nộp form reset trên Play Console (chờ Google duyệt)
- [ ] Sau khi Google duyệt: cập nhật `android/key.properties` trỏ về
      `upload-key-2026/upload-keystore.jks` với alias `upload-key-2026`
- [ ] Build lại AAB bằng key mới và upload lên Play Console

## Lưu ý

- Đây là bản sao duy nhất của keystore — **backup ngay** vào nơi an toàn
  (password manager / cloud lưu trữ riêng), tránh lặp lại tình huống mất
  key gốc lần trước.
- Không commit file `.jks` vào git (đã có trong `.gitignore` nếu áp dụng
  cho `*.jks`).
