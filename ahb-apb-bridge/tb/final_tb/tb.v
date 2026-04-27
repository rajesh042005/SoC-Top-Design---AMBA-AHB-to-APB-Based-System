`timescale 1ns/1ps

module tb_ahb_apb_bridge;

////////////////////////////////////////////////////////////
// CLOCK & RESET
////////////////////////////////////////////////////////////
reg hclk;
reg hresetn;

always #5 hclk = ~hclk;

initial begin
    hclk = 0;
    hresetn = 0;
    #20;
    hresetn = 1;
end

////////////////////////////////////////////////////////////
// AHB SIDE SIGNALS
////////////////////////////////////////////////////////////
reg  [31:0] haddr;
reg         hwrite;
reg  [1:0]  htrans;
reg  [31:0] hwdata;

wire [31:0] hrdata;
wire        hready;
wire [1:0]  hresp;

////////////////////////////////////////////////////////////
// APB SIDE SIGNALS
////////////////////////////////////////////////////////////
wire [31:0] paddr;
wire        pwrite;
wire        psel;
wire        penable;
wire [31:0] pwdata;

reg  [31:0] prdata;
reg         pready;
reg         pslverr;

////////////////////////////////////////////////////////////
// DUT (YOUR BRIDGE)
////////////////////////////////////////////////////////////
ahb_apb_bridge dut (
    .hclk(hclk),
    .hresetn(hresetn),

    .haddr(haddr),
    .hwrite(hwrite),
    .htrans(htrans),
    .hwdata(hwdata),

    .hrdata(hrdata),
    .hready(hready),
    .hresp(hresp),

    .paddr(paddr),
    .pwrite(pwrite),
    .psel(psel),
    .penable(penable),
    .pwdata(pwdata),

    .prdata(prdata),
    .pready(pready),
    .pslverr(pslverr)
);

////////////////////////////////////////////////////////////
// INIT
////////////////////////////////////////////////////////////
initial begin
    haddr   = 0;
    hwrite  = 0;
    htrans  = 2'b00;
    hwdata  = 0;

    prdata  = 32'hA5A5A5A5;
    pready  = 1;
    pslverr = 0;

    #30;

////////////////////////////////////////////////////////////
// WRITE TRANSFER
////////////////////////////////////////////////////////////
    $display("WRITE TRANSFER");

    @(posedge hclk);
    haddr  <= 32'h0000_1000;
    hwrite <= 1;
    htrans <= 2'b10; // NONSEQ
    hwdata <= 32'hDEADBEEF;

    @(posedge hclk);
    htrans <= 2'b00;

    wait(hready);

////////////////////////////////////////////////////////////
// READ TRANSFER
////////////////////////////////////////////////////////////
    $display("READ TRANSFER");

    @(posedge hclk);
    haddr  <= 32'h0000_2000;
    hwrite <= 0;
    htrans <= 2'b10;

    @(posedge hclk);
    htrans <= 2'b00;

    wait(hready);

////////////////////////////////////////////////////////////
// WAIT STATE TRANSFER
////////////////////////////////////////////////////////////
    $display("WAIT STATE TRANSFER");

    pready <= 0; // insert wait

    @(posedge hclk);
    haddr  <= 32'h0000_3000;
    hwrite <= 1;
    htrans <= 2'b10;
    hwdata <= 32'h12345678;

    repeat(3) @(posedge hclk); // wait cycles

    pready <= 1;

    wait(hready);

////////////////////////////////////////////////////////////
// ERROR TRANSFER
////////////////////////////////////////////////////////////
    $display("ERROR TRANSFER");

    pslverr <= 1;

    @(posedge hclk);
    haddr  <= 32'h0000_4000;
    hwrite <= 0;
    htrans <= 2'b10;

    @(posedge hclk);
    htrans <= 2'b00;

    wait(hready);

    pslverr <= 0;

////////////////////////////////////////////////////////////
// FINISH
////////////////////////////////////////////////////////////
    #50;
    $finish;
end

////////////////////////////////////////////////////////////
// WAVEFORM
////////////////////////////////////////////////////////////
initial begin
    $dumpfile("ahb_apb_bridge.vcd");
    $dumpvars(0, tb_ahb_apb_bridge);
end

////////////////////////////////////////////////////////////
// MONITOR
////////////////////////////////////////////////////////////
initial begin
    $monitor("T=%0t | HADDR=%h | HWRITE=%b | HTRANS=%b | HREADY=%b | HRESP=%b | PSEL=%b | PENABLE=%b | PREADY=%b | PSLVERR=%b",
        $time, haddr, hwrite, htrans, hready, hresp, psel, penable, pready, pslverr);
end

endmodule
