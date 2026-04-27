module apb_ram (
    input        pclk,
    input        presetn,

    input        psel,
    input        penable,
    input        pwrite,

    input  [31:0] paddr,
    input  [31:0] pwdata,

    output reg [31:0] prdata,
    output reg        pready,
    output reg        pslverr
);

    // =========================
    // PARAMETERS
    // =========================
    parameter MEM_DEPTH = 32;
    parameter ADDR_WIDTH = 5;   // log2(32)
    parameter WAIT_CYCLES = 2;  // change this for wait states

    // =========================
    // MEMORY
    // =========================
    reg [31:0] mem [0:MEM_DEPTH-1];

    // =========================
    // FSM STATES (no typedef for synthesis safety)
    // =========================
    parameter IDLE  = 2'b00;
    parameter SETUP = 2'b01;
    parameter ACCESS= 2'b10;

    reg [1:0] state, next_state;

    // =========================
    // WAIT STATE COUNTER
    // =========================
    reg [3:0] wait_cnt;

    // =========================
    // ADDRESS (word aligned)
    // =========================
    wire [ADDR_WIDTH-1:0] addr;
    assign addr = paddr[ADDR_WIDTH+1:2]; // word aligned

    // =========================
    // STATE REGISTER
    // =========================
    always @(posedge pclk or negedge presetn) begin
        if (!presetn)
            state <= IDLE;
        else
            state <= next_state;
    end

    // =========================
    // NEXT STATE LOGIC
    // =========================
    always @(*) begin
        case (state)
            IDLE: begin
                if (psel)
                    next_state = SETUP;
                else
                    next_state = IDLE;
            end

            SETUP: begin
                if (psel && !penable)
                    next_state = ACCESS;
                else
                    next_state = SETUP;
            end

            ACCESS: begin
                if (pready)
                    next_state = IDLE;  // or SETUP if back-to-back
                else
                    next_state = ACCESS; // wait state
            end

            default: next_state = IDLE;
        endcase
    end

    // =========================
    // OUTPUT + DATA LOGIC
    // =========================
    integer i;

    always @(posedge pclk or negedge presetn) begin
        if (!presetn) begin
            prdata  <= 32'd0;
            pready  <= 1'b0;
            pslverr <= 1'b0;
            wait_cnt <= 0;

            for (i = 0; i < MEM_DEPTH; i = i + 1)
                mem[i] <= 32'd0;
        end
        else begin
            case (state)

                IDLE: begin
                    pready  <= 1'b0;
                    pslverr <= 1'b0;
                    wait_cnt <= 0;
                end

                SETUP: begin
                    pready <= 1'b0;
                    wait_cnt <= 0;
                end

                ACCESS: begin
                    // WAIT STATE LOGIC
                    if (wait_cnt < WAIT_CYCLES) begin
                        wait_cnt <= wait_cnt + 1;
                        pready <= 1'b0;
                    end
                    else begin
                        pready <= 1'b1;

                        // ADDRESS CHECK
                        if (addr < MEM_DEPTH) begin
                            pslverr <= 1'b0;

                            if (pwrite) begin
                                // WRITE
                                mem[addr] <= pwdata;
                            end
                            else begin
                                // READ
                                prdata <= mem[addr];
                            end
                        end
                        else begin
                            // ERROR CASE
                            pslverr <= 1'b1;
                            prdata  <= 32'hDEADBEEF;
                        end
                    end
                end

            endcase
        end
    end

endmodule
