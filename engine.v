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
		$dumpfile("cpu.vcd");
		$readmemh("input.hex",input_data);
		$dumpvars(1,main);
		for(i = 0; i < 10; i = i + 1) begin
			for(j = 0; j < 10; j = j + 1) begin
				case(i*10 + j)
					50: begin
						map[i*10 + j] = `ENTRANCE;
					end
					59: begin
						map[i*10 + j] = `EXIT;
					end
					55: begin
						map[i*10 + j] = `CURRENT;
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

	reg[15:0]i;
	reg[15:0]j;
	wire clk;
	clock c0(clk);

	reg [15:0]input_data[99:0];
	reg [15:0]map[99:0]; //pseudo 10x10 2D array of 16 bit values
	reg bitmap[99:0]; //Literally a bitmap hahahahah

	reg [15:0]current_pos = 50;

	wire[15:0] test1 = map[0];

	wire[15:0] test_data = input_data[0];

	reg finished = 1;

	always @(posedge clk) begin
		
		if(current_pos - 10 > 0)
			bitmap[current_pos - 10] = 1;
		if(current_pos + 10 < 100)
			bitmap[current_pos + 10] = 1;
		if(current_pos + 1 < 100 && (current_pos + 1) % 10 > current_pos % 10)
			bitmap[current_pos + 1] = 1;
		if(current_pos - 1 > 0 && (current_pos - 1) % 10 < current_pos % 10)
			bitmap[current_pos - 1] = 1;		



		if(finished) begin
			finished <= 0;
			for(i = 0; i < 10; i = i + 1) begin
				for(j = 0; j < 10; j = j + 1) begin
					if(current_pos == i*10 + j) begin
						$write("! " );
					end
					else if(bitmap[i*10 + j] == 0) begin
						$write("? " );
					end
					else begin
						case(map[i*10 + j])

							`UNKNOWN: begin
								$write("? ");
							end
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

						endcase							
					end
				end
				$display("");
			end	


		end




	end


endmodule