`timescale 1s/1ms    


/* Map IDs */
`define UNKNOWN 0
`define CURRENT 1
`define ENTRANCE 2
`define MAP_EXIT 3
`define BLANK 4
`define WALL 5
`define ENEMY 6  //gets mapped to a random enemy
`define WEAPON 7 //gets mapped to a random weapon
`define ITEM 8 //gets mapped to a random item

/* Weapon and ITEM IDs - reserved 10-20*/
`define HEALTH_PACK 10
`define HEALTH_PACK_2 11
`define HEALTH_PACK_3 12
`define CLUB 13
`define KNIFE 14
`define RUSTY_SWORD 15
`define EXCALIBUR 16
`define EXP_BOOST 17 //random percentage boost
`define ITEM_6 18
`define ITEM_7 19
`define ITEM_8 20

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
`define INVENTORY 16'hD
`define EXIT 16'hF
`define CANCEL_WINDOW 16'h10;


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
		for(i = 0; i < 20; i = i + 1) begin /* Initialized bit map to 0 */
			for(j = 0; j < 20; j = j + 1) begin
				bitmap[i*20 + j] = 0;		
			end
		end
		for(j = 0; j < 16; j = j + 1) begin
			inventory_bitmap[j] = 0;	
			inventory[j] = 0;	
		end
		counter = 0;
		for(i = 0;i < 400; i = i+1) begin
			enemy_map[i][39:32] <= (i%10); //type		
			enemy_map[i][31:24] <= 40 + (i%25); //health
			enemy_map[i][23:16] <= 40 + (i%25); //max health	
			enemy_map[i][15:8] <= 7 + (i%3); //damage		
			enemy_map[i][7:0] <= `ITEM; //drop	
		end
		counter = 0;
		for(i = 0;i < 400; i = i+1) begin

			item_map[i][15:8] <= (i%3) +1; //item count
			/*item_map[i][7:0] <= 10 + (i%7); //item type	*/
			item_map[i][7:0] <= 10 + (i%8); //item type	
			$display("assigning item %d with count", 10 + (i%8), i%3 + 1);
		end	
		weapon_damage_map[`CLUB] <= 10;
		weapon_damage_map[`KNIFE] <= 15;
		weapon_damage_map[`RUSTY_SWORD] <= 20;
		weapon_damage_map[`EXCALIBUR] <= 255;	
	end



	/* Debug values - GTKWAVE files become huge*/
	wire[3:0] current_val = map_data[0][79:76];
	wire[3:0] current_val2 = map_data[1][75:72];

	/* Multi-purpose values - Saves wire clutter*/
	integer f, number;
	reg[9:0]i; 
	reg[7:0]j;
	reg[7:0]counter;
	reg[7:0]variable;

	reg[7:0]num_weapons = 4;

	/* Enemy logic */ //4 bit for type, 8 bit for health, 8 bit for max health, 8 bit for damage, 4 bit for item drop
	reg [39:0]enemy_map[0:1000]; //map of enemies
	wire is_current_enemy = !(^current_enemy === 1'bx);
	wire [39:0]current_enemy = enemy_map[current_pos];
	wire [7:0]current_enemy_type = current_enemy[39:32];
	wire [7:0]current_enemy_health = current_enemy[31:24];
	wire [7:0]current_enemy_max_health = current_enemy[23:16];
	wire [7:0]current_enemy_damage = current_enemy[15:8];
	wire [7:0]current_enemy_drop = current_enemy[7:0];

	/* Item logic */
	reg [15:0]item_map[0:1000]; //map of enemies
	wire [31:0]current_item = item_map[current_pos];
	wire[7:0]current_item_type = current_item[7:0];
	wire[7:0]current_item_count = current_item[15:8];
	reg[7:0]weapon_damage_map[0:400];

	/* Map information */
	reg [15:0]current_pos = 190;
	wire[15:0]x_coord = current_pos % 20;
	wire[15:0]y_coord = (current_pos - (current_pos % 20)) / 20;
	wire left_clear = (current_pos - 1 > 0 && (current_pos - 1) % 20 < current_pos % 20);
	wire left_2_clear = (current_pos - 2 > 0 && (current_pos - 2) % 20 < current_pos % 20);
	wire right_clear = (current_pos + 1 < 400 && (current_pos + 1) % 20 > current_pos % 20);
	wire right_2_clear = (current_pos + 2 < 400 && (current_pos + 2) % 20 > current_pos % 20);
	wire top_clear = (current_pos - 20 > 0);
	wire top_2_clear = (current_pos - 40 > 0);
	wire bottom_clear = (current_pos + 20 < 400);
	wire bottom_2_clear = (current_pos + 40 < 400);
	reg[15:0]map_size = 9;
	wire[15:0]map_constant = (map_size - 1) / 2;
	reg[15:0]max_enemies = 7;
	reg[15:0]current_enemies = 0;


	/* Player information */
	reg [15:0]player_health = 100;
	reg [15:0]player_max_health = 100;
	wire [15:0]player_health_ratio = (player_health * 10 / player_max_health);
	reg [15:0]player_level = 1;
	reg[8:0]player_damage = 0;
	wire[7:0]player_total_damage = player_damage + player_weapon_damage;
	reg[7:0]player_weapon_damage = 10;
	reg[15:0]player_exp = 0;
	wire[15:0]player_next_exp = player_level * player_level + 50;
	reg[15:0]inventory[0:7]; //16 inventory slots
	reg[0:7]inventory_bitmap;
	reg[7:0]player_weapon = `CLUB;

	/* Game data */
	wire on_enemy = map[current_pos] == `ENEMY;
	wire on_item = map[current_pos] == `ITEM;
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
	reg booting = 1;

	/* Random logic - random simulated by current clock cycle*/
	reg[15:0] random_weapon = 10;
	reg[15:0] random_enemy = 20;
	reg[15:0] random_3 = 0;
	reg[15:0] random_4 = 0;
	reg[15:0] random_10 = 0;
	reg[15:0] random_50 = 0;
	reg help_requested = 0;
	reg inventory_requested = 0;
	reg use_inventory_input = 0;
	reg[2:0] current_random = 0;
	reg[2:0] run_random = 0;
	reg[15:0] random_400 = 0;

	/* Game constants */
	reg[15:0] enemy_health_modifier = 20;
	reg[15:0] enemy_damage_modifier = 3;

	always @(posedge clk) begin
			
			
		if(booting) begin
			$display("Testing out location 196 %x", enemy_map[196][39:32]);
			$display("Testing out location 196 full %x", enemy_map[196]);
			booting <= 0;
		end

		//$display("Testing out location 196 fukll %x", enemy_map[i*20+j]);


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
		if(random_50 == 49)
			random_50 <= 0;
		else 
			random_50 <= random_50 + 1;	
		if(random_400 == 399)
			random_400 <= 0;
		else 
			random_400 <= random_400 + 1;						
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
		else if(inventory_requested)
			inventory_requested <= 0;
		else if(on_item) begin
			map[current_pos] <= `BLANK;
			$display("count is %d", current_item_count);

			for(j = 0; j < current_item_count; j = j+1) begin
				for(i = 0; i < 16; i = i+1) begin
					if(inventory[i] == 0) begin
						$display("On item with type %d and count %d\n", current_item_type, current_item_count);
						
						inventory[i][7:0] = current_item_type;
						i = 16;
					end
				end				
			end
		end
		else if(new_command) begin //prints out current information
			$display("Number of enemies %d", current_enemies);
			if(random_10 < 2 & current_enemies < max_enemies) begin //spawning enemies
				if(map[random_400] == `BLANK) begin
					map[random_400] <= `ENEMY;
					current_enemies <= current_enemies + 1;
					enemy_map[random_400][39:32] <= (random_400%10); //type		
					enemy_map[random_400][31:24] <= (40 + 10 * player_level * player_level + (random_400%25)); //health
					$display("attempting to assign health: %d to %d", 25 + (random_400%25), random_400);
					enemy_map[random_400][23:16] <= 40 + 10 * player_level * player_level  + (random_400%25); //max health	
					enemy_map[random_400][15:8] <= 5 + 2 * player_level + (random_400%3); //damage		
					enemy_map[random_400][7:0] <= `ITEM; //drop	
				end
			end
			if(random_10 > 2 & random_10 < 5) begin //spawning items
				if(map[random_400] == `BLANK) begin
					map[random_400] <= `ITEM;
					item_map[random_400][7:0] <= 10 + (random_400%8); //type		
					item_map[random_400][15:8] <= random_400 % 3;
					$display("attempting to assign health: %d to %d", 25 + (random_400%25), random_400);
				end
			end
			display_queued <= 1;
			$display("current pos is %d\n", map[current_pos]);
			if(on_enemy) begin //if fighting an enemy

				if(player_health <= current_enemy_damage) begin
					$display("\n\nOh no! You have died. You finished the game at level %d! Better luck next time.", player_level);
					$display("Plans to implement respawning later...");
					$finish;
				end
				else begin
					player_health <= player_health - current_enemy_damage;
				end
				
			end
			else if(on_item) begin
				//$finish;
				//$display("On item with type %d\n", current_item_type);

			end
			$display("current command: %d", current_command);
			if(use_inventory_input) begin //item logic
				if(inventory[input_data[eip]] != 0) begin //use the item
					case(inventory[input_data[eip]])
						`HEALTH_PACK: begin
							if(player_health + player_max_health/10 > player_max_health)
								player_health <= player_max_health;
							else begin
								player_health <= player_health + player_max_health/10;
							end
						end
						`HEALTH_PACK_2: begin
							if(player_health + player_max_health/7 > player_max_health)
								player_health <= player_max_health;
							else begin
								player_health <= player_health + player_max_health/7;
							end
						end		
						`HEALTH_PACK_3: begin
							if(player_health + player_max_health/5 > player_max_health)
								player_health <= player_max_health;
							else begin
								player_health <= player_health + player_max_health/5;
							end
						end
						`EXP_BOOST: begin
							if(player_exp + player_next_exp/2 >= player_next_exp) begin //level up
								player_exp <= player_exp + player_next_exp/2 - player_next_exp; //exp proportional to enemy hp
								player_level <= player_level + 1;
								player_damage <= player_damage + player_level * 4;
								player_max_health <= player_max_health + player_level * 10;
								player_health <= player_health + player_level * 10;
								current_enemies <= current_enemies - 1;
							end
							else begin
								player_exp <= player_exp + player_next_exp/2;
							end
						end	
					endcase
					if(inventory[input_data[eip]] > 12 & inventory[input_data[eip]] < 18) begin //weapon range
						player_weapon <= inventory[input_data[eip]];
						player_weapon_damage <= weapon_damage_map[inventory[input_data[eip]]];
						for(i = 0; i < 16; i = i+1) begin
							if(inventory[i] == 0) begin
								$display("On item with type %d and count %d\n", current_item_type, current_item_count);
								inventory[i][7:0] <= player_weapon;
								i = 16;
							end
						end									
					end

					inventory[input_data[eip]] = 0;
				end
				use_inventory_input <= 0;
			end
			else begin
				case(input_data[eip])
					/*16'h10: begin //why does `CANCEL_WINDOW not work??
						//do nothing
					end*/
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
						if(enemy_map[current_pos][31:24] < player_total_damage + 1) begin //if kill, remove and update
							enemy_map[current_pos] <= 0;
							map[current_pos] <= `BLANK;
							if(player_exp + enemy_map[current_pos][23:16] >= player_next_exp) begin //level up
								player_exp <= player_exp + enemy_map[current_pos][23:16] - player_next_exp; //exp proportional to enemy hp
								player_level <= player_level + 1;
								player_damage <= player_damage + player_level * 4;
								player_max_health <= player_max_health + player_level * 10;
								player_health <= player_health + player_level * 10;
								current_enemies <= current_enemies - 1;
							end
							else begin
								player_exp <= player_exp +  enemy_map[current_pos][23:16];
							end
						end
						else
							enemy_map[current_pos][31:24] <= enemy_map[current_pos][31:24] - player_total_damage;
	 				end	
					`EXIT: begin 
						$finish;
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
					`NO_SHROUD: begin //no shroud
						no_shroud <= !no_shroud;
						$display("No shroud");
					end
					`HELP: begin
						help_requested <= 1;
					end
					`INVENTORY: begin
						inventory_requested <= 1;
					end				
					`OK: begin
						$display("ok");
					end


				endcase
				if(input_data[eip] == `INVENTORY) begin
					use_inventory_input <= 1;
				end				
				else begin
					use_inventory_input <= 0;
				end
			end

			eip <= eip + 1;
		end
		else begin
			$readmemh("input.data",input_data);
		end
		if(display_queued |help_requested) begin

			if(!new_command)
				display_queued <= 0; 
			
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
				$display("Though the maps are preloaded, the user is free to modify the map files as they wish. Have fun!\n");
				$display("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n");				
			end
			if(inventory_requested) begin //printing inventory
				$display("____________________________________________________________________________________________________"); 
				$display("  [ I N V E N T O R Y ]");
				$display("   ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯");
				for(i = 0; i < 5; i = i+1) begin
					for(j = 0; j < 3; j = j+1) begin
						variable = j + i*3;
						$write("[%x] ", variable[4:0]);
						case(inventory[variable])
							`HEALTH_PACK: begin
								$write("Health potion    ");
							end
							`HEALTH_PACK_2: begin
								$write("Health potion II ");
							end
							`HEALTH_PACK_3: begin
								$write("Health potion III");
							end
							`CLUB: begin
								$write("Club             ");
							end							
							`KNIFE: begin
								$write("Knife            ");
							end						
							`RUSTY_SWORD: begin
								$write("Rusty sword      ");
							end
							`EXCALIBUR: begin
								$write("Excalibur        ");
							end
							`EXP_BOOST: begin
								$write("EXP boost        ");
							end
							default:
								$write("                 ");
						endcase

						$write("    ");
					end
					$display("");
				end		
			end			
			else if(on_enemy) begin //draw enemy if reached enemy
				$display("\n~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~");
				$display("               EVENT: You have encountered an enemy!");
				$display("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n");
				$display("                   ,===:'.,            `-._ \n                    `:.`---.__         `-._   \n                      `:.     `--.         `.   \n                        \\.        `.         `.   \n                (,,(,    \\.         `.   ____,-`.,  \n             (,'     `/   \\.   ,--.___`.'   \n         ,  ,'  ,--.  `,   \\.;'         `   \n          `{D, {    \\  :    \\;   \n            V,,'    /  /    //   \n            j;;    /  ,' ,-//.    ,---.      ,  \n            \\;'   /  ,' /  _  \\  /  _  \\   ,'/  \n                  \\   `'  / \\  `'  / \\  `.' /   \n                   `.___,'   `.__,'   `.__,'  	\n"         );
				$display("\n");
				$display("\nEnemy HP: [%d/%d]        Enemy dmg: [%d]", current_enemy_health, current_enemy_max_health, current_enemy_damage);
			end
			else begin
				 //$display("\n        ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~");
				 $display("\n____________________________________________________________________________________________________");
				 $display("  [M A P:  A S H U S H A T ]");
				 $display("   ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯");
				 //$display("____________________________________________________________________________________________________");
				 //$display("        ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n");
				//for(i = 0; i < 20; i = i + 1) begin
					//$write("                            ");
/*					for(j = 0; j < 20; j = j + 1) begin
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
									//$write("\nenemy type %d ", 20);
									//$write("%x ", enemy_map[i*20+j][35:32]);
									$write("@ ");
									//$write("\nlocation: %d ", i*20 + j);
								end	
								`WEAPON: begin
									$write("# ");
								end																											
							endcase							
						end
					end*/
				//$write("Attempting to print map with coords ");
				$write("              ____________________ \n");
				for(i = 0; i < map_size + 1; i = i + 1) begin
					$write("             |");	
					for(j = 0; j < map_size + 1; j = j + 1) begin
						if(y_coord - map_constant + i < 0| y_coord - map_constant + i > 19 | x_coord - map_constant + j < 0| x_coord - map_constant + j > 19)
							$write("▄ " );
						else if(current_pos == (y_coord - map_constant + i) * 20 + (x_coord - map_constant + j)) begin
							$write("P " );
						end
						else if(bitmap[(y_coord - map_constant + i) * 20 + (x_coord - map_constant + j)] == 0 && no_shroud == 0) begin
							$write("? " );
						end
						else begin
							case(map[(y_coord - map_constant + i) * 20 + (x_coord - map_constant + j)])
								`CURRENT: begin
									$write("☺ ");
								end
								`ENTRANCE: begin
									$write("< ");
								end
								`MAP_EXIT: begin
									$write("> ");
								end		
								`BLANK: begin
									$write("  ");
								end
								`WALL: begin
									$write("▄ ");
								end	
								`ENEMY: begin
									$write("E ");
								end	
								`ITEM: begin
									$write("I ");
								end
								default: begin
									$write("%d ", map[(y_coord - map_constant + i) * 20 + (x_coord - map_constant + j)]);
								end																											
							endcase							
						end
					end
					$display("|");
				end
				$write("              ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯ \n");
			end
			$display("____________________________________________________________________________________________________"); 
			$display("  [ P L A Y E R   S T A T S ]");
			$display("   ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯");
			$display("    Level: [%d]       HP: [%d/%d]        Damage: [%d]    ", player_level, player_health, player_max_health, player_total_damage);
			$write("\n    EXP: [%d/%d]   Weapon: [", player_exp, player_next_exp);
			case(player_weapon)
				`CLUB: begin
					$write("Club]           ");
				end
				`KNIFE: begin
					$write("Knife]          ");
				end
				`RUSTY_SWORD: begin
					$write("Rusty Sword]    ");
				end
				`EXCALIBUR: begin
					$write("Excalibur]      ");
				end
			endcase
			$write("Weapon Damage: [%d]   ", player_weapon_damage);
			$display("\n");
			$display("____________________________________________________________________________________________________");                                              
			
			/* Writing allowed commands */
			$display("  [ C O M M A N D S ]");
			$display("   ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯");
			if(inventory_requested)
				$write("[0-F] - Use corresponding inventory item    \n");
			if(!help_requested & can_move & !on_enemy & !inventory_requested)
				$write("[1] - Right        [2] - Left         [3] - Up           [4] - Down    \n");
			if(!help_requested & on_enemy & !inventory_requested)
				$write("[5] - Attack    [6] - Run    ");
			if(!help_requested & can_hacks & !inventory_requested)
				$write("[A] - No shroud    ");
			if(!help_requested)
				$write("[B] - Help         ");
			if(help_requested | inventory_requested)	
				$write("[C] - Ok           ");
			if(!inventory_requested & !help_requested & !on_enemy)	
				$write("[D] - Inventory    ");	
			$write("[F] - Exit    ");
			if(inventory_requested)
				$write("[10] - Cancel      ");
			$display("\n____________________________________________________________________________________________________");   
		end
	end


endmodule