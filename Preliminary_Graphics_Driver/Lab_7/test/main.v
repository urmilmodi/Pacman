module main
    (
        CLOCK_50,                        //    On Board 50 MHz
        // The ports below are for the VGA output.  Do not change.
        SW, LEDR, KEY,
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
    input     [9:0]    SW;
	output    [9:0]    LEDR;
    input [3:0] KEY;
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
    
    reg clk = 1'b0;
    reg [3:0] speedcount;

    wire pulse; // 120Hz pulse generated for 1/120 period
    wire [26:0] timer = 27'b000000001100101101110011010; // 1/120 sec count (120Hz)
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
/*
    wire pulse; // 120Hz pulse generated for 1/120 period
    wire [26:0] timer = 27'b000000001100101101110011010; // 1/120 sec count (120Hz)
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
        if (erasecounter >= SW[9:3])
            erasecounter <= 7'b0;
        else
            erasecounter <= erasecounter + 1;
        
        speedcount <= speedcount + 1;

        clk = ~clk; // Generate 120Hz clk - eqv of 60 Hz refresh rate
        if (clk) begin // clk posedge set clr, update sprite x location
            
            case(rx)
                1'b0: begin
                    if (xblock == 7'd124)
                        rx <= 1'b1;
                        
                    else if (speedcount >= SW[2:0])
                        xblock <= xblock + 7'd1;
                    end
                1'b1: begin
                    if (xblock == 7'd0)
                        rx <= 1'b0;
                        
                    else if (speedcount >= SW[2:0])
                        xblock <= xblock - 7'd1;
                    end
                default: rx <= 1'b0;
            endcase

            case(ry)
                1'b0: begin
                    if (yblock == 7'd116)
                        ry <= 1'b1;
                        
                    else if (speedcount >= SW[2:0])
                        yblock <= yblock + 7'd1;
                    end
                1'b1: begin
                    if (yblock == 7'd0)
                        ry <= 1'b0;
                        
                    else if (speedcount >= SW[2:0])
                        yblock <= yblock - 7'd1;
                    end
                default: ry <= 1'b0;
            endcase
        
            go <= 1'b0;
            trigger <= 1'b1;
        end
        else begin
            // clk negedge update sprite y location and display

            go <= 1'b1;
            trigger <= 1'b0;
        end
    end
*/
    // Create the colour, x, y and writeEn wires that are inputs to the controller.

    wire [7:0] x;
    wire [6:0] y;
    wire plot;
    wire [25:0] central_counter;
    wire [2:0] DataColour;
    wire reset = SW[9];

    // Create an Instance of a VGA controller - there can be only one!
    // Define the number of colours as well as the initial background
    // image file (.MIF) for the controller.
    vga_adapter VGA(
            .resetn(reset),
            .clock(CLOCK_50),
            .colour(DataColour),
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
    assign LEDR[2:0] = DataColour;
    control C0(
        .clk(CLOCK_50),
        .plot(plot),
        .blockx(xblock),
        .blocky(yblock),
        .xout(x),
        .yout(y),
        .cout(DataColour)
    );

endmodule

module control(clk, plot, blockx, blocky, xout, yout, cout);

    input clk;
    input [7:0] blockx;
    input [6:0] blocky;

    output reg plot;
    output reg [7:0] xout;
    output reg [6:0] yout;
    output reg [2:0] cout;

    reg [2:0] current_state;
    reg [2:0] next_state;
    reg [25:0] StateCounter;
    reg [7:0] Xorigin;
    reg [6:0] Yorigin;
    reg [3:0] blockcounter;
    reg [14:0] counterBlack;

    wire [2:0] backgroundclr;
    wire [2:0] blockclr = 3'b100;

    parameter Background_pixels = 14'd19200 - 14'd1;
    parameter Block_pixels = 5'd16 - 5'd1;
    parameter Erase_limiter = 27'b000000001100101101110011010;

    rambackground B0 (.address(counterBlack), .clock(clk), .q(backgroundclr), .data(15'b0), .wren(1'b0));

    localparam  Load_Background = 3'd0,
                BackgroundtoBlock_Wait = 3'd1,
                Load_Block = 3'd2,
                Speed_Wait = 3'd3;
    
    always@(posedge clk)
    begin: state_table
        case (current_state)
            Load_Background: next_state = (StateCounter > Background_pixels) ? BackgroundtoBlock_Wait : Load_Background;
            BackgroundtoBlock_Wait: next_state = (StateCounter > Background_pixels + 1) ? Load_Block : BackgroundtoBlock_Wait;
            Load_Block: next_state = (StateCounter > Background_pixels + 1 + Block_pixels) ? Speed_Wait : Load_Block;
            Speed_Wait: next_state = (StateCounter > Background_pixels + 2 + Block_pixels + Erase_limiter) ? Load_Background : Speed_Wait;
            default: next_state = Speed_Wait;
        endcase
    end

    always @(negedge clk)
    begin: enable_signals

        StateCounter = StateCounter + 1;
        
        case (current_state)
            Load_Background:begin
                                counterBlack <= counterBlack + 1'b1;
                                xout <= counterBlack[7:0];
                                yout <= counterBlack[14:8];
                                cout <= backgroundclr;
                                plot <= 1;
                            end
                          
            BackgroundtoBlock_Wait: begin
                                        Xorigin <= blockx;
                                        Yorigin <= blocky;
                                        plot <= 0;
                                    end
                          
            Load_Block: begin
                            blockcounter <= blockcounter + 1;
                            cout <= blockclr;
                            xout <= Xorigin + blockcounter[1:0];
                            yout <= Yorigin + blockcounter[3:2];
                            plot <= 1;
                        end
                          
            Speed_Wait: begin
                            plot <= 0;
                            counterBlack <= 0;
                            blockcounter <= 0;
                            if (StateCounter > Background_pixels + 1 + Block_pixels + Erase_limiter) begin
                                StateCounter = 0;
                            end
                        end
        endcase
    end
                    
    // current_state registers
    always@(posedge clk)
    begin: state_FFs
        current_state <= next_state;
    end // state_FFS
endmodule 

/*
module datapath(clk, load_background, load_wait, load_block, speed_wait, Erase_limiter, plot, blockx, blocky, xout, yout, cout, counter);

    input clk;
    input load_background;
    input load_wait;
    input load_block;
    input speed_wait;
    input [7:0] blockx;
    input [6:0] blocky;

    input [25:0] Erase_limiter;

    output reg [25:0] counter;
    output reg [7:0] xout;
    output reg [6:0] yout;
    output reg [2:0] cout;
    output reg plot;

    always@(posedge clk) begin

        /*if (load_background)
            Xorigin <= 8'b0;
            Yorigin <= 7'b0;
        //if (load_wait)
            //Yorigin <= yblock;
				
        if (load_block) begin
            Xorigin <= blockx;
            Yorigin <= blocky;
			end
        //if (speed_wait)
    end
        
    always@ (posedge clk) begin
        counter = counter + 1;

        if (load_background) begin
            counterBlack <= counterBlack + 1'b1;
            xout <= counterBlack[7:0];
            yout <= counterBlack[14:8];
            cout <= backgroundclr;
            plot <= 1;
        end
        if (load_wait) begin
            Xorigin <= blockx;
            Yorigin <= blocky;
            plot <= 0;
        end
        if (load_block) begin
            blockcounter <= blockcounter + 1;
            cout <= blockclr;
            xout <= Xorigin + blockcounter[1:0];
            yout <= Yorigin + blockcounter[3:2];
            plot <= 1;
        end
        if (speed_wait) begin
            plot <= 0;
            counterBlack <= 0;
            blockcounter <= 0;
            if (counter > Background_pixels + 1 + Block_pixels + Erase_limiter) begin
                counter = 0;
            end
        end
    end
endmodule*/