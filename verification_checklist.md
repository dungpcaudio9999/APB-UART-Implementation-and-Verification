# APB UART Verification Checklist

## 1. Cấu hình Khung truyền (Configuration)
| Tính năng | Trạng thái | Ghi chú / Test File |
| :--- | :---: | :--- |
| **Data Bits: 8** | ✅ PASS | `test_tx`, `test_rx`. |
| **Data Bits: 5, 6, 7** | ✅ PASS | `test_config_modes.sv`. |
| **Stop Bits: 1** | ✅ PASS | Default. |
| **Stop Bits: 2** | ✅ PASS | `test_config_modes.sv` (Part 2). |
| **Parity: None** | ✅ PASS | Default. |
| **Parity: Odd/Even** | ❌ FAIL | `test_error_injection.sv`. |

## 2. Truyền và Nhận Dữ liệu (Data Path)
| Tính năng | Trạng thái | Ghi chú / Test File |
| :--- | :---: | :--- |
| **TX Accuracy (Single)** | ✅ PASS | `test_sanity.sv`. |
| **TX Accuracy (Burst)** | ❌ FAIL | `test_tx.sv`. Lỗi: FIFO Overwrite. |
| **RX Accuracy (Single)** | ✅ PASS | `test_rx.sv`. |
| **RX Accuracy (Burst)** | ❌ FAIL | `test_flow_control.sv`. Lỗi: FIFO Overwrite. |
| **RX_DONE Flag** | ✅ PASS | Check ngầm. |

## 3. Điều khiển Luồng (Flow Control)
| Tính năng | Trạng thái | Ghi chú / Test File |
| :--- | :---: | :--- |
| **TX Pause (CTS)** | ✅ PASS | `test_flow_control.sv`. |
| **RX Pause (RTS)** | ❌ FAIL | `test_flow_control.sv`. |

## 4. Xử lý Lỗi và Trạng thái (Error Handling)
| Tính năng | Trạng thái | Ghi chú / Test File |
| :--- | :---: | :--- |
| **Parity Error Detection** | ❌ FAIL | `test_error_injection.sv`. |
| **FIFO Overrun Handling** | ❌ FAIL | `test_flow_control.sv`. |

## 5. Khôi phục Hệ thống (System Reset)
| Tính năng | Trạng thái | Ghi chú / Test File |
| :--- | :---: | :--- |
| **Power-on Reset** | ✅ PASS | Default. |
| **Reset On-the-fly** | ✅ PASS | `test_reset_stress.sv`. Hệ thống phục hồi tốt sau Reset. |

---
**TỔNG KẾT DỰ ÁN VERIFICATION**:
- **Độ phủ (Coverage)**: Đã đạt 100% Functional Coverage (Tất cả tính năng trong Spec đều có testcase).
- **Chất lượng RTL**:
    - Tốt: Logic cơ bản, Reset, Cấu hình Data Width, CTS.
    - Kém (Critical Bugs): Thiếu FIFO (gây mất dữ liệu khi Burst), Logic Parity Error hỏng, Logic RTS hỏng.
