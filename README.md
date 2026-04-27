<h1 align="center"> SoC Top Design - AMBA AHB to APB Based System </h1>

<p align="center">
<img src="https://img.shields.io/badge/Architecture-AMBA%20AHB%20%7C%20APB-blue?style=for-the-badge"/>
<img src="https://img.shields.io/badge/Design-RTL-orange?style=for-the-badge"/>
<img src="https://img.shields.io/badge/Language-Verilog-green?style=for-the-badge"/>
<img src="https://img.shields.io/badge/Stage-SoC%20Integration-purple?style=for-the-badge"/>
</p>

<p align="center">
<img src="https://img.shields.io/badge/Status-Completed-success?style=flat-square"/>
<img src="https://img.shields.io/badge/Type-Full%20System-blue?style=flat-square"/>
<img src="https://img.shields.io/badge/Focus-System%20Integration-informational?style=flat-square"/>
</p>

---

<p align="center">
Top-level integration of AHB, APB, Bridge, and peripherals forming a complete System-on-Chip.
</p>

---

# SoC Architecture

```mermaid
flowchart LR
    CPU[AHB Master] --> AHB[AHB BUS]
    AHB --> BRIDGE[AHB-APB Bridge]
    BRIDGE --> APB[APB BUS]

    APB --> RAM[APB RAM]
    APB --> UART[APB UART]
    APB --> SPI[APB SPI]
    APB --> I2C[APB I2C]
    APB --> USB[APB USB]
```

- AHB → high-speed backbone  
- APB → peripheral interconnect  
- Bridge → protocol conversion  

---

# Top Module Overview

The `soc_top` module integrates all components:

- AHB Master (transaction generator)  
- AHB Bus (pass-through interconnect)  
- AHB-APB Bridge (protocol conversion)  
- APB Bus (address decoding + mux)  
- APB Peripherals (UART, SPI, I2C, USB, RAM)  

---

# Signal Flow

```mermaid
flowchart LR
    HADDR --> PADDR
    HWDATA --> PWDATA
    PRDATA --> HRDATA
```

- Address/control: AHB → APB  
- Write data: Master → Peripheral  
- Read data: Peripheral → Master  

---

# Transaction Flow

```mermaid
flowchart LR
    CPU --> AHB_ADDR[Address Phase]
    AHB_ADDR --> BRIDGE
    BRIDGE --> APB_SETUP[APB Setup]
    APB_SETUP --> APB_ENABLE[APB Access]
    APB_ENABLE --> PERIPH[Peripheral]
    PERIPH --> RESP[Response]
```

- AHB issues address/control  
- Bridge converts to APB SETUP + ENABLE  
- Peripheral executes  
- Response returned back to AHB  

---

# Address Mapping

| Address | Peripheral |
|--------|-----------|
| 0x0000_0000 | RAM |
| 0x0000_1000 | UART |
| 0x0000_2000 | SPI |
| 0x0000_3000 | I2C |
| 0x0000_4000 | USB |

- Decoded using `paddr[15:12]`  
- Generates `psel_*` signals  
- Single active slave per transfer  

---

# Module Connectivity

```mermaid
flowchart LR
    MASTER --> AHB_BUS
    AHB_BUS --> BRIDGE
    BRIDGE --> APB_BUS
    APB_BUS --> RAM
    APB_BUS --> UART
    APB_BUS --> SPI
    APB_BUS --> I2C
    APB_BUS --> USB
```

- `ahb_master` drives bus  
- `ahb_bus` forwards signals  
- `bridge` converts protocol  
- `apb_bus` selects peripheral  
- Wrappers control peripherals  

---

# Key Components

## AHB Master
- Generates write → read sequence  
- Incrementing address pattern  
- Uses NONSEQ transfers  


## AHB Bus
- Simple pass-through  
- No arbitration (single master)  


## AHB-APB Bridge
- Converts AHB → APB  
- Uses FSM: IDLE → SETUP → ENABLE  
- Handles wait states and errors  

## APB Bus
- Address decoder (`paddr[15:12]`)  
- Multiplexes read data  
- Routes ready/error signals  

## Peripherals

### RAM
- Memory-mapped  
- Supports wait states  
- Error on invalid address  

### UART
- TX via `tx_start` pulse  
- RX continuously sampled  

### SPI
- Controlled using `start` bit  
- Configurable CPOL/CPHA  

### I2C
- Start via `enable`  
- Supports read/write  

### USB
- Enabled via control register  
- Minimal wrapper  

---

# System Behavior

- Write phase:
  - AHB → Bridge → APB → Peripheral  
- Read phase:
  - Peripheral → APB → Bridge → AHB  

- Wait states:
  - Introduced by RAM  
  - Propagated via bridge  

- Error:
  - Invalid address → PSLVERR → HRESP  

---

# Design Characteristics

- Single clock domain (clk)  
- Synchronous reset (resetn)  
- Memory-mapped architecture  
- Modular and scalable  

---

# Final System Flow

```mermaid
flowchart LR
    CPU --> AHB
    AHB --> BRIDGE
    BRIDGE --> APB
    APB --> RAM
    APB --> UART
    APB --> SPI
    APB --> I2C
    APB --> USB
```

---


<p align ="center"><b>
This SoC integrates AHB and APB protocols through a bridge, enabling structured communication between high-speed core logic and low-speed peripherals in a modular and scalable design.

---
