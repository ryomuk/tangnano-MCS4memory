//-----------------------------------------------------------------------------
//
// RAM module
//
//-----------------------------------------------------------------------------
module ram4002( addr, din, dout, port, cs, opa, we, clk, reset_n);
//-----------------------------------------------------------------------------
  input [5:0]      addr;
  input [3:0]	   din;
  output reg [3:0] dout;
  output reg [3:0] port;
  input		   cs;		   
  input [3:0]	   opa;
  input		   we;
  input		   clk;
  input		   reset_n;

  reg [5:0]	   count;    // counter for initialize on reset
  reg [3:0]	   mem[63:0]; // memory character
  reg [3:0]	   st0[3:0]; // status character
  reg [3:0]	   st1[3:0]; // status character
  reg [3:0]	   st2[3:0]; // status character
  reg [3:0]	   st3[3:0]; // status character

//-----------------------------------------------------------------------------
`include "param.vh"
//-----------------------------------------------------------------------------
  always @(posedge clk)
    if ( reset_n == 0 ) begin
       mem[count] <= 0;
       st0[count[1:0]] <= 0;
       st1[count[1:0]] <= 0;
       st2[count[1:0]] <= 0;
       st3[count[1:0]] <= 0;
       port <= 0;
       count <= count + 1'd1;
    end
    else if ( cs )
      case ( opa )
	RAM_SBM: dout <= mem[addr];
	RAM_RDM: dout <= mem[addr];
	RAM_ADM: dout <= mem[addr];
	RAM_RD0: dout <= st0[addr[5:4]];
	RAM_RD1: dout <= st1[addr[5:4]];
	RAM_RD2: dout <= st2[addr[5:4]];
	RAM_RD3: dout <= st3[addr[5:4]];
	RAM_WRM: if ( we ) mem[addr] <= din;
	RAM_WMP: if ( we ) port <= din;
	RAM_WR0: if ( we ) st0[addr[5:4]] <= din;
	RAM_WR1: if ( we ) st1[addr[5:4]] <= din;
	RAM_WR2: if ( we ) st2[addr[5:4]] <= din;
	RAM_WR3: if ( we ) st3[addr[5:4]] <= din;
      endcase
endmodule
//-----------------------------------------------------------------------------
