interface uart_if(input bit clk);
    bit reset_n;
    bit pclk;
    bit preset_n;
    logic psel, penable, pwrite;
    logic [3:0] pstrb;
    logic [11:0] paddr;
    logic [31:0] pwdata;
    logic rx;
    logic cts_n;
    logic pready;
    logic pslverr;
    logic [31:0] prdata;
    logic tx;
    logic rst_n;

    clocking cb @(posedge clk);
        

    modport TEST();
    modport DUT();
    modport MONITOR();
endinterface
