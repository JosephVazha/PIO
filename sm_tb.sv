
`timescale 1ns/1ps

module tb_upio_sm;


    localparam int DATA_WIDTH = 32;
    localparam int NUM_GPIO   = 32;
    localparam int PC_WIDTH   = 8;
    
    logic clk;
    logic rst_n;
    logic enable;

    logic [31:0] instruction;
    logic [PC_WIDTH-1:0] pc;


    logic [NUM_GPIO-1:0] gpio_in;
    logic [NUM_GPIO-1:0] gpio_out;


    upio_sm #(
        .DATA_WIDTH(DATA_WIDTH),
        .NUM_GPIO(NUM_GPIO),
        .PC_WIDTH(PC_WIDTH)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .enable(enable),
        .instruction(instruction),
        .pc(pc),
        .gpio_in(gpio_in),
        .gpio_out(gpio_out)

    );

    // 50 MHz clock
    initial clk = 0;
    always #10 clk = ~clk;

    // Instruction opcodes
    localparam logic [7:0] NOP  = 8'h00;
    localparam logic [7:0] JMP  = 8'h01;
    localparam logic [7:0] SET  = 8'h02;
    localparam logic [7:0] MOV  = 8'h03;
    localparam logic [7:0] IN   = 8'h04;
    localparam logic [7:0] OUT  = 8'h05;
    localparam logic [7:0] WAIT = 8'h06;

    localparam logic [3:0] REG_X   = 4'h0;
    localparam logic [3:0] REG_Y   = 4'h1;
    localparam logic [3:0] REG_ISR = 4'h2;
    localparam logic [3:0] REG_OSR = 4'h3;
    localparam logic [3:0] REG_PINS = 4'h4;

   // Instruction encoder
    function automatic [31:0] make_instr(
        input [7:0] opcode,
        input [3:0] dest,
        input [15:0] operand,
        input [3:0] src
    );
        begin
            make_instr = {opcode, 4'b0000, dest, operand[11:0], src};
        end
    endfunction

  
    logic [31:0] i_mem [0:255];

    always_comb begin
        instruction = i_mem [pc];
    end

    task automatic tick(input integer cycles);
        repeat(cycles) @(posedge clk);
        #1;
    endtask
    task automatic check(
        input logic condition,
        input string message
    );
        if (condition)
            $display("[PASS] %s", message);
        else begin
            $error("[FAIL] %s", message);
            $fatal;
        end
    endtask

    initial begin

        $dumpfile("upio_sm.vcd");
        $dumpvars(0, tb_upio_sm);

        // Initialize
        rst_n = 0;
        enable = 0;
        gpio_in = 0;

        for (int i = 0; i < 256; i++)
            i_mem[i] = {NOP, 24'b0};

        // Program
        i_mem[0] = {NOP, 24'b0};

        // SET X, 0x1234
        i_mem[1] = {SET, 4'b0, REG_X, 12'h234, 4'b0};

        // MOV Y, X
        i_mem[2] = {MOV, 4'b0, REG_Y, 12'b0, REG_X};

        // SET GPIO, 0x000F
        i_mem[3] = {SET, 4'b0, REG_PINS, 12'h00F, 4'b0};

        // JMP 5
        i_mem[4] = {JMP, 4'b0, 4'b0, 12'h005, 4'b0};

        // NOP
        i_mem[5] = {NOP, 24'b0};

        // WAIT GPIO 0 HIGH
        i_mem[6] = {WAIT, 4'b0, 4'b0, 12'h100, 4'b0};

        // Release reset
        tick(2);
        rst_n = 1;
        enable = 1;

        // Test NOP
        tick(1);
        check(pc == 1, "NOP increments PC");

        // Test SET
        tick(1);
        check(dut.x_reg == 32'h00000234,
              "SET writes X register");

        // Test MOV
        tick(1);
        check(dut.y_reg == 32'h00000234,
              "MOV copies X into Y");

        // Test GPIO
        tick(1);
        check(gpio_out == 32'h0000000F,
              "SET writes GPIO output");

        // Test JMP
        tick(1);
        check(pc == 5, "JMP updates PC");

        // Move to WAIT instruction
        tick(1);
        check(pc == 6, "PC reaches WAIT instruction");

        // Execute WAIT with GPIO low
        gpio_in[0] = 0;
        tick(1);
        check(dut.waiting == 1,
              "WAIT stalls when GPIO condition is false");

        // Release WAIT
        gpio_in[0] = 1;
        tick(1);
        check(dut.waiting == 0,
              "WAIT exits when GPIO condition is true");

        check(pc == 7, "WAIT advances PC after condition");

        $finish;

    end

endmodule

