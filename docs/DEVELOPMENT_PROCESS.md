# Quy Trình Phát Triển Môi Trường Verification (Step-by-Step)

Tài liệu này mô tả chi tiết quy trình xây dựng một môi trường Testbench từ con số 0 đến khi hoàn thiện, giúp bạn hình dung bức tranh tổng thể.

## Giai Đoạn 1: Phân Tích & Lập Kế Hoạch (Planning)

Trước khi viết dòng code nào, ta cần hiểu rõ mình đang làm gì.

1.  **Đọc kỹ Specification (Spec)**:
    *   DUT (Device Under Test) là gì? -> *UART Core*.
    *   Nó giao tiếp qua cổng nào? -> *APB Slave (để cấu hình) và Serial TX/RX (để truyền nhận)*.
    *   Tính năng cần test là gì? -> *Gửi, Nhận, Config Baudrate/Parity, FIFO, Lỗi...*

2.  **Lập Verification Plan (Test Plan)**:
    *   Liệt kê các kịch bản test (Test cases) cần chạy. (VD: Test gửi 100 gói tin, test lỗi parity, test reset...).
    *   Xác định chiến lược Check (Làm sao biết đúng/sai? -> Dùng Scoreboard).
    *   Xác định chỉ tiêu Coverage (Bao nhiêu % là đạt?).

---

## Giai Đoạn 2: Xây Dựng Khung Sườn (Skeleton Build)

Xây dựng bộ khung rỗng để đảm bảo mọi thứ kết nối được với nhau trước.

1.  **Tạo thư mục**: Tổ chức file gọn gàng (`rtl/`, `tb/`, `sim/`, `docs/`).
2.  **Định nghĩa Interface**:
    *   Viết `apb_if.sv` và `uart_if.sv` mô tả các bó dây tín hiệu.
3.  **Định nghĩa Transaction (Gói tin)**:
    *   Tạo `transaction.sv`. Thay vì nghĩ về các bit 0/1, ta nghĩ về "Gói tin APB Write", "Gói tin UART Frame".
4.  **Tạo Top-Level (`tb_top.sv`)**:
    *   Instantiate DUT.
    *   Instantiate Interface.
    *   Tạo Clock và Reset.
    *   Kết nối chúng lại với nhau. Thử compile xem có lỗi cú pháp không.

---

## Giai Đoạn 3: Phát Triển Các Thành Phần (Component Implementation)

Đây là giai đoạn code nhiều nhất, chia làm 2 nhánh chính: Agent và Monitor.

1.  **Viết Generator**:
    *   Tạo class chỉ biết sinh ngẫu nhiên các gói tin `transaction` và đẩy vào hộp thư (Mailbox).
2.  **Viết Driver (Đôi tay)**:
    *   Nhận gói tin từ hộp thư -> Chuyển thể thành tính hiệu điện (Wiggle pins) theo đúng timing của giao thức (APB hoặc UART).
    *   *Ví dụ: Muốn Write APB, phải kéo PSEL=1, sau đó PENABLE=1...*
3.  **Viết Monitor (Đôi mắt)**:
    *   Ngồi rình ở Interface. Thấy tín hiệu giật đúng chuẩn -> Gom lại thành gói tin -> Đẩy vào hộp thư báo cáo.
4.  **Viết Scoreboard (Trọng tài)**:
    *   Lấy gói tin từ Monitor APB và Monitor UART.
    *   So sánh: "Thằng APB bảo gửi chữ A, thằng UART có thấy chữ A không?". Nếu có -> MATCH, không -> ERROR.

---

## Giai Đoạn 4: Tích Hợp & Chạy Test Cơ Bản (Integration)

1.  **Viết `environment.sv`**:
    *   Gom Generator, Driver, Monitor, Scoreboard vào chung một chỗ.
    *   Tạo hòm thư (Mailbox) và phát cho từng đứa để chúng liên lạc.
2.  **Viết `base_test.sv`**:
    *   Lớp cha để setup môi trường.
3.  **Viết `test_sanity.sv` (Test đầu tiên)**:
    *   Bài test đơn giản nhất: Gửi 1 gói tin xem chạy được không.
    *   Mục tiêu: Debug các lỗi kết nối, lỗi biên dịch, lỗi thời gian (Timing).

---

## Giai Đoạn 5: Mở Rộng Test Case & Coverage (Refinement)

Khi khung đã chạy ổn, ta bắt đầu "tra tấn" DUT.

1.  **Viết thêm Test Case**:
    *   `test_fifo`: Test tràn bộ nhớ.
    *   `test_error`: Cố tình bơm lỗi để xem DUT phản ứng thế nào.
    *   `test_random`: Chạy ngẫu nhiên điên cuồng (Randomization).
2.  **Thêm Coverage (Thước đo)**:
    *   Viết `coverage.sv` để đo xem những trường hợp nào đã xảy ra (VD: Đã test parity lẻ chưa? Đã test full FIFO chưa?).
3.  **Regression**:
    *   Tạo script (`run.do`) để chạy 1 phát hết tất cả test case (Regression Test).

## Giai Đoạn 6: Clean-up & Documentation (Hoàn Thiện)

*   Review lại code, xóa comment thừa.
*   Viết tài liệu hướng dẫn (như file bạn đang đọc).
*   Giao hàng!

---
*Quy trình này giúp bạn kiểm soát độ phức tạp, không bị "ngợp" khi nhìn vào đống code khổng lồ ban đầu.*
