Q: Chỉ ra điểm giống và khác nhau giữa test_tx và test_flow_control

A:
So sánh chi tiết **`test_tx.sv`** (phiên bản hiện tại) và **`test_flow_control.sv`** (phần test TX):

### 1. Điểm Giống Nhau
*   **Mục tiêu**: Cả hai đều tìm cách kiểm tra khả năng truyền dữ liệu (TX) của DUT.
*   **Phương pháp Gửi**: Đều sử dụng phương pháp **Burst Write** (Ghi một loạt dữ liệu vào bộ đệm trước khi cho phép gửi). Cụ thể là ghi 16 byte liên tiếp vào FIFO.
*   **Kết quả phát hiện**: Cả hai đều phát hiện ra lỗi **FIFO Overwrite** (ghi đè mất dữ liệu cũ, chỉ còn byte cuối cùng) và lỗi buffer không chịu clear (gửi lặp lại).

### 2. Điểm Khác Nhau (Quan Trọng)

| Tính năng | `test_tx.sv` | `test_flow_control.sv` |
| :--- | :--- | :--- |
| **Mục đích chính** | Kiểm tra **Data Integrity** (Dữ liệu gửi đi có đúng không) khi hoạt động ở chế độ Burst/High-speed. | Kiểm tra **Protocol Compliance** (Tuân thủ giao thức) xem DUT có chịu **Dừng (Pause)** khi bị yêu cầu không. |
| **Trạng thái chân CTS** | Luôn để `CTS = 0` (Ready - Luôn cho phép gửi). Giả lập môi trường lý tưởng. | Bắt đầu với `CTS = 1` (Busy - Cấm gửi), sau đó mới thả `CTS = 0`. |
| **Hành vi mong đợi** | Ghi xong -> Start -> **Thấy sóng TX chạy ngay lập tức**. | Ghi xong -> Start -> **Thấy sóng TX đứng im** (vì bị CTS chặn). Phải chờ thả CTS mới được chạy. |
| **Điều kiện Fail** | Fail nếu dữ liệu ra sai/thiếu. | Fail nếu dữ liệu ra sai HOẶC **nếu DUT tự ý gửi khi CTS đang cấm**. |

**Tóm lại:**
*   `test_tx` hỏi: *"Mày có nhớ hết 16 chữ tao dạy không?"* -> DUT trả lời: *"Không, nhớ mỗi chữ cuối."* -> **FAIL**.
*   `test_flow_control` hỏi: *"Tao cấm nói (CTS=1), mày có im không?"* -> DUT trả lời: *"Im."* -> **PASS** (phần CTS). Sau đó hỏi tiếp *"Giờ nói đi, nhớ gì không?"* -> *"Nhớ mỗi chữ cuối."* -> **FAIL** (phần FIFO).
