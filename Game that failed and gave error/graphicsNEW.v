


//vga_adapter VGA(
//            .resetn(reset),
//            .clock(CLOCK_50),
//            .colour(colour),
//            .x(x),
//            .y(y),
//            .plot(plot),
//            /* Signals for the DAC to drive the monitor. */
//            .VGA_R(VGA_R),
//            .VGA_G(VGA_G),
//            .VGA_B(VGA_B),
//            .VGA_HS(VGA_HS),
//            .VGA_VS(VGA_VS),
//            .VGA_BLANK(VGA_BLANK_N),
//            .VGA_SYNC(VGA_SYNC_N),
//            .VGA_CLK(VGA_CLK)
//);
//        defparam VGA.RESOLUTION = "320x240";
//        defparam VGA.MONOCHROME = "FALSE";
//        defparam VGA.BITS_PER_COLOUR_CHANNEL = 4;
//        defparam VGA.BACKGROUND_IMAGE = "Untitled.mif";
//            
//    // Put your code here. Your code should produce signals x,y,colour and writeEn
//    // for the VGA controller, in addition to any other functionality your design may require.
//
//    // TODO: Add reset to clear graphics drivers
//
//    control C0(
//        .clk(CLOCK_50),
//        .resetn(reset),
//        .plot(plot),
//        .blockx(xblock),
//        .blocky(yblock),
//        .xout(x),
//        .yout(y),
//        .cout(colour)
//    );


