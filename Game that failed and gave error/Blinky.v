`timescale 1ns / 1ns

/*
Test Cases:

In chase should move in closest square to pacman in fwd direction only and turn 180 when enterring chase

In scatter should go to default square in top right and turn 180 when enterring scatter

In frightened should go in random sequence and turn 180 when enterring frightened

In eaten should go to the house

*/

/*

walls clear 1
Find Dir clear, random directions for frightened mode, 1
set target, 1
calculate dir/ections in lrud, 1

find min distance to find best direction, 1

update new location and facing with the direction given including rotation stuff, 1



posedge clk cycle per thingy

send in sysclk and a mode activation

level: after stuff is updated, turn mode activation on, once everything is done, wait, update locations


*/



module Blinky
    (
        pacloc,
        pacfacing,
        currentloc,
        currentfacing,
        mode,
        rotate,
        update,
        sysclk,
        nextfacing,
        nextloc
    );
    
    input [15:0] pacloc;
    input [15:0] pacfacing;
    input [15:0] currentloc;
    input [15:0] currentfacing;
    input [3:0] mode; // chase, scatter, frighten, eaten
    input rotate;
    input update;
    input sysclk;
    output reg [15:0] nextfacing;
    output reg [15:0] nextloc;

    // No Facing Up needs to be implemented

    wire [3:0] clearDirections;
    reg [15:0] target;
    reg clearLeft, clearRight, clearUp, clearDown; // Whether moving the direction is possible
    wire [15:0] randomdir;

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
                Eaten         = 4'b0001,
                ScatterTarget = {8'd216, 8'd0}, // Top Right
                EatenTarget   = {8'd108 - 8'd7, 8'd120-8'd14}; // Pinky Initial Location


    localparam  clearWalls          = 0,
                clearPaths          = 1,
                randomDirections    = 2,
                targetSelection     = 3,
                Distances           = 4,
                minDistance         = 5,
                updateLocation      = 6;

    reg [3:0] current_state;
    reg [3:0] next_state;

    always@(posedge sysclk) begin
        case(current_state)
            clearWalls: next_state <= update ? clearPaths : clearWalls;
            clearPaths: next_state <= update ? randomDirections : clearWalls;
            randomDirections: next_state <= update ? targetSelection : clearWalls;
            targetSelection: next_state <= update ? Distances : clearWalls;
            Distances: next_state <= update ? minDistance : clearWalls;
            minDistance: next_state <= update ? updateLocation : clearWalls;
            updateLocation: next_state <= clearWalls;
            default: next_state <= clearWalls;
        endcase
    end

    always@(negedge sysclk) begin
        current_state <= next_state;
    end

    clearRom u0 (.address(320*currentloc[7:0] + currentloc[15:8]), .clock(sysclk), .q(clearDirections));

    // Determines Direction Available for travel
    always@(posedge sysclk) begin

        if (current_state == clearPaths) begin
            if (!rotate) begin
                case(currentfacing)
                    LEFT: begin
                                clearLeft <= clearDirections[leftindex];
                                clearRight <= 0;
                                clearUp <= clearDirections[upindex];
                                clearDown <= clearDirections[downindex];
                        end
                    RIGHT: begin
                                clearLeft <= 0;
                                clearRight <= clearDirections[rightindex];
                                clearUp <= clearDirections[upindex];
                                clearDown <= clearDirections[downindex];
                        end
                    UP: begin
                            clearLeft <= clearDirections[leftindex];
                            clearRight <= clearDirections[rightindex];
                            clearUp <= clearDirections[upindex];
                            clearDown <= 0;
                        end
                    DOWN: begin
                            
                            clearLeft <= clearDirections[leftindex];
                            clearRight <= clearDirections[rightindex];
                            clearUp <= 0;
                            clearDown <= clearDirections[downindex];
                        end
                    //default: //"wtf" somethings wrong
                endcase
            end
            else begin
                case(currentfacing)
                    LEFT: begin
                                clearLeft <= 0;
                                clearRight <= clearDirections[rightindex];
                                clearUp <= clearDirections[upindex];
                                clearDown <= clearDirections[downindex];
                        end
                    RIGHT: begin
                                clearLeft <= clearDirections[leftindex];
                                clearRight <= 0;
                                clearUp <= clearDirections[upindex];
                                clearDown <= clearDirections[downindex];
                        end
                    UP: begin
                            clearLeft <= clearDirections[leftindex];
                            clearRight <= clearDirections[rightindex];
                            clearUp <= 0;
                            clearDown <= clearDirections[downindex];
                        end
                    DOWN: begin
                            clearLeft <= clearDirections[leftindex];
                            clearRight <= clearDirections[rightindex];
                            clearUp <= clearDirections[upindex];
                            clearDown <= 0;
                        end
                    //default: //"wtf" somethings wrong
                endcase
            end
        end
    end

    // Random Number Generator for Frightened Mode
    randomDirection u1(clearLeft, clearRight, clearUp, clearDown, sysclk, randomdir);

    // Set Target Position Based on Mode
    always@(posedge sysclk) begin
        if (current_state == targetSelection) begin
            case(mode)
                Chase: target <= pacloc;
                Scatter: target <= ScatterTarget;
                Frightened: begin
                                case(randomdir)
                                    LEFT: target <= currentloc + LEFT; // random number generator of 25% of all directions
                                    RIGHT: target <= currentloc + RIGHT;
                                    UP: target <= currentloc + UP + LEFT;
                                    DOWN: target <= currentloc + DOWN;
                                    default: target <= currentloc + LEFT; // Dummy Target
                                endcase
                            end
                Eaten: target <= EatenTarget; // The Ghost House
                default: target <= currentloc + LEFT; // Dummy Target
            endcase
        end
    end

    // Determine Optimium Path to Target
    wire [16:0] leftdis;
    wire [16:0] rightdis;
    wire [16:0] updis;
    wire [16:0] downdis;
    wire [15:0] direction;

    // Determines Distances from using path, if path is not available dis will be a very large value
    // this will ensure path will not be selected by min
    dis left(currentloc + LEFT, target, clearLeft, sysclk, leftdis);
    dis right(currentloc + RIGHT, target, clearRight, sysclk, rightdis);
    dis up(currentloc + UP + LEFT, target, clearUp, sysclk, updis);
    dis down(currentloc + DOWN, target, clearDown, sysclk, downdis);

    // Set Direction in the direction with the min distance to target
    minvalue bestdir(leftdis, rightdis, updis, downdis, sysclk, direction);

    always@(posedge sysclk) begin

        if (current_state == updateLocation) begin
            
            // Check for Invalid randomDir and clearValues
            if ((randomdir != LEFT && randomdir != RIGHT && randomdir != UP && randomdir != DOWN) ||
                (~clearLeft && ~clearRight && ~clearUp && ~clearDown)) begin
                
                nextloc <= currentloc;
                nextfacing <= direction;
            end
            else begin
            
                case(mode)
                    Eaten: begin
                                if (direction == UP) begin
                                    nextloc <= currentloc + direction + LEFT;
                                    nextfacing <= direction;
                                end
                                else begin
                                    nextloc <= currentloc + direction;
                                    nextfacing <= direction;
                                end
                            end
                    Frightened: begin
                                    if (rotate) begin
                                        case(currentfacing)
                                            LEFT: begin
                                                    nextloc <= currentloc + RIGHT;
                                                    nextfacing <= RIGHT;
                                            end
                                            RIGHT: begin
                                                    nextloc <= currentloc + LEFT;
                                                    nextfacing <= LEFT;
                                            end
                                            DOWN: begin
                                                    nextloc <= current_state + UP + LEFT;
                                                    nextfacing <= UP; 
                                            end
                                            UP: begin
                                                    nextloc <= current_state + DOWN;
                                                    nextfacing <= DOWN;
                                                end
                                        endcase
                                    end
                                    else begin        
                                        if (direction == UP) begin
                                            nextloc <= currentloc + direction + LEFT;
                                            nextfacing <= direction;
                                        end
                                        else begin
                                            nextloc <= currentloc + direction;
                                            nextfacing <= direction;
                                        end
                                    end
                                end
                    Scatter: begin
                                if (rotate) begin
                                    case(currentfacing)
                                        LEFT: begin
                                                nextloc <= currentloc + RIGHT;
                                                nextfacing <= RIGHT;
                                        end
                                        RIGHT: begin
                                                nextloc <= currentloc + LEFT;
                                                nextfacing <= LEFT;
                                        end
                                        DOWN: begin
                                                nextloc <= current_state + UP + LEFT;
                                                nextfacing <= UP; 
                                        end
                                        UP: begin
                                                nextloc <= current_state + DOWN;
                                                nextfacing <= DOWN;
                                            end
                                    endcase
                                end
                                else begin
                                    if (direction == UP) begin
                                        nextloc <= currentloc + direction + LEFT;
                                        nextfacing <= direction;
                                    end
                                    else begin
                                        nextloc <= currentloc + direction;
                                        nextfacing <= direction;
                                    end
                                end
                            end
                    Chase: begin
                                if (rotate) begin
                                    case(currentfacing)
                                        LEFT: begin
                                                nextloc <= currentloc + RIGHT;
                                                nextfacing <= RIGHT;
                                        end
                                        RIGHT: begin
                                                nextloc <= currentloc + LEFT;
                                                nextfacing <= LEFT;
                                        end
                                        DOWN: begin
                                                nextloc <= current_state + UP + LEFT;
                                                nextfacing <= UP; 
                                        end
                                        UP: begin
                                                nextloc <= current_state + DOWN;
                                                nextfacing <= DOWN;
                                            end
                                    endcase
                                end
                                else begin
                                    if (direction == UP) begin
                                        nextloc <= currentloc + direction + LEFT;
                                        nextfacing <= direction;
                                    end
                                    else begin
                                        nextloc <= currentloc + direction;
                                        nextfacing <= direction;
                                    end
                                end
                            end
                    default: nextloc <= currentloc;
                endcase
            end
        end
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