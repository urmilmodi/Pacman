module ram_test(input clk);
	
	reg [14:0] addresscounter = 0;
	wire [2:0] ramout;
	
	ram u0 (.address(addresscounter), .q(ramout), .clock(clk), .data(3'b0), .wren(1'b0));
	
	always @(posedge clk) begin
		addresscounter <= addresscounter + 1;
	end

endmodule