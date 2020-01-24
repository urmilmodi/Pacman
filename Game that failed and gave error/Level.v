module Level
    (
        Move,
        sysclk,
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

    localparam  LEFT          = 16'hFF00,
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
    input sysclk;
    
    output reg [15:0] PacmanLoc = {8'd101, 8'd175}; // Set to inital positions and directions
    output reg [15:0] PacmanFacing = RIGHT;
    output reg [15:0] BlinkyLoc = {8'd101, 8'd83}; // Same X pos as ^ but different Y
    output reg [15:0] BlinkyFacing = UP;
    output reg [15:0] InkyLoc = {8'd86, 8'd106};  // diff X pos as ^ but same Y
    output reg [15:0] InkyFacing = UP;
    output reg [15:0] PinkyLoc = {8'd101, 8'd106}; // Same X pos as ^ but same Y
    output reg [15:0] PinkyFacing = UP;
    output reg [15:0] ClydeLoc = {8'd116, 8'd106}; // diff X pos as ^ but same Y
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

    clearRom clearPacman (.address(320*PacmanLoc[7:0] + PacmanLoc[15:8]), .clock(sysclk), .q(clearPacmanDirections));
    
    // Need to Program GameOver State Where ghosts stop working
    // Error State with 0 directions
    // Note:
    // Ghosts work with old value of Pacman
    Blinky u0 (PacmanLoc, PacmanFacing, BlinkyLoc, BlinkyFacing, Blinkymode, rotate, update, sysclk, nextBlinkyFacing, nextBlinkyLoc);
    Inky u1   (PacmanLoc, PacmanFacing, BlinkyLoc, InkyLoc, InkyFacing, Inkymode, rotate, sysclk, update, nextInkyFacing, nextInkyLoc);
    Pinky u2  (PacmanLoc, PacmanFacing, PinkyLoc, PinkyFacing, Pinkymode, rotate, update, sysclk, nextPinkyFacing, nextPinkyLoc);
    Clyde u3  (PacmanLoc, PacmanFacing, ClydeLoc, ClydeFacing, Clydemode, rotate, update, sysclk, nextClydeFacing, nextClydeLoc);

    reg [25:0] Time_Counter = 0;
    reg [25:0] stateCounter = 0;
    reg [25:0] Frightened_counter = 0;
    reg [25:0] BlinkyEaten_counter = 0;
    reg [25:0] InkyEaten_counter = 0;
    reg [25:0] PinkyEaten_counter = 0;
    reg [25:0] ClydeEaten_counter = 0;
    reg [1:0] GhostsEaten = 1;
    reg FruitFlag = 0;
    
    reg [25:0] PipeLine_counter = 0;

    parameter dtEaten = 5*1000;
    parameter GameWaitTime = 50000*100;

    reg [3:0] currentPipeLineState;
    reg [3:0] nextPipeLineState;

    localparam  runGhosts       = 0,
                gameWait        = 1,
                UpdateLocations = 2,
                GameModeLogic   = 3,
                Scoring         = 4;

    always@(posedge sysclk) begin
        case(currentPipeLineState)
            runGhosts: begin
                            if (PipeLine_counter >= 8'd10) begin
                                PipeLine_counter <= 0;
                                nextPipeLineState <= gameWait;
                                update <= 0;
                            end
                            else begin
                                PipeLine_counter <= PipeLine_counter + 1;
                                update <= 1;
                            end
                        end
            gameWait: begin
                            if (PipeLine_counter >= GameWaitTime) begin
                                PipeLine_counter <= 0;
                                nextPipeLineState <= UpdateLocations;
                            end
                            else begin
                                PipeLine_counter <= PipeLine_counter + 1;
                            end
                        end
            UpdateLocations: begin
                                nextPipeLineState <= GameModeLogic;
                            end
            GameModeLogic: begin
                                nextPipeLineState <= Scoring;
                            end
            Scoring: begin
                        nextPipeLineState <= runGhosts;
                    end
            default: nextPipeLineState <= runGhosts;
        endcase
    end

    always@(negedge sysclk) begin
        currentPipeLineState <= nextPipeLineState;
    end



    /*
    parameter UpdateFreq = 5;
    always@(posedge sysclk) begin
        if (Update_counter > 50000*1000/UpdateFreq) begin
            Update_counter = 0;
            update = 1;
        end
        else begin
            Update_counter = Update_counter + 1;
            update = 0;
        end
    end
    */
    
    always@(posedge sysclk) begin
        
        // Time-Dependent Portion, must be placed to run in Parallel to the Pipeline to correctly keep time
        // Update Eaten_counter to eventually exit Eaten State before Frightened_State is over if possible
        if (Blinkymode == Eaten) begin
            BlinkyEaten_counter <= BlinkyEaten_counter + 1;
        end
        if (Inkymode == Eaten) begin
            InkyEaten_counter <= InkyEaten_counter + 1;
        end
        if (Pinkymode == Eaten) begin
            PinkyEaten_counter <= PinkyEaten_counter + 1;
        end
        if (Clydemode == Eaten) begin
            ClydeEaten_counter <= ClydeEaten_counter + 1;
        end

        // If Eaten time is exceeded exit Eaten state
        if (BlinkyEaten_counter > 50000*dtEaten) begin
            Blinkymode <= Frightened;
            BlinkyEaten_counter <= 0;
        end
        if (InkyEaten_counter > 50000*dtEaten) begin
            Inkymode <= Frightened;
            InkyEaten_counter <= 0;
        end
        if (PinkyEaten_counter > 50000*dtEaten) begin
            Pinkymode <= Frightened;
            PinkyEaten_counter <= 0;
        end
        if (ClydeEaten_counter > 50000*dtEaten) begin
            Clydemode <= Frightened;
            ClydeEaten_counter <= 0;
        end

        
        // Update current values to correspond with new changes
        if (currentPipeLineState == UpdateLocations) begin

            // Only perform move if legal
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

            BlinkyLoc <= nextBlinkyLoc;
            BlinkyFacing <= nextBlinkyFacing;
            InkyLoc <= nextInkyLoc;
            InkyFacing <= nextInkyFacing;
            PinkyLoc <= nextPinkyLoc;
            PinkyFacing <= nextPinkyFacing;
            ClydeLoc <= nextClydeLoc;
            ClydeFacing <= nextClydeFacing;
        end

        if (currentPipeLineState == GameModeLogic) begin

            if (Frightened_counter == 1) begin
                
                Blinkymode <= Gamemode;
                Inkymode <= Gamemode;
                Pinkymode <= Gamemode;
                Clydemode <= Gamemode;
            end
            
            // Pacman gets killed by ghosts in Chase & Scatter
            // Pacman kills ghosts in Frightened
            if (Gamemode == Chase || Gamemode == Scatter) begin

                Blinkymode <= Gamemode;
                Inkymode <= Gamemode;
                Pinkymode <= Gamemode;
                Clydemode <= Gamemode;
                
                if (PacmanLoc[7:0] == BlinkyLoc[7:0]) begin
                    if (PacmanLoc[15:8] > BlinkyLoc[15:8]) begin
                        if (PacmanLoc[15:8] - BlinkyLoc[15:8] < 8'd14) begin
                            GameOver <= 1;
                        end
                    end
                    else begin
                        if (BlinkyLoc[15:8] - PacmanLoc[15:8] < 8'd14) begin
                            GameOver <= 1;
                        end
                    end
                end

                else if (PacmanLoc[15:8] == BlinkyLoc[15:8]) begin
                    if (PacmanLoc[7:0] > BlinkyLoc[7:0]) begin
                        if (PacmanLoc[7:0] - BlinkyLoc[7:0] < 8'd14) begin
                            GameOver <= 1;
                        end
                    end
                    else begin
                        if (BlinkyLoc[7:0] - PacmanLoc[7:0] < 8'd14) begin
                            GameOver <= 1;
                        end
                    end
                end

                if (PacmanLoc[7:0] == InkyLoc[7:0]) begin
                    if (PacmanLoc[15:8] > InkyLoc[15:8]) begin
                        if (PacmanLoc[15:8] - InkyLoc[15:8] < 8'd14) begin
                            GameOver <= 1;
                        end
                    end
                    else begin
                        if (InkyLoc[15:8] - PacmanLoc[15:8] < 8'd14) begin
                            GameOver <= 1;
                        end
                    end
                end

                else if (PacmanLoc[15:8] == InkyLoc[15:8]) begin
                    if (PacmanLoc[7:0] > InkyLoc[7:0]) begin
                        if (PacmanLoc[7:0] - InkyLoc[7:0] < 8'd14) begin
                            GameOver <= 1;
                        end
                    end
                    else begin
                        if (InkyLoc[7:0] - PacmanLoc[7:0] < 8'd14) begin
                            GameOver <= 1;
                        end
                    end
                end

                if (PacmanLoc[7:0] == PinkyLoc[7:0]) begin
                    if (PacmanLoc[15:8] > PinkyLoc[15:8]) begin
                        if (PacmanLoc[15:8] - PinkyLoc[15:8] < 8'd14) begin
                            GameOver <= 1;
                        end
                    end
                    else begin
                        if (PinkyLoc[15:8] - PacmanLoc[15:8] < 8'd14) begin
                            GameOver <= 1;
                        end
                    end
                end

                else if (PacmanLoc[15:8] == PinkyLoc[15:8]) begin
                    if (PacmanLoc[7:0] > PinkyLoc[7:0]) begin
                        if (PacmanLoc[7:0] - PinkyLoc[7:0] < 8'd14) begin
                            GameOver <= 1;
                        end
                    end
                    else begin
                        if (PinkyLoc[7:0] - PacmanLoc[7:0] < 8'd14) begin
                            GameOver <= 1;
                        end
                    end
                end

                if (PacmanLoc[7:0] == ClydeLoc[7:0]) begin
                    if (PacmanLoc[15:8] > ClydeLoc[15:8]) begin
                        if (PacmanLoc[15:8] - ClydeLoc[15:8] < 8'd14) begin
                            GameOver <= 1;
                        end
                    end
                    else begin
                        if (ClydeLoc[15:8] - PacmanLoc[15:8] < 8'd14) begin
                            GameOver <= 1;
                        end
                    end
                end

                else if (PacmanLoc[15:8] == ClydeLoc[15:8]) begin
                    if (PacmanLoc[7:0] > ClydeLoc[7:0]) begin
                        if (PacmanLoc[7:0] - ClydeLoc[7:0] < 8'd14) begin
                            GameOver <= 1;
                        end
                    end
                    else begin
                        if (ClydeLoc[7:0] - PacmanLoc[7:0] < 8'd14) begin
                            GameOver <= 1;
                        end
                    end
                end
            end
            else if (Gamemode == Frightened) begin
                if (PacmanLoc[7:0] == BlinkyLoc[7:0]) begin
                    if (PacmanLoc[15:8] > BlinkyLoc[15:8]) begin
                        if (PacmanLoc[15:8] - BlinkyLoc[15:8] < 8'd14) begin
                            Blinkymode <= Eaten;
                            Score <= Score + GhostsEaten*200;
                            GhostsEaten <= GhostsEaten + 1;
                            BlinkyEaten_counter <= 0;
                        end
                    end
                    else begin
                        if (BlinkyLoc[15:8] - PacmanLoc[15:8] < 8'd14) begin
                            Blinkymode <= Eaten;
                            Score <= Score + GhostsEaten*200;
                            GhostsEaten <= GhostsEaten + 1;
                            BlinkyEaten_counter <= 0;
                        end
                    end
                end

                else if (PacmanLoc[15:8] == BlinkyLoc[15:8]) begin
                    if (PacmanLoc[7:0] > BlinkyLoc[7:0]) begin
                        if (PacmanLoc[7:0] - BlinkyLoc[7:0] < 8'd14) begin
                            Blinkymode <= Eaten;
                            Score <= Score + GhostsEaten*200;
                            GhostsEaten <= GhostsEaten + 1;
                            BlinkyEaten_counter <= 0;
                        end
                    end
                    else begin
                        if (BlinkyLoc[7:0] - PacmanLoc[7:0] < 8'd14) begin
                            Blinkymode <= Eaten;
                            Score <= Score + GhostsEaten*200;
                            GhostsEaten <= GhostsEaten + 1;
                            BlinkyEaten_counter <= 0;
                        end
                    end
                end

                if (PacmanLoc[7:0] == InkyLoc[7:0]) begin
                    if (PacmanLoc[15:8] > InkyLoc[15:8]) begin
                        if (PacmanLoc[15:8] - InkyLoc[15:8] < 8'd14) begin
                            Inkymode <= Eaten;
                            Score <= Score + GhostsEaten*200;
                            GhostsEaten <= GhostsEaten + 1;
                            InkyEaten_counter <= 0;
                        end
                    end
                    else begin
                        if (InkyLoc[15:8] - PacmanLoc[15:8] < 8'd14) begin
                            Inkymode <= Eaten;
                            Score <= Score + GhostsEaten*200;
                            GhostsEaten <= GhostsEaten + 1;
                            InkyEaten_counter <= 0;
                        end
                    end
                end

                else if (PacmanLoc[15:8] == InkyLoc[15:8]) begin
                    if (PacmanLoc[7:0] > InkyLoc[7:0]) begin
                        if (PacmanLoc[7:0] - InkyLoc[7:0] < 8'd14) begin
                            Inkymode <= Eaten;
                            Score <= Score + GhostsEaten*200;
                            GhostsEaten <= GhostsEaten + 1;
                            InkyEaten_counter <= 0;
                        end
                    end
                    else begin
                        if (InkyLoc[7:0] - PacmanLoc[7:0] < 8'd14) begin
                            Inkymode <= Eaten;
                            Score <= Score + GhostsEaten*200;
                            GhostsEaten <= GhostsEaten + 1;
                            InkyEaten_counter <= 0;
                        end
                    end
                end

                if (PacmanLoc[7:0] == PinkyLoc[7:0]) begin
                    if (PacmanLoc[15:8] > PinkyLoc[15:8]) begin
                        if (PacmanLoc[15:8] - PinkyLoc[15:8] < 8'd14) begin
                            Pinkymode <= Eaten;
                            Score <= Score + GhostsEaten*200;
                            GhostsEaten <= GhostsEaten + 1;
                            PinkyEaten_counter <= 0;
                        end
                    end
                    else begin
                        if (PinkyLoc[15:8] - PacmanLoc[15:8] < 8'd14) begin
                            Pinkymode <= Eaten;
                            Score <= Score + GhostsEaten*200;
                            GhostsEaten <= GhostsEaten + 1;
                            PinkyEaten_counter <= 0;
                        end
                    end
                end

                else if (PacmanLoc[15:8] == PinkyLoc[15:8]) begin
                    if (PacmanLoc[7:0] > PinkyLoc[7:0]) begin
                        if (PacmanLoc[7:0] - PinkyLoc[7:0] < 8'd14) begin
                            Pinkymode <= Eaten;
                            Score <= Score + GhostsEaten*200;
                            GhostsEaten <= GhostsEaten + 1;
                            PinkyEaten_counter <= 0;
                        end
                    end
                    else begin
                        if (PinkyLoc[7:0] - PacmanLoc[7:0] < 8'd14) begin
                            Pinkymode <= Eaten;
                            Score <= Score + GhostsEaten*200;
                            GhostsEaten <= GhostsEaten + 1;
                            PinkyEaten_counter <= 0;
                        end
                    end
                end

                if (PacmanLoc[7:0] == ClydeLoc[7:0]) begin
                    if (PacmanLoc[15:8] > ClydeLoc[15:8]) begin
                        if (PacmanLoc[15:8] - ClydeLoc[15:8] < 8'd14) begin
                            Clydemode <= Eaten;
                            Score <= Score + GhostsEaten*200;
                            GhostsEaten <= GhostsEaten + 1;
                            ClydeEaten_counter <= 0;
                        end
                    end
                    else begin
                        if (ClydeLoc[15:8] - PacmanLoc[15:8] < 8'd14) begin
                            Clydemode <= Eaten;
                            Score <= Score + GhostsEaten*200;
                            GhostsEaten <= GhostsEaten + 1;
                            ClydeEaten_counter <= 0;
                        end
                    end
                end

                else if (PacmanLoc[15:8] == ClydeLoc[15:8]) begin
                    if (PacmanLoc[7:0] > ClydeLoc[7:0]) begin
                        if (PacmanLoc[7:0] - ClydeLoc[7:0] < 8'd14) begin
                            Clydemode <= Eaten;
                            Score <= Score + GhostsEaten*200;
                            GhostsEaten <= GhostsEaten + 1;
                            ClydeEaten_counter <= 0;
                        end
                    end
                    else begin
                        if (ClydeLoc[7:0] - PacmanLoc[7:0] < 8'd14) begin
                            Clydemode <= Eaten;
                            Score <= Score + GhostsEaten*200;
                            GhostsEaten <= GhostsEaten + 1;
                            ClydeEaten_counter <= 0;
                        end
                    end
                end
            end
        end


        // Time-Dependent Portion, so placed to run in Parallel
        // Scoring Time
        if (Time_Counter >= 50000) begin
            Time_Counter <= 0;
            Score <= Score + 10;
        end
        else begin
            Time_Counter <= Time_Counter + 1;
        end


        if (currentPipeLineState == Scoring) begin

            // Reset Fruit Flag
            if (FruitFlag) begin
                FruitFlag <= 0;
            end

            // Scoring Fruits
            if (PacmanLoc[7:0] == TopLeftFruit[7:0]) begin
                if (PacmanLoc[15:8] > TopLeftFruit[15:8]) begin
                    if (PacmanLoc[15:8] - TopLeftFruit[15:8] < 8'd14) begin
                        TopLeftFruit <= 0;
                        Score <= Score + 500;
                        FruitFlag <= 1;
                        GhostsEaten <= 1;
                    end
                end
                else begin
                    if (TopLeftFruit[15:8] - PacmanLoc[15:8] < 8'd14) begin
                        TopLeftFruit <= 0;
                        Score <= Score + 500;
                        FruitFlag <= 1;
                        GhostsEaten <= 1;
                    end
                end
            end

            else if (PacmanLoc[15:8] == TopLeftFruit[15:8]) begin
                if (PacmanLoc[7:0] > TopLeftFruit[7:0]) begin
                    if (PacmanLoc[7:0] - TopLeftFruit[7:0] < 8'd14) begin
                        TopLeftFruit <= 0;
                        Score <= Score + 500;
                        FruitFlag <= 1;
                        GhostsEaten <= 1;
                    end
                end
                else begin
                    if (TopLeftFruit[7:0] - PacmanLoc[7:0] < 8'd14) begin
                        TopLeftFruit <= 0;
                        Score <= Score + 500;
                        FruitFlag <= 1;
                        GhostsEaten <= 1;
                    end
                end
            end

                    if (PacmanLoc[7:0] == TopRightFruit[7:0]) begin
                if (PacmanLoc[15:8] > TopRightFruit[15:8]) begin
                    if (PacmanLoc[15:8] - TopRightFruit[15:8] < 8'd14) begin
                        TopRightFruit <= 0;
                        Score <= Score + 500;
                        FruitFlag <= 1;
                        GhostsEaten <= 1;
                    end
                end
                else begin
                    if (TopRightFruit[15:8] - PacmanLoc[15:8] < 8'd14) begin
                        TopRightFruit <= 0;
                        Score <= Score + 500;
                        FruitFlag <= 1;
                        GhostsEaten <= 1;
                    end
                end
            end

            else if (PacmanLoc[15:8] == TopRightFruit[15:8]) begin
                if (PacmanLoc[7:0] > TopRightFruit[7:0]) begin
                    if (PacmanLoc[7:0] - TopRightFruit[7:0] < 8'd14) begin
                        TopRightFruit <= 0;
                        Score <= Score + 500;
                        FruitFlag <= 1;
                        GhostsEaten <= 1;
                    end
                end
                else begin
                    if (TopRightFruit[7:0] - PacmanLoc[7:0] < 8'd14) begin
                        TopRightFruit <= 0;
                        Score <= Score + 500;
                        FruitFlag <= 1;
                        GhostsEaten <= 1;
                    end
                end
            end

            if (PacmanLoc[7:0] == BottomLeftFruit[7:0]) begin
                if (PacmanLoc[15:8] > BottomLeftFruit[15:8]) begin
                    if (PacmanLoc[15:8] - BottomLeftFruit[15:8] < 8'd14) begin
                        BottomLeftFruit <= 0;
                        Score <= Score + 500;
                        FruitFlag <= 1;
                        GhostsEaten <= 1;
                    end
                end
                else begin
                    if (BottomLeftFruit[15:8] - PacmanLoc[15:8] < 8'd14) begin
                        BottomLeftFruit <= 0;
                        Score <= Score + 500;
                        FruitFlag <= 1;
                        GhostsEaten <= 1;
                    end
                end
            end

            else if (PacmanLoc[15:8] == BottomLeftFruit[15:8]) begin
                if (PacmanLoc[7:0] > BottomLeftFruit[7:0]) begin
                    if (PacmanLoc[7:0] - BottomLeftFruit[7:0] < 8'd14) begin
                        BottomLeftFruit <= 0;
                        Score <= Score + 500;
                        FruitFlag <= 1;
                        GhostsEaten <= 1;
                    end
                end
                else begin
                    if (BottomLeftFruit[7:0] - PacmanLoc[7:0] < 8'd14) begin
                        BottomLeftFruit <= 0;
                        Score <= Score + 500;
                        FruitFlag <= 1;
                        GhostsEaten <= 1;
                    end
                end
            end

            if (PacmanLoc[7:0] == BottomRightFruit[7:0]) begin
                if (PacmanLoc[15:8] > BottomRightFruit[15:8]) begin
                    if (PacmanLoc[15:8] - BottomRightFruit[15:8] < 8'd14) begin
                        BottomRightFruit <= 0;
                        Score <= Score + 500;
                        FruitFlag <= 1;
                        GhostsEaten <= 1;
                    end
                end
                else begin
                    if (BottomRightFruit[15:8] - PacmanLoc[15:8] < 8'd14) begin
                        BottomRightFruit <= 0;
                        Score <= Score + 500;
                        FruitFlag <= 1;
                        GhostsEaten <= 1;
                    end
                end
            end

            else if (PacmanLoc[15:8] == BottomRightFruit[15:8]) begin
                if (PacmanLoc[7:0] > BottomRightFruit[7:0]) begin
                    if (PacmanLoc[7:0] - BottomRightFruit[7:0] < 8'd14) begin
                        BottomRightFruit <= 0;
                        Score <= Score + 500;
                        FruitFlag <= 1;
                        GhostsEaten <= 1;
                    end
                end
                else begin
                    if (BottomRightFruit[7:0] - PacmanLoc[7:0] < 8'd14) begin
                        BottomRightFruit <= 0;
                        Score <= Score + 500;
                        FruitFlag <= 1;
                        GhostsEaten <= 1;
                    end
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

    always@(posedge sysclk)
    begin: state_table
        case (current_state)
            ScatterA: begin
                        if (FruitFlag) begin
                            next_state <= Frightened_State;
                        end
                        else begin
                            if (stateCounter > 50000*dtScatterA) begin
                                next_state <= ChaseA;
                            end
                            else begin
                                next_state <= ScatterA;
                            end
                        end
                        stateCounter <= stateCounter + 1;

                        Frightened_counter <= 0;
                        last_state <= current_state;
                     end
            ChaseA: begin
                        if (FruitFlag) begin
                            next_state <= Frightened_State;
                        end
                        else begin
                            if (stateCounter > 50000*dtScatterA + 50000*dtChaseA) begin
                                next_state <= ScatterB;
                            end
                            else begin
                                next_state <= ChaseA;
                            end
                        end
                        stateCounter <= stateCounter + 1;
                        
                        Frightened_counter <= 0;
                        last_state <= current_state;
                    end
            ScatterB: begin
                        if (FruitFlag) begin
                            next_state <= Frightened_State;
                        end
                        else begin
                            if (stateCounter > 50000*dtScatterA + 50000*dtChaseA + 50000*dtScatterB) begin
                                next_state <= ChaseB;
                            end
                            else begin
                                next_state <= ScatterB;
                            end
                        end
                        stateCounter <= stateCounter + 1;
                        
                        Frightened_counter <= 0;
                        last_state <= current_state;
                     end
            ChaseB: begin
                        if (FruitFlag) begin
                            next_state <= Frightened_State;
                        end
                        else begin
                            if (stateCounter > 50000*dtScatterA + 50000*dtChaseA + 50000*dtScatterB + 50000*dtChaseB) begin
                                next_state <= ScatterC;
                            end
                            else begin
                                next_state <= ChaseA;
                            end
                        end
                        stateCounter <= stateCounter + 1;
                        
                        Frightened_counter <= 0;
                        last_state <= current_state;
                     end
            ScatterC: begin
                        if (FruitFlag) begin
                            next_state <= Frightened_State;
                        end
                        else begin
                            if (stateCounter > 50000*dtScatterA + 50000*dtChaseA + 50000*dtScatterB + 50000*dtChaseB + 50000*dtScatterC) begin
                                next_state <= ChaseC;
                            end
                            else begin
                                next_state <= ScatterC;
                            end
                        end
                        stateCounter <= stateCounter + 1;
                        
                        Frightened_counter <= 0;
                        last_state <= current_state;
                     end
            ChaseC: begin
                        if (FruitFlag) begin
                            next_state <= Frightened_State;
                        end
                        else begin
                            if (stateCounter > 50000*dtScatterA + 50000*dtChaseA + 50000*dtScatterB + 50000*dtChaseB + 50000*dtScatterC + 50000*dtChaseC) begin
                                next_state <= ScatterD;
                            end
                            else begin
                                next_state <= ChaseC;
                            end
                        end
                        stateCounter <= stateCounter + 1;
                        
                        Frightened_counter <= 0;
                        last_state <= current_state;
                     end
            ScatterD: begin 
                        if (FruitFlag) begin
                            next_state <= Frightened_State;
                        end
                        else begin
                            if (stateCounter > 50000*dtScatterA + 50000*dtChaseA + 50000*dtScatterB + 50000*dtChaseB + 50000*dtScatterC + 50000*dtChaseC + 50000*dtScatterD) begin
                                next_state <= ChaseD;
                            end
                            else begin
                                next_state <= ScatterD;
                            end
                        end
                        stateCounter <= stateCounter + 1;
                        
                        Frightened_counter <= 0;
                        last_state <= current_state;
                     end
            ChaseD: begin
                        if (FruitFlag) begin
                            next_state <= Frightened_State;
                        end
                        else begin
                            if (stateCounter > 50000*dtScatterA + 50000*dtChaseA + 50000*dtScatterB + 50000*dtChaseB + 50000*dtScatterC + 50000*dtChaseC + 50000*dtScatterD) begin
                                next_state <= ChaseD;
                            end
                            else begin
                                next_state <= ChaseA;
                            end
                        end
                        stateCounter <= stateCounter + 1;

                        Frightened_counter <= 0;
                        last_state <= current_state;
                     end
            Frightened_State: begin
                                if (Frightened_counter > dtFrightened) begin
                                    next_state <= last_state;
                                end
                                else begin
                                    next_state <= Frightened_State;
                                end
                                Frightened_counter <= Frightened_counter + 1;
                              end
            default: next_state <= ScatterA;
        endcase
    end

    always@(negedge sysclk) begin
    
        if (next_state != current_state) begin

            // Rotate 180 when state changes
            rotate <= 1;

            case(next_state)
                ScatterA: Gamemode <= Scatter;
                ChaseA: Gamemode <= Chase;
                ScatterB: Gamemode <= Scatter;
                ChaseB: Gamemode <= Chase;
                ScatterC: Gamemode <= Scatter;
                ChaseC: Gamemode <= Chase;
                ScatterD: Gamemode <= Scatter;
                ChaseD: Gamemode <= Chase;
                Frightened_State: Gamemode <= Frightened;
            endcase

            current_state <= next_state;
        end
        else begin
            rotate <= 0;
        end
    end
endmodule