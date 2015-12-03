`timescale 1s/1ms    


/* Map IDs */
`define UNKNOWN 0
`define CURRENT 1
`define ENTRANCE 2
`define EXIT 3
`define BLANK 4
`define WALL 5
`define ENEMY 6  //gets mapped to a random enemy
`define WEAPON 7 //gets mapped to a random weapon

/* Weapon IDs - reserved 10-20*/
`define RUSTY_KNIFE 10
`define AXE 11
`define SWORD 12
`define SWORD1 13
`define SWORD2 14
`define SWORD3 15
`define SWORD4 16
`define SWORD5 17
`define SWORD6 18
`define SWORD7 19
`define SWORD8 20

/* Enemy IDs - reserved 20-30*/
`define GIANT_RAT 20
`define DRAGON 21
`define MONSTER_1 22
`define MONSTER_2 23
`define MONSTER_3 24
`define MONSTER_4 25
`define MONSTER_5 26
`define MONSTER_6 27
`define MONSTER_7 28
`define MONSTER_8 29
`define MONSTER_9 30

/* Input IDs */
`define NO_OP 0
`define RIGHT 1
`define LEFT 2
`define UP 3
`define DOWN 4
`define ATTACK 5
`define RUN 6
`define NO_SHROUD 16'hA
`define HELP 16'hB
`define OK 16'hC


module main();
	initial begin

		//$dumpfile("cpu.vcd");
		$readmemh("input.data",input_data);
		$readmemh("map.data", map_data);
		//$dumpvars(1,main);

	/* Copy pasta necessary because verilog 2001 doesn't support > 2D arrays.
	   Used to load map data from user */
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

		//initialize bitmap to 0, and assigns random values to weapons and enemies
		for(i = 0; i < 20; i = i + 1) begin
			for(j = 0; j < 20; j = j + 1) begin
				bitmap[i*20 + j] = 0;
				if(map[i*20 + j] == `WEAPON)
					map[i*20 + j] = random_weapon;
					
			end
		end

	end


	/* Debug values - GTKWAVE files become huge*/
	wire[3:0] current_val = map_data[0][79:76];
	wire[3:0] current_val2 = map_data[1][75:72];

	/* Multi-purpose values - Saves wire clutter*/
	integer f, number;
	reg[15:0]i; 
	reg[15:0]j;

	/* Enemy logic */ //4 bit for type, 8 bit for health, 8 bit for max health, 8 bit for damage, 4 bit for item drop
	reg [31:0]enemy_map[1000:0]; //map of enemies
	wire is_current_enemy = !(^current_enemy === 1'bx);
	wire [31:0]current_enemy = enemy_map[current_pos];
	wire [3:0]current_enemy_type = current_enemy[31:28];
	wire [3:0]current_enemy_health = current_enemy[27:20];
	wire [3:0]current_enemy_max_health = current_enemy[19:12];
	wire [3:0]current_enemy_damage = current_enemy[11:4];
	wire [3:0]current_enemy_drop = current_enemy[3:0];

	/* Map information */
	reg [15:0]current_pos = 50;
	wire left_clear = (current_pos - 1 > 0 && (current_pos - 1) % 20 < current_pos % 20);
	wire left_2_clear = (current_pos - 2 > 0 && (current_pos - 2) % 20 < current_pos % 20);
	wire right_clear = (current_pos + 1 < 400 && (current_pos + 1) % 20 > current_pos % 20);
	wire right_2_clear = (current_pos + 2 < 400 && (current_pos + 2) % 20 > current_pos % 20);
	wire top_clear = (current_pos - 20 > 0);
	wire top_2_clear = (current_pos - 40 > 0);
	wire bottom_clear = (current_pos + 20 < 400);
	wire bottom_2_clear = (current_pos + 40 < 400);

	/* Player information */
	reg [15:0]player_health = 100;
	reg [15:0]player_max_health = 100;
	wire [15:0]player_health_ratio = (player_health * 10 / player_max_health);

	/* Game data */
	wire on_enemy = map[current_pos] == `ENEMY;
	reg run_failed = 0;
	reg can_move = 1;
	reg can_fight = 0;
	reg can_hacks = 1;	

	/* Settings */
	reg no_clip = 0;
	reg no_shroud = 0;
	reg godmode = 0;

	/* System data*/
	reg display_queued = 1; // If set, next cycle will print current data
	wire new_command = !(^input_data[eip] === 1'bx); //If set, next cycle will process current command
	wire[15:0] current_command = input_data[eip];
	reg[15:0]eip = 0; //command pointer
	wire clk;
	clock c0(clk);
	reg [15:0]input_data[0:2000]; //Array of all command data
	reg [79:0]map_data[0:19]; //used to load up the map
	reg [15:0]map[1000:0]; //pseudo 10x10 2D array of 16 bit values
	reg bitmap[1000:0]; //Literally a bitmap haha

	/* Random logic - random simulated by current clock cycle*/
	reg[15:0] random_weapon = 10;
	reg[15:0] random_enemy = 20;
	reg[15:0] random_3 = 0;
	reg[15:0] random_4 = 0;
	reg[15:0] random_10 = 0;
	reg help_requested = 0;
	reg[2:0] current_random = 0;
	reg[2:0] run_random = 0;



	always @(posedge clk) begin
			
		/* Random logic */
		if(random_3 == 2)
			random_3 <= 0;
		else 
			random_3 <= random_3 + 1;
		if(random_4 == 3)
			random_4 <= 0;
		else 
			random_4 <= random_4 + 1;
		if(random_10 == 9)
			random_10 <= 0;
		else 
			random_10 <= random_10 + 1;	
       random_weapon <= (random_10) + 10;
       random_enemy <= (random_10) + 20;
		current_random <= random_4;
		run_random <= random_3;

		if(top_clear) begin
			bitmap[current_pos - 20] <= 1;
			if(left_clear)
				bitmap[current_pos - 20 - 1] <= 1;
			if(right_clear)
				bitmap[current_pos - 20 + 1] <= 1;
		end
		if(top_2_clear)
			bitmap[current_pos - 40] <= 1;			
		if(bottom_clear) begin
			bitmap[current_pos + 20] <= 1;
			if(left_clear)
				bitmap[current_pos + 20 - 1] <= 1;
			if(right_clear)
				bitmap[current_pos + 20 + 1] <= 1;			
		end
		if(bottom_2_clear)
			bitmap[current_pos + 40] <= 1;
		if(right_clear)
			bitmap[current_pos + 1] <= 1;
		if(right_2_clear)
			bitmap[current_pos + 2] <= 1;			
		if(left_clear)
			bitmap[current_pos - 1] <= 1;
		if(left_2_clear)
			bitmap[current_pos - 2] <= 1;

		if(help_requested) begin
			help_requested <= 0;
		end
		else if(new_command) begin //prints out current information
			display_queued <= 1;
			$display("current command: %d", current_command);
			case(input_data[eip])
				`RIGHT: begin
					if (current_pos + 1 > 0 && (current_pos + 1) % 20 > current_pos % 20)
						if(map[current_pos + 1] != 5)
							current_pos <= current_pos + 1;
				end
				`LEFT: begin //le
					if (current_pos - 1 > 0 && (current_pos - 1) % 20 < current_pos % 20)
						if(map[current_pos - 1] != 5)
							current_pos <= current_pos - 1;
				end
				`UP: begin //up
					if(current_pos - 20 > 0)
						if(map[current_pos - 20] != 5)
							current_pos <= current_pos - 20;
				end
				`DOWN: begin //down
					if(current_pos + 20 < 400)
						if(map[current_pos + 20] != 5)
							current_pos <= current_pos + 20;
				end
				`ATTACK: begin //attack
					player_health <= player_health - 10;
				end	
				`RUN: begin //run
					if(run_random > 0) begin
						case(current_random)
						`RIGHT: begin //right
							if (current_pos + 1 > 0 && (current_pos + 1) % 20 > current_pos % 20)
								if(map[current_pos + 1] != 5)
									current_pos <= current_pos + 1;
						end
						`LEFT: begin //left
							if (current_pos - 1 > 0 && (current_pos - 1) % 20 < current_pos % 20)
								if(map[current_pos - 1] != 5)
									current_pos <= current_pos - 1;
						end
						`UP: begin //up
							if(current_pos - 20 > 0 & map[current_pos - 20] != 5)
								current_pos <= current_pos - 20;
						end
						`DOWN: begin //down
							if(current_pos + 20 < 400 & map[current_pos + 20] != 5)
								current_pos <= current_pos + 20;
						end
						endcase
					end
					else begin
						run_failed <= 1;
					end

				end												
				16'hA: begin //no shroud
					no_shroud <= !no_shroud;
					$display("No shroud");
				end
				16'hB: begin
					help_requested <= 1;
				end
				`OK: begin
					
				end											
			endcase
			eip <= eip + 1;
		end
		else begin
			$readmemh("input.data",input_data);
		end
		if(display_queued |help_requested) begin

			if(!new_command)
				display_queued <= 0; 
			f = $fopen("output.data");
			
			if(run_failed) begin
				$display("RUN FAILED");
				run_failed <= 0;
			end
			for(j = 0; j < 20; j = j + 1) begin
				$display("\n");
			end
			if(help_requested) begin
				$display("\n~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~");
				$display("                                              HELP");
				$display("");
				$display("Welcome to > VeRiPG: Day of Proxies < !");
				$display("VeRiPG is a text-based RPG created using Verilog, a hardware simulation language.");
				$display("Playing is very simple. At each turn, the map is displayed and a list of allowed commands are listed below.");
				$display("The goal is to navigate your player to the exit, all the while leveling your character and staying alive.");
				$display("Though the maps are preloaded, the user is free to modify the map files as they wish. Have fun!");
				$display("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n");				
			end
			else if(on_enemy) begin //draw enemy if reached enemy
				 $display("\n~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~");
				 $display("               EVENT: You have encountered an enemy!");
				 $display("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n");
				 $display("                   ,===:'.,            `-._ \n                    `:.`---.__         `-._   \n                      `:.     `--.         `.   \n                        \\.        `.         `.   \n                (,,(,    \\.         `.   ____,-`.,  \n             (,'     `/   \\.   ,--.___`.'   \n         ,  ,'  ,--.  `,   \\.;'         `   \n          `{D, {    \\  :    \\;   \n            V,,'    /  /    //   \n            j;;    /  ,' ,-//.    ,---.      ,  \n            \\;'   /  ,' /  _  \\  /  _  \\   ,'/  \n                  \\   `'  / \\  `'  / \\  `.' /   \n                   `.___,'   `.__,'   `.__,'  	\n"         );
			end
			else begin
				 $display("\n~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~");
				 $display("               MAP: Dungeon of Illore");
				 $display("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n");
				for(i = 0; i < 20; i = i + 1) begin
					$write("");
					for(j = 0; j < 20; j = j + 1) begin
						if(current_pos == i*20 + j) begin
							$write("! " );
						end
						else if(bitmap[i*20 + j] == 0 && no_shroud == 0) begin
							$write("? " );
						end
						else begin
							case(map[i*20 + j])
								`CURRENT: begin
									$write("! ");
								end
								`ENTRANCE: begin
									$write("< ");
								end
								`EXIT: begin
									$write("> ");
								end		
								`BLANK: begin
									$write("  ");
								end
								`WALL: begin
									$write("X ");
								end	
								`ENEMY: begin
									$write("@ ");
								end	
								`WEAPON: begin
									$write("@ ");
								end																											
							endcase							
						end
					end
					$display("");
				end
			end
			$write("\nHP: [%d/%d]\n", player_health, player_max_health);
			if(on_enemy) begin
				$write("\nEnemy HP: [%d/%d]", player_health, player_max_health);
			end
			/* Writing allowed commands */
			$display("\n");
			if(!help_requested & can_move & !on_enemy)
				$write("[1] - Right    [2] - Left    [3] - Up    [4] - Down    ");
			if(!help_requested & on_enemy)
				$write("[5] - Attack    [6] - Run    ");
			if(!help_requested & can_hacks)
				$write("[A] - No shroud    ");
			if(!help_requested)
				$write("[B] - HELP    ");
			if(help_requested)	
				$write("[C] - OK    ");
			$display("\n");
			$fclose(f);
		end
	end


endmodule