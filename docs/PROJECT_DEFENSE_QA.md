# Bộ Câu Hỏi & Trả Lời Bảo Vệ Đồ Án (Project Defense Q&A)

Dưới đây là tổng hợp các câu hỏi hội đồng có thể đặt ra cho đồ án Verification này, kèm theo gợi ý trả lời dựa trên những gì chúng ta đã thực hiện.

## 1. Về Kiến Trúc & Phương Pháp (Architecture & Methodology)

**Q1: Tại sao bạn lại chọn kiến trúc Layered Testbench (phân tầng) mà không viết hết vào một file testbench đơn giản?**
*   **A**: Vì kiến trúc phân tầng (tương tự UVM) giúp tách biệt các thành phần theo chức năng (Generator tạo dữ liệu, Driver lái tín hiệu, Monitor quan sát...). Điều này giúp Code dễ tái sử dụng (Reusability), dễ mở rộng (Scalability) khi thêm tính năng mới, và dễ debug hơn so với một file testbench "dây nhợ" lộn xộn.

**Q2: Scoreboard của bạn hoạt động như thế nào? Làm sao biết DUT chạy đúng?**
*   **A**: Scoreboard hoạt động dựa trên mô hình so sánh với "Golden Reference" (Mẫu chuẩn). Nó nhận gói tin từ Input Monitor (dữ liệu vào) và Output Monitor (dữ liệu ra).
    *   Với TX: Nó kiểm tra xem dữ liệu CPU ghi vào có xuất hiện y hệt trên đường Serial TX không.
    *   Với RX: Nó kiểm tra xem dữ liệu ngoại vi gửi vào có được CPU đọc ra chính xác không.
    *   Nếu dữ liệu khớp -> Báo MATCH. Không khớp -> Báo ERROR.

**Q3: Bạn Verify giao thức APB và UART như thế nào?**
*   **A**: Em sử dụng **Interface** để định nghĩa tín hiệu và **Driver** để mô phỏng hành vi timing chuẩn.
    *   Với APB: Driver tuân thủ biểu đồ thời gian của PSEL, PENABLE, PWRITE.
    *   Với UART: Driver tuân thủ tốc độ baudrate, bit Start, bit Parity, và bit Stop.

---

## 2. Về Coverage (Độ Phủ)

**Q4: Code Coverage và Functional Coverage khác nhau chỗ nào? Cái nào quan trọng hơn?**
*   **A**:
    *   *Code Coverage*: Đo xem công cụ đã chạy qua bao nhiêu dòng code RTL. Nó giúp tìm "Dead code" hoặc các trường hợp chưa kích hoạt (VD: nhánh `else` khi lỗi).
    *   *Functional Coverage*: Đo xem các tính năng của DUT đã được test chưa (do con người định nghĩa).
    *   Cả hai đều quan trọng, nhưng Functional Coverage quan trọng hơn về mặt xác minh tính năng, vì Code Coverage 100% vẫn có thể bỏ sót bug nếu logic thiết kế sai từ đầu.

**Q5: Làm sao để đạt 100% FSM Coverage?**
*   **A**: Em sử dụng kỹ thuật **Whitebox Coverage**, dùng đường dẫn phân cấp (`hierarchical path`) để móc trực tiếp vào biến `state` bên trong RTL. Sau đó em viết Covergroup để theo dõi các chuyển đổi trạng thái (Transition bins).
    *   Em đã chạy các test case bao phủ mọi kịch bản: Idle -> Start -> Data -> Stop -> Idle.

**Q6: Project của bạn có đạt 100% Coverage không? Nếu không thì tại sao?**
*   **A**:
    *   Functional Coverage: Em đạt >90%.
    *   Code Coverage: >90%.
    *   Lý do chưa 100% tuyệt đối: Có một số trường hợp `default` hoặc logic bảo vệ an toàn (Safety) rất khó xảy ra trong mô phỏng thực tế. Em đã dùng biện pháp **Exclusion** cho các đoạn code debug/không dùng đến.

---

## 3. Về Bug & Kết Quả (Findings)

**Q7: Trong quá trình Verify, bạn có tìm thấy lỗi (Bug) nào không?**
*   **A**: Có, em đã tìm thấy một lỗi nghiêm trọng ở bộ đệm **TX FIFO**.
    *   *Mô tả*: Khi em ghi liên tiếp 16 byte vào FIFO (`test_fifo`), DUT không xếp hàng (Queue) mà lại ghi đè (Overwrite) lên nhau, khiến dữ liệu đầu ra bị sai lệch (chỉ còn byte cuối). đây là lỗi thiết kế bộ nhớ đệm.

