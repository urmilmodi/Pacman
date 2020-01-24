module main(
        CLOCK_50, LEDR, KEY, SW, HEX0, HEX1, HEX2, HEX3, HEX4, HEX5,
        PS2_CLK,
        PS2_DAT,
        VGA_CLK,                           //    VGA Clock
        VGA_HS,                            //    VGA H_SYNC
        VGA_VS,                            //    VGA V_SYNC
        VGA_BLANK_N,                        //    VGA BLANK
        VGA_SYNC_N,                        //    VGA SYNC
        VGA_R,                           //    VGA Red[9:0]
        VGA_G,                             //    VGA Green[9:0]
        VGA_B                           //    VGA Blue[9:0]
    );


    // 50 MHz Clk & Various I/O Connections
    input              CLOCK_50;
    input      [9:0]   SW;
    input      [3:0]   KEY;
    output reg [9:0]   LEDR = 0;
    output     [6:0]   HEX0;
    output     [6:0]   HEX1;
    output     [6:0]   HEX2;
    output     [6:0]   HEX3;
    output     [6:0]   HEX4 = 6'b111111;
    output     [6:0]   HEX5 = 6'b111111;
    
    // Signals for PS2 Controller & VGA Display
    inout              PS2_CLK;
    inout              PS2_DAT;
    output             VGA_CLK;                   //    VGA Clock
    output             VGA_HS;                    //    VGA H_SYNC
    output             VGA_VS;                    //    VGA V_SYNC
    output             VGA_BLANK_N;            //    VGA BLANK
    output             VGA_SYNC_N;                //    VGA SYNC
    output    [7:0]    VGA_R;                   //    VGA Red[7:0] Changed from 10 to 8-bit DAC
    output    [7:0]    VGA_G;                     //    VGA Green[7:0]
    output    [7:0]    VGA_B;                   //    VGA Blue[7:0]

    wire reset = 1;

    localparam  LEFT          = 16'hFF00,
                RIGHT         = 16'h0100,
                DOWN          = 16'h0001,
                UP            = 16'h00FF,
                Chase         = 4'b1000,
                Scatter       = 4'b0100,
                Frightened    = 4'b0010,
                Eaten         = 4'b0001;

    wire [7:0] data_out;
    wire data_sent;

    // Keyboard Module
    PS2_Controller keyboard(
            .CLOCK_50(CLOCK_50),
            .reset(~reset), 
            /* Signals for PS2 Controller */
            .PS2_CLK(PS2_CLK),
            .PS2_DAT(PS2_DAT), 
            .received_data(data_out), 
            .received_data_en(data_sent)
            );

    wire [16:0] xout;
    wire [16:0] yout; 
    wire [11:0] cout; 
    wire plot;

    wire [15:0] PacmanFacing;
    wire [15:0] PacmanLoc;
    wire [15:0] BlinkyFacing;
    wire [15:0] BlinkyLoc;
    wire [15:0] InkyFacing;
    wire [15:0] InkyLoc;
    wire [15:0] PinkyFacing;
    wire [15:0] PinkyLoc;
    wire [15:0] ClydeFacing;
    wire [15:0] ClydeLoc;

    wire [15:0] TopLeftFruit;
    wire [15:0] TopRightFruit;
    wire [15:0] BottomLeftFruit;
    wire [15:0] BottomRightFruit;
    wire [15:0] Score;
    wire GameOver;

    vga_adapter VGA(
            .resetn(reset),
            .clock(CLOCK_50),
            .colour(cout),
            .x(xout),
            .y(yout),
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
        defparam VGA.RESOLUTION = "320x240";
        defparam VGA.MONOCHROME = "FALSE";
        defparam VGA.BITS_PER_COLOUR_CHANNEL = 4;
        defparam VGA.BACKGROUND_IMAGE = "Untitled.mif";

    reg [15:0] Move;

    always@(posedge CLOCK_50) begin

        //keyboard recieves up arrow
        if(data_out == 8'b1110101) begin
            Move <= UP;
            LEDR <= Chase;
        end
        
        //keyboard recieves down arrow    
        if(data_out == 8'b1110010) begin
            Move <= DOWN;
            LEDR <= Scatter;
        end

        //keyboard recieves left arrow    
        if(data_out == 8'b1101011) begin
            Move <= LEFT;
            LEDR <= Frightened;
        end
        
        //keyboard recieves right arrow    
        if(data_out == 8'b1110100) begin
            Move <= RIGHT;
            LEDR <= Eaten;
        end
    end

    Level u0
    (
        Move,
        CLOCK_50,
        PacmanLoc,
        PacmanFacing,
        BlinkyLoc,
        BlinkyFacing,
        InkyLoc,
        InkyFacing,
        PinkyLoc,
        PinkyFacing,
        ClydeLoc,
        ClydeFacing,
        TopLeftFruit,
        TopRightFruit,
        BottomLeftFruit,
        BottomRightFruit,
        Score,
        GameOver
    );
     
     seg7_HEX0 hex0(Score[3:0], HEX0);
     seg7_HEX0 hex1(Score[7:4], HEX1);
     seg7_HEX0 hex2(Score[11:8], HEX2);
     seg7_HEX0 hex3(Score[15:12], HEX3);
     

    graphicsNEW p1(
            CLOCK_50, 1, 16'd51,
            
                            PacmanFacing,     PacmanLoc[15:8],  PacmanLoc[7:0],  //plotPacman,                  blockxPAC, blockyPAC,xoutPAC, youtPAC, coutPAC,xLocPAC,yLocPAC, 
            Chase,          BlinkyFacing,     BlinkyLoc[15:8],  BlinkyLoc[7:0],  //plotBLUE,                    blockxBLUE, blockyBLUE,xoutBLUE, youtBLUE, coutBLUE,xLocBLUE,yLocBLUE,
            Scatter,        InkyFacing,         InkyLoc[15:8], InkyLoc[7:0],  //plotRED,                     blockxRED, blockyRED,xoutRED, youtRED, coutRED,xLocRED,yLocRED, 
            Frightened,     PinkyFacing,     PinkyLoc[15:8], PinkyLoc[7:0],  //plotPINK,                    blockxPINK, blockyPINK,xoutPINK, youtPINK, coutPINK,xLocPINK,yLocPINK,  
            Eaten,          ClydeFacing,     ClydeLoc[15:8], ClydeLoc[7:0],  //plotYELLOW,                  blockxYELLOW, blockyYELLOW,xoutYELLOW, youtYELLOW, coutYELLOW,xLocYELLOW,yLocYELLOW,
           TopLeftFruit[15:8], TopRightFruit[15:8], BottomLeftFruit[15:8], BottomRightFruit[15:8],
            TopLeftFruit[7:0], TopRightFruit[7:0], BottomLeftFruit[7:0], BottomRightFruit[7:0], 
            xout, yout, cout, plot//, LEDR
                  );
    
endmodule


module seg7_HEX0 (input [3:0]SW, output [6:0] HEX0);
    /*
        0  1  2  3  4  5  6
    0 - 0, 0, 0, 0, 0, 0, 1
    1 - 1, 0, 0, 1, 1, 1, 1
    2 - 0, 0, 1, 0, 0, 1, 0
    3 - 0, 0, 0, 0, 1, 1, 0
    4 - 1, 0, 0, 1, 1, 0, 0
    5 - 0, 1, 0, 0, 1, 0, 0
    6 - 0, 1, 0, 0, 0, 0, 0
    7 - 0, 0, 0, 1, 1, 1, 1
    8 - 0, 0, 0, 0, 0, 0, 0
    9 - 0, 0, 0, 1, 1, 0, 0
    A - 0, 0, 0, 1, 0, 0, 0
    b - 1, 1, 0, 0, 0, 0, 0
    C - 0, 1, 1, 0, 0, 0, 1
    d - 1, 0, 0, 0, 0, 1, 0
    E - 0, 1, 1, 0, 0, 0, 0
    F - 0, 1, 1, 1, 0, 0, 0
    */

    assign HEX0[0] = (~ SW[0] & ~ SW[1] & ~ SW[2] & SW[3]) | (~ SW[0] & SW[1] & ~ SW[2] & ~ SW[3]) | (SW[0] & ~ SW[1] & SW[2] & SW[3]) | (SW[0] & SW[1] & ~ SW[2] & SW[3]);
    assign HEX0[1] = (SW[0] & SW[1] & SW[2] & SW[3]) | (SW[0] & SW[1] & SW[2] & ~ SW[3]) | (SW[0] & SW[1] & ~ SW[2] & ~ SW[3]) | (SW[0] & ~ SW[1] & SW[2] & SW[3]) | (~ SW[0] & SW[1] & SW[2] & ~ SW[3]) | (~ SW[0] & SW[1] & ~ SW[2] & SW[3]);
    assign HEX0[2] = (SW[0] & SW[1] & SW[2] & SW[3]) | (SW[0] & SW[1] & SW[2] & ~ SW[3]) | (SW[0] & SW[1] & ~ SW[2] & ~ SW[3]) | (~ SW[0] & ~ SW[1] & SW[2] & ~ SW[3]);
    assign HEX0[3] = (SW[0] & SW[1] & SW[2] & SW[3]) | (SW[0] & ~ SW[1] & SW[2] & ~ SW[3]) | (SW[0] & ~ SW[1] & ~ SW[2] & SW[3]) | (~ SW[0] & SW[1] & SW[2] & SW[3]) | (~ SW[0] & SW[1] & ~ SW[2] & ~ SW[3]) | (~ SW[0] & ~ SW[1] & ~ SW[2] & SW[3]);
    assign HEX0[4] = (SW[0] & ~ SW[1] & ~ SW[2] & SW[3]) | (~ SW[0] & SW[1] & SW[2] & SW[3]) | (~ SW[0] & SW[1] & ~ SW[2] & SW[3]) | (~ SW[0] & SW[1] & ~ SW[2] & ~ SW[3]) | (~ SW[0] & ~ SW[1] & SW[2] & SW[3]) | (~ SW[0] & ~ SW[1] & ~ SW[2] & SW[3]);
    assign HEX0[5] = (SW[0] & SW[1] & ~ SW[2] & SW[3]) | (~ SW[0] & SW[1] & SW[2] & SW[3]) | (~ SW[0] & ~ SW[1] & SW[2] & SW[3]) | (~ SW[0] & ~ SW[1] & SW[2] & ~ SW[3]) | (~ SW[0] & ~ SW[1] & ~ SW[2] & SW[3]);
    assign HEX0[6] = (SW[0] & SW[1] & ~ SW[2] & ~ SW[3]) | (~ SW[0] & SW[1] & SW[2] & SW[3]) | (~ SW[0] & ~ SW[1] & ~ SW[2] & SW[3]) | (~ SW[0] & ~ SW[1] & ~ SW[2] & ~ SW[3]);
endmodule

