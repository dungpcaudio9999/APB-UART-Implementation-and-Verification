# Tài Liệu Tổng Quan Môi Trường Testbench APB-UART

## 1. Kiến Trúc Tổng Quan (Architecture)
Môi trường Verification được xây dựng theo kiến trúc phân tầng lớp (Layered Architecture) mô phỏng theo chuẩn UVM, sử dụng SystemVerilog OOP.

### Sơ Đồ Khối
```mermaid
flowchart LR
    %% Global Graph Settings
    graph LR
    
    %% 1. Test Layer
    subgraph Test_Layer [TEST LAYER]
        direction TB
        Tests[Test Cases]
    end

    %% 2. Environment Layer
    subgraph Env_Layer [ENVIRONMENT]
        direction TB
        
        subgraph Agents
           direction TB
           APB_Ag[APB Agent\n(Master)]
           UART_Ag[UART Agent\n(Slave/Monitor)]
        end
        
        SCB[Scoreboard]
        COV[Coverage Collector]
    end

    %% 3. RTL Layer
    subgraph RTL_Layer [RTL SYSTEM]
        direction TB
        Intf[Interfaces]
        DUT[UART CORE]
    end

    %% Connections
    Tests --> Env_Layer
    
    %% Agent to RTL
    APB_Ag <--> Intf
    UART_Ag <--> Intf
    Intf <--> DUT

    %% Monitor to Analysis
    APB_Ag -.->|Monitor| SCB
    UART_Ag -.->|Monitor| SCB
    
    APB_Ag -.->|Monitor| COV
    UART_Ag -.->|Monitor| COV
```

## 2. Các Thành Phần Chính (Components)

### 2.1. Agents
- **APB Agent (Active)**: Đóng vai trò Master, điều khiển bus APB để ghi cấu hình (Config Regs) và ghi dữ liệu gửi (TX Data), hoặc đọc dữ liệu nhận (RX Data).
- **UART Agent (Active/Passive)**: 
  - **Driver**: Giả lập thiết bị ngoại vi gửi dữ liệu Serial vào chân RX của DUT.
  - **Monitor**: Giám sát chân TX của DUT để bắt dữ liệu gửi ra, và giám sát chân RX để bắt dữ liệu gửi vào (phục vụ check dữ liệu).

### 2.2. Checker (Scoreboard)
- **Cơ chế**: Dựa trên mô hình "Golden Reference" đơn giản hóa.
- **TX Path**: So sánh dữ liệu ghi vào `TXDATA` (từ APB Monitor) với dữ liệu xuất hiện trên chân `TX` (từ UART Monitor).
- **RX Path**: So sánh dữ liệu xuất hiện trên chân `RX` (từ UART Driver) với dữ liệu đọc được từ `RXDATA` (từ APB Monitor).
- **Status Checks**: Kiểm tra cờ TX_DONE, RX_READY (tuy nhiên logic này chủ yếu dựa vào timing).

### 2.3. Coverage Collector
Kết hợp giữa **Blackbox** và **Whitebox**:
- **CG_APB**: Cover các loại truy cập APB (Read/Write, Address Map). Đã loại trừ các truy cập không hợp lệ (Write to Read-only).
- **CG_UART_CFG**: Cover các mode cấu hình (Data Bits 5-8, Parity Odd/Even, Stop Bits 1/2).
- **CG_INTERNAL_FSM (Whitebox)**:
  - Sử dụng **Hierarchical References** (`tb_top.dut.signal`) để móc trực tiếp vào máy trạng thái bên trong RTL.
  - Đảm bảo 100% state transitions cho cả TX FSM và RX FSM.

## 3. Chiến Lược Kiểm Tra (Test Strategy)

Bộ Test Suite bao gồm các kịch bản sau:

| Test Case | Mục Tiêu | Kết Quả Đáng Chú Ý |
| :--- | :--- | :--- |
| **`test_sanity`** | Kiểm tra kết nối cơ bản, gửi nhận 1-2 gói tin. | PASS |
| **`test_tx` / `test_rx`** | Kiểm tra truyền nhận khối lượng lớn, kiểm tra tính toàn vẹn dữ liệu. | PASS (Data), FAIL (FIFO Logic) |
| **`test_config_modes`** | Kiểm tra khả năng hoạt động ở nhiều cấu hình khác nhau (Odd/Even Parity, 5-8 bits). | PASS |
| **`test_error_injection`** | **Functional**: Bơm lỗi Parity để xem DUT có phát hiện (bật cờ Error) không.<br>**Code Cov**: Truy cập địa chỉ không hợp lệ để kích hoạt logic báo lỗi (PSLVERR). | PASS |
| **`test_flow_control`** | Kiểm tra tín hiệu CTS/RTS. Yêu cầu DUT dừng gửi khi CTS=1. | PASS (Flow Control OK) |
| **`test_fifo`** | Kiểm tra tràn bộ đệm (Overrun) và dung lượng FIFO. | **BUG FOUND**: FIFO TX hoạt động sai, ghi đè dữ liệu cũ khi chưa đầy. |

## 4. Kết Quả Code Coverage
Sau khi chạy Regression và tối ưu hóa:
- **Total Functional Coverage**: >90%.
- **FSM Coverage**: 100% (Confirmed by Whitebox).
- **Config Coverage**: Cover được hết các trường hợp hợp lệ.

## 5. Hạn Chế / Bug Đã Tìm Thấy
1.  **Lỗi FIFO Nghiêm Trọng**: `test_fifo` cho thấy bộ đệm TX không hoạt động đúng nguyên tắc FIFO (First-In-First-Out) mà bị ghi đè như một thanh ghi đơn (1-deep buffer).
2.  **Thiếu thanh ghi trạng thái chi tiết**: RTL không public các bit FIFO Full/Empty rõ ràng ra thanh ghi Status, gây khó khăn cho việc verify trạng thái đầy/rỗng bằng Blackbox.

---
*Tài liệu được tạo tự động bởi Agent Verification Assistant.*
