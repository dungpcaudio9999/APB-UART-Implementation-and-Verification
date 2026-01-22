`ifndef APB_IF_SV
`define APB_IF_SV

`include "apb_defines.sv"

interface apb_if(input logic pclk, input logic presetn);

    logic                          psel;
    logic                          penable;
    logic                          pwrite;
    logic [3:0]                    pstrb;
    logic [`APB_ADDR_WIDTH-1:0]    paddr;
    logic [`APB_DATA_WIDTH-1:0]    pwdata;
    logic [`APB_DATA_WIDTH-1:0]    prdata;
    logic                          pready;
    logic                          pslverr;

    // Clocking blocks for TB side
    clocking cb_drv @(posedge pclk);
        default input #1step output #1step;
        output psel, penable, pwrite, pstrb, paddr, pwdata;
        input  prdata, pready, pslverr;
    endclocking

    clocking cb_mon @(posedge pclk);
        default input #1step output #1step;
        input psel, penable, pwrite, pstrb, paddr, pwdata, prdata, pready, pslverr;
    endclocking

    modport DUT (
        input  pclk, presetn, psel, penable, pwrite, pstrb, paddr, pwdata,
        output prdata, pready, pslverr
    );

    modport TB_DRV (clocking cb_drv, input presetn);
    modport TB_MON (clocking cb_mon, input presetn);

endinterface

`endif

