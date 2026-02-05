module pipeline_register #(
    parameter int DATA_WIDTH = 32
) (
    input  logic                  clk,
    input  logic                  rst_n,

    input  logic                  in_valid,
    output logic                  in_ready,
    input  logic [DATA_WIDTH-1:0] in_data,

    output logic                  out_valid,
    input  logic                  out_ready,
    output logic [DATA_WIDTH-1:0] out_data
);

    logic [DATA_WIDTH-1:0] data_reg;
    logic                 valid_reg;

    // Handshake signals
    wire input_transfer  = in_valid && in_ready;
    wire output_transfer = out_valid && out_ready;

    assign in_ready  = ~valid_reg || output_transfer;
    assign out_valid = valid_reg;
    assign out_data  = data_reg;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_reg  <= '0;
            valid_reg <= 1'b0;
        end else begin
            case ({input_transfer, output_transfer})
                2'b00: begin
                    valid_reg <= valid_reg;
                end
                2'b01: begin
                    valid_reg <= 1'b0;
                end
                2'b10: begin
                    data_reg  <= in_data;
                    valid_reg <= 1'b1;
                end
                2'b11: begin
                    data_reg  <= in_data;
                    valid_reg <= 1'b1;
                end
            endcase
        end
    end

endmodule