**Q8: Bạn đã test khả năng chịu lỗi (Error Handling) của mạch chưa?**
*   **A**: Rồi ạ. Em đã dùng test case `test_error_injection`:
    *   Em cố tình bơm sai Parity bit để xem DUT có bật cờ lỗi không -> Kết quả PASS.
    *   Em cố tình ghi vào thanh ghi Read-Only để xem DUT có báo lỗi PSLVERR không -> Kết quả PASS.

**Q9: Làm sao bạn chắc chắn rằng FIFO đã đầy (Full)?**
*   **A**: Do RTL không public tín hiệu FIFO Full ra ngoài thanh ghi Status, nên em phải kiểm tra gián tiếp bằng cách:
    *   Gửi số lượng byte bằng đúng dung lượng thiết kế (16 byte).
    *   Trong `test_flow_control`, em ép dòng dữ liệu (Traffic) dồn dập và quan sát phản ứng mất dữ liệu hoặc tín hiệu bắt tay (RTS/CTS).

---

## 4. Công Cụ & Script

**Q10: Quy trình chạy regression của bạn như thế nào?**
*   **A**: Em xây dựng script TCL (`run.do`). Chỉ cần gõ lệnh `do run.do all`, công cụ sẽ:
    1.  Biên dịch lại toàn bộ code.
    2.  Chạy lần lượt tất cả test case.
    3.  Tự động thu thập và gộp (merge) coverage database.
    4.  Xuất báo cáo HTML tổng hợp.

## 5. Về Debug & Thao Tác (Waveform & Validation)

**Q11: Làm sao bạn phát hiện lỗi FIFO bằng waveform?**
*   **A**: Em add các tín hiệu bên trong DUT (`tb_top/dut/Tpl_*` hoặc tên biến internal) lên Wave.
    *   Em thấy tín hiệu `wr_ptr` (con trỏ ghi) không tăng lên khi có xung `write_enable`.
    *   Hoặc em thấy dữ liệu tại địa chỉ cũ bị thay đổi giá trị ngay lập tức khi ghi byte mới vào.
    *   Điều này chứng tỏ logic quản lý bộ nhớ đang bị sai.

**Q12: Làm sao đo được Baudrate trên Waveform?**
*   **A**: Em dùng con trỏ (Cursor) đo độ rộng của 1 bit data (từ cạnh lên đến cạnh xuống hoặc giữa bit này sang bit kia).
    *   Ví dụ logic 1 kéo dài `8.68 us` -> Tần số = 1/8.68us ≈ 115200 bps.

**Q13: Bạn kiểm tra giao thức APB trên Waveform thế nào?**
*   **A**: Em soi 3 tín hiệu chính: `PSEL`, `PENABLE`, `PREADY`.
    *   Pha 1 (Setup): `PSEL` lên 1, `PENABLE` phải là 0.
    *   Pha 2 (Access): `PENABLE` lên 1.
    *   Kết thúc: Khi `PREADY` trả về 1, transaction mới hoàn tất.

**Q14: Làm sao chạy 1 test case lẻ thay vì chạy hết?**
*   **A**: Em dùng lệnh `do run.do test_fifo` (thay tên test vào tham số).

## 6. Về Báo Cáo HTML (Coverage Reports)

**Q15: Cái giao diện HTML báo cáo Coverage này là do bạn tự viết hay của tool?**
*   **A**: Dạ, đây là tính năng có sẵn (**Built-in Feature**) của phần mềm Questasim.
    *   Em không phải code giao diện web này.
    *   Em chỉ dùng lệnh `vcover report -html` để yêu cầu tool trích xuất dữ liệu từ database (`.ucdb`) và tự động sinh ra bộ file HTML này.

**Q16: Dữ liệu trong báo cáo này lấy từ đâu?**
*   **A**: Nó lấy từ file Database `.ucdb` (Unified Coverage Database).
    *   File này được sinh ra tự động sau mỗi lần chạy simulation (do em cài đặt cờ `-coverage` khi chạy `vsim`).
    *   Sau đó em dùng lệnh `vcover merge` để gộp kết quả của nhiều test case lại thành một file tổng rồi mới xuất báo cáo.

## 7. Về Giải Thích Code & Cấu Trúc (Code Explanation)

