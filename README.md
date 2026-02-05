# Single-Stage Pipeline Register with Valid/Ready Handshake

A synthesizable SystemVerilog implementation of a single-stage pipeline register using standard valid/ready handshake protocol.

**Developed and tested using Xilinx Vivado 2023.2**

## Quick Start

This repository contains:
- `rtl/pipeline_register.sv` - Main RTL implementation
- `tb/tb_pipeline_register.sv` - Functional testbench
- `simulation_waveform.png` - Vivado 2023.2 verification results
- Fully synthesizable design verified on Vivado 2023.2

## Overview

This module implements a pipeline stage that sits between input and output interfaces, storing data and managing flow control through backpressure handling. The design ensures no data loss or duplication while supporting full throughput when both sides are ready.


### Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| DATA_WIDTH | int | 32 | Width of data bus in bits |

### Ports

| Port | Direction | Width | Description |
|------|-----------|-------|-------------|
| clk | input | 1 | Clock signal |
| rst_n | input | 1 | Active-low asynchronous reset |
| in_valid | input | 1 | Input data is valid |
| in_ready | output | 1 | Ready to accept input data |
| in_data | input | DATA_WIDTH | Input data |
| out_valid | output | 1 | Output data is valid |
| out_ready | input | 1 | Downstream ready to accept |
| out_data | output | DATA_WIDTH | Output data |




### State Machine

The pipeline register operates as a simple two-state machine:

```
States:
- EMPTY  (valid_reg = 0): No data stored, ready to accept
- FULL   (valid_reg = 1): Data stored, presenting on output

Transitions:
- EMPTY → FULL:   Input transfer occurs (in_valid && in_ready)
- FULL → EMPTY:   Output transfer occurs (out_valid && out_ready)
- FULL → FULL:    Both transfers occur simultaneously (passthrough)
```

### Key Logic

**Ready Logic:**
```systemverilog
assign in_ready = ~valid_reg || output_transfer;
```
The pipeline can accept new data when:
1. It's empty (!valid_reg), OR
2. Current data is being read this cycle (output_transfer)

**Transfer Detection:**
```systemverilog
wire input_transfer  = in_valid && in_ready;
wire output_transfer = out_valid && out_ready;
```

**State Update:**
```systemverilog
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        data_reg  <= '0;
        valid_reg <= 1'b0;
    end else begin
        case ({input_transfer, output_transfer})
            2'b00: valid_reg <= valid_reg;        // No change
            2'b01: valid_reg <= 1'b0;              // Output only → become empty
            2'b10: begin                           // Input only → store new data
                data_reg  <= in_data;
                valid_reg <= 1'b1;
            end
            2'b11: begin                           // Both → passthrough
                data_reg  <= in_data;
                valid_reg <= 1'b1;
            end
        endcase
    end
end
```

## Design Decisions

### 1. Register Placement
The data register is placed at the **output** of the stage:
- Input side sees immediate ready response
- Output side always sees registered, stable data
- Simplifies timing closure in synthesis

### 2. Ready Signal Behavior
The `in_ready` signal is **combinational** based on current state:
- Allows immediate response to downstream conditions
- Enables maximum throughput (1 transfer/cycle when ready)
- Trade-off: Slightly longer combinational path vs. registered ready

### 3. Reset Behavior
Active-low asynchronous reset (`rst_n`):
- Clears to EMPTY state (valid_reg = 0, data_reg = 0)
- Industry standard for FPGA/ASIC designs
- Matches typical chip-level reset conventions

## Simulation and Verification

### Testbench Coverage

The provided testbench (`tb/tb_pipeline_register.sv`) validates:

1. **Basic Transfer**: Single data item through pipeline
2. **Sequential Transfers**: Multiple back-to-back transfers
3. **Backpressure**: Output not ready, data held correctly
4. **Reset Behavior**: Proper initialization

### Simulation Waveform (Vivado 2023.2)

![Pipeline Register Simulation](simulation_waveform.png)

The waveform demonstrates:
- **Basic Transfer** (~20-40ns): `in_data = 0xDEADBEEF` is accepted when `in_valid` and `in_ready` are both high, then appears on `out_data` in the next cycle
- **Backpressure Handling** (~60-100ns): `in_data = 0xCAFEBABE` is accepted but output is held when `out_ready = 0`, demonstrating proper data retention during backpressure
- **Correct Handshaking**: `in_ready` goes low when the pipeline is full and `out_ready` is not asserted, preventing data loss



### Vivado 2023.2 (Xilinx 7-Series, 32-bit DATA_WIDTH)

**Resource Utilization:**
- Flip-Flops: 33 (32 data + 1 valid)
- LUTs: ~2-3 (for ready logic)
- No BRAMs or DSPs used

**Timing:**
- Max Frequency: >400 MHz (typical, depends on target device)
- Critical Path: Register output → combinational ready logic
- No timing violations in typical configurations


## Tools and Environment

- **FPGA Design Suite**: Xilinx Vivado 2023.2
- **Language**: SystemVerilog (IEEE 1800-2017)
- **Simulation**: Vivado Simulator

## File Structure

```
pipeline-register/
├── README.md                    # Project documentation
├── simulation_waveform.png      # Vivado simulation results
├── rtl/
│   └── pipeline_register.sv     # Main RTL module
└── tb/
    └── tb_pipeline_register.sv  # Testbench

