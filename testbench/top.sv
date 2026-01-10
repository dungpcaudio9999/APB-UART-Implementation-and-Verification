module top;
	bit clk;
	always #10 clk = ~clk;

	uart_if uartif();
	
endmodule : top