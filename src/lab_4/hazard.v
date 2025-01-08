`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2017/11/22 10:23:13
// Design Name: 
// Module Name: hazard
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module hazard(
	//fetch stage
	output wire stallF,
	//decode stage
	input wire[4:0] rsD,rtD,
	input wire branchD,
	output wire forwardaD,forwardbD,
	output wire stallD,
	//execute stage
	input wire[4:0] rsE,rtE,
	input wire[4:0] writeregE,
	input wire regwriteE,
	input wire memtoregE,
	output reg[1:0] forwardaE,forwardbE,
	output wire flushE,
	//mem stage
	input wire[4:0] writeregM,
	input wire regwriteM,
	input wire memtoregM,

	//write back stage
	input wire[4:0] writeregW,
	input wire regwriteW
    );

	wire lwstallD,branchstallD;

	//forwarding sources to D stage (branch equality)
	assign forwardaD = (rsD != 0 & rsD == writeregM & regwriteM);//Because the two input of the compare unit of the branch instruction may come from the register file or the output of the alu, data forwarding is needed here.
	assign forwardbD = (rtD != 0 & rtD == writeregM & regwriteM);
	
	//forwarding sources to E stage (ALU)

	always @(*) begin
		forwardaE = 2'b00;
		forwardbE = 2'b00;
		if(rsE != 0) begin
			/* code */
			if(rsE == writeregM & regwriteM) begin//only when the input of the alu comes from the former stage and needs to be written back to the register file, which means the control signal regwrite is high, we need to forward the data from the mem stage or the write back stage to the execute stage
				/* code */
				forwardaE = 2'b10;//writeregM is the address of the register that will be written to register file in the mem stage, if the input address of the alu rsE that will be read in the execute stage is equal to the address of the register that will be written in the mem stage, then we need to forward the data from the mem stage to the execute stage
			end else if(rsE == writeregW & regwriteW) begin
				/* code */
				forwardaE = 2'b01;
			end
		end
		if(rtE != 0) begin
			/* code */
			if(rtE == writeregM & regwriteM) begin
				/* code */
				forwardbE = 2'b10;
			end else if(rtE == writeregW & regwriteW) begin
				/* code */
				forwardbE = 2'b01;
			end
		end
	end

	//stalls
	assign #1 lwstallD = memtoregE & (rtE == rsD | rtE == rtD);//Memtoreg=1 only when the instruction is lw. For lw, rt is the register address that will be written to the register file from the data memory, and rs and rt are the addresses of the registers that will be read from the register file. If the address of the register that will be written to the register file in the mem stage is equal to the address of the register that will be read from the register file in the decode stage, then we need to stall the decode stage. The address of the register that will be read from the register file in the decode stage is possibly rsD or rtD, which is decided by the type of the insruction. So we need to compare the rtE with rsD and rtD to determine whether we need to stall the decode stage. Here, E indicates the lw instruction, and D indicates the next instruction after the lw instruction.
	assign #1 branchstallD = branchD &
				(regwriteE & 
				(writeregE == rsD | writeregE == rtD) |
				memtoregM &
				(writeregM == rsD | writeregM == rtD));
	assign #1 stallD = lwstallD | branchstallD;
	assign #1 stallF = stallD;
		//stalling D stalls all previous stages
	assign #1 flushE = stallD;
		//stalling D flushes next stage
	// Note: not necessary to stall D stage on store
  	//       if source comes from load;
  	//       instead, another bypass network could
  	//       be added from W to M
endmodule
