/* clock */
`timescale 1ps/1ps
module clock(output clk);
    reg theClock = 1;
    reg [15:0] counter = 0;

    assign clk = theClock;
    
    always begin
        #500;
        theClock = !theClock;
        counter = counter + 1;
        if(counter > 1000) begin
        	//$finish;
        end

    end
endmodule
