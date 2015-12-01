`timescale 1ps/1ps    

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
		//$dumpvars(1,main);
		for(i = 0; i < 10; i = i + 1) begin
			for(j = 0; j < 10; j = j + 1) begin
				case(i*10 + j)
					50: begin
						map[i*10 + j] = `ENTRANCE;
					end
					59: begin
						map[i*10 + j] = `EXIT;
					end
					default: begin
						map[i*10 + j] = 4;
					end
				endcase
				bitmap[i*10 + j] = 0;
			end
		end
		//current_pos = 50;
	end

	integer f, number;
	reg[15:0]i; //multi-purpose indices
	reg[15:0]j;
	reg[15:0]eip = 0; //command pointer
	wire clk;
	clock c0(clk);

	reg [15:0]input_data[0:99]; //Array of all command data
	reg [15:0]map[99:0]; //pseudo 10x10 2D array of 16 bit values
	reg bitmap[99:0]; //Literally a bitmap haha
	reg display_queued;

	reg [15:0]current_pos = 50;

	wire[15:0] test1 = map[0];
	wire[15:0] test_data = input_data[0];

	wire[15:0] current_command = input_data[eip];

	wire new_command = !(^input_data[eip] === 1'bx);

	wire left_clear = (current_pos - 1 > 0 && (current_pos - 1) % 10 < current_pos % 10);
	wire left_2_clear = (current_pos - 2 > 0 && (current_pos - 2) % 10 < current_pos % 10);
	wire right_clear = (current_pos + 1 < 100 && (current_pos + 1) % 10 > current_pos % 10);
	wire right_2_clear = (current_pos + 2 < 100 && (current_pos + 2) % 10 > current_pos % 10);
	wire top_clear = (current_pos - 10 > 0);
	wire top_2_clear = (current_pos - 20 > 0);
	wire bottom_clear = (current_pos + 10 < 100);
	wire bottom_2_clear = (current_pos + 20 < 100);

	always @(posedge clk) begin
		
		if(top_clear) begin
			bitmap[current_pos - 10] = 1;
			if(left_clear)
				bitmap[current_pos - 10 - 1] = 1;
			if(right_clear)
				bitmap[current_pos - 10 + 1] = 1;
		end
		if(top_2_clear)
			bitmap[current_pos - 20] = 1;			
		if(bottom_clear) begin
			bitmap[current_pos + 10] = 1;
			if(left_clear)
				bitmap[current_pos + 10 - 1] = 1;
			if(right_clear)
				bitmap[current_pos + 10 + 1] = 1;			
		end
		if(bottom_2_clear)
			bitmap[current_pos + 20] = 1;
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
					current_pos <= current_pos + 1;
				end
			endcase
			eip <= eip + 1;
		end
		else begin
			//for(i = 0; i < 30; i = i + 1)
				//$display("");
			$readmemh("input.data",input_data);
		end

		if(display_queued) begin
			if(!new_command)
				display_queued <= 0; 
			f = $fopen("output.data");
			$fdisplay(f, "= = = = = = = = = = = = = = = = = = = = =");
			$fdisplay(f, "");
			$fdisplay(f, "");
			$fdisplay(f, "          MAP          ");
			$fdisplay(f, "- - - - - - - - - - - - - -");
			$fdisplay(f, "");
			for(i = 0; i < 10; i = i + 1) begin
				$fwrite(f, "");
				for(j = 0; j < 10; j = j + 1) begin
					if(current_pos == i*10 + j) begin
						$fwrite(f, "! " );
					end
					else if(bitmap[i*10 + j] == 0) begin
						$fwrite(f, "? " );
					end
					else begin
						case(map[i*10 + j])
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

			$fdisplay(f, "");
			$fdisplay(f, "");
			$fdisplay(f, "= = = = = = = = = = = = = = = = = = = = =");
			$fclose(f);
		end
	end


endmodule