`include "include/signals.v"
`include "basics/counter.v"

module control_unit #(
    parameter ROM_A = `"`ROMS_PATH/a.bin`",
    parameter ROM_B = `"`ROMS_PATH/b.bin`",
    parameter ROM_C = `"`ROMS_PATH/c.bin`",
    parameter ROM_D = `"`ROMS_PATH/d.bin`",
    parameter ROM_E = `"`ROMS_PATH/e.bin`",
    parameter ROM_F = `"`ROMS_PATH/f.bin`"
)(
    input wire clk,
    input wire not_clk,
    input wire reg_ir_load_override, // TODO: figure out how this thing resets
    input wire mcc_rst_override,   // TODO: figure out how this thing resets
    input wire [7:0] data,
    output wire [41:0] signals
);
wire reg_ir_load;
wire mcc_tick;
wire mcc_rst;
wire [3:0] mcc_bus;
wire [12:0] inst_bus;

reg [7:0] inst_reg;
reg [7:0] sig_a;
reg [7:0] sig_b;
reg [7:0] sig_c;
reg [7:0] sig_d;
// verilator lint_off UNUSED
reg [7:0] sig_e;
reg [7:0] sig_f;
// verilator lint_on UNUSED

reg [7:0] rom_a [(1 << 13)];
reg [7:0] rom_b [(1 << 13)];
reg [7:0] rom_c [(1 << 13)];
reg [7:0] rom_d [(1 << 13)];
reg [7:0] rom_e [(1 << 13)];
reg [7:0] rom_f [(1 << 13)];

counter #( .width(4) ) mcc (
    .clk(mcc_tick),
    .write(1'b0),
    .reset(~mcc_rst | mcc_rst_override), // mcc_rst is active low
    .countdown(1'b0),
    .in(4'b0),
    .out(mcc_bus)
);

always @(posedge reg_ir_load or posedge reg_ir_load_override) begin
    $display("loading inst_reg data = %2hh", data);
    inst_reg <= data;
end

always @(posedge not_clk) begin
    $display("loading signals from roms addr = %5hh", inst_bus);
    sig_a <= rom_a[inst_bus];
    sig_b <= rom_b[inst_bus];
    sig_c <= rom_c[inst_bus];
    sig_d <= rom_d[inst_bus];
    sig_e <= rom_e[inst_bus];
    sig_f <= rom_f[inst_bus];
end

initial begin
    $monitor("sig_a = %2hh", sig_a);
    $display("ROM_A = %s", ROM_A);
end

assign inst_bus = { 1'b0, inst_reg, mcc_bus };

assign signals[`REG_A_LOAD] = sig_a[0] & clk;
assign signals[`REG_B_LOAD] = sig_a[1] & clk;
assign signals[`ALU_OPC_4:`ALU_OPC_0] = sig_a[6:2];
assign signals[`REG_F_LOAD] = sig_a[7] & clk;

assign signals[`ALU_OUT:`REG_F_OUT] = sig_b[1:0];
assign signals[`REG_TMPH_LOAD] = sig_b[2] & clk;
assign signals[`REG_TMPL_LOAD] = sig_b[3] & clk;
assign signals[`REG_TMPH_PASS_DATA:`REG_TMPH_OUT] = sig_b[7:4];

assign signals[`PC_RST:`REG_TMPL_PASS_DATA] = sig_c[5:0];
assign signals[`PC_TICK] = sig_c[6];
assign signals[`PC_OUT] = sig_c[7];

assign signals[`STC_RST:`STC_LOAD] = sig_d[1:0];
assign signals[`STC_TICK] = sig_d[2] & clk;
assign signals[`STC_OUT:`STC_MODE] = sig_d[4:3];
assign signals[`REG_MAR_LOAD] = sig_d[5];
assign signals[`REG_MBR_LOAD] = sig_d[6];
assign signals[`MEM_OUT] = sig_d[7];

assign signals[`REG_MBR_USE_BUS:`MEM_IN] = sig_e[6:0];

assign reg_ir_load = sig_f[0] & clk;
assign signals[`REG_IR_LOAD] = reg_ir_load;
assign mcc_tick = sig_f[1] & clk;
assign signals[`MCC_TICK] = mcc_tick;
assign mcc_rst = sig_f[2];
assign signals[`MCC_RST] = mcc_rst;

// Load data into ROM, uses a plain binary file, not a text file with $memreadb/h
// format
initial begin
    integer file;
    file = $fopen(ROM_A, "rb");
    $fread(rom_a, file);
    file = $fopen(ROM_B, "rb");
    $fread(rom_b, file);
    file = $fopen(ROM_C, "rb");
    $fread(rom_c, file);
    file = $fopen(ROM_D, "rb");
    $fread(rom_d, file);
    file = $fopen(ROM_E, "rb");
    $fread(rom_e, file);
    file = $fopen(ROM_F, "rb");
    $fread(rom_f, file);
end

endmodule
