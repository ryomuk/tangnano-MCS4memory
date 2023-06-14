//---------------------------------------------------------------------------
// Memory system for Intel MCS-4 micro computer set
//
// June 3, 2023
// by Ryo Mukai
//---------------------------------------------------------------------------
module top (
            input	     sys_clk, // clk input
            input	     sw1,
            input	     sw2,
            input	     testn_sw_n, // button for test input
            input	     reset_sw_n, // button for reset input
            output reg [5:0] led, // 6 LEDS pin
            // output	     mclk, // 5.185MHz clock
            
            output reg [3:0] dout_n,
            output	     doe,
            input [3:0]	     din_n,
            input	     cmrom_n,
            input [3:0]	     cmram_n,
            output reg	     clk1, // 740Hz two phase clock 1
            output reg	     clk2, // 740Hz two phase clock 2
            input	     sync_n,
	    output	     tx, // bit 0 of the ram_port0
	    input	     rx,
	    output	     test_n, 
	    output	     reset_n, // reset output to 4004
	    output	     ws2812, // RGB LED
	    output reg	     debug_trg
            );
  
  // parameter	     CLK_FRE  = 27000; //kHz
  // parameter	     PLL_FRE  = 67500; //kHz (5185*13=67405)
  // parameter      MCLK_FRE =  5185; //kHz
  parameter Cycle_A1 = 3'd0;
  parameter Cycle_A2 = 3'd1;
  parameter Cycle_A3 = 3'd2;
  parameter Cycle_M1 = 3'd3;
  parameter Cycle_M2 = 3'd4;
  parameter Cycle_X1 = 3'd5;
  parameter Cycle_X2 = 3'd6;
  parameter Cycle_X3 = 3'd7;

  wire		pll_clk;
  wire		mclk;
  
  reg [23:0]	counter;
  reg [3:0]	cnt_ptom;
  reg [2:0]	cnt_mclk;
  reg [2:0]	cpu_cycle;
  reg		cpu_cycle_reset;
		
  reg [11:0]	rom_address;
  reg		rom_enable;
  wire		rom_oe;		
  wire [7:0]	rom_data;

  reg [7:0]	ram_address;
  reg		ram_command;
  wire		ram_we;
  wire		ram_oe;
  reg		ram_src;		
  wire		ram_cs0, ram_cs1, ram_cs2, ram_cs3;
  wire [3:0]	ram_port0, ram_port1, ram_port2, ram_port3;
  wire [3:0]	ram_dout0, ram_dout1, ram_dout2, ram_dout3;
  wire [3:0]	ram_dout;
  wire		cmram0_n;

  wire [7:0]	pm_data;
  reg		pm_command;		
  wire		pm_we;
      
  reg		nosync;		
  wire [3:0]	opa;
  wire [3:0]	opr;
  wire [3:0]	din;

  Gowin_rPLL pll_clkgen(
                     .clkout(pll_clk), //output clkout = 67.5MHz
	             .clkin(sys_clk)   //input clkin   = 27.0MHz
	             );
  
  //-----------------------------------------------------------------------
  // interface signals
  //-----------------------------------------------------------------------
  assign reset_n = ~(~reset_sw_n | sw1);
  assign test_n = ~testn_sw_n | ~rx | sw2;

  assign tx = ram_port3[0];

  //-----------------------------------------------------------------------
  // Generate 2 phase clock
  //-----------------------------------------------------------------------
  assign mclk = cnt_ptom[3];

  always @(posedge pll_clk) begin
     if (cnt_ptom == 4'd12) // = 13-1 (67.5MHz/5.185MHz = 13.018)
       cnt_ptom <= 4'd0;
     else
       cnt_ptom <= cnt_ptom + 1'd1;
  end
  
  always @(posedge mclk) begin
     if (cnt_mclk == 3'd6)
       cnt_mclk <= 3'd0;
     else
       cnt_mclk <= cnt_mclk + 1'd1;
  end
  always @(negedge mclk) begin
     clk1 <= cnt_mclk[1] | cnt_mclk[2];
     clk2 <= ~(~cnt_mclk[1] & cnt_mclk[2]);
  end

  
  //-----------------------------------------------------------------------
  // ROM, RAM and Program Memory
  //-----------------------------------------------------------------------
  assign cmram0_n = cmram_n[0]; // all RAMs are located in the bank 0
  assign din = ~din_n;

  programmemory pm(.bank({ram_port1, ram_port0}),
		   .romaddr(rom_address[7:0]), .ramaddr(ram_address),
		   .dout(pm_data), .din(din), .opa(opa), .we(pm_we),
		   .clk(clk2), .reset_n(reset_n));
  assign pm_we = pm_command & (cpu_cycle == Cycle_X2);
  
  rom_image rom(.addr(rom_address), .dout(rom_data));
  assign rom_oe = rom_enable
		  & ((cpu_cycle == Cycle_M1) | (cpu_cycle == Cycle_M2))
		  & ~clk2;
  
  assign ram_oe = ram_command
		  & opa[3] // read RAM or RAM port
		  // & (opa != 4'b1010) // read ROM port
		  & (cpu_cycle == Cycle_X2)
		  & ~clk2;

  // write is executed when (ram_we==1) & (opa is write command)
  // at the posedge clk2 in the end of X2
  assign ram_we = ram_command & (cpu_cycle == Cycle_X2);

  ram4002 ram0(.addr(ram_address[5:0]), .din(din), .opa(opa), .we(ram_we),
	       .dout(ram_dout0), .port(ram_port0), .cs(ram_cs0),
	       .clk(clk2), .reset_n(reset_n));
  ram4002 ram1(.addr(ram_address[5:0]), .din(din), .opa(opa),  .we(ram_we),
	       .dout(ram_dout1), .port(ram_port1), .cs(ram_cs1),
	       .clk(clk2), .reset_n(reset_n));
  ram4002 ram2(.addr(ram_address[5:0]), .din(din), .opa(opa),  .we(ram_we),
	       .dout(ram_dout2), .port(ram_port2), .cs(ram_cs2),
	       .clk(clk2), .reset_n(reset_n));
  ram4002 ram3(.addr(ram_address[5:0]), .din(din), .opa(opa),  .we(ram_we),
	       .dout(ram_dout3), .port(ram_port3), .cs(ram_cs3),
	       .clk(clk2), .reset_n(reset_n));

  assign ram_cs0 = ram_address[7:6] == 2'b00;
  assign ram_cs1 = ram_address[7:6] == 2'b01;
  assign ram_cs2 = ram_address[7:6] == 2'b10;
  assign ram_cs3 = ram_address[7:6] == 2'b11;
  
  function [3:0] select;
    input [3:0] x0, x1, x2, x3;
    input [1:0]	addr;
     case (addr)
       2'b00: select = x0;
       2'b01: select = x1;
       2'b10: select = x2;
       2'b11: select = x3;
       default: select = 4'bxxxx;
     endcase  
  endfunction
  assign ram_dout = select(ram_dout0, ram_dout1, ram_dout2, ram_dout3,
			   ram_address[7:6]);
  
  //-----------------------------------------------------------------------
  // data output
  //-----------------------------------------------------------------------
  assign doe = rom_oe | ram_oe;

  //: 000-EFF: ROM area
  //  F00-FFF: Program Memory RAM area
  assign opr = (rom_address[11:8] == 4'b1111) ? pm_data[7:4]: rom_data[7:4];
  assign opa = (rom_address[11:8] == 4'b1111) ? pm_data[3:0]: rom_data[3:0];
  
  //-----------------------------------------------------------------------
  // CPU cycle
  //-----------------------------------------------------------------------
  //     X3  A1  A2  A3  M1  M2  X1  X2  X3  A1
  //CLK1\_/~\_/~\_/~\_/~\_/~\_/~\_/~\_/~\_/~\_
  //CLK2~\_/~\_/~\_/~\_/~\_/~\_/~\_/~\_/~\_/~
  //SYNC\___/~~~~~~~~~~~~~~~~~~~~~~~~~~~\___/
  //
  // 2 phase clocks
  //      6    0    1    2    3    4    5    6    0
  // CLK1 ~~~~~\_________/~~~~~~~~~~~~~~~~~~~~~~~~\____
  //
  // CLK2 /~~~~~~~~~~~~~~~~~~~~~~~~\_________/~~~~~~~~~
  // BUS->CPU                       X__TRUE___X
  // CPU->BUS                  X_____TRUE_____X

  always @(negedge clk1)
    if ( cpu_cycle_reset )
      cpu_cycle <= Cycle_A1;
    else if( cpu_cycle != Cycle_X3 )
      cpu_cycle <= cpu_cycle + 1'd1;

  always @(negedge clk2) begin
     case (cpu_cycle)
       Cycle_M1: dout_n <= ~opr;
       Cycle_M2: dout_n <= ~opa;
       Cycle_X1: dout_n <= ~ram_dout;
     endcase
  end

  always @(posedge clk2) begin
     if ( !reset_n ) begin
	ram_address <= 8'd0;
     end

     // check SYNC signal
     cpu_cycle_reset <= ~sync_n; // reset cpu_cycle at the next negedge CLK1

     case (cpu_cycle)
       Cycle_A1: rom_address[3:0] <= din;
       Cycle_A2: rom_address[7:4] <= din;
       Cycle_A3: begin
	  rom_address[11:8] <= din;
	  rom_enable <= ~cmrom_n;
       end
       Cycle_M2: begin
	  ram_command <= ~cmram0_n;
	  pm_command <= ~cmrom_n;
       end
       Cycle_X2:
	 if( cmram0_n == 0 ) begin // SRC instruction
	    ram_src <= 1;
	    ram_address[7:4] <= din;
	 end
	 else
	   ram_src <= 0;
       Cycle_X3:
	 if ( ram_src )
	   ram_address[3:0] <= din;
     endcase
     // for debug
     if(pm_we & (opa == 4'b0011))
       debug_trg <= 1;
     else 
       debug_trg <= 0;
  end

  //-----------------------------------------------------------------------
  // LED demo
  //-----------------------------------------------------------------------
  reg [7:0] rgb_r;
  reg [7:0] rgb_g;
  reg [7:0] rgb_b;
  ws2812 rgb_led(.clk(sys_clk), .we(1'd1),
		 .r(rgb_r),
		 .g(rgb_g),
		 .b(rgb_b),
		 .sout(ws2812));

  reg	    blink_flag;
  always @(posedge sys_clk or negedge reset_n) begin
     if (!reset_n) begin
	led <= 6'b111111;
	counter <= 24'd0;
	blink_flag <= 0;
	//{rgb_r, rgb_g, rgb_b} <= 24'h000000;
	{rgb_r, rgb_g, rgb_b} <= 24'h000000;
     end
     else if (counter < 24'd674_9999) begin
	counter <= counter + 1'd1;
	led[3:0] <= ~ram_port0;  // for debug
	//led[3:0] <= ~ram_port3;  // for debug
	led[4] <= ~test_n;  // for debug
	if (sync_n == 0)
	  nosync <= 0;
     end
     else begin       // each 0.25s
	counter <= 24'd0;
	blink_flag = ~blink_flag;
	// led[4:0] <= ~rom_address[4:0]; // for debug
	// led[5] <= ~(nosync ? blink_flag : 0);
	{rgb_r, rgb_g, rgb_b} <= nosync ?
				 (blink_flag ? 24'h0F0000 : 0)
	                         : 24'h000F00;
	nosync <= 1;
     end
  end

endmodule
