module register (
    input wire clk,
    input wire enable,
    input wire [width - 1:0] data_in,
    output reg [width - 1:0] data_out
);

    parameter width = 8;

    always @(posedge clk) begin
        if (enable) begin
            data_out <= data_in;
        end
    end

endmodule