module graphicsNEW(
			clk, resetn, shift,
			
			             directionPAC,    xLocPAC, yLocPAC,  //plotPacman,                  blockxPAC, blockyPAC,xoutPAC, youtPAC, coutPAC,xLocPAC,yLocPAC, 
			stateBLUE,   directionBLUE,   xLocBLUE, yLocBLUE,  //plotBLUE,                    blockxBLUE, blockyBLUE,xoutBLUE, youtBLUE, coutBLUE,xLocBLUE,yLocBLUE,
			stateRED,    directionRED,    xLocRED, yLocRED,  //plotRED,                     blockxRED, blockyRED,xoutRED, youtRED, coutRED,xLocRED,yLocRED, 
			statePINK,   directionPINK,   xLocPINK, yLocPINK,  //plotPINK,                    blockxPINK, blockyPINK,xoutPINK, youtPINK, coutPINK,xLocPINK,yLocPINK,  
			stateYELLOW, directionYELLOW, xLocYELLOW, yLocYELLOW,  //plotYELLOW,                  blockxYELLOW, blockyYELLOW,xoutYELLOW, youtYELLOW, coutYELLOW,xLocYELLOW,yLocYELLOW,
		   fruit1_loc_x, fruit2_loc_x, fruit3_loc_x, fruit4_loc_x, 
			fruit1_loc_y, fruit2_loc_y, fruit3_loc_y, fruit4_loc_y,
			xout, yout, cout, plot, 
			//ledr
); 

	
	//output reg [9:0]ledr = 0;	
		
	input clk; 
	input resetn; 
	input shift; 
	
	input [8:0]fruit1_loc_x; 
	input [8:0]fruit2_loc_x; 
	input [8:0]fruit3_loc_x; 
	input [8:0]fruit4_loc_x; 
	
	input [7:0]fruit1_loc_y;
	input [7:0]fruit2_loc_y;
	input [7:0]fruit3_loc_y;
	input [7:0]fruit4_loc_y;
	
	//input blockxPAC[8:0]; 
	//input blockyPAC[7:0];
	input [8:0]xLocPAC;
	input [7:0]yLocPAC;
	input [15:0]directionPAC;   //used to be 3:0
	
	
	//input blockxBLUE[8:0]; 
	//input blockyBLUE[7:0];
	input [8:0]xLocBLUE;
	input [7:0]yLocBLUE;
	input [15:0]directionBLUE; 
	input [3:0]stateBLUE;
	
	//input [8:0]blockxRED; 
	//input [7:0]blockyRED;
	input [8:0]xLocRED;
	input [7:0]yLocRED;
	input [15:0]directionRED; 
	input [3:0]stateRED;
	
	//input [8:0]blockxPINK; 
	//input [7:0]blockyPINK;
	input [8:0]xLocPINK;
	input [7:0]yLocPINK;
	input [15:0]directionPINK; 
	input [3:0]statePINK;
	
	//input [8:0]blockxYELLOW; 
	//input [7:0]blockyYELLOW;
	input [8:0]xLocYELLOW;
	input [7:0]yLocYELLOW;
	input [15:0]directionYELLOW; 
	input [3:0]stateYELLOW;

	
	//output reg [8:0]xoutPAC;
	//output reg [7:0]youtPAC; 
	//output reg [11:0]coutPAC; 
	//output reg plotPAC; 
	
	//output reg [8:0]xoutBLUE;
	//output reg [7:0]youtBLUE; 
	//output reg [11:0]coutBLUE; 
	//output reg plotBLUE; 
	
	//output reg [8:0]xoutRED;
	//output reg [7:0]youtRED; 
	//output reg [11:0]coutRED; 
	//output reg plotRED; 

	//output reg [8:0]xoutPINK;
	//output reg [7:0]youtPINK; 
	//output reg [11:0]coutPINK; 
	//output reg plotPINK; 

	//output reg [8:0]xoutYELLOW;
	//output reg [7:0]youtYELLOW; 
	//output reg [11:0]coutYELLOW; 
	//output reg plotYELLOW; 	
	
	output reg [8:0]xout; 
	output reg [7:0]yout; 
	output reg [11:0]cout; 
	output reg plot; 
	
   reg [25:0] stateCounter = 0;
   reg [5:0] current_state;
   reg [5:0] next_state;
	//reg [3:0] dirVectorPAC; 
     
   parameter Erase_Delay = 50000*10; //50000*delay(in ms)
	parameter wait_gen = 10; //arbitrary 
   parameter Background_pixels = 76800;
   parameter Block_pixels = 14*14+1;
	parameter Wait_Erase = 10*50000; 

   localparam   Load_Background        = 5'd0,
                BackgroundtoBlock_Wait = 5'd1,
                Load_FRUIT1 =            5'd2,
					 Wait_FRUIT1 =            5'd3,
					 Load_FRUIT2 =            5'd4, 
					 Wait_FRUIT2 =            5'd5,
					 Load_FRUIT3 =            5'd6, 
					 Wait_FRUIT3 =            5'd7,
					 Load_FRUIT4 =            5'd8, 
					 Wait_FRUIT4 =            5'd9,
					 Load_BLUE   =            5'd10,
					 Wait_BLUE   =            5'd11,
					 Load_RED    =            5'd12, 
					 Wait_RED    =            5'd13,
					 Load_PINK   =            5'd14, 
					 Wait_PINK   =            5'd15,
					 Load_YELLOW =            5'd16, 
					 Wait_YELLOW =            5'd17, 
					 Load_PAC    =            5'd18,
					 Wait_PAC    =            5'd19, 
					 Erase_Wait  =            5'd19,
					 Preset      =            5'd20; 
					 
     
   always@(posedge clk)
   begin: state_table
       case (current_state)
			  Load_Background:        		next_state = (stateCounter > Background_pixels) ? BackgroundtoBlock_Wait : Load_Background; 
			  BackgroundtoBlock_Wait: 		next_state = (stateCounter > Background_pixels + 1) ? Load_FRUIT1 : BackgroundtoBlock_Wait; 
			  Load_FRUIT1:               	next_state = (stateCounter > Background_pixels + Block_pixels + 1) ? Wait_FRUIT1 : Load_FRUIT1; 
			  Wait_FRUIT1:					  	next_state = (stateCounter > Background_pixels + Block_pixels + wait_gen + 1) ? Load_FRUIT2 : Wait_FRUIT1;
			  Load_FRUIT2:              	next_state = (stateCounter > Background_pixels + Block_pixels + wait_gen + Block_pixels + 1) ? Wait_FRUIT2 : Load_FRUIT2; 
			  Wait_FRUIT2: 				  	next_state = (stateCounter > Background_pixels + Block_pixels + wait_gen + Block_pixels + wait_gen + 1) ? Load_FRUIT3 : Wait_FRUIT2;
			  Load_FRUIT3:               	next_state = (stateCounter > Background_pixels + Block_pixels + wait_gen + Block_pixels + wait_gen + Block_pixels + 1) ? Wait_FRUIT3 : Load_FRUIT3;
			  Wait_FRUIT3:  				  	next_state = (stateCounter > Background_pixels + Block_pixels + wait_gen + Block_pixels + wait_gen + Block_pixels + wait_gen + 1) ? Load_FRUIT4 : Wait_FRUIT3;
			  Load_FRUIT4:              	next_state = (stateCounter > Background_pixels + Block_pixels + wait_gen + Block_pixels + wait_gen + Block_pixels + wait_gen + Block_pixels + 1) ? Wait_FRUIT4 : Load_FRUIT4;
			  Wait_FRUIT4: 				  	next_state = (stateCounter > Background_pixels + Block_pixels + wait_gen + Block_pixels + wait_gen + Block_pixels + wait_gen + Block_pixels + wait_gen + 1) ? Load_BLUE : Wait_FRUIT4;
			  Load_BLUE:            		next_state = (stateCounter > Background_pixels + Block_pixels + wait_gen + Block_pixels + wait_gen + Block_pixels + wait_gen + Block_pixels + wait_gen + Block_pixels + 1) ? Wait_BLUE : Load_BLUE;
			  Wait_BLUE: 			  			next_state = (stateCounter > Background_pixels + Block_pixels + wait_gen + Block_pixels + wait_gen + Block_pixels + wait_gen + Block_pixels + wait_gen + Block_pixels + wait_gen + 1) ? Load_RED : Wait_BLUE;
			  Load_RED:            			next_state = (stateCounter > Background_pixels + Block_pixels + wait_gen + Block_pixels + wait_gen + Block_pixels + wait_gen + Block_pixels + wait_gen + Block_pixels + wait_gen + Block_pixels+ 1) ? Wait_RED : Load_RED;
			  Wait_RED: 			  			next_state = (stateCounter > Background_pixels + Block_pixels + wait_gen + Block_pixels + wait_gen + Block_pixels + wait_gen + Block_pixels + wait_gen + Block_pixels + wait_gen + Block_pixels + wait_gen + 1) ? Load_PINK : Wait_RED;
			  Load_PINK: 			  			next_state = (stateCounter > Background_pixels + Block_pixels + wait_gen + Block_pixels + wait_gen + Block_pixels + wait_gen + Block_pixels + wait_gen + Block_pixels + wait_gen + Block_pixels + wait_gen + Block_pixels + 1) ? Wait_PINK : Load_PINK;
			  Wait_PINK:            		next_state = (stateCounter > Background_pixels + Block_pixels + wait_gen + Block_pixels + wait_gen + Block_pixels + wait_gen + Block_pixels + wait_gen + Block_pixels + wait_gen + Block_pixels + wait_gen + Block_pixels + wait_gen + 1) ? Load_YELLOW : Wait_PINK;
			  Load_YELLOW: 			  		next_state = (stateCounter > Background_pixels + Block_pixels + wait_gen + Block_pixels + wait_gen + Block_pixels + wait_gen + Block_pixels + wait_gen + Block_pixels + wait_gen + Block_pixels + wait_gen + Block_pixels + wait_gen + Block_pixels + 1) ? Wait_YELLOW : Load_YELLOW;
			  Wait_YELLOW:            		next_state = (stateCounter > Background_pixels + Block_pixels + wait_gen + Block_pixels + wait_gen + Block_pixels + wait_gen + Block_pixels + wait_gen + Block_pixels + wait_gen + Block_pixels + wait_gen + Block_pixels + wait_gen + Block_pixels + wait_gen + 1) ? Load_PAC : Wait_YELLOW;
			  Load_PAC: 			  			next_state = (stateCounter > Background_pixels + Block_pixels + wait_gen + Block_pixels + wait_gen + Block_pixels + wait_gen + Block_pixels + wait_gen + Block_pixels + wait_gen + Block_pixels + wait_gen + Block_pixels + wait_gen + Block_pixels + wait_gen + Block_pixels + 1) ? Wait_PAC : Load_PAC;
			  Wait_PAC:				  			next_state = (stateCounter > Background_pixels + Block_pixels + wait_gen + Block_pixels + wait_gen + Block_pixels + wait_gen + Block_pixels + wait_gen + Block_pixels + wait_gen + Block_pixels + wait_gen + Block_pixels + wait_gen + Block_pixels + wait_gen + Block_pixels + wait_gen + 1) ? Erase_Wait : Wait_PAC;
			  Erase_Wait:             		next_state = (stateCounter > Background_pixels + Block_pixels + wait_gen + Block_pixels + wait_gen + Block_pixels + wait_gen + Block_pixels + wait_gen + Block_pixels + wait_gen + Block_pixels + wait_gen + Block_pixels + wait_gen + Block_pixels + wait_gen + Block_pixels + wait_gen + Erase_Delay + 1) ? Preset : Erase_Wait;
			  Preset:  							next_state = Load_Background; 
			  default: 							next_state = Load_Background; 
        endcase
   end



    reg [8:0] counterX = 0;
    reg [7:0] counterY = 0;

    wire [11:0] backgroundclr;
    //wire [11:0] blockclr; //= 12'b111111110000;
	 wire [11:0] blockclrEATEN; 
	 wire [11:0] blockclrFRIGHT; 
	 wire [11:0] blockclrFRUIT; 
 	 reg [11:0] blockclrPAC;
	 reg [11:0] blockclrBLUE; 
	 //reg [11:0] blockclrRED; 
	 //reg [11:0] blockclrPINK;
	 //reg [11:0] blockclrYELLOW; 
	 wire [11:0] blockclrPAC_right;// = 12'b111111110000;    
	 wire [11:0] blockclrPAC_left;// = 12'b111111110000;   
	 wire [11:0] blockclrPAC_up;// = 12'b111111110000;  
	 wire [11:0] blockclrPAC_down;// = 12'b111111110000; 
	 wire	[11:0] blockclrBLUE_right;//= 12'b000000001111;
	 wire [11:0] blockclrBLUE_left;//= 12'b000000001111;
    wire	[11:0] blockclrBLUE_up;//= 12'b000000001111;
	 wire [11:0] blockclrBLUE_down;// = 12'b000000001111;
	 				 //blockclrRED_right,    blockclrRED_left,    blockclrRED_up,    blockclrRED_down, 
					 //blockclrPINK_right,   blockclrPINK_left,   blockclrPINK_up,   blockclrPINK_down, 
					 //blockclrYELLOW_right, blockclrYELLOW_left, blockclrYELLOW_up, blockclrYELLOW_down; 
					 
	localparam  Chase      =     4'b1000, 
				   Scatter    =     4'b0100,
					Frightened =     4'b0010, 
					Eaten      =     4'b0001,
					LEFT       =     16'hFF00,
					RIGHT      =     16'h0100, 
					DOWN       =     16'h0001, 
					UP         =     16'h00FF;
					 
	rombackground u0(.address(320*counterY+counterX), .clock(clk), .q(backgroundclr));
	 
	rom_PACMAN_right u1(.address(14*counterY + counterX), .clock(clk), .q(blockclrPAC_right)); 
	rom_PACMAN_left u2(.address(14*counterY + counterX), .clock(clk), .q(blockclrPAC_left)); 
	rom_PACMAN_up u3(.address(14*counterY + counterX), .clock(clk), .q(blockclrPAC_up)); 
	rom_PACMAN_down u4(.address(14*counterY + counterX), .clock(clk), .q(blockclrPAC_down)); 
	 
	rom_BLUE_right u5(.address(14*counterY + counterX), .clock(clk), .q(blockclrBLUE_right));
	rom_BLUE_left u6(.address(14*counterY + counterX), .clock(clk), .q(blockclrBLUE_left));
	rom_BLUE_up u7(.address(14*counterY + counterX), .clock(clk), .q(blockclrBLUE_up));
	rom_BLUE_down u8(.address(14*counterY + counterX), .clock(clk), .q(blockclrBLUE_down));
	 
	 //rom_RED_right u9(.address(196*counterX + counterY), .clock(clk), .q(blockclrRED_right));
	 //rom_RED_left u10(.address(196*counterX + counterY), .clock(clk), .q(blockclrRED_left));
	 //rom_RED_up u11(.address(196*counterX + counterY), .clock(clk), .q(blockclrRED_up));
	 //rom_RED_down u12(.address(196*counterX + counterY), .clock(clk), .q(blockclrRED_down));
	 
	 //rom_PINK_right u13(.address(196*counterX + counterY), .clock(clk), .q(blockclrPINK_right));
	 //rom_PINK_left u14(.address(196*counterX + counterY), .clock(clk), .q(blockclrPINK_left));
	 //rom_PINK_up u15(.address(196*counterX + counterY), .clock(clk), .q(blockclrPINK_up));
	 //rom_PINK_down u16(.address(196*counterX + counterY), .clock(clk), .q(blockclrPINK_down));
	 
	 //rom_YELLOW_right u17(.address(196*counterX + counterY), .clock(clk), .q(blockclrYELLOW_right));
	 //rom_YELLOW_left u18(.address(196*counterX + counterY), .clock(clk), .q(blockclrYELLOW_left));
	 //rom_YELLOW_up u19(.address(196*counterX + counterY), .clock(clk), .q(blockclrYELLOW_up));
	 //rom_YELLOW_down u20(.address(196*counterX + counterY), .clock(clk), .q(blockclrYELLOW_down));
	 
	 rom_FRUIT u21(.address(14*counterY+counterX), .clock(clk), .q(blockclrFRUIT)); 
	 
	 //rom_EATEN  u22(.address(14*counterY+counterX), .clock(clk), .q(blockclrEATEN));
	 //rom_FRIGHT u23(.address(14*counterY+counterX), .clock(clk), .q(blockclrFRIGHT));
	 
	 
	 //// - means to indicated spacing after each if statement 
	 
	always@ (negedge clk) begin
      stateCounter <= stateCounter + 1;
		//if (current_state == Wait_FRUIT4) begin
		//	ledr<=10'b1111111111;
		//end
        
			////
			
         if (current_state == Load_Background) begin
				
            xout <= counterX;
            yout <= counterY;
            cout <= backgroundclr;
            plot <= 1;
                
            // Think of Display Setup and this will make sense
            if (counterX == 319) begin
                counterX <= 0;
                counterY <= counterY + 1;
            end
            else begin
                counterX <= counterX + 1;
            end
         end
			
			////
			
         if (current_state == BackgroundtoBlock_Wait) begin
            plot <= 0;
            counterX <= 0;
            counterY <= 0;
         end
			
			////
			
		   if (current_state == Load_FRUIT1) begin 
				if(fruit1_loc_x == 0 && fruit1_loc_y == 0) begin
					plot <= 0; 
				end
				else begin 
					plot <= 1;
					xout <= fruit1_loc_x + shift + counterX;
					yout <= fruit1_loc_y + counterY; 
					
					if (blockclrFRUIT != 12'b111111111111 || blockclrFRUIT != 12'b111111111011 || blockclrFRUIT != 12'b111111111110) begin
						cout <= blockclrFRUIT; 
					end
					
					if (counterX == 14 - 1) begin
						counterX <= 0;
						counterY <= counterY + 1;
					end
					else begin
						counterX <= counterX + 1;
					end
				end 
			end 		  
			
			////
		  
		   if (current_state == Wait_FRUIT2) begin
				plot <= 0; 
				counterX <= 0; 
				counterY <= 0; 	
		   end 
			
			////
			
		   if (current_state == Load_FRUIT2) begin 
				if(fruit2_loc_x == 0 && fruit2_loc_y == 0) begin
					plot <= 0; 
				end
				else begin 
					plot <= 1;
					xout <= fruit2_loc_x + shift + counterX;
					yout <= fruit2_loc_y + counterY; 
					if (blockclrFRUIT != 12'b111111111111 || blockclrFRUIT != 12'b111111111011 || blockclrFRUIT != 12'b111111111110) begin
						cout <= blockclrFRUIT; 
					end
					
					if (counterX == 14 - 1) begin
						counterX <= 0;
						counterY <= counterY + 1;
					end
					else begin
						counterX <= counterX + 1;
					end
				end 
			end 				
			
			////
			
		   if (current_state == Wait_FRUIT2) begin
				plot <= 0; 
				counterX <= 0; 
				counterY <= 0; 	
		   end 			
						
			
			////
			
		   if (current_state == Load_FRUIT3) begin 
				if(fruit3_loc_x == 0 && fruit3_loc_y == 0) begin
					plot <= 0; 
				end
				else begin 
					plot <= 1;
					xout <= fruit3_loc_x + shift+ counterX;
					yout <= fruit3_loc_y + counterY; 
					if (blockclrFRUIT != 12'b111111111111 || blockclrFRUIT != 12'b111111111011 || blockclrFRUIT != 12'b111111111110) begin
						cout <= blockclrFRUIT; 
					end 
					
					if (counterX == 14 - 1) begin
						counterX <= 0;
						counterY <= counterY + 1;
					end
					else begin
						counterX <= counterX + 1;
					end
				end 
			end 		
		
			////
			
		   if (current_state == Wait_FRUIT3) begin
				plot <= 0; 
				counterX <= 0; 
				counterY <= 0; 	
		   end 				
			
			
			////
			
			if (current_state == Load_FRUIT4) begin 
				if(fruit4_loc_x == 0 && fruit4_loc_y == 0) begin
					plot <= 0; 
				end
				else begin 
					plot <= 1;
					xout <= fruit4_loc_x + shift+ counterX;
					yout <= fruit4_loc_y+ counterY; 
					if (blockclrFRUIT != 12'b111111111111 || blockclrFRUIT != 12'b111111111011 || blockclrFRUIT != 12'b111111111110) begin
						cout <= blockclrFRUIT; 
					end 
					
					if (counterX == 14 - 1) begin
						counterX <= 0;
						counterY <= counterY + 1;
					end
					else begin
						counterX <= counterX + 1;
					end
				end 
			end 	
			
			////
			
			if (current_state == Wait_FRUIT4) begin
				plot <= 0; 
				counterX <= 0; 
				counterY <= 0; 	
		   end 
			
			////
			
			if (current_state == Load_BLUE) begin
				/*
				case(stateBLUE)
					Eaten: blockclrBLUE = blockclrEATEN; 
					Frightened: blockclrBLUE = blockclrFRIGHT; 
					Scatter:  blockclrBLUE = blockclrBLUE;
					Chase:      blockclrBLUE = blockclrBLUE; 
				endcase 
				*/
				
				if (stateBLUE == Eaten) begin
					if (blockclrBLUE != 12'b111011101110 || blockclrBLUE != 12'b111111111111) begin
						blockclrBLUE = blockclrEATEN;
					end
				end
				
				if (stateBLUE == Frightened) begin
					if (blockclrBLUE != 12'b111011101111 || blockclrBLUE != 12'b111111111111) begin
					blockclrBLUE = blockclrFRIGHT;
					end
				end
				else begin	
					case(directionBLUE)
						LEFT: blockclrBLUE = (blockclrBLUE_left); 
						RIGHT: blockclrBLUE = blockclrBLUE_right;
						UP: blockclrBLUE = blockclrBLUE_up;
						DOWN: blockclrBLUE = blockclrBLUE_down;
					endcase
					
					plot <= 1;
					xout <= xLocBLUE + shift + counterX;
					yout <= yLocBLUE+ counterY; 
					cout <= blockclrBLUE; 
					
					if (counterX == 14 - 1) begin
						counterX <= 0;
						counterY <= counterY + 1;
					end
					
					else begin
						counterX <= counterX + 1;
					end
				end
			end
			////
			
			if (current_state == Wait_BLUE) begin
				plot <= 0; 
				counterX <= 0; 
				counterY <= 0; 	
		   end 
			
			////
			
			if (current_state == Load_RED) begin
				/*
				case(stateRED)
					Eaten:      blockclrBLUE = blockclrEATEN; 
					Frightened: blockclrBLUE = blockclrFRIGHT; 
					Scatter:  blockclrBLUE = blockclrBLUE;
					Chase:      blockclrBLUE = blockclrBLUE; 
				endcase 
				*/
				
				if (stateRED == Eaten) begin
					if (blockclrBLUE != 12'b111011101110 || blockclrBLUE != 12'b111111111111) begin
						blockclrBLUE = blockclrEATEN;
					end
				end
				
				if (stateRED == Frightened) begin
					if (blockclrBLUE != 12'b111011101111 || blockclrBLUE != 12'b111111111111) begin
					blockclrBLUE = blockclrFRIGHT;
					end
				end
				
				if (stateRED == Scatter || stateRED == Chase) begin
					blockclrBLUE = blockclrEATEN; 	
					case(directionRED)
						LEFT: blockclrBLUE = (blockclrBLUE_left == 12'b000010101110 || blockclrBLUE_left == 12'b000110011101 || blockclrBLUE_left == 12'b001010011011 || blockclrBLUE_left == 12'b000110011101 || blockclrBLUE_left == 12'b000010011110) ? 12'b111100000000 : blockclrBLUE_left; 
						RIGHT: blockclrBLUE = (blockclrBLUE_right == 12'b000010101110 || blockclrBLUE_right == 12'b000110011101 || blockclrBLUE_right == 12'b001010011011 || blockclrBLUE_right == 12'b000110011101 || blockclrBLUE_right == 12'b000010011110) ? 12'b111100000000 : blockclrBLUE_right;
						UP: blockclrBLUE = (blockclrBLUE_up == 12'b000010101110 || blockclrBLUE_up == 12'b000110011101 || blockclrBLUE_up == 12'b001010011011 || blockclrBLUE_up == 12'b000110011101 || blockclrBLUE_up == 12'b000010011110) ? 12'b111100000000 : blockclrBLUE_up;
						DOWN: blockclrBLUE = (blockclrBLUE_down == 12'b000010101110 || blockclrBLUE_down == 12'b000110011101 || blockclrBLUE_down == 12'b001010011011 || blockclrBLUE_down == 12'b000110011101 || blockclrBLUE_down == 12'b000010011110) ? 12'b111100000000 : blockclrBLUE_down;				
					endcase
					plot <= 1;
					xout <= xLocRED + shift + counterX;
					yout <= yLocRED + counterY; 
					cout <= blockclrBLUE; 
					
					if (counterX == 14 - 1) begin
						counterX <= 0;
						counterY <= counterY + 1;
					end
					
					else begin
						counterX <= counterX + 1;
					end
				end
			end
			////
			
			if (current_state == Wait_RED) begin
				plot <= 0; 
				counterX <= 0; 
				counterY <= 0; 	
		   end 			
			
			////
			
			if (current_state == Load_PINK) begin
				
				if (statePINK == Eaten) begin
					if (blockclrBLUE != 12'b111011101110 || blockclrBLUE != 12'b111111111111) begin
						blockclrBLUE = blockclrEATEN;
					end
				end
				
				if (statePINK == Frightened) begin
					if (blockclrBLUE != 12'b111011101111 || blockclrBLUE != 12'b111111111111) begin
					blockclrBLUE = blockclrFRIGHT;
					end
				end
				
				if (statePINK == Scatter || statePINK == Chase) begin
					blockclrBLUE = blockclrEATEN; 	
					case(directionPINK)
						LEFT: blockclrBLUE = (blockclrBLUE_left == 12'b000010101110 || blockclrBLUE_left == 12'b000110011101 || blockclrBLUE_left == 12'b001010011011 || blockclrBLUE_left == 12'b000110011101 || blockclrBLUE_left == 12'b000010011110) ? 12'b011100000010 : blockclrBLUE_left; 
						RIGHT: blockclrBLUE = (blockclrBLUE_right == 12'b000010101110 || blockclrBLUE_right == 12'b000110011101 || blockclrBLUE_right == 12'b001010011011 || blockclrBLUE_right == 12'b000110011101 || blockclrBLUE_right == 12'b000010011110) ? 12'b011100000010 : blockclrBLUE_right;
						UP: blockclrBLUE = (blockclrBLUE_up == 12'b000010101110 || blockclrBLUE_up == 12'b000110011101 || blockclrBLUE_up == 12'b001010011011 || blockclrBLUE_up == 12'b000110011101 || blockclrBLUE_up == 12'b000010011110) ? 12'b011100000010 : blockclrBLUE_up;
						DOWN: blockclrBLUE = (blockclrBLUE_down == 12'b000010101110 || blockclrBLUE_down == 12'b000110011101 || blockclrBLUE_down == 12'b001010011011 || blockclrBLUE_down == 12'b000110011101 || blockclrBLUE_down == 12'b000010011110) ? 12'b011100000010 : blockclrBLUE_down;			
					endcase
					
					plot <= 1;
					xout <= xLocPINK + shift+ counterX;
					yout <= yLocPINK + counterY; 
					cout <= blockclrBLUE; 
					
					if (counterX == 14 - 1) begin
						counterX <= 0;
						counterY <= counterY + 1;
					end
					
					else begin
						counterX <= counterX + 1;
					end
				end
			end			
			
			////
			
			if (current_state == Wait_PINK) begin
				plot <= 0; 
				counterX <= 0; 
				counterY <= 0; 	
		   end 

			
			////
			if (current_state == Load_YELLOW) begin
				
				if (stateYELLOW == Eaten) begin
						if (blockclrBLUE != 12'b111011101110 || blockclrBLUE != 12'b111111111111) begin
							blockclrBLUE = blockclrEATEN;
						end
					end
				
				if (stateYELLOW == Frightened) begin
					if (blockclrBLUE != 12'b111011101111 || blockclrBLUE != 12'b111111111111) begin
						blockclrBLUE = blockclrFRIGHT;
					end
				end
				
				if (stateYELLOW == Scatter || stateYELLOW == Chase) begin
					blockclrBLUE = blockclrEATEN; 	
					case(directionYELLOW)
						LEFT: blockclrBLUE = (blockclrBLUE_left == 12'b000010101110 || blockclrBLUE_left == 12'b000110011101 || blockclrBLUE_left == 12'b001010011011 || blockclrBLUE_left == 12'b000110011101 || blockclrBLUE_left == 12'b000010011110) ? 12'b111111000000 : blockclrBLUE_left; 
						RIGHT: blockclrBLUE = (blockclrBLUE_right == 12'b000010101110 || blockclrBLUE_right == 12'b000110011101 || blockclrBLUE_right == 12'b001010011011 || blockclrBLUE_right == 12'b000110011101 || blockclrBLUE_right == 12'b000010011110) ? 12'b111111000000 : blockclrBLUE_right;
						UP: blockclrBLUE = (blockclrBLUE_up == 12'b000010101110 || blockclrBLUE_up == 12'b000110011101 || blockclrBLUE_up == 12'b001010011011 || blockclrBLUE_up == 12'b000110011101 || blockclrBLUE_up == 12'b000010011110) ? 12'b111111000000 : blockclrBLUE_up;
						DOWN: blockclrBLUE = (blockclrBLUE_down == 12'b000010101110 || blockclrBLUE_down == 12'b000110011101 || blockclrBLUE_down == 12'b001010011011 || blockclrBLUE_down == 12'b000110011101 || blockclrBLUE_down == 12'b000010011110) ? 12'b111111000000 : blockclrBLUE_down;			
					endcase
					
					plot <= 1;
					xout <= xLocYELLOW + shift + counterX;
					yout <= yLocYELLOW + counterY; 
					cout <= blockclrBLUE; 
					
					if (counterX == 14 - 1) begin
						counterX <= 0;
						counterY <= counterY + 1;
					end
					
					else begin
						counterX <= counterX + 1;
					end
				end
			end			
			
			
			
			////
			
			
			
			if (current_state == Wait_YELLOW) begin
				plot <= 0; 
				counterX <= 0; 
				counterY <= 0; 	
		   end 
			
			if (current_state == Load_PAC) begin
					case(directionPAC)
						LEFT: blockclrPAC = blockclrPAC_left; 
						RIGHT: blockclrPAC = blockclrPAC_right;
						UP: blockclrPAC = blockclrPAC_up;
						DOWN: blockclrPAC = blockclrPAC_down;
					endcase
					
					plot <= 1;
					xout <= xLocPAC + shift + counterX;
					yout <= yLocPAC + counterY; 
					if (blockclrPAC != 12'b111111111111 || blockclrPAC != 12'b111111111011 || blockclrPAC != 12'b111111111110) begin
						cout <= blockclrPAC; 
					end
					
					if (counterX == 14 - 1) begin
						counterX <= 0;
						counterY <= counterY + 1;
					end
					else begin
						counterX <= counterX + 1;
					end
			end
			////
			
			if (current_state == Wait_PAC) begin
				plot <= 0; 
				counterX <= 0; 
				counterY <= 0; 	
		   end

			////
			
         if (current_state == Erase_Wait) begin
            plot <= 0;
         end
         
			////
			
			if (current_state == Preset) begin
            stateCounter <= 0;
            plot <= 0;
            counterX <= 0;
            counterY <= 0;
            //blockcounter <= 0;
         end
         
			////
		
			if (!resetn) begin
            plot <= 0;
            xout <= 0;
            yout <= 0;
            counterX <= 0;
            counterY <= 0;
            stateCounter <= 0;
         end	
   end

	

    // current_state registers
   always@(posedge clk)
   begin: state_FFs
      if (!resetn) begin
         current_state <= Load_Background;
		end
			
      else begin
         current_state <= next_state;
	   end
   end
endmodule 


 			
			