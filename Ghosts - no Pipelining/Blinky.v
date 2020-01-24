`timescale 1ns / 1ns

/*
Test Cases:

In chase should move in closest square to pacman in fwd direction only and turn 180 when enterring chase

In scatter should go to default square in top right and turn 180 when enterring scatter

In frightened should go in random sequence and turn 180 when enterring frightened

In eaten should go to the house

*/

module Blinky
    (
        pacloc,
        pacfacing,
        currentloc,
        currentfacing,
        clearDirections,
        mode,
        rotate,
        update,
        nextfacing,
        nextloc
    );
    
    input [15:0] pacloc;
    input [15:0] pacfacing;
    input [15:0] currentloc;
    input [3:0] clearDirections;
    input [3:0] mode; // chase, scatter, frighten, eaten
    input rotate;
    input update;
    input [15:0] currentfacing;
    output reg [15:0] nextfacing;
    output reg [15:0] nextloc;

    // No Facing Up needs to be implemented

    reg [15:0] target;
    reg clearLeft, clearRight, clearUp, clearDown; // Whether moving the direction is possible
    wire [15:0] rand;

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
                ScatterTarget = {8'd267, 8'd0}, // Top Right
                EatenTarget   = {108 - side/2, 120-side}; // Pinky Initial Location

    // Determines Direction Available for travel
    always@(posedge update) begin
        clearLeft = 0;
        clearRight = 0;
        clearUp = 0;
        clearDown = 0;

        if (!rotate) begin
            case(currentfacing)
                LEFT: begin
                            clearLeft = clearDirections[leftindex];
                            clearUp = clearDirections[upindex];
                            clearDown = clearDirections[downindex];
                      end
                RIGHT: begin
                            clearRight = clearDirections[rightindex];
                            clearUp = clearDirections[upindex];
                            clearDown = clearDirections[downindex];
                       end
                UP: begin
                        clearUp = clearDirections[upindex];
                        clearLeft = clearDirections[leftindex];
                        clearRight = clearDirections[rightindex];
                    end
                DOWN: begin
                        clearDown = clearDirections[downindex];
                        clearLeft = clearDirections[leftindex];
                        clearRight = clearDirections[rightindex];
                      end
                //default: //"wtf" somethings wrong
            endcase
        end
        else begin
            case(currentfacing)
                LEFT: begin
                            clearRight = clearDirections[rightindex];
                            clearUp = clearDirections[upindex];
                            clearDown = clearDirections[downindex];
                      end
                RIGHT: begin
                            clearLeft = clearDirections[leftindex];
                            clearUp = clearDirections[upindex];
                            clearDown = clearDirections[downindex];
                       end
                UP: begin
                        clearDown = clearDirections[downindex];
                        clearLeft = clearDirections[leftindex];
                        clearRight = clearDirections[rightindex];
                    end
                DOWN: begin
                        clearUp = clearDirections[upindex];
                        clearLeft = clearDirections[leftindex];
                        clearRight = clearDirections[rightindex];
                      end
                //default: //"wtf" somethings wrong
            endcase
        end
    end

    // Random Number Generator for Frightened Mode
    randomDirection u0(clearLeft, clearRight, clearUp, clearDown, update, rand);

    // Set Target Position Based on Mode
    always@(posedge update) begin
        case(mode)
            Chase: target <= pacloc;
            Scatter: target <= ScatterTarget;
            Frightened: begin
                            case(rand)
                                LEFT: target <= currentloc + LEFT; // random number generator of 25% of all directions
                                RIGHT: target <= currentloc + RIGHT;
                                UP: target <= currentloc + UP + LEFT;
                                DOWN: target <= currentloc + DOWN;
                            endcase
                        end
            Eaten: target <= EatenTarget; // The Ghost House
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
    dis up(currentloc + UP + LEFT, target, clearUp, updis);
    dis down(currentloc + DOWN, target, clearDown, downdis);

    // Set Direction in the direction with the min distance to target
    minvalue bestdir(leftdis, rightdis, updis, downdis, direction);

    always@(negedge update) begin

        nextfacing = direction;
        case(mode)
            Eaten: begin
                    if (nextfacing == UP)
                        nextloc = currentloc + nextfacing + LEFT;
                    else 
                        nextloc = currentloc + nextfacing;
                    end
            Frightened: begin
                            if (rotate) begin
                                case(currentfacing)
                                    LEFT: nextfacing = RIGHT;
                                    RIGHT: nextfacing = LEFT;
                                    DOWN: nextfacing = UP;
                                    UP: nextfacing = DOWN;
                                endcase
                            end
                            if (nextfacing == UP)
                                nextloc = currentloc + nextfacing + LEFT;
                            else 
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
                        end
                        if (nextfacing == UP)
                            nextloc = currentloc + nextfacing + LEFT;
                        else 
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
                        end
                        if (nextfacing == UP)
                            nextloc = currentloc + nextfacing + LEFT;
                        else 
                            nextloc = currentloc + nextfacing;
                   end
        endcase
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