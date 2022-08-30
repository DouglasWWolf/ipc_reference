//Copyright 1986-2021 Xilinx, Inc. All Rights Reserved.
//--------------------------------------------------------------------------------
//Tool Version: Vivado v.2021.1 (lin64) Build 3247384 Thu Jun 10 19:36:07 MDT 2021
//Date        : Mon Aug 29 19:51:50 2022
//Host        : simtool5-2 running 64-bit Ubuntu 20.04.4 LTS
//Command     : generate_target reference_design_wrapper.bd
//Design      : reference_design_wrapper
//Purpose     : IP block netlist
//--------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

module reference_design_wrapper
   (CLK100_MHZ,
    CPU_RESETN,
    GPIO_LED,
    UART_rxd,
    UART_txd);
  input CLK100_MHZ;
  input CPU_RESETN;
  output [15:0]GPIO_LED;
  input UART_rxd;
  output UART_txd;

  wire CLK100_MHZ;
  wire CPU_RESETN;
  wire [15:0]GPIO_LED;
  wire UART_rxd;
  wire UART_txd;

  reference_design reference_design_i
       (.CLK100_MHZ(CLK100_MHZ),
        .CPU_RESETN(CPU_RESETN),
        .GPIO_LED(GPIO_LED),
        .UART_rxd(UART_rxd),
        .UART_txd(UART_txd));
endmodule
