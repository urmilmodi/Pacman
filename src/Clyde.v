 `timescale 1ns / 1ns
 
module Clyde(pacloc, pacfacing, currentloc, mode, rotate, update, currentfacing, WallsVector, NoFacingUpVector, nextfacing, nextloc);
    
    input [15:0] pacloc;
    input [15:0] pacfacing;
    input [15:0] currentloc;
    input [3:0] mode; // chase, scatter, frighten, eaten
    input rotate;
    input update;
    input [15:0] currentfacing;
    output reg [15:0] nextfacing;
    output reg [15:0] nextloc;

    parameter [9:0] TotalWalls = 10'd1008;
    parameter [9:0] TotalNoFacingUp = 10'd1008;

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
        clearLeft = 0;
        clearRight = 0;
        clearUp = 0;
        clearDown = 0;

        if (!rotate) begin
            // if no wall or other ghost in facing
            case(currentfacing)
                LEFT: begin
                            clearLeft = 1;
                            clearUp = 1;
                            clearDown = 1;
                            // if no wall or other ghost in facing
                            // check up and down
                      end
                RIGHT: begin
                            clearRight = 1;
                            clearUp = 1;
                            clearDown = 1;
                            // if no wall or other ghost in facing
                            // check up and down
                       end
                UP: begin
                        clearUp = 1;
                        clearLeft = 1;
                        clearRight = 1;
                        // if no wall or other ghost in facing
                        // check left right
                    end
                DOWN: begin
                        clearDown = 1;
                        clearLeft = 1;
                        clearRight = 1;
                        // if no wall or other ghost in facing
                        // check left right
                      end
                //default: //"wtf" somethings wrong
            endcase
        end
        else begin

            // if no wall or other ghost behind
            case(currentfacing)
                LEFT: begin
                            clearRight = 1;
                            clearUp = 1;
                            clearDown = 1;
                            // check up and down
                      end
                RIGHT: begin
                            clearLeft = 1;
                            clearUp = 1;
                            clearDown = 1;
                            // check up and down
                       end
                UP: begin
                        clearDown = 1;
                        clearLeft = 1;
                        clearRight = 1;
                        // check left right
                    end
                DOWN: begin
                        clearUp = 1;
                        clearLeft = 1;
                        clearRight = 1;
                        // check left right
                      end
                //default: //"wtf" somethings wrong
            endcase
        end
    end

    // Random Number Generator for Frightened Mode
    randomnumbergen u0(clearLeft, clearRight, clearUp, clearDown, rand);

    // Clyde reverts to Scatter if Distance to Pacman is < 8
    wire [16:0] disToPac;
    
    dis Pac(currentloc, pacloc, 1'b1, disToPac);

    // Compares to 64 because dis module returns the distance squared
    wire [3:0] InternalMode = (disToPac <= 17'b00000000001000000) ? 0100 : mode;

    // Set Target Position Based on Mode
    always@(posedge update) begin
        case(InternalMode)
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