# Giải Thích Chi Tiết Về Code Coverage

Tài liệu này giải thích sâu hơn về lý do và cách thức triển khai Coverage trong môi trường Verification, giúp bạn hiểu "Tại sao code lại viết như thế?".

## 1. Coverage Là Gì & Tại Sao Cần?
Coverage (Độ phủ) là thước đo định lượng trả lời câu hỏi: **"Đã test đủ chưa?"**.
Nếu chỉ chạy test mà không đo coverage, bạn không thể biết liệu mình có bỏ sót trường hợp quan trọng nào hay không (ví dụ: chưa bao giờ test Parity Lẻ).

Có 2 loại chính:
1.  **Code Coverage**: Tự động đo bởi công cụ. Đo xem bao nhiêu dòng code RTL đã được chạy.
2.  **Functional Coverage**: Do con người định nghĩa. Đo xem các tính năng (Feature) đã được kiểm tra chưa.

---

## 2. Quy Trình Triển Khai Coverage (4 Bước)

Để viết ra file `coverage.sv`, chúng ta đi qua 4 bước tư duy logic:

### Bước 1: Lập Kế Hoạch (Planning)
Nhìn vào Spec và liệt kê các biến số cần phủ.
*   *Ví dụ*: UART có cấu hình Data Width (5,6,7,8 bit). Vậy ta cần đảm bảo test đủ cả 4 trường hợp này.

### Bước 2: Định Nghĩa Covergroup (Coding)
Dùng SystemVerilog `covergroup` để mô tả kế hoạch trên thành code.

```systemverilog
covergroup cg_uart_cfg;
    // Coverpoint: Điểm cần phủ (Biến số)
    cp_data_width: coverpoint cfg.data_width {
        // Bins: Các giá trị cụ thể cần đạt được
        bins width_5 = {5}; // Phải thấy số 5 ít nhất 1 lần
        bins width_6 = {6};
        bins width_7 = {7};
        bins width_8 = {8};
    }
endgroup
```

### Bước 3: Lấy Mẫu (Sampling/Binding)
Định nghĩa xong thì phải có người kích hoạt nó ("Chụp ảnh").
*   **Khi nào chụp?**: Khi cấu hình thay đổi (Write Config Register) hoặc khi có gói tin mới.
*   **Kết nối**: Trong `coverage.sv`, ta dùng Mailbox để nhận dữ liệu từ Monitor, sau đó gọi hàm `sample()`:

```systemverilog
task collect_apb();
    // ...
    if (tr.write && tr.addr == `UART_REG_CONFIG) begin
        cg_uart_cfg.sample(); // Chụp lại cấu hình ngay lúc này!
    end
endtask
```

### Bước 4: Phân Tích (Analysis)
Sau khi chạy simulation, xem báo cáo:
*   Nếu `width_5` = 0% -> Chưa bao giờ test 5 bit -> Cần viết thêm test case hoặc chỉnh random constraint.
*   Nếu `cross_addr_rw` báo 100% -> Đã kiểm tra đủ mọi ngóc ngách Write/Read vào mọi thanh ghi.

---

## 3. Các Kỹ Thuật Coverage Nâng Cao Đã Dùng

### A. Cross Coverage (Phủ chéo)
Kiểm tra sự kết hợp giữa các biến.
*   *Lý do*: Đôi khi biến A đúng, biến B đúng, nhưng A+B đi chung lại sai.
*   *Code*: `cross cp_addr, cp_write`.
*   *Ý nghĩa*: Đảm bảo ta đã test (Ghi vào RX), (Đọc từ TX)...

### B. Ignore Bins (Loại trừ)
Loại bỏ các trường hợp vô lý hoặc không thể xảy ra để tránh làm giảm điểm số oan.
*   *Code*: `ignore_bins rx_write = binsof(cp_addr.rx_reg) && binsof(cp_write.write);`
*   *Ý nghĩa*: Thanh ghi RX là Read-Only, nên việc Ghi vào RX là vô nghĩa (hoặc gây lỗi), ta không mong đợi nó xảy ra trong luồng chuẩn (trừ khi test lỗi), nên loại nó ra khỏi mẫu số tính %.

### C. Whitebox Coverage (Soi ruột)
Coverage bình thường (Blackbox) chỉ nhìn thấy Interface bên ngoài. Whitebox nhìn thấy dây tín hiệu bên trong RTL.
*   *Cách làm*: Dùng đường dẫn phân cấp (Hierarchical Path) `tb_top.dut.signal`.
*   *Ứng dụng*: `cg_internal_fsm` trong dự án này móc trực tiếp vào biến `state` của máy trạng thái trong RTL để chắc chắn nó đã chuyển qua đủ các trạng thái (Idle -> Start -> Data...).

```systemverilog
cp_tx_state: coverpoint tb_top.dut.Tpl_41 { // Tpl_41 là tên biến state sau khi compile
    bins idle  = {2'b00};
    bins start = {2'b01};
    // ...
}
```

---
*Tóm lại, Coverage không làm cho code chạy đúng hơn, nhưng nó là bằng chứng thép để khẳng định code đã được kiểm tra kỹ càng.*
