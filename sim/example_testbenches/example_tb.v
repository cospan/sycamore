//example_tb.v

module example_tb; 

	reg clk = 0;
	reg rst = 0;

	reg [7:0] stimulus_in_byte;
	wire [7:0] stimulus_out_byte;


	integer fd;
	integer ch;
	integer more;

	always #1 clk = ~clk;
	
	initial begin

		ch 		= 0;
		more	= 1;

		$dumpfile ("design.vcd");
		$dumpvars (0, example_tb);
//		$dumpvars (0, <sub modules);
		fd = $fopen ("example_testbenches/example_input_data.txt", "r");


		#5
			rst = 1;
		#5
			rst = 0;
		#5

	//	$monitor (ch);
		if (fd == 0) begin
			$display("file was not found\n");
			
		end	
		else begin

			ch = $fgetc(fd);
			while (ch != -1) begin
				$display("found %d", ch);
				ch = $fgetc(fd);				
			end
			$fclose(fd);
		end
		$finish;
	end
endmodule
