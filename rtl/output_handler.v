module output_handler(
    clk,
    rst,
    buffer,
    begin_transfer,
    status,
    data_count,
    finished,
    rts,
    byte
);

input clk;
input rst;
input [255:0] buffer; //buffer of data
input begin_transfer; //tell this controller when to start
input [7:0]status; //status of the system, this gets transfered to the host
input [15:0] data_count; //from controller to indicate how many bytes to send

output reg finished; //output to the controller to indicate done with transfer
output reg rts; //ready to send (connect this up to the UART module
output reg [7:0]byte; //output byte (connect this up to the UART module



always @ (posedge clk) begin

    if (rst) begin
        finished <= 8'h0;
        rts <= 16'h00;
        byte <= 0;
    end
    else begin
        //main state machine goes here
    end
end
endmodule