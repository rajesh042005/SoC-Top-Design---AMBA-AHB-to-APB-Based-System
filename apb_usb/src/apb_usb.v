module apb_usb (

    input         pclk,
    input         presetn,
    input         psel,
    input         penable,
    input         pwrite,
    input  [31:0] paddr,
    input  [31:0] pwdata,

    output reg [31:0] prdata,
    output reg        pready,
    output reg        pslverr,

    // USB PHY
    input  rx_j,
    input  rx_se0,
    output tx_en,
    output tx_j,
    output tx_se0
);

    // =========================
    // INTERNAL CONTROL
    // =========================
    reg enable;

    // =========================
    // USB SIGNALS
    // =========================
    wire transaction_active;
    wire success;
    wire [3:0] endpoint;
    wire [7:0] data_out;
    wire data_strobe;

    // =========================
    // USB INSTANCE
    // =========================
    usb_top usb_inst (
        .clk(pclk),
        .rst_n(presetn & enable),

        .rx_j(rx_j),
        .rx_se0(rx_se0),

        .tx_en(tx_en),
        .tx_j(tx_j),
        .tx_se0(tx_se0)
    );

    // NOTE: usb_top internally handles most logic
    // (we are exposing only minimal control)

    // =========================
    // WRITE
    // =========================
    always @(posedge pclk or negedge presetn) begin
        if (!presetn) begin
            enable <= 0;
        end else begin
            if (psel && penable && pwrite) begin
                case (paddr[3:0])
                    4'h0: enable <= pwdata[0];
                endcase
            end
        end
    end

    // =========================
    // READ
    // =========================
    always @(*) begin
        case (paddr[3:0])

            // CONTROL
            4'h0: prdata = {31'b0, enable};

            // STATUS (dummy for now)
            4'h4: prdata = 32'h1;  // you can improve later

            // DATA (not fully wired yet)
            4'h8: prdata = 32'h0;

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
