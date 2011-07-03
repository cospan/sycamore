//uart_top_tb.v

module uart_top_tb; 

	reg clk = 0;
	reg rst = 0;

	//uart_input_handler_signals
	reg [7:0] 	stimulus_in_byte;
	reg			stimulus_rx_en;
	wire [31:0]	command_input;
	wire [31:0] address_input;
	wire [31:0]	data_input;

	wire input_ready;


	
	uart_input_handler uih (
		.clk(clk),
		.rst(rst),
		.byte_available(stimulus_rx_en),
		.byte(stimulus_in_byte),
		.command(command_input),
		.address(address_input),
		.data(data_input),
		.ready(input_ready)
	);

	//uart_output handler_signals
	wire [7:0] 	out_byte;
	wire		oh_finished;
//	reg [31:0]	stimulus_status;
//	reg [31:0] 	stimulus_address;
//	reg [31:0] 	stimulus_data;
//	reg 		stimulus_send_en;

	wire [31:0]	status_out;
	wire [31:0]	address_out;
	wire [31:0]	data_out;
	wire		oh_send_en;
	reg			stimulus_uart_ready;
	wire		oh_ready;
	wire		uart_byte_en;

	integer		count;
	uart_output_handler uoh (
		.clk(clk),
		.rst(rst),
		.byte(out_byte),
//		.status(stimulus_status),
//		.address(stimulus_address),
//		.data(stimulus_data),
//		.send_en(stimulus_send_en),
		.status(status_out),
		.address(address_out),
		.data(data_out),
		.send_en(oh_send_en),
		.uart_ready(stimulus_uart_ready),
		.handler_ready(oh_ready),
		.uart_byte_en(uart_byte_en),
		.finished(oh_finished)
	);


	wishbone_master wm (
		.clk(clk),
		.rst(rst),
		.in_ready(input_ready),
		.in_command(command_input),
		.in_address(address_input),
		.in_data(data_input),
		.out_ready(oh_ready),
		.out_en(oh_send_en),
		.out_status(status_out),
		.out_address(address_out),
		.out_data(data_out)
		);

	integer fd_in;
	integer fd_out;
	integer ch = 0;

	always #1 clk = ~clk;
	
	initial begin

		ch 		= 0;

		$dumpfile ("design.vcd");
		$dumpvars (0, uart_top_tb);
		$dumpvars (0, uih);
		$dumpvars (0, uoh);
		fd_in = $fopen ("uart/uart_input_data.txt", "r");
		//fd_out = $fopen ("uart/uart_output_data.txt", "r");

			rst 					<= 0;	
		#5
			rst 					<= 1;
			stimulus_in_byte		<= 0;
			stimulus_rx_en			<= 0;
			stimulus_uart_ready		<= 1;
			//stimulus_send_en		<= 0;
			//stimulus_status			<= 8'h0;
			//stimulus_address		<= 8'h0;
			//stimulus_data			<= 8'h0;
			
		#5
			rst 					<= 0;
		#5

		//testing input
		if (fd_in == 0) begin
			$display("uart_input_data.txt was not found");
			
		end	
		else begin
			ch = $fgetc(fd_in);
			while (ch != -1) begin
				stimulus_in_byte 	<= ch;
				stimulus_rx_en		<= 1;

				#5
				stimulus_rx_en		<= 0;

				#5
				ch = $fgetc(fd_in);				
			
			end
			$fclose(fd_in);
		end
	
		//testing output
		
		/*
		if (fd_out == 0) begin
			$display ("uart_output_data.txt file was not found");
		end
		else begin
			count = $fscanf(fd_out, "%h:%h:%h", stimulus_status, stimulus_address, stimulus_data);  
			#5
				stimulus_send_en	<= 1;
			#5
				stimulus_send_en 	<= 0;
			$fclose(fd_out);
		end
		*/
		#1000
		$finish;
		
	end


	initial begin
//		$monitor ("%t, in_ch:%h, ih_rdy:%h, ih_cmd:%h, ih_addr:%h, ih_data:%h", $time, stimulus_in_byte, input_ready, command_input, address_input, data_input);  
		$monitor ("%t, out_c: %c, send_en: %h, uart_en: %h: fin: %h, S:A:D : %h:%h:%h", $time, out_byte, oh_send_en, uart_byte_en, oh_finished, status_out, address_out, data_out);

		//$monitor ("%t, send_en: %h, out_c: %c", $time, oh_send_en, out_byte);
	end

	always @ (posedge clk) begin

		if (input_ready) begin
			$display ("New input data (C:A:D): %h:%h:%h", command_input, address_input, data_input);
		end
		if (oh_send_en) begin
			$display ("output ready: (S:A:D): %h:%h:%h", status_out, address_out, data_out);
		end
	end
endmodule
