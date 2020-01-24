module Level
    (
        Move,
        clk,
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

    localparam  size          = 14,
                LEFT          = 16'hFF00,
                RIGHT         = 16'h0100,
                DOWN          = 16'h0001,
                UP            = 16'h00FF,
                leftindex     = 3,
                rightindex    = 2,
                upindex       = 1,
                downindex     = 0,
                Chase         = 4'b1000,
                Scatter       = 4'b0100,
                Frightened    = 4'b0010,
                Eaten         = 4'b0001;

    input [15:0] Move;
    input clk;
    
    output reg [15:0] PacmanLoc = {108 - side/2, 8'd175}; // Set to inital positions and directions
    output reg [15:0] PacmanFacing = RIGHT;
    output reg [15:0] BlinkyLoc = {108 - side/2, 97-side}; // Same X pos as ^ but different Y
    output reg [15:0] BlinkyFacing = UP;
    output reg [15:0] InkyLoc = {108 - side/2 - side - 1, 120-side};  // diff X pos as ^ but same Y
    output reg [15:0] InkyFacing = UP;
    output reg [15:0] PinkyLoc = {108 - side/2, 120-side}; // Same X pos as ^ but same Y
    output reg [15:0] PinkyFacing = UP;
    output reg [15:0] ClydeLoc = {108 + side/2 + 1, 120-side}; // diff X pos as ^ but same Y
    output reg [15:0] ClydeFacing = UP;

    output reg [15:0] TopLeftFruit; // Initialize the Locations
    output reg [15:0] TopRightFruit;
    output reg [15:0] BottomLeftFruit;
    output reg [15:0] BottomRightFruit;

    output reg [15:0] Score = 0;
    output reg GameOver = 0;

    wire [15:0] nextPacmanLoc;
    wire [15:0] nextPacmanFacing;
    wire [15:0] nextBlinkyLoc;
    wire [15:0] nextBlinkyFacing;
    wire [15:0] nextInkyLoc;
    wire [15:0] nextInkyFacing;
    wire [15:0] nextPinkyLoc;
    wire [15:0] nextPinkyFacing;
    wire [15:0] nextClydeLoc;
    wire [15:0] nextClydeFacing;

    reg [3:0] Gamemode; // chase, scatter, frighten, eaten
    reg [3:0] Blinkymode;
    reg [3:0] Inkymode;
    reg [3:0] Pinkymode;
    reg [3:0] Clydemode;
    reg rotate;
    reg update;

    wire [3:0] clearPacmanDirections;
    wire [3:0] clearBlinkyDirections;
    wire [3:0] clearInkyDirections;
    wire [3:0] clearPinkyDirections;
    wire [3:0] clearClydeDirections;

    clearRom clearPacman (.address(320*PacmanLoc[7:0] + PacmanLoc[15:8]), .clock(update), .q(clearPacmanDirections));
    clearRom clearBlinky (.address(320*BlinkyLoc[7:0] + BlinkyLoc[15:8]), .clock(update), .q(clearBlinkyDirections));
    clearRom clearInky (.address(320*InkyLoc[7:0] + InkyLoc[15:8]), .clock(update), .q(clearInkyDirections));
    clearRom clearPinky (.address(320*PinkyLoc[7:0] + PinkyLoc[15:8]), .clock(update), .q(clearPinkyDirections));
    clearRom clearClyde (.address(320*ClydeLoc[7:0] + ClydeLoc[15:8]), .clock(update), .q(clearClydeDirections));

    // Need to Program GameOver State Where ghosts stop working
    // Error State with 0 directions
    // Note:
    // Ghosts work with old value of Pacman
    Blinky u0 (PacmanLoc, PacmanFacing, BlinkyLoc, BlinkyFacing, clearBlinkyDirections, Blinkymode, rotate, update, nextBlinkyFacing, nextBlinkyLoc);
    Inky u1   (PacmanLoc, PacmanFacing, BlinkyLoc, InkyLoc, InkyFacing, clearInkyDirections, Inkymode, rotate, update, nextInkyFacing, nextInkyLoc);
    Pinky u2  (PacmanLoc, PacmanFacing, PinkyLoc, PinkyFacing, clearPinkyDirections, Pinkymode, rotate, update, nextPinkyFacing, nextPinkyLoc);
    Clyde u3  (PacmanLoc, PacmanFacing, ClydeLoc, ClydeFacing, clearClydeDirections, Clydemode, rotate, update, nextClydeFacing, nextClydeLoc);

    reg [25:0] Time_Counter = 0;
    reg GameUpdate = 0; // wtf was this for
    reg [25:0] stateCounter = 0;
    reg [25:0] Frightened_counter = 0;
    reg [25:0] BlinkyEaten_counter = 0;
    reg [25:0] InkyEaten_counter = 0;
    reg [25:0] PinkyEaten_counter = 0;
    reg [25:0] ClydeEaten_counter = 0;
    reg [1:0] GhostsEaten = 0;
    reg FruitFlag = 0;
    
    reg [25:0] Update_counter = 0;

    parameter dtEaten = 5*1000;
    parameter UpdateFreq = 5;
    always@(posedge clk) begin
        if (Update_counter > 50000*1000/UpdateFreq) begin
            Update_counter <= 0;
            update <= 1;
        end
        else begin
            Update_counter <= Update_counter + 1;
            update <= 0;
        end
    end
    
    always@(negedge update) begin

        if (Frightened_counter == 1) begin
            
            Blinkymode = Gamemode;
            Inkymode = Gamemode;
            Pinkymode = Gamemode;
            Clydemode = Gamemode;
        end
        
        // Pacman gets killed by ghosts in Chase & Scatter
        // Pacman kills ghosts in Frightened
        if (Gamemode == Chase || Gamemode == Scatter) begin

            Blinkymode = Gamemode;
            Inkymode = Gamemode;
            Pinkymode = Gamemode;
            Clydemode = Gamemode;
            
            if (PacmanLoc[7:0] == BlinkyLoc[7:0]) begin
                if (PacmanLoc[15:8] > BlinkyLoc[15:8]) begin
                    if (PacmanLoc[15:8] - BlinkyLoc[15:8] < size) begin
                        GameOver <= 1;
                    end
                end
                else begin
                    if (BlinkyLoc[15:8] - PacmanLoc[15:8] < size) begin
                        GameOver <= 1;
                    end
                end
            end

            else if (PacmanLoc[15:8] == BlinkyLoc[15:8]) begin
                if (PacmanLoc[7:0] > BlinkyLoc[7:0]) begin
                    if (PacmanLoc[7:0] - BlinkyLoc[7:0] < size) begin
                        GameOver <= 1;
                    end
                end
                else begin
                    if (BlinkyLoc[7:0] - PacmanLoc[7:0] < size) begin
                        GameOver <= 1;
                    end
                end
            end

            if (PacmanLoc[7:0] == InkyLoc[7:0]) begin
                if (PacmanLoc[15:8] > InkyLoc[15:8]) begin
                    if (PacmanLoc[15:8] - InkyLoc[15:8] < size) begin
                        GameOver <= 1;
                    end
                end
                else begin
                    if (InkyLoc[15:8] - PacmanLoc[15:8] < size) begin
                        GameOver <= 1;
                    end
                end
            end

            else if (PacmanLoc[15:8] == InkyLoc[15:8]) begin
                if (PacmanLoc[7:0] > InkyLoc[7:0]) begin
                    if (PacmanLoc[7:0] - InkyLoc[7:0] < size) begin
                        GameOver <= 1;
                    end
                end
                else begin
                    if (InkyLoc[7:0] - PacmanLoc[7:0] < size) begin
                        GameOver <= 1;
                    end
                end
            end

            if (PacmanLoc[7:0] == PinkyLoc[7:0]) begin
                if (PacmanLoc[15:8] > PinkyLoc[15:8]) begin
                    if (PacmanLoc[15:8] - PinkyLoc[15:8] < size) begin
                        GameOver <= 1;
                    end
                end
                else begin
                    if (PinkyLoc[15:8] - PacmanLoc[15:8] < size) begin
                        GameOver <= 1;
                    end
                end
            end

            else if (PacmanLoc[15:8] == PinkyLoc[15:8]) begin
                if (PacmanLoc[7:0] > PinkyLoc[7:0]) begin
                    if (PacmanLoc[7:0] - PinkyLoc[7:0] < size) begin
                        GameOver <= 1;
                    end
                end
                else begin
                    if (PinkyLoc[7:0] - PacmanLoc[7:0] < size) begin
                        GameOver <= 1;
                    end
                end
            end

            if (PacmanLoc[7:0] == ClydeLoc[7:0]) begin
                if (PacmanLoc[15:8] > ClydeLoc[15:8]) begin
                    if (PacmanLoc[15:8] - ClydeLoc[15:8] < size) begin
                        GameOver <= 1;
                    end
                end
                else begin
                    if (ClydeLoc[15:8] - PacmanLoc[15:8] < size) begin
                        GameOver <= 1;
                    end
                end
            end

            else if (PacmanLoc[15:8] == ClydeLoc[15:8]) begin
                if (PacmanLoc[7:0] > ClydeLoc[7:0]) begin
                    if (PacmanLoc[7:0] - ClydeLoc[7:0] < size) begin
                        GameOver <= 1;
                    end
                end
                else begin
                    if (ClydeLoc[7:0] - PacmanLoc[7:0] < size) begin
                        GameOver <= 1;
                    end
                end
            end
        end
        else if (Gamemode == Frightened) begin

            // Update Eaten_counter to eventually exit Eaten State before Frightened_State is over if possible
            if (Blinkymode == Eaten) begin
                BlinkyEaten_counter = BlinkyEaten_counter + 1;
            end
            if (Inkymode == Eaten) begin
                InkyEaten_counter = InkyEaten_counter + 1;
            end
            if (Pinkymode == Eaten) begin
                PinkyEaten_counter = PinkyEaten_counter + 1;
            end
            if (Clydemode == Eaten) begin
                ClydeEaten_counter = ClydeEaten_counter + 1;
            end

            // If Eaten time is exceeded exit Eaten state
            if (BlinkyEaten_counter > (UpdateFreq/1000)*dtEaten) begin
                Blinkymode = Frightened;
                BlinkyEaten_counter = 0;
            end
            if (InkyEaten_counter > (UpdateFreq/1000)*dtEaten) begin
                Inkymode = Frightened;
                InkyEaten_counter = 0;
            end
            if (PinkyEaten_counter > (UpdateFreq/1000)*dtEaten) begin
                Pinkymode = Frightened;
                PinkyEaten_counter = 0;
            end
            if (ClydeEaten_counter > (UpdateFreq/1000)*dtEaten) begin
                Clydemode = Frightened;
                ClydeEaten_counter = 0;
            end


            if (PacmanLoc[7:0] == BlinkyLoc[7:0]) begin
                if (PacmanLoc[15:8] > BlinkyLoc[15:8]) begin
                    if (PacmanLoc[15:8] - BlinkyLoc[15:8] < size) begin
                        Blinkymode = Eaten;
                        Score <= Score + GhostsEaten*200;
                        GhostsEaten = GhostsEaten + 1;
                        BlinkyEaten_counter = 0;
                    end
                end
                else begin
                    if (BlinkyLoc[15:8] - PacmanLoc[15:8] < size) begin
                        Blinkymode = Eaten;
                        Score <= Score + GhostsEaten*200;
                        GhostsEaten = GhostsEaten + 1;
                        BlinkyEaten_counter = 0;
                    end
                end
            end

            else if (PacmanLoc[15:8] == BlinkyLoc[15:8]) begin
                if (PacmanLoc[7:0] > BlinkyLoc[7:0]) begin
                    if (PacmanLoc[7:0] - BlinkyLoc[7:0] < size) begin
                        Blinkymode = Eaten;
                        Score <= Score + GhostsEaten*200;
                        GhostsEaten = GhostsEaten + 1;
                        BlinkyEaten_counter = 0;
                    end
                end
                else begin
                    if (BlinkyLoc[7:0] - PacmanLoc[7:0] < size) begin
                        Blinkymode = Eaten;
                        Score <= Score + GhostsEaten*200;
                        GhostsEaten = GhostsEaten + 1;
                        BlinkyEaten_counter = 0;
                    end
                end
            end

            if (PacmanLoc[7:0] == InkyLoc[7:0]) begin
                if (PacmanLoc[15:8] > InkyLoc[15:8]) begin
                    if (PacmanLoc[15:8] - InkyLoc[15:8] < size) begin
                        Inkymode = Eaten;
                        Score <= Score + GhostsEaten*200;
                        GhostsEaten = GhostsEaten + 1;
                        InkyEaten_counter = 0;
                    end
                end
                else begin
                    if (InkyLoc[15:8] - PacmanLoc[15:8] < size) begin
                        Inkymode = Eaten;
                        Score <= Score + GhostsEaten*200;
                        GhostsEaten = GhostsEaten + 1;
                        InkyEaten_counter = 0;
                    end
                end
            end

            else if (PacmanLoc[15:8] == InkyLoc[15:8]) begin
                if (PacmanLoc[7:0] > InkyLoc[7:0]) begin
                    if (PacmanLoc[7:0] - InkyLoc[7:0] < size) begin
                        Inkymode = Eaten;
                        Score <= Score + GhostsEaten*200;
                        GhostsEaten = GhostsEaten + 1;
                        InkyEaten_counter = 0;
                    end
                end
                else begin
                    if (InkyLoc[7:0] - PacmanLoc[7:0] < size) begin
                        Inkymode = Eaten;
                        Score <= Score + GhostsEaten*200;
                        GhostsEaten = GhostsEaten + 1;
                        InkyEaten_counter = 0;
                    end
                end
            end

            if (PacmanLoc[7:0] == PinkyLoc[7:0]) begin
                if (PacmanLoc[15:8] > PinkyLoc[15:8]) begin
                    if (PacmanLoc[15:8] - PinkyLoc[15:8] < size) begin
                        Pinkymode = Eaten;
                        Score <= Score + GhostsEaten*200;
                        GhostsEaten = GhostsEaten + 1;
                        PinkyEaten_counter = 0;
                    end
                end
                else begin
                    if (PinkyLoc[15:8] - PacmanLoc[15:8] < size) begin
                        Pinkymode = Eaten;
                        Score <= Score + GhostsEaten*200;
                        GhostsEaten = GhostsEaten + 1;
                        PinkyEaten_counter = 0;
                    end
                end
            end

            else if (PacmanLoc[15:8] == PinkyLoc[15:8]) begin
                if (PacmanLoc[7:0] > PinkyLoc[7:0]) begin
                    if (PacmanLoc[7:0] - PinkyLoc[7:0] < size) begin
                        Pinkymode = Eaten;
                        Score <= Score + GhostsEaten*200;
                        GhostsEaten = GhostsEaten + 1;
                        PinkyEaten_counter = 0;
                    end
                end
                else begin
                    if (PinkyLoc[7:0] - PacmanLoc[7:0] < size) begin
                        Pinkymode = Eaten;
                        Score <= Score + GhostsEaten*200;
                        GhostsEaten = GhostsEaten + 1;
                        PinkyEaten_counter = 0;
                    end
                end
            end

            if (PacmanLoc[7:0] == ClydeLoc[7:0]) begin
                if (PacmanLoc[15:8] > ClydeLoc[15:8]) begin
                    if (PacmanLoc[15:8] - ClydeLoc[15:8] < size) begin
                        Clydemode = Eaten;
                        Score <= Score + GhostsEaten*200;
                        GhostsEaten = GhostsEaten + 1;
                        ClydeEaten_counter = 0;
                    end
                end
                else begin
                    if (ClydeLoc[15:8] - PacmanLoc[15:8] < size) begin
                        Clydemode = Eaten;
                        Score <= Score + GhostsEaten*200;
                        GhostsEaten = GhostsEaten + 1;
                        ClydeEaten_counter = 0;
                    end
                end
            end

            else if (PacmanLoc[15:8] == ClydeLoc[15:8]) begin
                if (PacmanLoc[7:0] > ClydeLoc[7:0]) begin
                    if (PacmanLoc[7:0] - ClydeLoc[7:0] < size) begin
                        Clydemode = Eaten;
                        Score <= Score + GhostsEaten*200;
                        GhostsEaten = GhostsEaten + 1;
                        ClydeEaten_counter = 0;
                    end
                end
                else begin
                    if (ClydeLoc[7:0] - PacmanLoc[7:0] < size) begin
                        Clydemode = Eaten;
                        Score <= Score + GhostsEaten*200;
                        GhostsEaten = GhostsEaten + 1;
                        ClydeEaten_counter = 0;
                    end
                end
            end
        end

        // Update current values to correspond with new changes

        /*
        if pacman is not facing a wall then do move otherwise stays in the same location
        Wraparound functionality
        Will have to adjust the distance function if want to automatically cross
        Adjust wraparound output inside the game itself for the ghosts to work
        */

        // TODO: Only perform move if legal
        case(Move)
            LEFT: begin
                    if (clearPacmanDirections[leftindex]) begin
                        PacmanLoc <= nextPacmanLoc + Move;
                        PacmanFacing <= Move;
                    end
                  end
            RIGHT: begin
                    if (clearPacmanDirections[rightindex]) begin
                        PacmanLoc <= nextPacmanLoc + Move;
                        PacmanFacing <= Move;
                    end
                  end
            UP: begin
                    if (clearPacmanDirections[upindex]) begin
                        PacmanLoc <= nextPacmanLoc + Move + RIGHT;
                        PacmanFacing <= Move;
                    end
                  end
            DOWN: begin
                    if (clearPacmanDirections[downindex]) begin
                        PacmanLoc <= nextPacmanLoc + Move;
                        PacmanFacing <= Move;
                    end
                  end
        endcase

        BlinkyLoc <= nextBlinkyLoc;
        BlinkyFacing <= nextBlinkyFacing;
        InkyLoc <= nextInkyLoc;
        InkyFacing <= nextInkyFacing;
        PinkyLoc <= nextPinkyLoc;
        PinkyFacing <= nextPinkyFacing;
        ClydeLoc <= nextClydeLoc;
        ClydeFacing <= nextClydeFacing;

        // Scoring Time
        if (Time_Counter == (UpdateFreq/1000)) begin
            Time_Counter <= 0;
            Score <= Score + 10;
        end
        else begin
            Time_Counter <= Time_Counter + 1;
        end
        
        if (FruitFlag) begin
            FruitFlag = 0;
        end

        // Scoring Fruits
        if (PacmanLoc[7:0] == TopLeftFruit[7:0]) begin
            if (PacmanLoc[15:8] > TopLeftFruit[15:8]) begin
                if (PacmanLoc[15:8] - TopLeftFruit[15:8] < size) begin
                    TopLeftFruit <= 0;
                    Score <= Score + 500;
                    FruitFlag = 1;
                    GhostsEaten = 0;
                end
            end
            else begin
                if (TopLeftFruit[15:8] - PacmanLoc[15:8] < size) begin
                    TopLeftFruit <= 0;
                    Score <= Score + 500;
                    FruitFlag = 1;
                    GhostsEaten = 0;
                end
            end
        end

        else if (PacmanLoc[15:8] == TopLeftFruit[15:8]) begin
            if (PacmanLoc[7:0] > TopLeftFruit[7:0]) begin
                if (PacmanLoc[7:0] - TopLeftFruit[7:0] < size) begin
                    TopLeftFruit <= 0;
                    Score <= Score + 500;
                    FruitFlag = 1;
                    GhostsEaten = 0;
                end
            end
            else begin
                if (TopLeftFruit[7:0] - PacmanLoc[7:0] < size) begin
                    TopLeftFruit <= 0;
                    Score <= Score + 500;
                    FruitFlag = 1;
                    GhostsEaten = 0;
                end
            end
        end

                if (PacmanLoc[7:0] == TopRightFruit[7:0]) begin
            if (PacmanLoc[15:8] > TopRightFruit[15:8]) begin
                if (PacmanLoc[15:8] - TopRightFruit[15:8] < size) begin
                    TopRightFruit <= 0;
                    Score <= Score + 500;
                    FruitFlag = 1;
                    GhostsEaten = 0;
                end
            end
            else begin
                if (TopRightFruit[15:8] - PacmanLoc[15:8] < size) begin
                    TopRightFruit <= 0;
                    Score <= Score + 500;
                    FruitFlag = 1;
                    GhostsEaten = 0;
                end
            end
        end

        else if (PacmanLoc[15:8] == TopRightFruit[15:8]) begin
            if (PacmanLoc[7:0] > TopRightFruit[7:0]) begin
                if (PacmanLoc[7:0] - TopRightFruit[7:0] < size) begin
                    TopRightFruit <= 0;
                    Score <= Score + 500;
                    FruitFlag = 1;
                    GhostsEaten = 0;
                end
            end
            else begin
                if (TopRightFruit[7:0] - PacmanLoc[7:0] < size) begin
                    TopRightFruit <= 0;
                    Score <= Score + 500;
                    FruitFlag = 1;
                    GhostsEaten = 0;
                end
            end
        end

        if (PacmanLoc[7:0] == BottomLeftFruit[7:0]) begin
            if (PacmanLoc[15:8] > BottomLeftFruit[15:8]) begin
                if (PacmanLoc[15:8] - BottomLeftFruit[15:8] < size) begin
                    BottomLeftFruit <= 0;
                    Score <= Score + 500;
                    FruitFlag = 1;
                    GhostsEaten = 0;
                end
            end
            else begin
                if (BottomLeftFruit[15:8] - PacmanLoc[15:8] < size) begin
                    BottomLeftFruit <= 0;
                    Score <= Score + 500;
                    FruitFlag = 1;
                    GhostsEaten = 0;
                end
            end
        end

        else if (PacmanLoc[15:8] == BottomLeftFruit[15:8]) begin
            if (PacmanLoc[7:0] > BottomLeftFruit[7:0]) begin
                if (PacmanLoc[7:0] - BottomLeftFruit[7:0] < size) begin
                    BottomLeftFruit <= 0;
                    Score <= Score + 500;
                    FruitFlag = 1;
                    GhostsEaten = 0;
                end
            end
            else begin
                if (BottomLeftFruit[7:0] - PacmanLoc[7:0] < size) begin
                    BottomLeftFruit <= 0;
                    Score <= Score + 500;
                    FruitFlag = 1;
                    GhostsEaten = 0;
                end
            end
        end

                if (PacmanLoc[7:0] == BottomRightFruit[7:0]) begin
            if (PacmanLoc[15:8] > BottomRightFruit[15:8]) begin
                if (PacmanLoc[15:8] - BottomRightFruit[15:8] < size) begin
                    BottomRightFruit <= 0;
                    Score <= Score + 500;
                    FruitFlag = 1;
                    GhostsEaten = 0;
                end
            end
            else begin
                if (BottomRightFruit[15:8] - PacmanLoc[15:8] < size) begin
                    BottomRightFruit <= 0;
                    Score <= Score + 500;
                    FruitFlag = 1;
                    GhostsEaten = 0;
                end
            end
        end

        else if (PacmanLoc[15:8] == BottomRightFruit[15:8]) begin
            if (PacmanLoc[7:0] > BottomRightFruit[7:0]) begin
                if (PacmanLoc[7:0] - BottomRightFruit[7:0] < size) begin
                    BottomRightFruit <= 0;
                    Score <= Score + 500;
                    FruitFlag = 1;
                    GhostsEaten = 0;
                end
            end
            else begin
                if (BottomRightFruit[7:0] - PacmanLoc[7:0] < size) begin
                    BottomRightFruit <= 0;
                    Score <= Score + 500;
                    FruitFlag = 1;
                    GhostsEaten = 0;
                end
            end
        end
    end

    reg [3:0] current_state;
    reg [3:0] next_state;
    reg [3:0] last_state;

    localparam  ScatterA         = 0,
                ChaseA           = 1,
                ScatterB         = 2,
                ChaseB           = 3,
				ScatterC         = 4,
                ChaseC           = 5,
                ScatterD         = 6,
                ChaseD           = 7,
                Frightened_State = 8;

    parameter dtScatterA = 7*1000; // in ms
    parameter dtChaseA = 20*1000;
    parameter dtScatterB = 7*1000;
    parameter dtChaseB = 20*1000;
    parameter dtScatterC = 5*1000;
    parameter dtChaseC = 20*1000;
    parameter dtScatterD = 5*1000;
    parameter dtFrightened = 5*1000; // Need to find level 1 value

    always@(posedge update)
    begin: state_table
        case (current_state)
            ScatterA: begin
                        next_state = (stateCounter > (UpdateFreq/1000)*dtScatterA) ? ChaseA : ScatterA;
                        stateCounter <= stateCounter + 1;

                        next_state = FruitFlag ? Frightened_State : next_state;
                        Frightened_counter <= 0;
                        last_state <= current_state;
                     end
            ChaseA: begin
                        next_state = (stateCounter > (UpdateFreq/1000)*dtScatterA + (UpdateFreq/1000)*dtChaseA) ? ScatterB : ChaseA;
                        stateCounter <= stateCounter + 1;
                        
                        next_state = FruitFlag ? Frightened_State : next_state;
                        Frightened_counter <= 0;
                        last_state <= current_state;
                    end
            ScatterB: begin
                        next_state = (stateCounter > (UpdateFreq/1000)*dtScatterA + (UpdateFreq/1000)*dtChaseA + (UpdateFreq/1000)*dtScatterB) ? ChaseB : ScatterB;
                        stateCounter <= stateCounter + 1;
                        
                        next_state = FruitFlag ? Frightened_State : next_state;
                        Frightened_counter <= 0;
                        last_state <= current_state;
                     end
            ChaseB: begin
                        next_state = (stateCounter > (UpdateFreq/1000)*dtScatterA + (UpdateFreq/1000)*dtChaseA + (UpdateFreq/1000)*dtScatterB + (UpdateFreq/1000)*dtChaseB) ? ScatterC : ChaseB;
                        stateCounter <= stateCounter + 1;
                        
                        next_state = FruitFlag ? Frightened_State : next_state;
                        Frightened_counter <= 0;
                        last_state <= current_state;
                     end
            ScatterC: begin
                        next_state = (stateCounter > (UpdateFreq/1000)*dtScatterA + (UpdateFreq/1000)*dtChaseA + (UpdateFreq/1000)*dtScatterB + (UpdateFreq/1000)*dtChaseB + (UpdateFreq/1000)*dtScatterC) ? ChaseC : ScatterC;
                        stateCounter <= stateCounter + 1;
                        
                        next_state = FruitFlag ? Frightened_State : next_state;
                        Frightened_counter <= 0;
                        last_state <= current_state;
                     end
            ChaseC: begin
                        next_state = (stateCounter > (UpdateFreq/1000)*dtScatterA + (UpdateFreq/1000)*dtChaseA + (UpdateFreq/1000)*dtScatterB + (UpdateFreq/1000)*dtChaseB + (UpdateFreq/1000)*dtScatterC + (UpdateFreq/1000)*dtChaseC) ? ScatterD : ChaseC;
                        stateCounter <= stateCounter + 1;
                        
                        next_state = FruitFlag ? Frightened_State : next_state;
                        Frightened_counter <= 0;
                        last_state <= current_state;
                     end
            ScatterD: begin 
                        next_state = (stateCounter > (UpdateFreq/1000)*dtScatterA + (UpdateFreq/1000)*dtChaseA + (UpdateFreq/1000)*dtScatterB + (UpdateFreq/1000)*dtChaseB + (UpdateFreq/1000)*dtScatterC + (UpdateFreq/1000)*dtChaseC + (UpdateFreq/1000)*dtScatterD) ? ChaseD : ScatterD;
                        stateCounter <= stateCounter + 1;
                        
                        next_state = FruitFlag ? Frightened_State : next_state;
                        Frightened_counter <= 0;
                        last_state <= current_state;
                     end
            ChaseD: begin
                        next_state = (stateCounter > (UpdateFreq/1000)*dtScatterA + (UpdateFreq/1000)*dtChaseA + (UpdateFreq/1000)*dtScatterB + (UpdateFreq/1000)*dtChaseB + (UpdateFreq/1000)*dtScatterC + (UpdateFreq/1000)*dtChaseC + (UpdateFreq/1000)*dtScatterD) ? ChaseD : ChaseA; // decide the else conditions
                        stateCounter <= stateCounter + 1;
                        
                        next_state = FruitFlag ? Frightened_State : next_state;
                        Frightened_counter <= 0;
                        last_state <= current_state;
                     end
            Frightened_State: begin
                                next_state = (Frightened_counter > dtFrightened) ? last_state : Frightened_State;
                                Frightened_counter = Frightened_counter + 1;
                              end
            default: next_state = ScatterA;
        endcase
        
        if (next_state != current_state) begin

            // Replace with rotate = 1;
            case(next_state)
                ScatterA: rotate = 1;
                ChaseA: rotate = 1;
                ScatterB: rotate = 1;
                ChaseB: rotate = 1;
                ScatterC: rotate = 1;
                ChaseC: rotate = 1;
                ScatterD: rotate = 1;
                ChaseD: rotate = 1;
                Frightened_State: rotate = 1;
            endcase

            case(next_state)
                ScatterA: Gamemode = Scatter;
                ChaseA: Gamemode = Chase;
                ScatterB: Gamemode = Scatter;
                ChaseB: Gamemode = Chase;
                ScatterC: Gamemode = Scatter;
                ChaseC: Gamemode = Chase;
                ScatterD: Gamemode = Scatter;
                ChaseD: Gamemode = Chase;
                Frightened_State: Gamemode = Frightened;
            endcase
        end
        else begin
            rotate = 0;
        end
        current_state = next_state;
    end
endmodule