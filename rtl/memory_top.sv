`timescale 1ns / 1ps

module memory_top (
	input logic clk,
	input logic rst,						// Reset all values to 0.

	input logic 		A_CYC_O,			// TRUE anytime a wishbone transaction is taking place, needs ot be true on the first STB clock cycle, stays true through ACK received.
	input logic 		A_STB_O,			// TRUE for any bus transaction request, while TRUE: other wishbone inputs are valid and reference the same transaction. Transaction accepted by slave any time STB is TRUE and STALL is FALSE.
	input logic 		A_WE_O,			 	// TRUE for any write requests.
	input logic [7:0] 	A_ADDR_O,		 	// Address of the request.
	input logic [31:0] 	A_DATA_O,			// Data to be written to the address.
	input logic [3:0] 	A_SEL_O,		 	// Byte select (?)

	input logic 		B_CYC_O,
	input logic 		B_STB_O,
	input logic 		B_WE_O,
	input logic [7:0] 	B_ADDR_O,
	input logic [31:0] 	B_DATA_O,
	input logic [3:0] 	B_SEL_O,


	output logic 		A_STALL_I,			// TRUE on any cycle when the slave CANNOT accept a request from the master, FALSE when it is ready to accept a request.
	output logic 		A_ACK_I, 	        // When TRUE, the output data is valid, when FALSE, the output data is not valid.
	output logic [31:0] A_DATA_I,			// Data read from the address after a read request.

	output logic 		B_STALL_I, 	 	
	output logic 		B_ACK_I,
	output logic [31:0] B_DATA_I


);

	logic STALLCTRL = 0; 				 	// 1 = A goes next, 0 = B goes next
	// output "state" for which ram A and B are getting data from updates every clock cycle
	// output data is fed out combinationally.
	
	logic [3:0] 	RAM_1_WE0;
	logic 			RAM_1_EN0;
	logic [31:0] 	RAM_1_Di0;
	logic [31:0]	RAM_1_Do0;
	logic [7:0]		RAM_1_A0;

	logic [3:0] 	RAM_2_WE0;
	logic 			RAM_2_EN0;
	logic [31:0] 	RAM_2_Di0;
	logic [31:0]	RAM_2_Do0;
	logic [7:0]		RAM_2_A0;

	logic 			A_SEL;
	logic 			B_SEL;

	logic			A_PREV;
	logic 			B_PREV;

	logic 			A_CUR;
	logic 			B_CUR;


	DFFRAM256x32 DFFRAM1 (
		.CLK(clk),
		.WE0(RAM_1_WE0),
		.EN0(RAM_1_EN0),
		.Di0(RAM_1_Di0),
		.Do0(RAM_1_Do0),
		.A0(RAM_1_A0)
	);

	DFFRAM256x32 DFFRAM2 (
		.CLK(clk),
		.WE0(RAM_2_WE0),
		.EN0(RAM_2_EN0),
		.Di0(RAM_2_Di0),
		.Do0(RAM_2_Do0),
		.A0(RAM_2_A0)
	);

	always @(posedge clk) begin
		A_ACK_I <= 0;
		B_ACK_I <= 0;

		A_CUR <= A_SEL;
		B_CUR <= B_SEL;

		if (B_STALL_I || A_STALL_I) begin
			STALLCTRL <= ~STALLCTRL;
		end 

		if (A_STB_O && ~A_STALL_I) begin
			A_ACK_I <= 1;
		end 

		if (B_STB_O && ~B_STALL_I) begin
			B_ACK_I <= 1;
		end 
	end 

	assign A_SEL = A_ADDR_O[7];
	assign B_SEL = B_ADDR_O[7];

	always_comb begin
		RAM_1_EN0 = 0;
		RAM_2_EN0 = 0;

		RAM_1_WE0 = 1;
		RAM_2_WE0 = 1;

		RAM_1_A0 = 0;
		RAM_2_A0 = 0;

		RAM_1_Di0 = 0;
		RAM_2_Di0 = 0;

		//STALLCTRL = 0;

		A_STALL_I = 0;
		B_STALL_I = 0;

		// A_ACK_I = 0;
		// B_ACK_I = 0;

		if ((A_SEL == B_SEL) && (A_STB_O == 1) && (B_STB_O == 1)) begin

			if (STALLCTRL == 0) begin
				A_STALL_I = 1;
				B_STALL_I = 0;
			end 
			else begin
				A_STALL_I = 1;
				B_STALL_I = 0;
			end 


		end 



		// A gets what it wants
		if (  ((A_STB_O == 1 && B_STB_O == 1) && (A_SEL != B_SEL)) 			// both active with no collision
			| (A_STB_O == 1 && B_STB_O == 0) 								// only A active
			| ((A_STB_O == 1 && B_STB_O == 1) && STALLCTRL == 1)) begin		// collision and priority

			// general stuff
			// if (((A_STB_O == 1 && B_STB_O == 1) && STALLCTRL == 1)) begin
			// 	A_STALL_I = 1;
			// end 

			// if it accesses RAM1
			if (A_SEL == 0) begin
				RAM_1_EN0 = 1;
				RAM_1_WE0 = 4'b1111;
				RAM_1_A0 = A_ADDR_O;
				RAM_1_Di0 = A_DATA_O; 
			end

			// if it accesses RAM2
			else if (A_SEL == 1) begin
				RAM_2_EN0 = 1;
				RAM_2_WE0 = 4'b1111;
				RAM_2_A0 = A_ADDR_O;
				RAM_2_Di0 = A_DATA_O; 
			end

			

		end 

		// B gets what it wants
		if (  ((A_STB_O == 1 && B_STB_O == 1) && (A_SEL != B_SEL)) 			// both active with no collision
			| (A_STB_O == 0 && B_STB_O == 1) 								// only B active
			| ((A_STB_O == 1 && B_STB_O == 1) && STALLCTRL == 0)) begin		// collision and priority

			// if it accesses RAM1
			if (B_SEL == 0) begin
				RAM_1_EN0 = 1;
				RAM_1_WE0 = 4'b1111;
				RAM_1_A0 = B_ADDR_O;
				RAM_1_Di0 = B_DATA_O; 
			end

			// if it accesses RAM2
			else if (B_SEL == 1) begin
				RAM_2_EN0 = 1;
				RAM_2_WE0 = 4'b1111;
				RAM_2_A0 = B_ADDR_O;
				RAM_2_Di0 = B_DATA_O; 
			end

		end 

		if (A_CUR == 0) begin
			A_DATA_I = RAM_1_Do0;
		end 

		else if (A_CUR == 1) begin
			A_DATA_I = RAM_2_Do0;
		end 

		else A_DATA_I = 0;

		if (B_CUR == 0) begin
			B_DATA_I = RAM_1_Do0;
		end 

		else if (B_CUR == 1) begin
			B_DATA_I = RAM_2_Do0;
		end 

		else B_DATA_I = 0;






	end 


		
	





endmodule