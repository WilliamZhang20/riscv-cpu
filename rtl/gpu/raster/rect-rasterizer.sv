// Rectangle rasterizer front-end (next split step).
//
// Current status: `axi4_span_writer` (rtl/gpu/memory/axi4-span-writer.sv,
// still named `axi4_fill_engine`) owns rect iteration + AXI4 burst writes,
// driven directly by `primitive_gpu_2d` in rtl/gpu/gpu.sv.
//
// Next: extract rect walk (x/y/width/height -> span descriptors) here as
// `rect_rasterizer`, leaving `axi4_span_writer` as a pure span/burst writer.
// `triangle-rasterizer.sv` comes after that.
module rect_rasterizer #(
    parameter int unsigned ADDR_W = 32,
    parameter int unsigned DATA_W = 32
) (
    input  logic             clk,
    input  logic             rst_n,
    input  logic             start,
    input  logic [15:0]      x,
    input  logic [15:0]      y,
    input  logic [15:0]      width,
    input  logic [15:0]      height,
    output logic             busy,
    output logic             done,
    output logic             error,
    // Span descriptor stream toward axi4_span_writer (TODO: define).
    output logic             span_valid,
    input  logic             span_ready,
    output logic [ADDR_W-1:0] span_base_off,
    output logic [15:0]      span_len
);
  // TODO: move row/col walk out of axi4_fill_engine.
  assign busy = 1'b0;
  assign done = 1'b0;
  assign error = 1'b0;
  assign span_valid = 1'b0;
  assign span_base_off = '0;
  assign span_len = '0;
endmodule : rect_rasterizer
