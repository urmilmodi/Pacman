module Pacman(SW, LEDR);
    input [3:0] SW;
    output reg [9:0] LEDR;

    reg [15:0] dir;

    localparam  LEFT          = 16'h0100,
                RIGHT         = 16'hFF00,
                DOWN          = 16'h0001,
                UP            = 16'h00FF;

    always@(SW) begin
      
        case(SW)
            4'b1000: dir = LEFT;
            4'b0100: dir = RIGHT;
            4'b0010: dir = UP + RIGHT;
            4'b0001: dir = DOWN;
        endcase

        LEDR[3:0] = SW[3:0];
    end
endmodule


/*
toplevelfn -> level fn -> ghost modules & pacman movement

level fn:

manage changes and return changes

toplevelfn pass changes into game-graphics module if in game or into other_non_game-graphics module then display info

game graphics module

    background
    pacman
    ghosts (4)
    fruits (a lot)
    special fruits (couple)
    

*/