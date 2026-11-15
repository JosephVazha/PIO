module top #(
   parameter int NUM_SM = 4,
   parameter int NUM_GPIO = 32,
   parameter int DATA_WIDTH = 32,
   parameter int INSTR_WIDTH = 16,
   
   parameter int FIFO_DEPTH = 4,
   parameter int ADDR_WIDTH = 5
   
   )(
   
   input logic clock,
   input logic rst,
   
   input logic bus_wr_en,
   input logic bus_r_en,
   
   input logic [15:0] bus_addr,
   input logic [31:0] bus_wdata,
   
   output logic bus_ready,
   
   input logic [NUM_GPIO-1:0] gpio_in,
   output logic [NUM_GPIO-1:0] gpio_out,
   output logic [NUM_GPIO-1:0] gpio_out_en,

   output logic [NUM_SM-1:0] sm_enable,
   output logic [NUM_SM-1:0] sm_budy
   );
   
   
