module main
    (
        CLOCK_50,                        //    On Board 50 MHz
        // The ports below are for the VGA output.  Do not change.
        KEY, SW, LEDR,
        VGA_CLK,                           //    VGA Clock
        VGA_HS,                            //    VGA H_SYNC
        VGA_VS,                            //    VGA V_SYNC
        VGA_BLANK_N,                        //    VGA BLANK
        VGA_SYNC_N,                        //    VGA SYNC
        VGA_R,                           //    VGA Red[9:0]
        VGA_G,                             //    VGA Green[9:0]
        VGA_B                           //    VGA Blue[9:0]
    );

    input              CLOCK_50;                //    50 MHz
    input     [3:0]    KEY;
	 input     [9:0]    SW;
	 input     [9:0]    LEDR;
    // Do not change the following outputs
    output             VGA_CLK;                   //    VGA Clock
    output             VGA_HS;                    //    VGA H_SYNC
    output             VGA_VS;                    //    VGA V_SYNC
    output             VGA_BLANK_N;            //    VGA BLANK
    output             VGA_SYNC_N;                //    VGA SYNC
    output    [7:0]    VGA_R;                   //    VGA Red[7:0] Changed from 10 to 8-bit DAC
    output    [7:0]    VGA_G;                     //    VGA Green[7:0]
    output    [7:0]    VGA_B;                   //    VGA Blue[7:0]
    
    reg [7:0] xblock = 8'd0;
    reg [6:0] yblock = 7'd0;
    reg [3:0] r = 4'b0;

    localparam  left = 4'b0001,
                right = 4'b0010,
                up = 4'b0100,
                down = 4'b1000,
                stop = 4'b0000;
    
    reg [3:0] speedcount;

    wire pulse; // 120Hz pulse generated for 1/120 period
    wire [26:0] timer = 27'b1100101101110011010; // 1/120 sec count (120Hz)
    reg [26:0] counter;
    
    // Generate 120Hz Pulse
    assign pulse = (counter == 27'b0) ? 1'b1 : 1'b0;
    always@(posedge CLOCK_50) begin
        if (counter >= timer)
            counter <= 27'b0;
        else
            counter <= counter + 1;
    end
    
    always @(posedge pulse) begin

        speedcount <= speedcount + 1;
        case(~KEY)
            stop: r = stop;
            left: r = left;
            right: r = right;
            down: r = down;
            up: r = up;
            default: r = stop;
        endcase

        case(r)
            stop: begin
                    xblock <= xblock;
                    yblock <= yblock;
                  end
            left: begin
                    if (xblock == 8'd156)
                        r <= stop;
                        
                    else if (speedcount >= SW[2:0])
                        xblock <= xblock + 8'd1;
                    end
            right: begin
                    if (xblock == 8'd0)
                        r <= stop;
                        
                    else if (speedcount >= SW[2:0])
                        xblock <= xblock - 8'd1;
                    end
            up: begin
                    if (yblock == 7'd0)
                        r <= stop;
                        
                    else if (speedcount >= SW[2:0])
                        yblock <= yblock - 7'd1;
                    end
            down: begin
                    if (yblock == 7'd116)
                        r <= stop;
                        
                    else if (speedcount >= SW[2:0])
                        yblock <= yblock + 7'd1;
                    end
            default: r <= stop;
        endcase
    end

    // Create the colour, x, y and writeEn wires that are inputs to the controller.
    wire [7:0] x;
    wire [6:0] y;
    wire plot;
    wire [25:0] central_counter;
    wire load_background, load_wait, load_block, Erase_Wait;
    wire [2:0] colour;
	 
	 wire reset = 1;

    // Create an Instance of a VGA controller - there can be only one!
    // Define the number of colours as well as the initial background
    // image file (.MIF) for the controller.
    
    vga_adapter VGA(
            .resetn(reset),
            .clock(CLOCK_50),
            .colour(colour),
            .x(x),
            .y(y),
            .plot(plot),
            /* Signals for the DAC to drive the monitor. */
            .VGA_R(VGA_R),
            .VGA_G(VGA_G),
            .VGA_B(VGA_B),
            .VGA_HS(VGA_HS),
            .VGA_VS(VGA_VS),
            .VGA_BLANK(VGA_BLANK_N),
            .VGA_SYNC(VGA_SYNC_N),
            .VGA_CLK(VGA_CLK));
        defparam VGA.RESOLUTION = "160x120";
        defparam VGA.MONOCHROME = "FALSE";
        defparam VGA.BITS_PER_COLOUR_CHANNEL = 1;
        defparam VGA.BACKGROUND_IMAGE = "white.mif";
            
    // Put your code here. Your code should produce signals x,y,colour and writeEn
    // for the VGA controller, in addition to any other functionality your design may require.

    // TODO: Add reset to clear graphics drivers

    control C0(
        .clk(CLOCK_50),
        .resetn(reset),
        .plot(plot),
        .blockx(xblock),
        .blocky(yblock),
        .xout(x),
        .yout(y),
        .cout(colour)
    );
endmodule

module control(clk, resetn, plot, blockx, blocky, xout, yout, cout);

    input clk;
	input resetn;
    input [7:0] blockx;
    input [6:0] blocky;

    output reg [7:0] xout;
    output reg [6:0] yout;
    output reg [2:0] cout;
    output reg plot;

    reg [25:0] counter = 0;
    reg [2:0] current_state;
    reg [2:0] next_state;
	 
    parameter Erase_Delay = 2500000; //50000*delay(in ms)
    parameter Background_pixels = 19200;
    parameter Block_pixels = 17;

    localparam  Load_Background        = 0,
                BackgroundtoBlock_Wait = 1,
                Load_Block             = 2,
                Erase_Wait             = 3,
					 Preset                 = 4;
    
    always@(posedge clk)
    begin: state_table
        case (current_state)
            Load_Background: next_state = (counter > Background_pixels) ? BackgroundtoBlock_Wait : Load_Background;
            BackgroundtoBlock_Wait: next_state = (counter > Background_pixels + 1) ? Load_Block : BackgroundtoBlock_Wait;
            Load_Block: next_state = (counter > Background_pixels + 1 + Block_pixels) ? Erase_Wait : Load_Block;
            Erase_Wait: next_state = (counter > Background_pixels + 1 + Block_pixels + Erase_Delay) ? Preset : Erase_Wait;
				Preset: next_state = Load_Background;
            default: next_state = Preset;
        endcase
    end

    reg [2:0] regcolour;
    reg [7:0] Xorigin;
    reg [6:0] Yorigin;
    reg [3:0] blockcounter;
    reg [2:0] regBlack;
    reg [7:0] counterX = 0;
	reg [6:0] counterY = 0;

    wire [2:0] backgroundclr;
    wire [2:0] blockclr = 3'b111;

	 // this address weirdness even I don't completely get but it works
	 // Try following the same style for a bigger size
	 
	 // General Address : <width>(counterY + 1) + counterX
	 
    rombackground u0(.address((8'd160)*(counterY + 1) + counterX), .clock(clk), .q(backgroundclr));
        
    always@ (negedge clk) begin
        counter = counter + 1;
        
        if (current_state == Load_Background) begin
			
            xout = counterX;
			yout = counterY;
            cout <= backgroundclr;
            plot <= 1;
				
            // Think of Display Setup and this will make sense
            if (counterX == 8'd159) begin
                counterX <= 0;
                counterY <= counterY + 1;
            end
            else begin
				counterX <= counterX + 1;
			end
        end
        if (current_state == BackgroundtoBlock_Wait) begin
            plot <= 0;
            Xorigin <= blockx;
            Yorigin <= blocky;
        end
        if (current_state == Load_Block) begin
            
            cout <= blockclr;
            xout = Xorigin + blockcounter[1:0];
            yout = Yorigin + blockcounter[3:2];
            plot <= 1;
			   blockcounter <= blockcounter + 1;
        end
        if (current_state == Erase_Wait) begin
            plot <= 0;
            counterX <= 0;
			counterY <= 0;
            blockcounter <= 0;
        end
		  if (current_state == Preset) begin
				counter <= 0;
				plot <= 0;
            counterX <= 0;
			counterY <= 0;
            blockcounter <= 0;
		  end
        if (!resetn) begin
            plot <= 0;
            xout <= 0;
            yout <= 0;
            counterX <= 0;
            counterY <= 0;
            blockcounter <= 0;
            counter <= 0;
        end
    end

    // current_state registers
    always@(posedge clk)
    begin: state_FFs
        if (!resetn)
            current_state <= Erase_Wait;
        else
            current_state <= next_state;
    end
endmodule