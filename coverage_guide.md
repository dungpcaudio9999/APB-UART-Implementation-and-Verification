# Hướng Dẫn Đọc & Xử Lý Coverage Report

Tài liệu này hướng dẫn cách đọc báo cáo coverage từ Questasim và các chiến lược xử lý khi coverage không đạt 100%.

## 1. Cách Đọc Báo Cáo (HTML Report)

Mở file `sim/coverage_report/index.html`. Giao diện thường chia thành các phần chính:

### Tổng Quan (Dashboard/Summary)
- **Total Coverage**: Con số % tổng hợp cuối cùng.
- **Code Coverage Types**:
  - **Statement/Block**: Các dòng code đã được chạy qua.
  - **Branch/Conditional**: Các nhánh `if`, `else`, `case` đã được đi vào.
  - **Toggle**: Các tín hiệu (bit) đã chuyển trạng thái 0->1 và 1->0.
  - **FSM**: Các trạng thái và chuyển đổi trạng thái (State Machine).
- **Functional Coverage (Covergroups)**: Độ phủ các chức năng kiểm thử do ta tự định nghĩa (trong `coverage.sv`).

### Chi Tiết Từng Module (Hierarchy)
Nhấn vào từng module trong cây thư mục bên trái để xem chi tiết:
- **Màu Xanh (Green)**: Đạt yêu cầu (>90%).
- **Màu Vàng (Yellow)**: Cảnh báo (50-90%).
- **Màu Đỏ (Red)**: Nguy hiểm (<50%), chưa được test kỹ.

---

## 2. Phân Tích & Xử Lý Coverage Thấp

Khi coverage chưa đạt 100%, hãy phân tích theo hai trường hợp:

### Trường Hợp A: Code Coverage Thấp (RTL chưa chạy hết)

**Biểu hiện**: Các dòng code RTL vẫn còn màu đỏ.

| Nguyên nhân | Cách xử lý |
| :--- | :--- |
| **Thiếu kịch bản test** | RTL có tính năng đó nhưng testbench chưa bao giờ kích hoạt. <br>👉 **Giải pháp**: Viết thêm test case mới nhắm vào tính năng đó. |
| **Code thừa / Dead code** | Code không bao giờ chạy được do logic sai hoặc thiết kế thừa. <br>👉 **Giải pháp**: Review lại RTL, xóa bỏ code thừa. |
| **Code không thể đạt tới (Unreachable)** | Ví dụ: Trường hợp `default` trong `case` khi đã cover hết các trường hợp khác, hoặc logic bảo vệ an toàn (safety) khó xảy ra. <br>👉 **Giải pháp**: Dùng **Exclusion** (loại trừ) trong báo cáo coverage. |

### Trường Hợp B: Functional Coverage Thấp (Covergroups chưa hit)

**Biểu hiện**: Các bins trong `coverage.sv` báo 0 hits.

| Nguyên nhân | Cách xử lý |
| :--- | :--- |
| **Random chưa trúng** | Do chạy random chưa đủ lâu hoặc không may mắn. <br>👉 **Giải pháp**: Tăng số lần lặp (`repeat`), chạy regression nhiều lần với seed khác nhau (`-sv_seed random`). |
| **Constraints quá chặt** | Testbench random nhưng bị ràng buộc không cho phép sinh ra trường hợp đó. <br>👉 **Giải pháp**: Nới lỏng constraint, hoặc viết test riêng (Directed Test) để ép trường hợp đó xảy ra. |
| **Bug trong RTL hoặc Testbench** | Testbench đã gửi kích thích đúng nhưng RTL không phản hồi đúng, hoặc Monitor bắt sai. <br>👉 **Giải pháp**: Debug waveform, kiểm tra xem tại sao sự kiện đó không xảy ra. |

---

## 3. Chiến Lược Cải Thiện Coverage (Closure Workflow)

1.  **Chạy Regression**: Chạy tất cả test case hiện có.
2.  **Merge & Report**: Gộp kết quả và xem báo cáo tổng.
3.  **Tấn công lỗ hổng (Hole Analysis)**: Sắp xếp các mục chưa đạt (0%) lên đầu.
    - Nếu là tính năng quan trọng: **Viết thêm test**.
    - Nếu là trường hợp khó (Corner case): **Điều chỉnh constraint** hoặc viết **Directed Test**.
    - Nếu là code không dùng: **Thêm Exclusion filter**.
4.  **Lặp lại**: Chạy lại regression với các bổ sung mới cho đến khi đạt mục tiêu (thường là 100% Functional, >95% Code).

## 4. Exclusion (Loại Trừ)
Với các đoạn code không thể test (ví dụ tín hiệu debug, tính năng tắt đi), tạo file `.exclude` hoặc click chuột phải trong GUI chọn **Exclude** để loại chúng khỏi tính toán coverage tổng.
