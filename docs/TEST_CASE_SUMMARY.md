# Tổng Hợp Danh Sách Test Case

Bảng dưới đây mô tả chi tiết các test case hiện có, bao gồm mục đích, phương pháp thực hiện và các điểm kiểm tra chính.

|Test Case | Mục Đích | Phương Pháp |PASS | FAIL |
| :--- | :--- | :--- | :--- | :--- |
| **`test_sanity`** | Kiểm tra kết nối cơ bản | Gửi/Nhận 1-2 gói tin ngẫu nhiên. | Log xuất hiện `[sb] MATCH!` và không có lỗi Fatal nào. | Simulation bị treo, không có log `[sb]`, hoặc báo `MISMATCH` ngay gói đầu. |
| **`test_tx`** | Kiểm tra truyền (TX) | Ghi Burst 16 byte vào FIFO -> Start -> Gửi các pattern (0x00, 0xFF). | `[sb] TX MATCH!` xuất hiện đủ số lượng byte đã gửi. Sóng TX tái tạo đúng pattern. | Báo `[sb] TX MISMATCH!` (Dữ liệu ra khác dữ liệu ghi vào) hoặc mất dữ liệu. |
| **`test_rx`** | Kiểm tra nhận (RX) | Driver gửi liên tục -> Monitor đọc RXDATA. | `[sb] READ MATCH!` xuất hiện đủ số lượng. Cờ RX_READY bật/tắt đúng lúc. | Báo `[sb] READ MISMATCH!` hoặc đọc ra `0x00/Garbage` không đúng dữ liệu gửi. |
| **`test_fifo`** | Kiểm tra tràn (Overrun) | **P1**: Ghi 16 byte -> Xả.<br>**P2**: Ghi 20 byte (Tràn). | **P1**: Nhận đủ 16 byte đúng thứ tự.<br>**P2**: Scoreboard báo lỗi/mismatch (do mất dữ liệu). | **P1**: Báo `MISMATCH` (Chứng tỏ FIFO bị ghi đè/lỗi pointer).<br>**P2**: Không thấy báo lỗi (DUT không phát hiện tràn). |
| **`test_config_modes`** | Đa cấu hình (Parity/Bits) | Chạy loop: đổi config -> gửi data -> đổi config. | Coverage đạt 100%. Dữ liệu truyền nhận đúng format (ví dụ: 7 bit data, Odd parity). | Báo `MISMATCH` hoặc `Parity Error` giả (do DUT tính sai parity). |
| **`test_flow_control`** | Handshake (RTS/CTS) | Kéo chân CTS=1 khi DUT đang gửi. | Chân TX **đứng im (giữ mức cao)** trong suốt thời gian CTS=1. | Chân TX vẫn **toggle (truyền dữ liệu)** bất chấp tín hiệu CTS đang cấm. |
| **`test_error_injection`** | Xử lý lỗi (Robustness) | Bơm lỗi Parity (Data sai so với bit Parity). | Scoreboard báo `Parity Error Detected`. Thanh ghi Status bit [2] = 1. | Thanh ghi Status vẫn báo OK (bit [2] = 0) dù dữ liệu sai. |
| **`test_reset_stress`** | Reset bất ngờ | Assert Reset khi đang chạy -> Thả ra -> Chạy lại. | Sau khi thả Reset, DUT nhận cấu hình mới và chạy đúng (MATCH). | DUT bị treo, không phản hồi APB, hoặc dữ liệu rác sau khi Reset. |
| **`test_full_regression`** | Chạy chuỗi tích hợp | Chạy nối tiếp Sanity -> TX -> RX -> FIFO. | Tất cả log `[REGRESSION]` hoàn thành, không có lỗi Fatal. | Bị treo giữa chừng hoặc báo lỗi ở bất kỳ phase con nào. |

---
*Bảng này giúp định hướng việc debug và lựa chọn test case phù hợp khi phát triển tính năng mới.*
