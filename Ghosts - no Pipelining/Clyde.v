`timescale 1ns / 1ns
 
module Clyde
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
                ScatterTarget = {8'd51, 8'd240}, // Bottom Left
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

    // Clyde reverts to Scatter if Distance to Pacman is < 8
    wire [16:0] disToPac;
    
    dis Pac(currentloc, pacloc, 1'b1, disToPac);

    // Compares to 64 because dis module returns the distance squared
    wire [3:0] InternalMode = (disToPac <= 17'd64) ? Scatter : mode;

    // Set Target Position Based on Mode
    always@(posedge update) begin
        case(InternalMode)
            Chase: target = pacloc;
            Scatter: target = ScatterTarget;
            Frightened: begin
                            case(rand)
                                LEFT: target = currentloc + LEFT; // random number generator of 25% of all directions
                                RIGHT: target = currentloc + RIGHT;
                                UP: target = currentloc + UP + LEFT;
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