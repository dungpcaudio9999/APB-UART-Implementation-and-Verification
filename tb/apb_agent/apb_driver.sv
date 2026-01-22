`ifndef APB_DRIVER_SV
`define APB_DRIVER_SV

`include "apb_if.sv"
`include "transaction.sv"

class apb_driver;
    string                      name;
    virtual apb_if.TB_DRV       vif;
    mailbox #(apb_transaction)  in_mb;

    function new(string name = "apb_driver",
               virtual apb_if.TB_DRV vif,
               mailbox #(apb_transaction) in_mb);
        this.name  = name;
        this.vif   = vif;
        this.in_mb = in_mb;
    endfunction

    task reset_signals();
    endtask

    task drive(apb_transaction tr);
    // 1. Start Bit
    @(vif.cb_drv);
    vif.cb_drv.rx <= 1'b0;

    // 2. Data Bits
    // [TODO for Member 3]: Viết vòng lặp gửi data bit ở đây. 
    // Lưu ý: Phải gửi LSB trước hay MSB trước? Xem lại Spec!
    
    // 3. Parity Bit
    // [TODO for Member 3]: Tính toán bit Parity dựa trên tr.parity_type
    // và lái tín hiệu rx tương ứng.

    // 4. Stop Bit
    // [TODO for Member 3]: Xử lý logic 1 hoặc 2 stop bit
    endtask

    task run();
        apb_transaction tr;
        reset_signals();
        forever begin
            in_mb.get(tr);
            drive(tr);
        end
    endtask
endclass

`endif

