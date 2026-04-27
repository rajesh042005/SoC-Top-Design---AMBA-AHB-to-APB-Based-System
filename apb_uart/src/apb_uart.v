module apb_uart (

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

    input  rx,
    output tx
);

    // UART signals
    reg  [7:0] tx_data;
    reg        tx_start;
    wire       tx_busy;

    wire [7:0] rx_data;
    wire       rx_done;

    // UART instance
    uart_top uart_inst (
        .clk(pclk),
        .reset_n(presetn),
        .rx(rx),
        .tx(tx),
        .tx_data(tx_data),
        .tx_start(tx_start),
        .tx_busy(tx_busy),
        .rx_data(rx_data),
        .rx_done(rx_done)
    );

    // WRITE
    always @(posedge pclk or negedge presetn) begin
        if (!presetn) begin
            tx_data  <= 0;
            tx_start <= 0;
        end else begin
            if (psel && penable && pwrite) begin
                case (paddr[3:0])
                    4'h0: begin
                        tx_data  <= pwdata[7:0];
                        tx_start <= 1;
                    end
                endcase
            end else begin
                tx_start <= 0;
            end
        end
    end

    // READ
    always @(*) begin
        case (paddr[3:0])
            4'h4: prdata = {24'b0, rx_data};
            4'h8: prdata = {30'b0, rx_done, tx_busy};
            default: prdata = 32'h0;
        endcase
    end

    // READY / ERROR
    always @(*) begin
        pready  = 1'b1;
        pslverr = 1'b0;
    end

endmodule
