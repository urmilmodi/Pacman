`timescale 1ns / 1ns
 
module Pinky
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
                ScatterTarget = {8'd216, 8'd240}, // Bottom Right
                EatenTarget   = {108 - 8'd14/2, 120-8'd14}; // Pinky Initial Location

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
    always@(posedge update) begin
        if (current_state == targetSelection) begin
            case(mode)
                Chase: target <= pacloc + 4*pacfacing*8'd14;
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