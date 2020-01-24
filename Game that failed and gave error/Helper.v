module minvalue(leftdis, rightdis, updis, downdis, clk, direction);

    input [16:0] leftdis;
    input [16:0] rightdis;
    input [16:0] updis;
    input [16:0] downdis;
	 input clk;

    output reg [15:0] direction;

    reg [16:0] minUpDown;
    reg [16:0] minLeftRight;

    //if tiles are same distance the tile directly up is preferred, then left, then down, then right

    localparam  LEFT       = 16'hFF00,
                RIGHT      = 16'h0100,
                DOWN       = 16'h0001,
                UP         = 16'h00FF;
    
    always@(posedge clk) begin

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
                direction <= LEFT;
            else
                direction <= RIGHT;
        end
        else begin

            if (minUpDown == updis)
                direction <= UP;
            
            else begin

                if (minUpDown == leftdis)
                    direction <= LEFT;
                else
                    direction <= DOWN;
            end
        end
    end
endmodule

module dis(locationA, locationB, clear, clk, distance);

    input [15:0] locationA;
    input [15:0] locationB;
    input clear;
	input clk;
    output reg [16:0] distance;

    always@(posedge clk) begin
        if (clear) begin
            /*if (locationA[7:0] > locationB[7:0]) begin
                distance = (locationA[7:0] - locationB[7:0])*(locationA[7:0] - locationB[7:0]);
            end
            else begin
                distance = (locationB[7:0] - locationA[7:0])*(locationB[7:0] - locationA[7:0]);
            end

            if (locationA[15:8] > locationB[15:8]) begin
                
            end
            else begin
                distance = distance + (locationB[15:8] - locationA[15:8])*(locationB[15:8] - locationA[15:8]);
            end*/
				distance <= (locationA[7:0] - locationB[7:0])*(locationA[7:0] - locationB[7:0]) + (locationA[15:8] - locationB[15:8])*(locationA[15:8] - locationB[15:8]);
		  end
        else
            distance <= 17'b11111111111111111;
    end
endmodule

module randomDirection(clearLeft, clearRight, clearUp, clearDown, clk, RandomDirection);

    input clearLeft, clearRight, clearUp, clearDown;
    input clk;
    output reg [15:0] RandomDirection;
    
    localparam  LEFT       = 16'hFF00,
                RIGHT      = 16'h0100,
                DOWN       = 16'h0001,
                UP         = 16'h00FF;

    localparam  leftdir    = 2'd0,
                rightdir   = 2'd1,
                downdir    = 2'd2,
                updir      = 2'd3;
     
    wire [1:0] leftright;
    wire [1:0] leftup = leftright + 2'd3;
    wire [1:0] leftdown = (leftright == rightdir) ? downdir : leftright;
    wire [1:0] rightdown = leftright + 2'd1;
    wire [1:0] rightup = (leftright == leftdir) ? updir : leftright;
    wire [1:0] updown = leftright + 2'd2;
     
    wire [1:0] leftrightdown;
    wire [1:0] leftrightup = leftrightdown + 2'd3;
    wire [1:0] leftupdown = leftrightdown + 2'd2;
    wire [1:0] rightupdown = leftrightdown + 2'd1;
     
    reg [7:0] index = 8'd0;

    LeftRightData u0(.address(index), .clock(clk), .q(leftright));
    LeftRightDownData u1(.address(index), .clock(clk), .q(leftrightdown));
     
    reg [1:0] direction;

    always@(posedge clk) begin
        
        index = index + 8'd1;
          
        // 4'b1111 is NOT possible by the design of the game
        case({clearLeft, clearRight, clearUp, clearDown})
            //4'b0000: direction = 0;// messed up here
            4'b0001: direction = downdir;
            4'b0010: direction = updir;
            4'b0100: direction = rightdir;
            4'b1000: direction = leftdir;
            4'b0011: direction = updown;
            4'b0101: direction = rightdown;
            4'b1001: direction = leftdown;
            4'b0110: direction = rightup;
            4'b1010: direction = leftup;
            4'b1100: direction = leftright;
            4'b1101: direction = leftrightdown;
            4'b0111: direction = rightupdown;
            4'b1011: direction = leftupdown;
            4'b1110: direction = leftrightup;
				//4'b1111: // need to fine
        endcase

        case(direction)
            leftdir: RandomDirection <= LEFT;
            rightdir: RandomDirection <= RIGHT;
            downdir: RandomDirection <= DOWN;
            updir: RandomDirection <= UP;
            //0: RandomDirection = 0;
        endcase
          /*
        // Error Case, NO Direction Available
        if ({clearLeft, clearRight, clearUp, clearDown} == 0) begin
            RandomDirection = 0;
        end
		  // NOT SURE IF ^ SHOULD BE DONE OR SHOULD IT BE IGNORED
          */
    end
endmodule