`timescale 1ns/1ps

module ahb_apb_bridge (

    input         hclk,
    input         hresetn,

    ////////////////////////////////////////////////////////////
    // AHB SLAVE SIDE
    ////////////////////////////////////////////////////////////
    input  [31:0] haddr,
    input         hwrite,
    input  [1:0]  htrans,
    input  [2:0]  hsize,
    input  [31:0] hwdata,

    output reg [31:0] hrdata,
    output reg        hready,
    output reg [1:0]  hresp,

    ////////////////////////////////////////////////////////////
    // APB MASTER SIDE
    ////////////////////////////////////////////////////////////
    output reg [31:0] paddr,
    output reg        pwrite,
    output reg        penable,
    output reg        psel,     // ⭐ IMPORTANT
    output reg [31:0] pwdata,

    input  [31:0] prdata,
    input         pready,
    input         pslverr
);

////////////////////////////////////////////////////////////
// PARAMETERS
////////////////////////////////////////////////////////////
parameter IDLE   = 2'b00;
parameter BUSY   = 2'b01;
parameter NONSEQ = 2'b10;
parameter SEQ    = 2'b11;

parameter OKAY  = 2'b00;
parameter ERROR = 2'b01;

////////////////////////////////////////////////////////////
// STATES
////////////////////////////////////////////////////////////
parameter S_IDLE   = 2'd0;
parameter S_SETUP  = 2'd1;
parameter S_ENABLE = 2'd2;

reg [1:0] state, next_state;

////////////////////////////////////////////////////////////
// LATCHED SIGNALS (PIPELINE BREAK)
////////////////////////////////////////////////////////////
reg [31:0] addr_reg;
reg        write_reg;
reg [31:0] wdata_reg;
reg [2:0]  size_reg;

////////////////////////////////////////////////////////////
// VALID TRANSFER DETECTION
////////////////////////////////////////////////////////////
wire valid_transfer;
assign valid_transfer = (htrans == NONSEQ) || (htrans == SEQ);

////////////////////////////////////////////////////////////
// NEXT STATE LOGIC
////////////////////////////////////////////////////////////
always @(*) begin
    case (state)

        S_IDLE:
            if (valid_transfer)
                next_state = S_SETUP;
            else
                next_state = S_IDLE;

        S_SETUP:
            next_state = S_ENABLE;

        S_ENABLE:
            if (pready)
                next_state = S_IDLE;
            else
                next_state = S_ENABLE;

        default:
            next_state = S_IDLE;
    endcase
end

////////////////////////////////////////////////////////////
// SEQUENTIAL LOGIC
////////////////////////////////////////////////////////////
always @(posedge hclk or negedge hresetn) begin
    if (!hresetn) begin
        state   <= S_IDLE;

        // AHB outputs
        hrdata  <= 32'd0;
        hready  <= 1'b1;
        hresp   <= OKAY;

        // APB outputs
        paddr   <= 32'd0;
        pwrite  <= 1'b0;
        penable <= 1'b0;
        psel    <= 1'b0;
        pwdata  <= 32'd0;

        // internal
        addr_reg  <= 0;
        write_reg <= 0;
        wdata_reg <= 0;
        size_reg  <= 0;
    end
    else begin

        state <= next_state;

        case (state)

        ////////////////////////////////////////////////////
        // IDLE
        ////////////////////////////////////////////////////
        S_IDLE: begin
            psel    <= 0;
            penable <= 0;
            hready  <= 1;
            hresp   <= OKAY;

            if (valid_transfer) begin
                ////////////////////////////////////////////////////
                // LATCH AHB ADDRESS PHASE
                ////////////////////////////////////////////////////
                addr_reg  <= haddr;
                write_reg <= hwrite;
                size_reg  <= hsize;

                hready <= 0; // stall AHB
            end
        end

        ////////////////////////////////////////////////////
        // SETUP (APB SETUP PHASE)
        ////////////////////////////////////////////////////
        S_SETUP: begin
            paddr  <= addr_reg;
            pwrite <= write_reg;
            pwdata <= hwdata;   // data phase aligned

            psel   <= 1;
            penable<= 0;

            hready <= 0;
        end

        ////////////////////////////////////////////////////
        // ENABLE (APB ACCESS PHASE)
        ////////////////////////////////////////////////////
        S_ENABLE: begin
            penable <= 1;

            if (pready) begin
                ////////////////////////////////////////////////////
                // COMPLETE TRANSFER
                ////////////////////////////////////////////////////
                psel    <= 0;
                penable <= 0;
                hready  <= 1;

                ////////////////////////////////////////////////////
                // READ DATA
                ////////////////////////////////////////////////////
                if (!write_reg)
                    hrdata <= prdata;

                ////////////////////////////////////////////////////
                // ERROR HANDLING
                ////////////////////////////////////////////////////
                if (pslverr)
                    hresp <= ERROR;
                else
                    hresp <= OKAY;
            end
            else begin
                hready <= 0; // wait
            end
        end

        endcase
    end
end

endmodule
