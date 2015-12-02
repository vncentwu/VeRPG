`timescale 1ms/1ms    

/*

ID Legend:
- 0: ?

*/

`define UNKNOWN 0
`define CURRENT 1
`define ENTRANCE 2
`define EXIT 3
`define BLANK 4
`define WALL 5

module main();
	initial begin

		//$dumpfile("cpu.vcd");
		$readmemh("input.data",input_data);
		$readmemh("map.data", map_data);
		//$dumpvars(1,main);

		//initialize bitmap to 0
		for(i = 0; i < 20; i = i + 1) begin
			for(j = 0; j < 20; j = j + 1) begin
				bitmap[i*20 + j] = 0;
			end
		end

		for(i = 0; i < 20; i = i+1) begin
			map[i*20 + 0] = map_data[i][79:76];
			map[i*20 + 1] = map_data[i][75:72];
			map[i*20 + 2] = map_data[i][71:68];
			map[i*20 + 3] = map_data[i][67:64];
			map[i*20 + 4] = map_data[i][63:60];
			map[i*20 + 5] = map_data[i][59:56];
			map[i*20 + 6] = map_data[i][55:52];
			map[i*20 + 7] = map_data[i][51:48];
			map[i*20 + 8] = map_data[i][47:44];
			map[i*20 + 9] = map_data[i][43:40];
			map[i*20 + 10] = map_data[i][39:36];
			map[i*20 + 11] = map_data[i][35:32];
			map[i*20 + 12] = map_data[i][31:28];
			map[i*20 + 13] = map_data[i][27:24];
			map[i*20 + 14] = map_data[i][23:20];
			map[i*20 + 15] = map_data[i][19:16];
			map[i*20 + 16] = map_data[i][15:12];
			map[i*20 + 17] = map_data[i][11:8];
			map[i*20 + 18] = map_data[i][7:4];
			map[i*20 + 19] = map_data[i][3:0];
		end
	end

	wire[3:0] current_val = map_data[0][79:76];
	wire[3:0] current_val2 = map_data[1][75:72];

	integer f, number;
	reg[15:0]i; //multi-purpose indices
	reg[15:0]j;
	reg[15:0]eip = 0; //command pointer
	wire clk;
	clock c0(clk);

	reg [15:0]input_data[0:2000]; //Array of all command data
	reg [79:0]map_data[0:19]; //used to load up the map

	reg [15:0]map[399:0]; //pseudo 10x10 2D array of 16 bit values
	reg bitmap[399:0]; //Literally a bitmap haha
	reg display_queued = 1;

	reg [15:0]current_pos = 50;
	wire[15:0] current_command = input_data[eip];

	wire new_command = !(^input_data[eip] === 1'bx);

	wire left_clear = (current_pos - 1 > 0 && (current_pos - 1) % 20 < current_pos % 20);
	wire left_2_clear = (current_pos - 2 > 0 && (current_pos - 2) % 20 < current_pos % 20);
	wire right_clear = (current_pos + 1 < 400 && (current_pos + 1) % 20 > current_pos % 20);
	wire right_2_clear = (current_pos + 2 < 400 && (current_pos + 2) % 20 > current_pos % 20);
	wire top_clear = (current_pos - 20 > 0);
	wire top_2_clear = (current_pos - 40 > 0);
	wire bottom_clear = (current_pos + 20 < 400);
	wire bottom_2_clear = (current_pos + 40 < 400);

	reg can_move = 1;
	reg can_fight = 0;
	reg can_hacks = 1;

	/* Player information */
	reg [15:0]player_health = 100;
	reg [15:0]player_max_health = 100;
	wire [15:0]player_health_ratio = (player_health * 10 / player_max_health);

	/* Settings */
	reg no_clip = 0;
	reg no_shroud = 0;
	reg godmode = 0;

	always @(posedge clk) begin
		

		if(top_clear) begin
			bitmap[current_pos - 20] = 1;
			if(left_clear)
				bitmap[current_pos - 20 - 1] = 1;
			if(right_clear)
				bitmap[current_pos - 20 + 1] = 1;
		end
		if(top_2_clear)
			bitmap[current_pos - 40] = 1;			
		if(bottom_clear) begin
			bitmap[current_pos + 20] = 1;
			if(left_clear)
				bitmap[current_pos + 20 - 1] = 1;
			if(right_clear)
				bitmap[current_pos + 20 + 1] = 1;			
		end
		if(bottom_2_clear)
			bitmap[current_pos + 40] = 1;
		if(right_clear)
			bitmap[current_pos + 1] = 1;
		if(right_2_clear)
			bitmap[current_pos + 2] = 1;			
		if(left_clear)
			bitmap[current_pos - 1] = 1;
		if(left_2_clear)
			bitmap[current_pos - 2] = 1;

		if(new_command) begin //prints out current information
			display_queued <= 1;
			case(input_data[eip])
				1: begin
					if (current_pos + 1 > 0 && (current_pos + 1) % 20 > current_pos % 20 && map[current_pos + 1] != 5)
						current_pos <= current_pos + 1;
				end
				2: begin //le
					if (current_pos - 1 > 0 && (current_pos - 1) % 20 < current_pos % 20 && map[current_pos - 1] != 5)
						current_pos <= current_pos - 1;
				end
				3: begin //up
					if(current_pos - 20 > 0 & map[current_pos - 20] != 5)
						current_pos <= current_pos - 20;
				end
				4: begin //down
					if(current_pos + 20 < 400 & map[current_pos + 20] != 5)
						current_pos <= current_pos + 20;
				end		
				16'h10: begin //exit
					no_shroud <= !no_shroud;
					$display("No shroud");
				end
				11: begin // no_shroud
					
				end											
			endcase
			eip <= eip + 1;
		end
		else begin
			$readmemh("input.data",input_data);
		end
		if(display_queued) begin
			if(!new_command)
				display_queued <= 0; 
			f = $fopen("output.data");
			$fdisplay(f, "\n\n");
			for(i = 0; i < 20; i = i + 1) begin
				$fwrite(f, "");
				for(j = 0; j < 20; j = j + 1) begin
					if(current_pos == i*20 + j) begin
						$fwrite(f, "! " );
					end
					else if(bitmap[i*20 + j] == 0 && no_shroud == 0) begin
						$fwrite(f, "? " );
					end
					else begin
						case(map[i*20 + j])
							`CURRENT: begin
								$fwrite(f, "! ");
							end
							`ENTRANCE: begin
								$fwrite(f, "< ");
							end
							`EXIT: begin
								$fwrite(f, "> ");
							end		
							`BLANK: begin
								$fwrite(f, "  ");
							end
							`WALL: begin
								$fwrite(f, "X ");
							end												
						endcase							
					end
				end
				$fdisplay(f, "");
			end	
			$fwrite(f, "\nHP: [%d/%d]", player_health, player_max_health);

			/* Writing allowed commands */
			$fdisplay(f, "\n");
			if(can_move)
				$fwrite(f, "[1] - Right    [2] - Left    [3] - Up    [4] - Down    ");
			if(can_hacks)
				$fwrite(f, "[10] - No shroud    ");
			$fdisplay(f, "\n");
			$fclose(f);
		end
	end


endmodule