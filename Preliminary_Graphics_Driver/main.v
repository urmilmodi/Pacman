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
    output reg [9:0]    LEDR;
    // Do not change the following outputs
    output             VGA_CLK;                   //    VGA Clock
    output             VGA_HS;                    //    VGA H_SYNC
    output             VGA_VS;                    //    VGA V_SYNC
    output             VGA_BLANK_N;            //    VGA BLANK
    output             VGA_SYNC_N;                //    VGA SYNC
    output    [7:0]    VGA_R;                   //    VGA Red[7:0] Changed from 10 to 8-bit DAC
    output    [7:0]    VGA_G;                     //    VGA Green[7:0]
    output    [7:0]    VGA_B;                   //    VGA Blue[7:0]
    
    reg [8:0] xblock = 51;
    reg [8:0] yblock = 176;
    reg [3:0] r = 0;

    localparam  left = 4'b1000,
                right = 4'b0100,
                up = 4'b0010,
                down = 4'b0001,
                stop = 4'b0000;
    
    reg [3:0] speedcount;

    wire pulse; // 120Hz pulse generated for 1/120 period
    wire [26:0] timer = 27'b11001011011100110100000; // 1/120 sec count (120Hz)
    reg [26:0] counter;
    
    // Generate 120Hz Pulse
    assign pulse <= (counter == 0) ? 1 : 0;
    always@(posedge CLOCK_50) begin
        if (counter >= timer)
            counter <= 0;
        else
            counter <= counter + 1;
    end
    
    wire [3:0] clear;

    // Outputs clear Directions for specific xy locations
    clearRom u0(.address(320*yblock + xblock), .q(clear), .clock(pulse));

    always@(posedge pulse) begin
     
        LEDR[3:0] <= clear;

        case(~KEY)
            stop: r <= stop;
            left: r <= left;
            right: r <= right;
            down: r <= down;
            up: r <= up;
            default: r <= stop;
        endcase

        case(r)
            stop: begin
                    xblock <= xblock;
                    yblock <= yblock;
                  end
            left: begin
                    if (xblock == 0 || ~clear[3])
                        r <= stop;
                        
                    else begin
                        xblock <= xblock - 1;
                            end
                 end
            right: begin
                    if (xblock == 320-14 || ~clear[2])
                        r <= stop;
                        
                    else begin
                        xblock <= xblock + 1;
                            end
                  end
            up: begin
                    if (yblock == 0 || ~clear[1])
                        r <= stop;
                        
                    else begin
                        yblock <= yblock - 1;
                            end
                 end
            down: begin
                    if (yblock == 240-14 || ~clear[0])
                        r <= stop;
                        
                    else begin
                        yblock <= yblock + 1;
                            end
                 end
            default: r <= stop;
        endcase
    end

    // Create the colour, x, y and writeEn wires that are inputs to the controller.
    wire [8:0] x;
    wire [8:0] y;
    wire plot;
    wire [11:0] colour;
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
        defparam VGA.RESOLUTION <= "320x240";
        defparam VGA.MONOCHROME <= "FALSE";
        defparam VGA.BITS_PER_COLOUR_CHANNEL <= 4;
        defparam VGA.BACKGROUND_IMAGE <= "Untitled.mif";
            
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
    input [8:0] blockx;
    input [8:0] blocky;

    output reg [8:0] xout;
    output reg [8:0] yout;
    output reg [11:0] cout;
    output reg plot;
     
    parameter Erase_Delay = 50000*10; //50000*delay(in ms)
    parameter Background_pixels = 76800;
    parameter Block_pixels = 14*14+1;

    localparam  Load_Background        = 0,
                BackgroundtoBlock_Wait = 1,
                Load_Block             = 2,
                Erase_Wait             = 3,
                Preset                 = 4;

    reg [25:0] stateCounter = 0;
    reg [2:0] current_state = Load_Background;
    reg [2:0] next_state;
    
    always@(posedge clk)
    begin: state_table
        case (current_state)
            Load_Background: next_state <= (stateCounter > Background_pixels) ? BackgroundtoBlock_Wait : Load_Background;
            BackgroundtoBlock_Wait: next_state <= (stateCounter > Background_pixels + 1) ? Load_Block : BackgroundtoBlock_Wait;
            Load_Block: next_state <= (stateCounter > Background_pixels + 1 + Block_pixels) ? Erase_Wait : Load_Block;
            Erase_Wait: next_state <= (stateCounter > Background_pixels + 1 + Block_pixels + Erase_Delay) ? Preset : Erase_Wait;
            Preset: next_state <= Load_Background;
            default: next_state <= Load_Background;
        endcase
    end

    reg [7:0] blockcounter;
    reg [8:0] counterX = 0;
    reg [8:0] counterY = 0;

    wire [11:0] backgroundclr;
    wire [11:0] blockclr <= 12'b111111110000;
    // General Address : <width>counterY + counterX
     /* Below is a 3x3 pixel grid
     
     
        ***
        ***
        ***
         
        pixel 3 is the pixel in the left col, middle row 
         
        the formula ^ outputs 3 using the x, y coordinates of (0, and 1) check it works for the remaining 8 other pixels as well
         
        this formula is similar to how a 2d array can be implemented using a regular 1D array (if you don't get this pls ignore it and just blindly use the formula)
         
    */
     
    rombackground u0(.address(320*counterY + counterX), .clock(clk), .q(backgroundclr));
        
    always@ (negedge clk) begin
        stateCounter <= stateCounter + 1;
        
        if (current_state == Load_Background) begin
            
            xout <= counterX;
            yout <= counterY;
            cout <= backgroundclr;
            plot <= 1;
                
            // Think of Display Setup and this will make sense
            if (counterX == 319) begin
                counterX <= 0;
                counterY <= counterY + 1;
            end
            else begin
                counterX <= counterX + 1;
            end
        end
        if (current_state == BackgroundtoBlock_Wait) begin
            plot <= 0;
            counterX <= 0;
            counterY <= 0;
        end
        if (current_state == Load_Block) begin
            
            cout <= blockclr;
            xout <= blockx + counterX;
            yout <= blocky + counterY;
            plot <= 1;
            if (counterX == 14 - 1) begin
                counterX <= 0;
                counterY <= counterY + 1;
            end
            else begin
                counterX <= counterX + 1;
            end
        end
        if (current_state == Erase_Wait) begin
            plot <= 0;
        end
          if (current_state == Preset) begin
            stateCounter <= 0;
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
            stateCounter <= 0;
        end
    end

    // current_state registers
    always@(posedge clk)
    begin: state_FFs
        if (!resetn)
            current_state <= Load_Background;
        else
            current_state <= next_state;
    end
endmodule