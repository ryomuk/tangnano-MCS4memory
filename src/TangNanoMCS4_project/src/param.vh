//
// param.vh
//


// OPA of memory instructions
parameter RAM_WRM  = 4'b0000;  // write to memory charactor
parameter RAM_WMP  = 4'b0001;  // write to memory port 
parameter ROM_WRR  = 4'b0010;  // write to ROM output port
parameter ROM_WPM  = 4'b0011;  // write to program memory (with 4289)
parameter RAM_WR0  = 4'b0100;  // write to status character 0
parameter RAM_WR1  = 4'b0101;  // write to status character 1
parameter RAM_WR2  = 4'b0110;  // write to status character 2
parameter RAM_WR3  = 4'b0111;  // write to status character 3
parameter RAM_SBM  = 4'b1000;  // read memory character (for SBM)
parameter RAM_RDM  = 4'b1001;  // read memory character (for RDM)
parameter ROM_RDR  = 4'b1010;  // read ROM port
parameter RAM_ADM  = 4'b1011;  // read memory character (for ADM)
parameter RAM_RD0  = 4'b1100;  // read status character 0
parameter RAM_RD1  = 4'b1101;  // read status character 1
parameter RAM_RD2  = 4'b1110;  // read status character 2
parameter RAM_RD3  = 4'b1111;  // read status character 3
