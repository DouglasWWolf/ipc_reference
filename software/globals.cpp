//==========================================================================================================
// globals.cpp - Instantiate globally accessible objects
//==========================================================================================================
#include "globals.h"

// The server
CDemoServer  Server;

// This gives us access to the AXI bus via a serial port
CAxiUart     AXIUart;

// The AXI IPC interface
CAXI_IPC     AXI_IPC;

// The configuration file
CConfigFile  Config;

// The configuration settings from the Config object
config_t     config;