#include "globals.h"
using std::string;

///=============================================================================
// strcpyToAxi() - like strcpy, but the destination is in AXI address space
//=============================================================================
static void strcpyToAxi(uint32_t axiAddress, const char* src)
{
    // Loop until we find the nul-byte that terminates the string
    while (true)
    {
        // Fetch the next four bytes of the string
        uint32_t data = (src[3] << 24) | (src[2] << 16) | (src[1] << 8 ) | src[0];

        // Write them to the specified AXI address
        int rc = AXIUart.write(axiAddress, data);
        
        // If an error occurs during that AXI write, whine about it and exit
        if (rc)
        {
            printf("Error %i on AXI write to 0x%08x\n", rc, axiAddress);
            exit(1);
        }

        // If any of those four bytes was nul, we're done
        if (src[0] == 0 || src[1] == 0 || src[2] == 0 || src[3] == 0) break;

        // Point to the next 32-bit word of AXI address space
        axiAddress += 4;

        // And point to the next four bytes of the input string
        src += 4;
    }
}
//=============================================================================


//=============================================================================
// post() - Posts a message to the FPGA IPC layer
//=============================================================================
void CAXI_IPC::post(string s)
{
    int rc;
    uint32_t axi_addr_lo, axi_addr_hi;

    // These are the three 32-bit AXI registers we need to interact with
    uint32_t REG_DEST_HI = config.ipc_base_addr + 0;
    uint32_t REG_DEST_LO = config.ipc_base_addr + 4;
    uint32_t REG_POST    = config.ipc_base_addr + 8;

    // Fetch the high 32-bits of the AXI address where we should write the string
    rc = AXIUart.read(REG_DEST_HI, &axi_addr_hi);
    if (rc)
    {
        printf("Error %i on AXI serial read of 0x%08x\n", rc, REG_DEST_HI);
        exit(1);
    }

    // Fetch the low 32-bits of the AXI address where we should write the string
    rc = AXIUart.read(REG_DEST_LO, &axi_addr_lo);
    if (rc)
    {
        printf("Error %i on AXI serial read of 0x%08x\n", rc, REG_DEST_LO);
        exit(1);
    }

    // Copy the string to the indicated address
    strcpyToAxi(axi_addr_lo, s.c_str());

    // And tell the IPC layer in the FPGA that we just posted a new message
    AXIUart.write(REG_POST, 1);
}
//=============================================================================
