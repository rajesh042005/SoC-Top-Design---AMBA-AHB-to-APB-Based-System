module apb_i2c (

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
    reg enable;
    reg rw;
    reg [6:0] addr;
    reg [7:0] tx_data;

    wire [7:0] rx_data;

    // =========================
    // I2C INSTANCE
    // =========================
    i2c_top i2c_inst (
        .clk(pclk),
        .rst(~presetn),
        .enable(enable),
        .rw(rw),
        .addr(addr),
        .data_in(tx_data),
        .data_out(rx_data)
    );

    // =========================
    // WRITE LOGIC
    // =========================
    always @(posedge pclk or negedge presetn) begin
        if (!presetn) begin
            enable  <= 0;
            rw      <= 0;
            addr    <= 0;
            tx_data <= 0;
        end else begin
            if (psel && penable && pwrite) begin
                case (paddr[3:0])

                    4'h0: begin
                        enable <= pwdata[0];   // start
                        rw     <= pwdata[1];   // read/write
                    end

                    4'h4: addr <= pwdata[6:0];

                    4'h8: tx_data <= pwdata[7:0];

                endcase
            end else begin
                enable <= 0;  // pulse
            end
        end
    end

    // =========================
    // READ LOGIC
    // =========================
    always @(*) begin
        case (paddr[3:0])

            4'hC: prdata = {24'b0, rx_data};

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
