module soc_top (

    input clk,
    input resetn,

    // UART
    input  uart_rx,
    output uart_tx,

    // USB
    input  usb_rx_j,
    input  usb_rx_se0,
    output usb_tx_en,
    output usb_tx_j,
    output usb_tx_se0
);

////////////////////////////////////////////////////////////
// AHB MASTER SIGNALS
////////////////////////////////////////////////////////////
wire [31:0] m_haddr, m_hwdata, m_hrdata;
wire        m_hwrite, m_hready, m_hmastlock;
wire [2:0]  m_hsize, m_hburst;
wire [3:0]  m_hprot;
wire [1:0]  m_htrans, m_hresp;

////////////////////////////////////////////////////////////
// AHB SLAVE (BRIDGE SIDE)
////////////////////////////////////////////////////////////
wire [31:0] s_haddr, s_hwdata, s_hrdata;
wire        s_hwrite, s_hready, s_hmastlock;
wire [2:0]  s_hsize, s_hburst;
wire [3:0]  s_hprot;
wire [1:0]  s_htrans, s_hresp;

////////////////////////////////////////////////////////////
// APB SIGNALS
////////////////////////////////////////////////////////////
wire [31:0] paddr, pwdata, prdata;
wire        pwrite, penable, psel;
wire        pready, pslverr;

////////////////////////////////////////////////////////////
// APB SLAVE SELECT
////////////////////////////////////////////////////////////
wire psel_ram, psel_uart, psel_spi, psel_i2c, psel_usb;

wire [31:0] prdata_ram, prdata_uart, prdata_spi, prdata_i2c, prdata_usb;
wire pready_ram, pready_uart, pready_spi, pready_i2c, pready_usb;
wire pslverr_ram, pslverr_uart, pslverr_spi, pslverr_i2c, pslverr_usb;

////////////////////////////////////////////////////////////
// AHB MASTER
////////////////////////////////////////////////////////////
ahb_master master (
    .hclk(clk),
    .hresetn(resetn),

    .hready(m_hready),
    .hresp(m_hresp),
    .hrdata(m_hrdata),

    .haddr(m_haddr),
    .hwrite(m_hwrite),
    .hsize(m_hsize),
    .hburst(m_hburst),
    .hprot(m_hprot),
    .htrans(m_htrans),
    .hmastlock(m_hmastlock),
    .hwdata(m_hwdata)
);

////////////////////////////////////////////////////////////
// AHB BUS
////////////////////////////////////////////////////////////
ahb_bus bus (
    .hclk(clk),
    .hresetn(resetn),

    // MASTER SIDE
    .m_haddr(m_haddr),
    .m_hwrite(m_hwrite),
    .m_hsize(m_hsize),
    .m_hburst(m_hburst),
    .m_hprot(m_hprot),
    .m_htrans(m_htrans),
    .m_hmastlock(m_hmastlock),
    .m_hwdata(m_hwdata),

    .m_hrdata(m_hrdata),
    .m_hready(m_hready),
    .m_hresp(m_hresp),

    // SLAVE SIDE (to bridge)
    .s_haddr(s_haddr),
    .s_hwrite(s_hwrite),
    .s_hsize(s_hsize),
    .s_hburst(s_hburst),
    .s_hprot(s_hprot),
    .s_htrans(s_htrans),
    .s_hmastlock(s_hmastlock),
    .s_hwdata(s_hwdata),

    .s_hrdata(s_hrdata),
    .s_hready(s_hready),
    .s_hresp(s_hresp)
);

////////////////////////////////////////////////////////////
// AHB → APB BRIDGE
////////////////////////////////////////////////////////////
ahb_apb_bridge bridge (
    .hclk(clk),
    .hresetn(resetn),

    .haddr(s_haddr),
    .hwrite(s_hwrite),
    .htrans(s_htrans),
    .hsize(s_hsize),
    .hwdata(s_hwdata),

    .hrdata(s_hrdata),
    .hready(s_hready),
    .hresp(s_hresp),

    .paddr(paddr),
    .pwrite(pwrite),
    .penable(penable),
    .psel(psel),
    .pwdata(pwdata),

    .prdata(prdata),
    .pready(pready),
    .pslverr(pslverr)
);

////////////////////////////////////////////////////////////
// APB BUS
////////////////////////////////////////////////////////////
apb_bus apb_bus_inst (

    .paddr(paddr),
    .pwrite(pwrite),
    .penable(penable),
    .psel(psel),
    .pwdata(pwdata),
    .pclk(clk),
    .presetn(resetn),

    .psel_ram(psel_ram),
    .psel_uart(psel_uart),
    .psel_spi(psel_spi),
    .psel_i2c(psel_i2c),
    .psel_usb(psel_usb),

    .prdata_ram(prdata_ram),
    .prdata_uart(prdata_uart),
    .prdata_spi(prdata_spi),
    .prdata_i2c(prdata_i2c),
    .prdata_usb(prdata_usb),

    .pready_ram(pready_ram),
    .pready_uart(pready_uart),
    .pready_spi(pready_spi),
    .pready_i2c(pready_i2c),
    .pready_usb(pready_usb),

    .pslverr_ram(pslverr_ram),
    .pslverr_uart(pslverr_uart),
    .pslverr_spi(pslverr_spi),
    .pslverr_i2c(pslverr_i2c),
    .pslverr_usb(pslverr_usb),

    .prdata(prdata),
    .pready(pready),
    .pslverr(pslverr)
);

////////////////////////////////////////////////////////////
// PERIPHERALS
////////////////////////////////////////////////////////////

// RAM
apb_ram ram (
    .pclk(clk), .presetn(resetn),
    .psel(psel_ram), .penable(penable), .pwrite(pwrite),
    .paddr(paddr), .pwdata(pwdata),
    .prdata(prdata_ram), .pready(pready_ram), .pslverr(pslverr_ram)
);

// UART
apb_uart uart (
    .pclk(clk), .presetn(resetn),
    .psel(psel_uart), .penable(penable), .pwrite(pwrite),
    .paddr(paddr), .pwdata(pwdata),
    .prdata(prdata_uart), .pready(pready_uart), .pslverr(pslverr_uart),
    .rx(uart_rx), .tx(uart_tx)
);

// SPI
apb_spi spi (
    .pclk(clk), .presetn(resetn),
    .psel(psel_spi), .penable(penable), .pwrite(pwrite),
    .paddr(paddr), .pwdata(pwdata),
    .prdata(prdata_spi), .pready(pready_spi), .pslverr(pslverr_spi)
);

// I2C
apb_i2c i2c (
    .pclk(clk), .presetn(resetn),
    .psel(psel_i2c), .penable(penable), .pwrite(pwrite),
    .paddr(paddr), .pwdata(pwdata),
    .prdata(prdata_i2c), .pready(pready_i2c), .pslverr(pslverr_i2c)
);

// USB
apb_usb usb (
    .pclk(clk), .presetn(resetn),
    .psel(psel_usb), .penable(penable), .pwrite(pwrite),
    .paddr(paddr), .pwdata(pwdata),
    .prdata(prdata_usb), .pready(pready_usb), .pslverr(pslverr_usb),

    .rx_j(usb_rx_j),
    .rx_se0(usb_rx_se0),
    .tx_en(usb_tx_en),
    .tx_j(usb_tx_j),
    .tx_se0(usb_tx_se0)
);

endmodule
