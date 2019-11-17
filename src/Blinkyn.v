 `timescale 1ns / 1ns

/*
Test Cases:

In chase should move in closest square to pacman in fwd direction only and turn 180 when enterring chase

In scatter should go to default square in top right and turn 180 when enterring scatter

In frightened should go in random sequence and turn 180 when enterring frightened

In eaten should go to the house

*/

module Blinky(pacloc, currentloc, mode, rotate, update, currentfacing, WallsVector, NoFacingUpVector, nextfacing, nextloc);
    
    input [15:0] pacloc;
    input [15:0] currentloc;
    input [3:0] mode; // chase, scatter, frighten, eaten
    input rotate;
    input update;
    input [15:0] currentfacing;
    output reg [15:0] nextfacing;
    output reg [15:0] nextloc;

    parameter [9:0] TotalWalls = 10'd1008;
    parameter [9:0] TotalNoFacingUp = 10'd108;

    input [16*TotalWalls - 1:0] WallsVector;
    input [16*TotalNoFacingUp - 1:0] NoFacingUpVector;

    reg [15:0] Walls [TotalWalls:0];
    reg [15:0] NoFacingUp [TotalNoFacingUp:0];

    integer i;
    always @(*) begin
        for (i = 0; i < TotalWalls; i = i + 1)
            Walls[i] = WallsVector[16*i +: 16];
    end

    always @(*) begin
        for (i = 0; i < TotalNoFacingUp; i = i + 1)
            NoFacingUp[i] = NoFacingUpVector[16*i +: 16];
    end

    reg [15:0] target;
    reg clearLeft, clearRight, clearUp, clearDown; // Whether moving the direction is possible
    wire [15:0] rand;

    localparam  LEFT          = 16'h0100,
                RIGHT         = 16'hFF00,
                DOWN          = 16'h0001,
                UP            = 16'h00FF,
                Chase         = 4'b1000,
                Scatter       = 4'b0100,
                ScatterTarget = 16'b0001000100010001,
                Frightened    = 4'b0010,
                Eaten         = 4'b0001;
    parameter EatenTarget     = 16'b0001000100010001;

    // Determines Direction Available for travel
    always@(posedge update) begin
        clearLeft = 1;
        clearRight = 1;
        clearUp = 1;
        clearDown = 1;

        if (!rotate) begin
            // if no wall or other ghost in facing
            case(currentfacing)
                LEFT: begin
                            clearRight = 0;
                            
                            // if no wall or other ghost in facing
                            for (i = 0; i < TotalWalls; i = i + 1) begin
                                if (Walls[i] == currentloc + LEFT)
                                    clearLeft = 0;
                                if (Walls[i] == currentfacing + UP + RIGHT)
                                    clearUp = 0;
                                if (Walls[i] == currentfacing + DOWN)
                                    clearDown = 0;
                            end

                            for (i = 0; i < TotalNoFacingUp; i = i + 1) begin
                                if (NoFacingUp[i] == currentloc + UP + RIGHT)
                                    clearUp = 0;
                            end
                      end
                RIGHT: begin
                            clearLeft = 0;
                            
                            // if no wall or other ghost in facing
                            for (i = 0; i < TotalWalls; i = i + 1) begin
                                if (Walls[i] == currentloc + RIGHT)
                                    clearRight = 0;
                                if (Walls[i] == currentfacing + UP + RIGHT)
                                    clearUp = 0;
                                if (Walls[i] == currentfacing + DOWN)
                                    clearDown = 0;
                            end

                            for (i = 0; i < TotalNoFacingUp; i = i + 1) begin
                                if (NoFacingUp[i] == currentloc + UP + RIGHT)
                                    clearUp = 0;
                            end
                       end
                UP: begin
                        clearDown = 0;
                            
                        // if no wall or other ghost in facing
                        for (i = 0; i < TotalWalls; i = i + 1) begin
                            if (Walls[i] == currentloc + UP + RIGHT)
                                clearUp = 0;
                            if (Walls[i] == currentfacing + RIGHT)
                                clearRight = 0;
                            if (Walls[i] == currentfacing + LEFT)
                                clearLeft = 0;
                        end
                    end
                DOWN: begin
                        clearUp = 0;
                            
                        // if no wall or other ghost in facing
                        for (i = 0; i < TotalWalls; i = i + 1) begin
                            if (Walls[i] == currentloc + DOWN)
                                clearDown = 0;
                            if (Walls[i] == currentfacing + RIGHT)
                                clearRight = 0;
                            if (Walls[i] == currentfacing + LEFT)
                                clearLeft = 0;
                        end
                      end
                //default: //"wtf" somethings wrong
            endcase
        end
        else begin

            // if no wall or other ghost behind
            case(currentfacing)
                LEFT: begin
                            clearLeft = 0;
                            
                            // if no wall or other ghost in facing
                            for (i = 0; i < TotalWalls; i = i + 1) begin
                                if (Walls[i] == currentloc + RIGHT)
                                    clearRight = 0;
                                if (Walls[i] == currentfacing + UP + RIGHT)
                                    clearUp = 0;
                                if (Walls[i] == currentfacing + DOWN)
                                    clearDown = 0;
                            end

                            for (i = 0; i < TotalNoFacingUp; i = i + 1) begin
                                if (NoFacingUp[i] == currentloc + UP + RIGHT)
                                    clearUp = 0;
                            end
                      end
                RIGHT: begin
                            clearRight = 0;
                            
                            // if no wall or other ghost in facing
                            for (i = 0; i < TotalWalls; i = i + 1) begin
                                if (Walls[i] == currentloc + LEFT)
                                    clearLeft = 0;
                                if (Walls[i] == currentfacing + UP + RIGHT)
                                    clearUp = 0;
                                if (Walls[i] == currentfacing + DOWN)
                                    clearDown = 0;
                            end

                            for (i = 0; i < TotalNoFacingUp; i = i + 1) begin
                                if (NoFacingUp[i] == currentloc + UP + RIGHT)
                                    clearUp = 0;
                            end
                            // check up and down
                       end
                UP: begin
                        clearUp = 0;
                            
                        // if no wall or other ghost in facing
                        for (i = 0; i < TotalWalls; i = i + 1) begin
                            if (Walls[i] == currentloc + DOWN)
                                clearDown = 0;
                            if (Walls[i] == currentfacing + RIGHT)
                                clearRight = 0;
                            if (Walls[i] == currentfacing + LEFT)
                                clearLeft = 0;
                        end
                        // check left right
                    end
                DOWN: begin
                        clearDown = 0;
                            
                        // if no wall or other ghost in facing
                        for (i = 0; i < TotalWalls; i = i + 1) begin
                            if (Walls[i] == currentloc + UP + RIGHT)
                                clearUp = 0;
                            if (Walls[i] == currentfacing + RIGHT)
                                clearRight = 0;
                            if (Walls[i] == currentfacing + LEFT)
                                clearLeft = 0;
                        end
                        // check left right
                      end
                //default: //"wtf" somethings wrong
            endcase
        end
    end

    // Random Number Generator for Frightened Mode
    randomnumbergen u0(clearLeft, clearRight, clearUp, clearDown, rand);

    // Set Target Position Based on Mode
    always@(posedge update) begin
        case(mode)
            Chase: target = pacloc;
            Scatter: target = ScatterTarget;
            Frightened: begin
                            case(rand)
                                LEFT: target = currentloc + LEFT;// random number generator of 25% of all directions
                                RIGHT: target = currentloc + RIGHT;
                                UP: target = currentloc + UP + RIGHT;
                                DOWN: target = currentloc + DOWN;
                            endcase
                        end
            Eaten: target = EatenTarget; // The Ghost House
        endcase
    end

    // Determine Optimium Path to Target
    wire [16:0] leftdis;
    wire [16:0] rightdis;
    wire [16:0] updis;
    wire [16:0] downdis;
    wire [15:0] direction;

    // Determines Distances from using path, if path is not available dis will be a very large value
    // this will ensure path will not be selected by min
    dis left(currentloc + LEFT, target, clearLeft, leftdis);
    dis right(currentloc + RIGHT, target, clearRight, rightdis);
    dis up(currentloc + UP, target, clearUp, updis);
    dis down(currentloc + DOWN, target, clearDown, downdis);

    // Set Direction in the direction with the min distance to target
    minvalue bestdir(leftdis, rightdis, updis, downdis, direction);

    always@(negedge update) begin

        nextfacing = direction;
        case(mode)
            Eaten: nextloc = currentloc + nextfacing;
            Frightened: begin
                            if (rotate) begin
                                case(currentfacing)
                                    LEFT: nextfacing = RIGHT;
                                    RIGHT: nextfacing = LEFT;
                                    DOWN: nextfacing = UP;
                                    UP: nextfacing = DOWN;
                                endcase
                                // change rotate to false
                            end
                            nextloc = currentloc + nextfacing;
                        end
            Scatter: begin
                        if (rotate) begin
                            case(currentfacing)
                                LEFT: nextfacing = RIGHT;
                                RIGHT: nextfacing = LEFT;
                                DOWN: nextfacing = UP;
                                UP: nextfacing = DOWN;
                            endcase
                            // change rotate to false
                        end
                        nextloc = currentloc + nextfacing;
                     end
            Chase: begin
                        if (rotate) begin
                            case(currentfacing)
                                LEFT: nextfacing = RIGHT;
                                RIGHT: nextfacing = LEFT;
                                DOWN: nextfacing = UP;
                                UP: nextfacing = DOWN;
                            endcase
                            // change rotate to false
                        end
                        if (nextfacing == UP)
                            nextloc = currentloc + nextfacing + RIGHT;
                        else 
                            nextloc = currentloc + nextfacing;
                   end
        endcase
    end
endmodule

module minvalue(leftdis, rightdis, updis, downdis, direction);

    input [16:0] leftdis;
    input [16:0] rightdis;
    input [16:0] updis;
    input [16:0] downdis;

    output reg [15:0] direction;

    reg [15:0] minUpDown;
    reg [15:0] minLeftRight;

    //if tiles are same distance the tile directly up is preferred, then left, then down, then right

    localparam  LEFT       = 16'h0100,
                RIGHT      = 16'hFF00,
                DOWN       = 16'h0001,
                UP         = 16'h00FF;
    
    always@(leftdis, rightdis, updis, downdis) begin

        if (downdis < updis)
            minUpDown = downdis;
        else
            minUpDown = updis;

        if (rightdis < leftdis)
            minLeftRight = rightdis;
        else
            minLeftRight = leftdis;

        if (minLeftRight < minUpDown) begin
            
            if (minLeftRight == leftdis)
                direction = LEFT;
            else
                direction = RIGHT;
        end
        else begin

            if (minUpDown == updis)
                direction = UP;
            
            else begin

                if (minUpDown == leftdis)
                    direction = LEFT;
                else
                    direction = DOWN;
            end
        end
    end
endmodule

module dis(locationA, locationB, clear, distance);

    input [15:0] locationA;
    input [15:0] locationB;
    input clear;
    output reg [16:0] distance;

    always@(*) begin
        if (clear)
            distance = (locationA[7:0] - locationB[7:0])*(locationA[7:0] - locationB[7:0]) + (locationA[15:8] - locationB[15:8])*(locationA[15:8] - locationB[15:8]);
        else
            distance = 17'b11111111111111111;
    end
endmodule

module randomnumbergen(clearLeft, clearRight, clearUp, clearDown, rand);
    input clearLeft, clearRight, clearUp, clearDown;
    output reg [15:0] rand;

    localparam  LEFT       = 16'h0100,
                RIGHT      = 16'hFF00,
                DOWN       = 16'h0001,
                UP         = 16'h00FF;

    always@(*) begin
        /*
        case({clearLeft, clearRight, clearUp, clearDown})
            4'b0001: rand = DOWN;
            4'b0010: rand = UP;
            4'b0100: rand = RIGHT;
            4'b1000: rand = LEFT;
            4'b0011: // Up, down
            4'b0101: // right down
            4'b1001: // left down
            4'b0110: // right up
            4'b1010: // left up
            4'b1100: // left right
            4'b0111: // right up down
            4'b1011: // left up down
            4'b1101: // left right down
            4'b1110: // left right up
            4'b1111: // left right up down
            
        endcase
        */
        if (clearLeft)
            rand = LEFT;
        else if (clearRight)
            rand = RIGHT;
        else if (clearUp)
            rand = UP;
        else if (clearDown)
            rand = DOWN;
    end
endmodule


// parameter for the walls
// parameter for not going up

//parameter for scatter state clock

// note general description from video and then write generic controller system


/*

GameFSM -> Menu, Game Mode, Other Modes, GameOver

Game Mode -> Level FSM (after this go to next level fsm) -> Ghost FSMs, Pacman FSM, GameLogic FSM

come up with high level design then begin writing code, using as many parameters as possible to allow module usage anywhere, example scatter mode counter is a param

*/



/*


Scatter-Chase state changes occur roughly 4 times per level, after last scatter sequence ghosts go into chase mode permanently

Blinky's chase fn can appear as scatter depending on the number of dots left


Scatter (time const dependent) - Initial State
Chase (time const dependent) 
Frightened (when Pacman eats power fruit) after certain time const will enter either scatter or chase
Eaten (if touched by pacman when in frighten state) after certain time const will enter either scatter or chase


Target System: 

Bwd is not allowed
going into walls is not allowed
going into other ghosts is not allowed

The ghost will find the euclidian distance from all available tiles to the target tile and choose the tile with the shortest euclidian distance
if tiles are same distance the tile directly up is preferred, then left, then down, then right


Scatter State Target System:

Turn 180 degrees

Blinky - Top right (clockwise rotation)
Pinky - top left (counterclockwise rotation)
blue - bottom right (either depending on initial)
clyde - bottom left (either depending on initial)

Fightened:

All ghosts turn into the same frightened sprite, and turn 180 degrees 
for frightened mode, a random tile is chosen based off a random number generator



Eaten:

when pacman touches in frightened mode
Different sprite
Target tile is right infacing of the gate
once they enter the jail they'll they go back to normal in terms of sprite and will revert back to the state they would have been in if not frightened

Chase: 
Turn 180 degrees

Blinky Target Tile is Pacman's Tile

Pinky's Target Tile is 4 tiles directly in facing of pacman, if he's facing left then 4 to the left and similar for the remaining directions

Inky's Target Tile is 

the vector from 2 tiles directly in facing of pacman to blinky's loc is rotated 180 degrees and made inky's target

let the 2 tiles ahead be (x, y) and blinky be (xb, yb)

inky will be (x - (x-xb), y - (y-yb))

Clyde's Target Tile:

Target is blinky's tile if dist to pacman is >= 8
otherwise target is same target on scatter mode

Location Storage is 4 bit vector
16 to 8 is x loc
8 to 0 is y loc

treated as 1 16bit value

In hEX:
left is 0100
right is FF00
down is 0001
up is 00FF


*******
The ghosts cannot turn up pixels in facing of the ghost house, they must enter and then leave up

The ghosts also can't turn up in pixels where pacman originally spawns

after level 19 ghosts don't turn into frightened mode
*/