`ifndef BASE_TEST_SV
`define BASE_TEST_SV

`include "environment.sv"

class base_test;
  string      name;
  environment env;

  // Constructor nên nhận name làm tham số
  function new(string name = "base_test");
    this.name = name;
    // Khởi tạo environment ở đây
    env = new("env");
  endfunction

  // Hàm để cấu hình các thông số trước khi chạy
  virtual task configure(); 
    // Mặc định không làm gì
  endtask

  virtual task run();
    $display("[%s] Starting test at %0t", name, $time);
    env.run();
    // Đợi một khoảng thời gian đủ để kết thúc mô phỏng
    #10000;
    $display("[%s] Finished test at %0t", name, $time);
  endtask
endclass

`endif