//-----------------------------------------------------------------------------
//
// pm.v
//
// emulation for program memory
// consists of i4289 and 64KB(256byte x 256bank) RAM
//
//-----------------------------------------------------------------------------

module programmemory(bank, romaddr, ramaddr,
		     din, dout, opa, we, clk, reset_n);
  input [7:0]  bank;
  input [7:0]  romaddr;
  input [7:0]  ramaddr;
  input [3:0]  din;
  output [7:0] dout;
  input [3:0]  opa;
  input	       we;
  input	       clk;
  input	       reset_n;
//-----------------------------------------------------------------------------
  reg	       ff_FL;
  reg [7:0]    mem[65535:0];
//-----------------------------------------------------------------------------
`include "param.vh"
  
  assign dout = mem[{bank, romaddr}];
  
  always @(posedge clk)
    if (reset_n == 0)
      ff_FL <= 0;
    else 
      case (opa)  // only WPM is implemented for now
	ROM_WPM:
	  if ( we ) begin
	     if ( ff_FL )
	       mem[{bank, ramaddr}][7:4] <= din; // write to OPR
	     else
	       mem[{bank, ramaddr}][3:0] <= din; // write to OPA
	     ff_FL <= ~ff_FL;
	  end
      endcase
  initial
    begin
       ff_FL = 0;
    end
endmodule
