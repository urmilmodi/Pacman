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
    output     [6:0]   HEX4;
    output     [6:0]   HEX5;
    
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

    localparam  leftindex     = 3,
                rightindex    = 2,
                upindex       = 1,
                downindex     = 0;

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

    wire [16:0] x;
    wire [16:0] y; 
    wire [11:0] colour; 
    wire plot;

    reg [15:0] PacmanLoc = {8'd101, 8'd175}; // Set to inital positions and directions
    reg [15:0] PacmanFacing = RIGHT;
    reg [15:0] GhostLoc = {8'd101, 8'd80}; // Same X pos as ^ but different Y
    reg [15:0] GhostFacing = RIGHT;
    wire [15:0] nextGhostLoc;
    wire [15:0] nextGhostFacing;
    reg update;
    
    reg [23:0] Score;
    reg GameOver = 0;

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
        defparam VGA.RESOLUTION = "320x240";
        defparam VGA.MONOCHROME = "FALSE";
        defparam VGA.BITS_PER_COLOUR_CHANNEL = 4;
        defparam VGA.BACKGROUND_IMAGE = "Untitled.mif";

    reg [15:0] Move;

    always@(posedge CLOCK_50) begin

        //keyboard recieves up arrow
        if(data_out == 8'b1110101) begin
            Move <= UP;
            LEDR <= 4'b0001;
        end
        
        //keyboard recieves down arrow    
        if(data_out == 8'b1110010) begin
            Move <= DOWN;
            LEDR <= 4'b0010;
        end

        //keyboard recieves left arrow    
        if(data_out == 8'b1101011) begin
            Move <= LEFT;
            LEDR <= 4'b0100;
        end
        
        //keyboard recieves right arrow    
        if(data_out == 8'b1110100) begin
            Move <= RIGHT;
            LEDR <= 4'b1000;
        end
    end

    // Display Score in HEX
    seg7_HEX0 hex0(Score[3:0], HEX0);
    seg7_HEX0 hex1(Score[7:4], HEX1);
    seg7_HEX0 hex2(Score[11:8], HEX2);
    seg7_HEX0 hex3(Score[15:12], HEX3);
    seg7_HEX0 hex4(Score[19:16], HEX4);
    seg7_HEX0 hex5(Score[23:20], HEX5);

    wire pulse; // 120Hz pulse generated for 1/120 period
    wire [26:0] timer = 27'b000000001100101101110011010; // 1/120 sec count (120Hz)
    reg [26:0] counter;
    reg [26:0] Time_Counter;
     
     // Generate 120Hz Pulse
    assign pulse = (counter == 27'b0) ? 1'b1 : 1'b0;
    always@(posedge CLOCK_50) begin
        if (counter >= timer)
            counter <= 27'b0;
        else
            counter <= counter + 1;
                
          // Time-Dependent Portion, so placed to run in Parallel
        // Scoring Time
          if (~KEY[3]) begin
                Score <= 0;
            end
            else if (~GameOver) begin
                if (Time_Counter >= 50000*1000) begin
                    Time_Counter <= 0;
                    Score <= Score + 8'd10;
                end
                else begin
                    Time_Counter <= Time_Counter + 1;
                end
          end
    end

    Blinky u0 (PacmanLoc, PacmanFacing, GhostLoc, GhostFacing, SW[3:0], ~KEY[0], update, pulse, nextGhostFacing, nextGhostLoc);

    reg [3:0] checkcounter;
     
     wire [3:0] clearPacmanDirections;

    clearRom clearPacman (.address(320*PacmanLoc[7:0] + PacmanLoc[15:8]), .clock(pulse), .q(clearPacmanDirections));

    always@(negedge pulse) begin
        if (~KEY[3]) begin
            PacmanLoc = {8'd101, 8'd175}; // Set to inital positions and directions
            PacmanFacing = RIGHT;
            GhostLoc = {8'd101, 8'd80}; // Same X pos as ^ but different Y
            GhostFacing = RIGHT;
            GameOver <= 0;
        end
        else begin
            if (checkcounter >= 10) begin
                    
                    if (PacmanLoc[7:0] == GhostLoc[7:0]) begin
                    if (PacmanLoc[15:8] > GhostLoc[15:8]) begin
                        if (PacmanLoc[15:8] - GhostLoc[15:8] < 8'd14) begin
                            GameOver <= 1;
                        end
                    end
                    else begin
                        if (GhostLoc[15:8] - PacmanLoc[15:8] < 8'd14) begin
                            GameOver <= 1;
                        end
                    end
                end

                else if (PacmanLoc[15:8] == GhostLoc[15:8]) begin
                    if (PacmanLoc[7:0] > GhostLoc[7:0]) begin
                        if (PacmanLoc[7:0] - GhostLoc[7:0] < 8'd14) begin
                            GameOver <= 1;
                        end
                    end
                    else begin
                        if (GhostLoc[7:0] - PacmanLoc[7:0] < 8'd14) begin
                            GameOver <= 1;
                        end
                    end
                end
                    
                    if (~GameOver) begin
                        case(Move)
                             LEFT: begin
                                        if (clearPacmanDirections[leftindex]) begin
                                             PacmanLoc <= PacmanLoc + Move;
                                        end
                                        PacmanFacing <= Move;
                                  end
                             RIGHT: begin
                                        if (clearPacmanDirections[rightindex]) begin
                                             PacmanLoc <= PacmanLoc + Move;
                                        end
                                        PacmanFacing <= Move;
                                  end
                             UP: begin
                                        if (clearPacmanDirections[upindex]) begin
                                             PacmanLoc <= PacmanLoc + Move + LEFT;
                                        end
                                        PacmanFacing <= Move;
                                  end
                             DOWN: begin
                                        if (clearPacmanDirections[downindex]) begin
                                             PacmanLoc <= PacmanLoc + Move;
                                        end
                                        PacmanFacing <= Move;
                                  end
                             default: begin
                                             PacmanLoc <= PacmanLoc;
                                             PacmanFacing <= PacmanFacing;
                                        end
                        endcase
                        
                        GhostLoc <= nextGhostLoc;
                        GhostFacing <= nextGhostFacing;
                        update <= 0;
                        checkcounter <= 0;
                    end
            end
            else begin
                update <= 1;
                checkcounter <= checkcounter + 1;
            end
        end
    end

    Graphics monitor(CLOCK_50, 1, PacmanLoc[15:8], PacmanLoc[7:0], GhostLoc[15:8], GhostLoc[7:0], x, y, colour, plot);
    
endmodule

module Graphics(clk, resetn, pacmanx, pacmany, ghostx, ghosty, xout, yout, cout, plot);

    input clk;
    input resetn;
    input [8:0] pacmanx;
    input [8:0] pacmany;
    input [8:0] ghostx;
    input [8:0] ghosty;

    output reg [8:0] xout;
    output reg [8:0] yout;
    output reg [11:0] cout;
    output reg plot;

    reg [25:0] stateCounter = 0;
    reg [2:0] current_state;
    reg [2:0] next_state;
     
    parameter Erase_Delay = 50000*100; //50000*delay(in ms)
    parameter Background_pixels = 76800;
    parameter Block_pixels = 10*10+1;

    localparam  Load_Background        = 0,
                BackgroundtoBlock_WaitA = 1,
                Load_BlockA             = 2,
                BackgroundtoBlock_WaitB = 3,
                Load_BlockB             = 4,
                Erase_Wait             = 5,
                Preset                 = 6;
    
    always@(posedge clk)
    begin: state_table
        case (current_state)
            Load_Background: next_state = (stateCounter > Background_pixels) ? BackgroundtoBlock_WaitA : Load_Background;
            BackgroundtoBlock_WaitA: next_state = (stateCounter > Background_pixels + 1) ? Load_BlockA : BackgroundtoBlock_WaitA;
            Load_BlockA: next_state = (stateCounter > Background_pixels + 1 + Block_pixels) ? BackgroundtoBlock_WaitB : Load_BlockA;
            BackgroundtoBlock_WaitB: next_state = (stateCounter > Background_pixels + 1 + Block_pixels + 1) ? Load_BlockB : BackgroundtoBlock_WaitB;
            Load_BlockB: next_state = (stateCounter > Background_pixels + 1 + Block_pixels + 1 + Block_pixels) ? Erase_Wait : Load_BlockB;
            Erase_Wait: next_state = (stateCounter > Background_pixels + 1 + Block_pixels + 1 + Block_pixels + Erase_Delay) ? Preset : Erase_Wait;
            Preset: next_state = Load_Background;
            default: next_state = Load_Background;
        endcase
    end

    reg [8:0] counterX = 0;
    reg [8:0] counterY = 0;

    wire [11:0] backgroundclr;
    wire [11:0] pacmanclr;
    wire [11:0] ghostclr;
    
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
    rom_PACMAN_up u1(.address(10*counterY + counterX), .clock(clk), .q(pacmanclr));
    rom_BLUE_up u2(.address(10*counterY + counterX), .clock(clk), .q(ghostclr));

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
        if (current_state == BackgroundtoBlock_WaitA) begin
            plot <= 0;
            counterX <= 0;
            counterY <= 0;
        end
        if (current_state == Load_BlockA) begin
            
            if (pacmanclr != 12'b111111111111) begin
                    cout <= pacmanclr;
                    xout <= pacmanx + counterX + 51;
                    yout <= pacmany + counterY;
                    plot <= 1;
                end
            if (counterX == 10 - 1) begin
                counterX <= 0;
                counterY <= counterY + 1;
            end
            else begin
                counterX <= counterX + 1;
            end
        end
        if (current_state == BackgroundtoBlock_WaitB) begin
            plot <= 0;
            counterX <= 0;
            counterY <= 0;
        end
        if (current_state == Load_BlockB) begin
            
            cout <= ghostclr;
            xout <= ghostx + counterX + 51;
            yout <= ghosty + counterY;
            plot <= 1;
            if (counterX == 10 - 1) begin
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