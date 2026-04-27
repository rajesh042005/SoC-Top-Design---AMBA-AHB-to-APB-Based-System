export DESIGN_NAME = soc_top
export PLATFORM = sky130hd
export TOP_MODULE = soc_top

export VERILOG_FILES = \
    ./designs/sky130hd/soc_top/src/soc_top.v \
    ./designs/sky130hd/ahb_master/src/*.v \
    ./designs/sky130hd/ahb_bus/src/*.v \
    ./designs/sky130hd/ahb_apb_bridge/src/*.v \
    ./designs/sky130hd/apb_bus/src/*.v \
    ./designs/sky130hd/apb_ram/src/*.v \
    ./designs/sky130hd/uart/src/*.v \
    ./designs/sky130hd/apb_uart/src/*.v \
    ./designs/sky130hd/spi/src/*.v \
    ./designs/sky130hd/apb_spi/src/*.v \
    ./designs/sky130hd/i2c/src/*.v \
    ./designs/sky130hd/apb_i2c/src/*.v \
    ./designs/sky130hd/usb/src/*.v \
    ./designs/sky130hd/apb_usb/src/*.v

export SDC_FILE = ./designs/sky130hd/soc_top/const.sdc

export CLK_NAME = clk
export CLK_PERIOD = 20

export DIE_AREA = 0 0 170 170
export CORE_AREA = 10 10 160 160

export PLACEMENT_DENSITY = 0.6
