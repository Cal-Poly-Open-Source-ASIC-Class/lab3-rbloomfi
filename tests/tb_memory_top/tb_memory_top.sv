module tb_memory_top;

	logic clk;
	logic rst;					// Reset all values to 0.

	logic 			A_CYC_O;			// TRUE anytime a wishbone transaction is taking place, needs ot be true on the first STB clock cycle, stays true through ACK received.
	logic 			A_STB_O;			// TRUE for any bus transaction request, while TRUE: other wishbone inputs are valid and reference the same transaction. Transaction accepted by slave any time STB is TRUE and STALL is FALSE.
	logic 			A_WE_O;			 	// TRUE for any write requests.
	logic [7:0] 	A_ADDR_O;		 	// Address of the request.
	logic [31:0] 	A_DATA_O;			// Data to be written to the address.
	logic [3:0] 	A_SEL_O;		 	// Byte select (?)

	logic 			B_CYC_O;
	logic 			B_STB_O;
	logic 			B_WE_O;
	logic [7:0] 	B_ADDR_O;
	logic [31:0] 	B_DATA_O;
	logic [3:0] 	B_SEL_O;


	logic 			A_STALL_I;			// TRUE on any cycle when the slave CANNOT accept a request from the master, FALSE when it is ready to accept a request.
	logic 			A_ACK_I; 	        // When TRUE, the output data is valid, when FALSE, the output data is not valid.
	logic [31:0] 	A_DATA_I;			// Data read from the address after a read request.

	logic 			B_STALL_I; 	 	
	logic 			B_ACK_I;
	logic [31:0] 	B_DATA_I;

	memory_top UUT(.*);

	localparam CLK_PERIOD = 10;

	always begin
			#(CLK_PERIOD/2)
			clk <= ~clk;
	end 

	initial begin
    // Name as needed
		$dumpfile("tb_memory_top.vcd");
		$dumpvars(0);
	end

	initial begin

		clk = 0;
		rst = 0;

		A_WE_O = 1;
		A_ADDR_O = 8'h80;
		A_DATA_O = 32'hFFFF0000;
		A_STB_O = 1;
		B_ADDR_O = 8'h70;
		B_DATA_O = 32'hDEADBEEF;
		B_STB_O = 1;
		#50

		A_ADDR_O = 8'h85;
		B_ADDR_O = 8'h89;
		A_DATA_O = 32'h12341234;
		B_DATA_O = 32'h98989898;
		#50


		$finish();

	end 



endmodule