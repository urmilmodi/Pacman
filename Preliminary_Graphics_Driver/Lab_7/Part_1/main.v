module main(SW, KEY, HEX0, HEX2, HEX4, HEX5);
	input [9:0]SW;
	input [0:0]KEY;
	output [6:0]HEX0;
	output [6:0]HEX2;
	output [6:0]HEX4;
	output [6:0]HEX5;
	
	wire [3:0]out;
	
	ram32x4 u0 (.data(SW[3:0]), .address(SW[8:4]), .wren(SW[9]), .clock(KEY[0]), .q(out));
	
	seg7_HEX u1 (.data(SW[8:4]), .HEX_display(HEX4));
	seg7_HEX u2 (.data(SW[8:4]), .HEX_display(HEX5));
	
	seg7_HEX u3 (.data(SW[3:0]), .HEX_display(HEX2));
	seg7_HEX u4 (.data(out), .HEX_display(HEX0));
	
endmodule


module seg7_HEX (data, HEX_display);
    input [0:3] data;
    output [6:0] HEX_display;

    assign HEX_display[0] = (~ data[0] & ~ data[1] & ~ data[2] & data[3]) | (~ data[0] & data[1] & ~ data[2] & ~ data[3]) | (data[0] & ~ data[1] & data[2] & data[3]) | (data[0] & data[1] & ~ data[2] & data[3]);
    assign HEX_display[1] = (data[0] & data[1] & data[2] & data[3]) | (data[0] & data[1] & data[2] & ~ data[3]) | (data[0] & data[1] & ~ data[2] & ~ data[3]) | (data[0] & ~ data[1] & data[2] & data[3]) | (~ data[0] & data[1] & data[2] & ~ data[3]) | (~ data[0] & data[1] & ~ data[2] & data[3]);
    assign HEX_display[2] = (data[0] & data[1] & data[2] & data[3]) | (data[0] & data[1] & data[2] & ~ data[3]) | (data[0] & data[1] & ~ data[2] & ~ data[3]) | (~ data[0] & ~ data[1] & data[2] & ~ data[3]);
    assign HEX_display[3] = (data[0] & data[1] & data[2] & data[3]) | (data[0] & ~ data[1] & data[2] & ~ data[3]) | (data[0] & ~ data[1] & ~ data[2] & data[3]) | (~ data[0] & data[1] & data[2] & data[3]) | (~ data[0] & data[1] & ~ data[2] & ~ data[3]) | (~ data[0] & ~ data[1] & ~ data[2] & data[3]);
    assign HEX_display[4] = (data[0] & ~ data[1] & ~ data[2] & data[3]) | (~ data[0] & data[1] & data[2] & data[3]) | (~ data[0] & data[1] & ~ data[2] & data[3]) | (~ data[0] & data[1] & ~ data[2] & ~ data[3]) | (~ data[0] & ~ data[1] & data[2] & data[3]) | (~ data[0] & ~ data[1] & ~ data[2] & data[3]);
    assign HEX_display[5] = (data[0] & data[1] & ~ data[2] & data[3]) | (~ data[0] & data[1] & data[2] & data[3]) | (~ data[0] & ~ data[1] & data[2] & data[3]) | (~ data[0] & ~ data[1] & data[2] & ~ data[3]) | (~ data[0] & ~ data[1] & ~ data[2] & data[3]);
    assign HEX_display[6] = (data[0] & data[1] & ~ data[2] & ~ data[3]) | (~ data[0] & data[1] & data[2] & data[3]) | (~ data[0] & ~ data[1] & ~ data[2] & data[3]) | (~ data[0] & ~ data[1] & ~ data[2] & ~ data[3]);
endmodule