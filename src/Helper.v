
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


module test(currentloc, pacloc, mode);

    input [15:0] currentloc;
    input [15:0] pacloc;
    input [3:0] mode;

    wire [16:0] disToPac;
    
    dis Pac(currentloc, pacloc, 1'b1, disToPac);

    wire [3:0] InternalMode = (disToPac < 17'b00000000001000000) ? 0100 : mode;

endmodule