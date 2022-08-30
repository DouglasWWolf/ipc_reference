//==========================================================================================================
// globals.h - Declare globally accessible objects
//==========================================================================================================
#pragma once
#include "fpga_server.h"
#include "config_file.h"
#include "axi_uart.h"
#include "axi_ipc.h"

enum axi_mode_t
{
    AXI_MODE_UART = 0,
    AXI_MODE_PCI  = 1
};

struct config_t
{
    axi_mode_t  axi_mode;
    std::string serial_port;
    std::string connect_ip;
    int         connect_port;
    uint32_t    ipc_base_addr;

};

extern CAxiUart    AXIUart;
extern CAXI_IPC    AXI_IPC;
extern CDemoServer Server;
extern CConfigFile Config;
extern config_t    config;
