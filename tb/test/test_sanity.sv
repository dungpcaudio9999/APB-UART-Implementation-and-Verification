`ifndef TEST_SANITY_SV
`define TEST_SANITY_SV

`include "base_test.sv"

class test_sanity extends base_test;
  
  // Sửa lại hàm new để nhận string name
  function new(string name = "test_sanity");
    super.new(name); // Gọi constructor của class cha
  endfunction

  virtual task configure();
    $display("[TEST_SANITY] Configuring test with 10 transactions");
    // Truy cập vào generator thông qua environment để đặt số lượng gói tin
    env.apb_gen.num_transactions = 10;
  endtask
  
endclass

`endif