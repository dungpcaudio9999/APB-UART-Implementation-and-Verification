# Hướng Dẫn Các Câu Lệnh Coverage (Cheat Sheet)

Tài liệu này tổng hợp các câu lệnh cần thiết để thực hiện quy trình Functional & Code Coverage trong Questasim.

## 1. Enable Coverage (Biên dịch & Chạy)

Để thu thập dữ liệu, cần bật cờ `-coverage` và `+cover=bcestf` (Branch, Condition, Expression, Statement, Toggle, FSM).

### Cách 1: Chạy Thủ Công (Manual)
```bash
# Bước 1: Biên dịch code RTL với cờ coverage
vlog -work work +cover=bcestf +incdir+../rtl ../rtl/uart.sv

# Bước 2: Chạy mô phỏng, bật coverage và lưu vào Database (.ucdb)
# -voptargs="+acc": Giữ lại tín hiệu để debug
# -do "...": Chuỗi lệnh tự động chạy
vsim -c -coverage -voptargs="+acc +cover=bcestf" tb_top +TESTNAME=test_fifo \
     -do "run -all; coverage save coverage_db/test_fifo.ucdb; quit"
```

### Cách 2: Dùng Script Tự Động (Khuyên dùng)
```tcl
# Trong Questasim Console (File > Open > sim/run.do)
do run.do all         ;# Chạy và gộp tất cả các test case
do run.do test_fifo   ;# Chạy riêng test_fifo
```

---

## 2. Quản Lý Coverage Database (.ucdb)

Mỗi test case sinh ra một file `.ucdb`. Cần gộp chúng lại để có kết quả tổng thể.

```bash
# Merge tất cả file .ucdb trong thư mục coverage_db thành 1 file tổng
vcover merge coverage_db/merged_coverage.ucdb coverage_db/*.ucdb
```

---

## 3. Tạo Báo Cáo (Reporting)

Sau khi có file `merged_coverage.ucdb`, xuất báo cáo để phân tích.

### Dạng Text (Xem nhanh)
```bash
# Xem chi tiết theo từng covergroup instance trên màn hình
vcover report -cvg -details coverage_db/merged_coverage.ucdb

# Xuất ra file text
vcover report -cvg -details coverage_db/merged_coverage.ucdb > coverage_summary.txt
```

### Dạng HTML (Giao diện trực quan)
Dùng trình duyệt để xem, dễ dàng trace ngược lại code.

```bash
# Tạo báo cáo HTML với ngưỡng cảnh báo (Low=50%, High=90%)
vcover report -html -htmldir sim/coverage_report -verbose -threshL 50 -threshH 90 coverage_db/merged_coverage.ucdb
```
*   **Xem báo cáo**: Mở file `sim/coverage_report/index.html`.

---

## 4. Automation Scripts

Các lệnh trên đã được tích hợp vào file script TCL:

*   **`sim/run.do`**:
    *   Tự động Compile RTL & TB với cờ coverage.
    *   Chạy test case (đơn lẻ hoặc tất cả).
    *   Tự động lưu `.ucdb`.

*   **`sim/generate_coverage_report.do`**:
    *   Tự động Merge các file `.ucdb`.
    *   Tự động tạo báo cáo HTML và Text.

**Cách dùng nhanh:**
1.  Mở Questasim, `cd` vào thư mục `sim`.
2.  Gõ: `do run.do all` (Chạy Regression).
3.  Gõ: `do generate_coverage_report.do` (Xuất báo cáo).