**Q17: Tại sao bạn lại dùng Mailbox? Sao không dùng biến toàn cục cho dễ?**
*   **A**: Dùng Mailbox để đảm bảo tính **đồng bộ hóa (Synchronization)** và an toàn dữ liệu giữa các tiến trình chạy song song (Thread-safe).
    *   Generator chạy tốc độ khác, Driver chạy tốc độ khác. Mailbox giúp nó hoạt động như cái hàng đợi (Queue), không bị mất dữ liệu.

**Q18: `virtual interface` là cái gì? Tại sao phải có chữ `virtual`?**
*   **A**: Interface là một thành phần tĩnh (Static) phần cứng, còn Class (như Driver/Monitor) là thành phần động (Dynamic OOP).
    *   Class không thể trỏ trực tiếp vào phần cứng.
    *   Nên ta cần biến `virtual interface` làm "cây cầu" (con trỏ) để đối tượng Class có thể điều khiển được tín hiệu Interface bên ngoài.

**Q19: Trong `coverage.sv`, tôi thấy bạn dùng `cross`. Tại sao không cover riêng lẻ thôi?**
*   **A**: Cover riêng lẻ chưa đủ. Ví dụ: Ta đã test `Data Width=8` và `Parity=Odd`. Nhưng chưa chắc ta đã test trường hợp "8 bit + Odd" đi chung với nhau.
    *   `cross` giúp đảm bảo mọi tổ hợp quan trọng đều đã được kiểm thử.

**Q20: Tại sao trong `test_tx.sv` lại có khối `fork...join`?**
*   **A**: Để chạy song song 2 luồng công việc:
    1.  Một luồng gửi dữ liệu vào (Driver).
    2.  Một luồng ngồi đọc dữ liệu ra (Monitor/Checker).
    *   Nếu chạy tuần tự, thì khi gửi xong mới đọc thì dữ liệu đã trôi mất rồi.

**Q21: File `base_test.sv` để làm gì? Sao không viết thẳng trong test con?**
*   **A**: Để tránh lặp code (Duplicate Code).
    *   Việc khởi tạo Environment, kết nối Mailbox, cài đặt Timeout là giống nhau ở mọi test.
    *   Em viết một lần ở `base_test`, các test con chỉ cần kế thừa (`extends`) và tập trung vào kịch bản riêng của nó.

**Q22: `clocking block` trong Interface có tác dụng gì? Sao không dùng `posedge clk` bình thường?**
*   **A**: `clocking block` giúp giải quyết vấn đề **Race Condition** (Đua tín hiệu) giữa Testbench và RTL.
    *   Nó giúp lấy mẫu (sample) và lái (drive) tín hiệu với một độ lệch thời gian cố định (skew) so với cạnh xung nhịp, đảm bảo Testbench luôn nhìn thấy dữ liệu ổn định, tránh việc đọc sai giá trị ngay tại thời điểm tín hiệu đang thay đổi.

**Q23: Trong `environment.sv`, tại sao lại dùng `fork join_none` trong hàm `run()`?**
*   **A**: Để kích hoạt các thành phần con chạy nền (background) mà không làm trình mô phỏng bị treo (block).
    *   `apb_gen.run()`, `apb_drv.run()`, `apb_mon.run()` đều là các vòng lặp vô tận (`forever`). Nếu dùng `fork join` (chờ xong mới đi tiếp) thì simulation sẽ đứng yên mãi mãi ở dòng đó.
    *   `join_none` giúp thả các process đó chạy song song và trả quyền điều khiển lại ngay cho Testbench để thực hiện các bước tiếp theo.

**Q24: Bạn tạo dữ liệu ngẫu nhiên (Random) bằng cách nào? Có kiểm soát được nó không?**
*   **A**: Em dùng hàm `randomize()` có sẵn trong SystemVerilog. Để kiểm soát, em dùng các ràng buộc (`constraint`) hoặc `randomize() with {}` (inline constraint).
    *   Ví dụ: Thay vì random địa chỉ loạn xạ, em ép `addr` phải nằm trong các dải hợp lệ (0, 4, 8, 12) để tránh tạo ra các transaction rác không cần thiết.

---
*Mẹo nhỏ: Khi trả lời, hãy tự tin và nhấn mạnh vào việc bạn hiểu rõ cấu trúc bên trong (Whitebox) cũng như hành vi bên ngoài (Blackbox) của hệ thống.*
