module apb_spi (

    input         pclk,
    input         presetn,
    input         psel,
    input         penable,
    input         pwrite,
    input  [31:0] paddr,
    input  [31:0] pwdata,

    output reg [31:0] prdata,
    output reg        pready,
    output reg        pslverr
);

    // =========================
    // INTERNAL REGISTERS
    // =========================
    reg [11:0] tx_data;
    reg        start;
    reg        cpol;
    reg        cpha;

    wire [11:0] rx_data;
    wire        done;

    // =========================
    // SPI INSTANCE
    // =========================
    spi_top spi_inst (
        .clk(pclk),
        .rst(~presetn),
        .newd(start),

        .cpol(cpol),
        .cpha(cpha),

        .master_din(tx_data),
        .slave_din(12'hA5A),   // dummy (for now)

        .master_dout(rx_data),
        .slave_dout(),         // unused
        .done(done)
    );

    // =========================
    // WRITE LOGIC
    // =========================
    always @(posedge pclk or negedge presetn) begin
        if (!presetn) begin
            tx_data <= 0;
            start   <= 0;
            cpol    <= 0;
            cpha    <= 0;
        end else begin
            if (psel && penable && pwrite) begin
                case (paddr[3:0])

                    4'h0: begin
                        tx_data <= pwdata[11:0];
                    end

                    4'h8: begin
                        cpol  <= pwdata[0];
                        cpha  <= pwdata[1];
                        start <= pwdata[2];  // trigger
                    end

                endcase
            end else begin
                start <= 0;  // pulse
            end
        end
    end

    // =========================
    // READ LOGIC
    // =========================
    always @(*) begin
        case (paddr[3:0])

            4'h4: prdata = {20'b0, rx_data};

            4'hC: prdata = {31'b0, done};

            default: prdata = 32'h0;

        endcase
    end

    // =========================
    // READY / ERROR
    // =========================
    always @(*) begin
        pready  = 1'b1;
        pslverr = 1'b0;
    end

endmodule
