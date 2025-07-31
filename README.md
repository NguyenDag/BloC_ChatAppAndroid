# Chat App

Một ứng dụng chat được xây dựng bằng Flutter.

## Mô tả

Đây là một dự án Flutter nhằm mục đích tạo ra một ứng dụng chat với các tính năng cơ bản và một số tính năng nâng cao.

## Các Tính Năng:

Dựa trên các thư viện được sử dụng trong `pubspec.yaml`, ứng dụng này có thể có các tính năng sau:

*   **Giao diện người dùng:** Sử dụng các widget Material Design của Flutter (`flutter`) và các icon Cupertino (`cupertino_icons`).
*   **Xử lý đường dẫn file:** Quản lý và thao tác với đường dẫn file hệ thống (`path`).
*   **Chọn ảnh/file:**
    *   Cho phép người dùng chọn ảnh từ thư viện hoặc chụp ảnh mới (`image_picker`).
    *   Cho phép người dùng chọn các loại file khác nhau (`file_picker`).
*   **Giao tiếp mạng:**
    *   Thực hiện các yêu cầu HTTP để tương tác với API backend (`http`).
    *   Tải xuống và lưu file từ server (`dio`, `path_provider`).
*   **Lưu trữ bảo mật:** Lưu trữ dữ liệu nhạy cảm một cách an toàn trên thiết bị (`flutter_secure_storage`).
*   **Lưu trữ cục bộ:** Lưu trữ các cài đặt hoặc dữ liệu người dùng đơn giản (`shared_preferences`).
*   **Chọn Emoji:** Cung cấp giao diện chọn emoji cho người dùng (`emoji_picker_flutter`).
*   **Định dạng quốc tế:** Hỗ trợ định dạng ngày tháng, số, v.v. cho các ngôn ngữ khác nhau (`intl`).
*   **Kiểm tra kết nối mạng:** Phát hiện trạng thái kết nối internet của thiết bị (`connectivity_plus`).
*   **Quản lý quyền:** Yêu cầu và kiểm tra các quyền cần thiết của ứng dụng (ví dụ: quyền truy cập bộ nhớ, camera) (`permission_handler`).
*   **Truy cập đường dẫn bên ngoài:** Có khả năng truy cập các đường dẫn lưu trữ bên ngoài (ví dụ: thẻ SD) (`external_path`).
*   **Lưu ảnh vào thư viện:** Lưu ảnh tải về hoặc tạo ra vào thư viện ảnh của thiết bị (`saver_gallery`).
*   **Lưu trữ dữ liệu offline:** Sử dụng Realm để lưu trữ dữ liệu cục bộ, cho phép ứng dụng hoạt động khi không có kết nối mạng (`realm`).
*   **Giao tiếp Real-time (WebSocket - đang được cân nhắc/chưa hoàn thiện):** Có vẻ như dự án đã có kế hoạch hoặc đang thử nghiệm việc sử dụng WebSocket để giao tiếp real-time, nhưng các thư viện liên quan (`web_socket_channel`, `json_annotation`, `json_serializable`) hiện đang được comment lại.

## Cấu Trúc Dự Án (Cần Bổ Sung)

Phần này cần bạn mô tả cấu trúc thư mục chính của dự án. Ví dụ:

*   `lib/`: Chứa mã nguồn Dart của ứng dụng.
    *   `main.dart`: Điểm khởi đầu của ứng dụng.
    *   `screens/` hoặc `pages/`: Chứa các file UI cho từng màn hình.
    *   `widgets/`: Chứa các widget tái sử dụng.
    *   `models/`: Chứa các lớp mô hình dữ liệu.
    *   `services/`: Chứa logic nghiệp vụ, giao tiếp API, v.v.
    *   `providers/` hoặc `blocs/` hoặc `controllers/`: (Tùy thuộc vào kiến trúc quản lý trạng thái bạn sử dụng)
    *   `utils/`: Chứa các hàm tiện ích.
    *   `constants/`: Chứa các hằng số.
*   `assets/`: Chứa các tài nguyên tĩnh như hình ảnh, font chữ.
    *   `images/`: Chứa các file hình ảnh được liệt kê trong `pubspec.yaml`.
*   `test/`: Chứa các file unit test và widget test.

## Cách Hoạt Động (Cần Bổ Sung)

Phần này mô tả luồng hoạt động chính của ứng dụng. Ví dụ:

1.  **Khởi động:** Ứng dụng khởi chạy từ `main.dart`.
2.  **Xác thực (nếu có):** Người dùng đăng nhập hoặc đăng ký. Thông tin xác thực có thể được lưu trữ bằng `flutter_secure_storage`.
3.  **Màn hình chính/Danh sách chat:** Hiển thị danh sách các cuộc trò chuyện.
4.  **Màn hình chat:**
    *   Hiển thị tin nhắn.
    *   Cho phép người dùng gửi tin nhắn văn bản, emoji (`emoji_picker_flutter`).
    *   Cho phép gửi hình ảnh (`image_picker`, `file_picker`) hoặc các file đính kèm khác.
    *   Hình ảnh và file có thể được tải lên server (sử dụng `http` hoặc `dio`).
    *   Tin nhắn mới có thể được nhận real-time (nếu WebSocket được triển khai).
5.  **Lưu trữ offline:** Dữ liệu chat có thể được lưu trữ cục bộ bằng `realm` để xem lại khi không có mạng.
6.  **Tải xuống file/ảnh:** Người dùng có thể tải xuống file đính kèm (`dio`, `path_provider`) hoặc lưu ảnh vào thư viện (`saver_gallery`).
7.  **Kiểm tra kết nối:** Ứng dụng kiểm tra kết nối mạng (`connectivity_plus`) để thông báo cho người dùng hoặc thay đổi hành vi.
8.  **Quản lý quyền:** Ứng dụng yêu cầu các quyền cần thiết (`permission_handler`) khi truy cập các tính năng như camera hoặc bộ nhớ.

## Dependencies Chính

*   **Flutter SDK:** `flutter`
*   **UI & UX:** `cupertino_icons`, `emoji_picker_flutter`
*   **File & Path:** `path`, `image_picker`, `file_picker`, `path_provider`, `external_path`, `saver_gallery`
*   **Networking:** `http`, `dio`, `connectivity_plus`
*   **Storage:** `flutter_secure_storage`, `shared_preferences`, `realm`
*   **Permissions:** `permission_handler`
*   **Internationalization:** `intl`
*   **(Potentially) Real-time Communication:** `web_socket_channel` (hiện đang comment)
*   **(Potentially) Code Generation for JSON:** `json_annotation`, `json_serializable` (hiện đang comment)

## Dev Dependencies

*   **Testing:** `flutter_test`
*   **Linting:** `flutter_lints`
*   **Code Generation:** `build_runner`

## Bắt đầu

Để chạy dự án này, bạn cần có Flutter SDK được cài đặt.

1.  Clone repository (nếu có).
2.  Chạy `flutter pub get` để cài đặt các dependencies.
3.  Kết nối một thiết bị hoặc khởi chạy một emulator.
4.  Chạy `flutter run`.

## Tài sản (Assets)

Ứng dụng sử dụng các tài sản hình ảnh sau, được lưu trữ trong thư mục `assets/images/`:

*   `emoji_icon.png`
*   `attach.png`
*   `image.png`
*   `no_avatar.jpg`
