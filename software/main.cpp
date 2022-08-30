//==========================================================================================================
// cppserver - A demonstration of the CCmdServerBase class
//==========================================================================================================
#include <unistd.h>
#include "cmd_line.h"
#include "globals.h"
using namespace std;

// A command line parser
CCmdLine    CmdLine;

void fetch_specs()
{
    string s;
    int    i;

    // Read the specs
    if (!Config.read("fpga_server.conf")) exit(1);

    if (Config.exists("connect"))
    {
        Config.get("connect", "si", &config.connect_ip, &config.connect_port);
    }

    // Find out how we're getting to the AXI bus
    Config.get("axi_access", &s);

    // Figure out what AXI access mode we're using
    config.axi_mode = (s == "serial") ? AXI_MODE_UART : AXI_MODE_PCI;

    // Set the appropriate configuration section name
    if (config.axi_mode == AXI_MODE_UART)
        Config.set_current_section("serial");
    else
        Config.set_current_section("pci");

    // Fetch AXI_MODE_UART configurations...
    if (config.axi_mode == AXI_MODE_UART)
    {
        Config.get("serial_port", &config.serial_port);
        Config.get("ipc_base_addr", &i);
        config.ipc_base_addr = (uint32_t)i;
    }

}


int main(int argc, char** argv)
{
    cmd_server_t server_params;

    // Fetch fields from the configuration file
    fetch_specs();

    // Set up some default server parameters
    server_params.verbose = false;
    server_params.port    = 12345;

    // Declare the valid command line switches
    CmdLine.declare_switch("-port",    CLP_REQUIRED);
    CmdLine.declare_switch("-verbose", CLP_NONE);

    // Parse the command line
    if (!CmdLine.parse(argc, argv))
    {
        fprintf(stderr, "%s: %s\n", argv[0], CmdLine.error().c_str());
        exit(1);
    }

    // If the user specified a port, fetch it
    CmdLine.has_switch("-port", &server_params.port);

    // Find out if the user wants to be in verbose mode
    server_params.verbose = CmdLine.has_switch("-verbose");

    // If we're interfaced to the AXI bus via the UART, open the serial connection
    if (config.axi_mode == AXI_MODE_UART)
    {
        if (server_params.verbose) printf("Connecting to %s\n", config.serial_port.c_str());
        if (!AXIUart.connect(config.serial_port))
        {
            printf("Couldn't connect to FPGA on serial port %s\n", config.serial_port.c_str());
            exit(1);
        }        
        if (server_params.verbose) printf("Connected!\n");

    }

    // Start the command server
    Server.start(&server_params);

    // Wait for the server to be fully initialized
    while (!Server.is_initialized()) usleep(10000);

    // We have nothing else to do, so we'll just wait on the server thread
    Server.join();
}

