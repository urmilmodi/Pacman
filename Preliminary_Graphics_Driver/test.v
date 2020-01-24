module test(clk, KEY, LEDR);

    input clk;
    input [3:0] KEY;
    output reg [3:0] LEDR = 0;

    reg [8:0] xblock = 51;
    reg [8:0] yblock = 3;

    reg [3:0] side = 0;

    localparam left = 4'b1000,
                right = 4'b0100,
                up = 4'b0010,
                down = 4'b0001;

    reg [16:0] address = 0;

    wire [11:0] clr;

    rombackground u0 (.address(address), .q(clr), .clock(clk));

    always@(negedge clk) begin
    
        case(side)
            left: begin
                    if (clr == 0) begin
                        LEDR[3] = 1;
                    end
                    side = right;
                    address = 320*yblock + xblock + 1;
                end
            right: begin
                    if (clr == 0) begin
                        LEDR[2] = 1;
                    end
                    side = up;
                    address = 320*(yblock - 1) + xblock;
                end
            up: begin
                    if (clr == 0) begin
                        LEDR[1] = 1;
                    end
                    side = down;
                    address = 320*(yblock + 1) + xblock;
                end
            down: begin
                    if (clr == 0) begin
                        LEDR[0] = 1;
                    end
                    side = 0;
                    //address = 320*(yblock + 1) + xblock;
                end
            0: begin
                if (KEY[0] == 0) begin
                    side = left;
                    address = 320*yblock + xblock - 1;
                end
            end
        endcase
    end

endmodule