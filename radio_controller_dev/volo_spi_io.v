
module volo_spi_io (
	input sys_clk,
	input sys_ce,
	input reset,
	input go,
	// input [2:0]  clkdiv,

	input [31:0] tx_data,

	output  [31:0] rx_data1,
	// output reg [31:0] rx_data2,
	// output reg [31:0] rx_data3,
	// output reg [31:0] rx_data4,

	output done,

	//Current bit index, in case user code needs to switch output enable mid-xfer
	output [4:0] curbitnum,
	
	//SPI signals
	output spi_mosi, //Master-out-slave-in serial data
	output spi_cs,   //NAREN: Active-LOW chip select
	output spi_sclk, //Serial clock (masked by spi_cs)

	input spi_miso1 //Dev 1 master-in-slave-out
	// input spi_miso2, //Dev 2 master-in-slave-out
	// input spi_miso3, //Dev 3 master-in-slave-out
	// input spi_miso4  //Dev 4 master-in-slave-out
);

parameter SPI_XFER_LEN = 5'd16;



// NAREN: Bus flipping for sysgen requirements
reg [0:31] rx_data1_int;
wire[0:31] tx_data_int;

assign rx_data1[31:0] = rx_data1_int[0:31];  
assign tx_data_int[0:31] = tx_data[31:0]; 


//Counter to generate SPI clock
// Big enough that clkdiv can index any bit
reg [0:7] spi_clk_counter;

wire spi_clk;
reg spi_clk_d1;
wire spi_clk_pos, spi_clk_neg;

reg go_d1;
wire go_pos;

reg [0:4] spi_xfer_counter;
reg spi_xfer_running, spi_xfer_done;

assign go_pos = go & ~go_d1;

assign spi_cs = ~spi_xfer_running; // NAREN: ACTIVE LOW!
assign curbitnum = spi_xfer_counter;
assign done = spi_xfer_done;


// NAREN: Initialize outputs (mainly for SysGen)
initial begin

	rx_data1_int = 5'd0;
	spi_xfer_done = 1'd0;
end




always @(posedge sys_clk)
begin
	if(reset == 1)
		go_d1 <= 1'b0;
	else if(spi_clk_neg)
		go_d1 <= go;
end

//Free-running counter to generate SPI clock
// 1 bit of this counter will be selected as the clock source
always @(posedge sys_clk)
begin
	if(reset == 1)
	begin
		spi_clk_counter <= 6'b0;
		spi_clk_d1 <= 1'b0;
	end
	else
	begin
		spi_clk_counter <= spi_clk_counter + 6'b000001;
		spi_clk_d1 <= spi_clk;
	end
end

//Select a bit of the counter to create the free-running clock
// masked by an active SPI transfer
//User code will mask again by per-device CS
assign spi_clk = spi_clk_counter[7];
assign spi_sclk = spi_clk & spi_xfer_running;

//Rising/falling edges of spi clk for internal clk enables
// ** NAREN: Swapped spi_clk pos and neg since LIME chip operates on opposite edges from warp
assign spi_clk_pos = (~spi_clk & spi_clk_d1);//(spi_clk & ~spi_clk_d1);
assign spi_clk_neg = (spi_clk & ~spi_clk_d1);//(~spi_clk & spi_clk_d1);


//SPI transfer status signals
// spi_xfer_running:
//  Asserts when the user signals go
//  De-asserts when the last SPI character bit is processed
// spi_xfer_done
//  Asserts after the last SPI character bit is processed
//  De-asserts when a new SPI transaction starts

//initial assign spi_xfer_running = 1'b0;
//initial assign spi_xfer_done = 1'b0;

always @(posedge sys_clk)
begin
	if(reset == 1)
	begin
		spi_xfer_running <= 1'b0;
		spi_xfer_done <= 1'b0;
	end
	else if( go & (spi_xfer_counter < SPI_XFER_LEN) & spi_clk_neg)
	begin		
		spi_xfer_running <= 1'b1;
		spi_xfer_done <= 1'b0;
	end
	else if(spi_xfer_counter >= SPI_XFER_LEN)
	begin
		spi_xfer_running <= 1'b0;
		spi_xfer_done <= 1'b1;
	end
	else
	begin
		spi_xfer_running <= spi_xfer_running;
		spi_xfer_done <= 1'b0;
	end
end

//Bit-counter for SPI transactions
// Counts from 0 to SPI_XFER_LEN, used to select the current Tx/Rx bit for serial I/O
// Increments on the neg edge of the output SPI clock, so that output data is valid
//  on the arriving rising edge of sclk at SPI slave devices
always @(posedge sys_clk)
begin
	if((reset == 1) || spi_xfer_done)
		spi_xfer_counter <= 5'b0;
	else if (spi_xfer_counter >= (SPI_XFER_LEN))
		spi_xfer_counter <= SPI_XFER_LEN;
	else if (spi_xfer_running & spi_clk_neg)
		spi_xfer_counter <= spi_xfer_counter + 1;
	else
		spi_xfer_counter <= spi_xfer_counter;
end

//Add 1 extra bit to tx_data, so the bit select below can safely select bit[32]
wire [0:32] tx_data_safe;
wire [4:0] data_bitSel;
assign data_bitSel = spi_xfer_counter + (32-SPI_XFER_LEN);//assign data_bitSel = spi_xfer_counter;// + (32-SPI_XFER_LEN);//31-(15-spi_xfer_counter);//
assign tx_data_safe = {tx_data_int, 1'b0}; // NAREN

//SPI data out is one bit from tx_data
// The least significant SPI_XFER_LEN bits of tx_data are used
// Data is transmitted MSB first
//Example: for SPI_XFER_LEN=24, tx_data[8:31] is used, with tx_data[8] sent first, tx_data[31] last
assign spi_mosi = spi_xfer_running ? tx_data_safe[data_bitSel] : 1'b0;

//Second condition used to be:
// else if(spi_xfer_running & spi_rnw & (spi_xfer_counter >= SPI_FIRST_RXBIT) & spi_clk_freerun_neg)
// Don't care about rnw at this level anymore (right?)
//data capture used to be:
//		if(~ad1_spi_cs_n)
//			rxByte1[spi_xfer_counter - SPI_FIRST_RXBIT] <= ad1_spi_miso;
			
always @(posedge sys_clk)
begin
	if(reset == 1)
	begin
		rx_data1_int <= 32'b0;
		// rx_data2 <= 32'b0;
		// rx_data3 <= 32'b0;
		// rx_data4 <= 32'b0;
	end
//	else if(spi_xfer_running & spi_clk_neg)
	else if(spi_xfer_running & spi_clk_neg)
	begin
		rx_data1_int[data_bitSel] <= spi_miso1;
		// rx_data2[data_bitSel] <= spi_miso2;
		// rx_data3[data_bitSel] <= spi_miso3;
		// rx_data4[data_bitSel] <= spi_miso4;
	end
	else
	begin
		rx_data1_int <= rx_data1_int;
		// rx_data2 <= rx_data2;
		// rx_data3 <= rx_data3;
		// rx_data4 <= rx_data4;
	end
end

endmodule
