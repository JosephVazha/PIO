module upio_sm #(
    parameter int DATA_WIDTH = 32,
    parameter int NUM_GPIO   = 32,
    parameter int PC_WIDTH   = 8
)(
    input  logic                  clk,
    input  logic                  rst_n,

    input  logic                  enable,

    input  logic [31:0]           instruction,
    output logic [PC_WIDTH-1:0]   pc,

 
    input  logic [31:0]   gpio_in,
    output logic [31:0]   gpio_out
);
  //opcode in [31:24].
    typedef enum logic [7:0] {
        NOP = 8'h00,
        JMP = 8'h01,
        SET = 8'h02,
        MOV = 8'h03,
        IN = 8'h04,
        OUT = 8'h05,
        WAIT = 8'h06
    } opcode_t;

   // Registers
//ADD AN ARRAY?
    typedef enum logic [3:0] {
        REG_X = 4'h0,
        REG_Y = 4'h1,
        REG_ISR = 4'h2,
        REG_OSR = 4'h3,
        REG_PINS = 4'h4
    } register_t;

    logic [7:0]  opcode;
    logic [3:0]  flags;
    logic [3:0]  dest, src;
    logic [15:0] operand;

    // decoder
    assign opcode = instruction[31:24];
    assign flags = instruction[23:20];
    assign dest = instruction[19:16];
    assign src = instruction[3:0];    
    assign operand = instruction[15:0];
    

    logic [DATA_WIDTH-1:0] x_reg;
    logic [DATA_WIDTH-1:0] y_reg;

    
    logic [DATA_WIDTH-1:0] isr;

    
    logic [DATA_WIDTH-1:0] osr;

    
    logic [DATA_WIDTH-1:0] source_data;    

    
    logic waiting;

    
    logic wait_condition;

    always_comb begin
        source_data = '0;

        case (src)
            REG_X: source_data = x_reg;
            REG_Y: source_data = y_reg;
            REG_ISR: source_data = isr;
            REG_OSR: source_data = osr;
            REG_PINS: source_data = gpio_in;
            default: source_data = '0;
        endcase
    end

    always_ff @(posedge clk or negedge rst_n) begin

        // Reset all internal state.
        if (!rst_n) begin

            pc           <= '0;
            x_reg        <= '0;
            y_reg        <= '0;
            isr          <= '0;
            osr          <= '0;

            gpio_out     <= '0;

            waiting      <= 1'b0;
            wait_condition <= 1'b0;

        end

        else if (enable) begin

            // WAIT stalls the state machine until the
            
            if (waiting) begin

                if (gpio_in[operand[4:0]] == operand[8]) begin
                    waiting <= 1'b0;
                    pc <= pc + 1'b1;
                end

            end

            else begin

                // Default behavior: advance to next instruction.
                pc <= pc + 1'b1;

                case (opcode)
                    NOP: begin
                        // no operation.
                    end          

                    JMP: begin 
                        // jump to addr in operand
                        pc <= operand[PC_WIDTH-1:0];
                    end

                    SET: begin
                        //SET X, 100
                        // moves operand to dest register
                        case (dest)

                            REG_X:
                                x_reg <= operand;

                            REG_Y:
                                y_reg <= operand;

                            REG_PINS: 
                                gpio_out <= operand[NUM_GPIO-1:0];

                            default: begin
                                $display("Invalid dest");
                            end

                        endcase

                    end
                    
                    MOV: begin
                        //MOV X,Y
                        //moves src_data to dest reg
                        case (dest)

                            REG_X:
                                x_reg <= source_data;

                            REG_Y:
                                y_reg <= source_data;

                            REG_ISR:
                                isr <= source_data;

                            REG_OSR:
                                osr <= source_data;

                            REG_PINS:
                                gpio_out <= source_data[NUM_GPIO-1:0];

                            default: begin
                            end

                        endcase

                    end
                    
                    IN: begin
                        //moves operand[5:0] worth of input data into isr 
                       
                        isr <= {(isr << operand[5:0]) |
                            (gpio_in & ((1 << operand[5:0]) - 1))
                        };

                    end

                    
                    OUT: begin
                        
                       
                        // shift opreant [5:0] lsb to gpio outputs and then shift osr [5:0] right                      
                        gpio_out <= (gpio_out & ~(( 32'h1 << operand[5:0]) - 1)) | 
                        (osr & ((32'h1 << operand[5:0]) - 1));
                        osr <= osr >> operand[5:0];                        

                    end

       
                    WAIT: begin

                        // Wait until condition met.
                        // WAIT GPIO, 0, HIGH
                        if (gpio_in[operand[4:0]] != operand[8]) begin
                            waiting <= 1'b1;
                        end

                    end                   
                    
                  default: begin 
                        $display("Roor - Unkown isntr");
                   end

                endcase

            end

        end

    end

endmodule

