module sha2_controller_tb;


    
    reg btn_north;
    reg clk;
    wire [7:0]led;
    reg RX;
    wire TX;

    sha2_controller DUT (
        .btn_north(btn_north),
        .clk(clk),
        .led(led),
        .RX(RX),
        .TX(TX)
    );

    parameter PERIOD = 2;
initial begin
    clk = 1'b0;
    #(PERIOD/2);
    forever
        #(PERIOD/2) clk = ~clk;
    
end

/*
initial begin
    RX = 1'b0;
    btn_north = 1'b0;
    
    #2;
    btn_north = 1'b1;
    #2; 
    btn_north = 1'b0;
end
*/


endmodule