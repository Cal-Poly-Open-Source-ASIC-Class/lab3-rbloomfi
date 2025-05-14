module memory_top (
	input logic clk,

	input logic CYC_O_A;
	input logic STB_O_A;
	input logic WE_O_A;
	input logic [31:0] ADRR_O_A;
	input logic [31:0] DATA_O_A;
	input logic [3:0] SEL_O_A;

	input logic CYC_O_B;
	input logic STB_O_B;
	input logic WE_O_B;
	input logic [31:0] ADRR_O_B;
	input logic [31:0] DATA_O_B;
	input logic [3:0] SEL_O_B; 

	output logic STALL_I_A;
	output logic ACK_I_A;
	output logic [31:0] DATA_I_A;
	output logic ERR_I_A; 

	output logic STALL_I_B;
	output logic ACK_I_B;
	output logic [31:0] DATA_I_B;
	output logic ERR_I_B;


);

	DFFRAM256x32 DFFRAM1 (
		.clk(clk),
		.aIN(aIN),
		.bIN(bIN),
		.aOUT(aOUT),
		.bOUT(bOUT)
	)

	DFFRAM256x32 DFFRAM2 (
		.clk(clk),
		.aIN(aIN),
		.bIN(bIN),
		.aOUT(aOUT),
		.bOUT(bOUT)
	)



endmodule