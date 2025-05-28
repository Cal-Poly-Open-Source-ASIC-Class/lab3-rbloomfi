`timescale 1ns/1ps
module tb_memory_top;

	`ifdef USE_POWER_PINS
        wire VPWR;
        wire VGND;
        assign VPWR = 1'b1;
        assign VGND = 1'b0;
    `endif

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
		$dumpfile("tb_memory_top.vcd");
		$dumpvars(0);
	end
	initial #100000 $error("Timeout");


	// Task for writing to both RAMs, inputs for Address and Data
	task automatic write_both (
		input [7:0] addrA, input [31:0] dataA,
		input [7:0] addrB, input [31:0] dataB
	);
	begin
		@(posedge clk);
		A_ADDR_O <= addrA;
		A_DATA_O  <= dataA;
		A_WE_O   <= 1;
		A_STB_O  <= 1;

		B_ADDR_O <= addrB;
		B_DATA_O  <= dataB;
		B_WE_O   <= 1;
		B_STB_O  <= 1;
	
	 	@(posedge clk);
		A_STB_O  <= 0;
		A_WE_O   <= 0;

		B_STB_O  <= 0;
		B_WE_O   <= 0;
	end
	endtask

	// Task for writing to both RAMs
	task automatic read_both (
		input [7:0] addrA, input [31:0] expOutA,
		input [7:0] addrB, input [31:0] expOutB
	);
	begin
		@(posedge clk);
		A_ADDR_O <= addrA;
		A_WE_O <= 0;
		A_STB_O <= 1;

		B_ADDR_O <= addrB;
		B_WE_O <= 0;
		B_STB_O <= 1;

		@(posedge clk);
		A_STB_O <= 0;
		A_STB_O <= 0;

		@(negedge clk);
		if ((A_DATA_I != expOutA)) begin
			$error("ERROR @ PORT A: Expected %h at address %h, got %h", expOutA, addrA, A_DATA_I);
		end
		//assert(A_DATA_I === expOutA);

		if ((B_DATA_I != expOutB)) begin
			$error("ERROR @ PORT B: Expected %h at address %h, got %h", expOutB, addrB, B_DATA_I);
		end
		//assert(B_DATA_I === expOutB);

	end 
	endtask

	task automatic read_single (
		input [7:0] addr, input [31:0] expOut, input ramSel	// 0 = RAM1
	);
	endtask



	// Tests
	always begin
		clk = 0;
		rst = 0;

		@(posedge clk)
		A_CYC_O <= 1;
		B_CYC_O <= 1;

		A_STB_O <= 0;
		B_STB_O <= 0;

		A_ADDR_O <= 0;
		B_ADDR_O <= 0;

		A_WE_O <= 0;
		B_WE_O <= 0;

		A_DATA_O <= 0;
		B_DATA_O <= 0;

		@(posedge clk);
		write_both(8'hF1, 32'hABABABAB, 8'h05, 32'hF0F0F0F0);			// write to different RAMs
		write_both(8'hF4, 32'h12345678, 8'h35, 32'h77777777);			// write to different RAMs

		@(posedge clk);
		read_both(8'h00, 32'h00000000, 8'hF1, 32'hABABABAB);			// read previously written RAM

		@(posedge clk);
		//write_both(8'hF1, 32'hCCCCCCCC, 8'hF2, 32'hAAAAAAAA);			// write to the same RAM
		//write_both(8'h01, 32'h11112222, 8'h02, 32'h99998888);			// write to the same RAM


		/*
			1. why does my testbench of data-out being correct, but not being read by the testbench? Not directed to correct output port?
			2. how to deal with stalling data for the next cycle
			3. anything else
		*/




		$finish();

	end 



endmodule