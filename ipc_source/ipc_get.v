
`timescale 1ns/100ps
//<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>
//           This RTL core fetches a tokenized IPC message into a FIFO
//<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>

/*
    >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
    >>>> IF YOU GET A BUILD-TIME ERROR THAT SAYS 'xpm_fifo_sync not found', <<<<
    >>>> run the TCL command "auto_detect_xpm" and try your build again.    <<<<
    >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

*/

//====================================================================================
//                        ------->  Revision History  <------
//====================================================================================
//
//   Date     Who   Ver  Changess
//====================================================================================
// 18-Aug-22  DWW  1000  Initial creation
//====================================================================================
`include "ipc_configuration.vh"

module ipc_get #
(
    parameter FIFO_DEPTH = `IPC_DEFAULT_FIFO_DEPTH
)
(
    input clk, resetn,

    // This will strobe high for one cycle when we should start
    input START,
    
    // This will be high when we're idle
    output IDLE,

    // This will be high when the FIFO is empty
    output FIFO_EMPTY,

    // When the FIFO is not empty, this will contain a token
    output[`IPC_TOKEN_WIDTH-1:0] FIFO_DATA,

    // On any cycle when this is high, the FIFO will advance by 1
    input FIFO_RD_EN,

    //======================  An AXI Master Interface  =========================

    // "Specify write address"          -- Master --    -- Slave --
    output[`IPC_AXI_ADDR_WIDTH-1:0]     AXI_AWADDR,   
    output                              AXI_AWVALID,  
    output[2:0]                         AXI_AWPROT,
    output[3:0]                         AXI_AWID,
    output[7:0]                         AXI_AWLEN,
    output[2:0]                         AXI_AWSIZE,
    output[1:0]                         AXI_AWBURST,
    output                              AXI_AWLOCK,
    output[3:0]                         AXI_AWCACHE,
    output[3:0]                         AXI_AWQOS,
    input                                               AXI_AWREADY,


    // "Write Data"                     -- Master --    -- Slave --
    output[`IPC_TOKEN_WIDTH-1:0]        AXI_WDATA,      
    output                              AXI_WVALID,
    output[(`IPC_TOKEN_WIDTH/8)-1:0]    AXI_WSTRB,
    output                              AXI_WLAST,
    input                                               AXI_WREADY,


    // "Send Write Response"            -- Master --    -- Slave --
    input[1:0]                                          AXI_BRESP,
    input                                               AXI_BVALID,
    output                              AXI_BREADY,

    // "Specify read address"           -- Master --    -- Slave --
    output[`IPC_AXI_ADDR_WIDTH-1:0]     AXI_ARADDR,     
    output reg                          AXI_ARVALID,
    output[2:0]                         AXI_ARPROT,     
    output                              AXI_ARLOCK,
    output[3:0]                         AXI_ARID,
    output[7:0]                         AXI_ARLEN,
    output[2:0]                         AXI_ARSIZE,
    output[1:0]                         AXI_ARBURST,
    output[3:0]                         AXI_ARCACHE,
    output[3:0]                         AXI_ARQOS,
    input                                              AXI_ARREADY,

    // "Read data back to master"       -- Master --    -- Slave --
    input[`IPC_TOKEN_WIDTH-1:0]                         AXI_RDATA,
    input                                               AXI_RVALID,
    input[1:0]                                          AXI_RRESP,
    input                                               AXI_RLAST,
    output                              AXI_RREADY
    //==========================================================================

);
    // The state of the (very simple) state machine
    reg state;

    // This will be high when the FIFO has no more room
    wire fifo_full;

    // Various configuration settings
    localparam AXI_DATA_WIDTH = `IPC_TOKEN_WIDTH;
    localparam AXI_DATA_BYTES = (`IPC_TOKEN_WIDTH/8);
    localparam AXI_ADDR_WIDTH = `IPC_AXI_ADDR_WIDTH;
    localparam TOKEN_WIDTH    = `IPC_TOKEN_WIDTH;
    localparam TOKEN_BYTES    = (TOKEN_WIDTH/8); 
    localparam TOKENS_ADDR    = `IPC_H2F_TOKENS_ADDR;

    // Assign all of the "read transaction" signals that are constant
    assign AXI_ARLOCK  = 0;   // Normal signaling
    assign AXI_ARID    = 1;   // Arbitrary ID
    assign AXI_ARBURST = 1;   // Increment address on each beat of the burst (unused)
    assign AXI_ARCACHE = 2;   // Normal, no cache, no buffer
    assign AXI_ARQOS   = 0;   // Lowest quality of service (unused)
    assign AXI_ARPROT  = 0;   // Normal

    // THe width of a read is the width of a token
    assign AXI_ARSIZE  = $clog2(TOKEN_BYTES);

    // We will always do a burst read for the maximum potential number of input tokens
    assign AXI_ARLEN   = `IPC_MAX_INPUT_TOKENS - 1;

    // And our read will always start from the same address
    assign AXI_ARADDR  = TOKENS_ADDR;

    // We're only ready to receive data when the FIFO isn't full
    assign AXI_RREADY  = (state == 1) & (fifo_full == 0);

    // Define the handshakes for the read-related channels
    wire R_HANDSHAKE  = AXI_RVALID  & AXI_RREADY;
    wire AR_HANDSHAKE = AXI_ARVALID & AXI_ARREADY;

    // This mask, anded with an address, will give the byte-offset-from-aligned of that address
    wire[15:0] ADDR_OFFSET_MASK = (1 << $clog2(AXI_DATA_BYTES)) - 1;

    // This is the address we're reading on any given beat    
    reg[AXI_ADDR_WIDTH-1:0] axi_araddr;

    // This is the offset of the read-address from perfect aligned (in bytes)
    wire[7:0] raddr_offset = axi_araddr & ADDR_OFFSET_MASK;

    // This is AXI_RDATA shifted down the appropriate number of bits to account for narrow width
    wire[TOKEN_WIDTH-1:0] axi_rdata = AXI_RDATA >> (raddr_offset << 3);

    // We're idle when we're in state 0 and no one has told us to start
    assign IDLE = (state == 0) && (START == 0);

    // This will be true when we're supposed to throw away all subsequent beats of a burst
    reg throw_away;

    // FIFO write-enable is true whenever we receive a byte and "throw_away" is deasserted
    wire fifo_wr_en = R_HANDSHAKE & (throw_away == 0);

    //===============================================================================================
    // This state machine reads tokens into the FIFO in a single AXI burst
    //===============================================================================================
    always @(posedge clk) begin

        if (resetn == 0)
            state <= 0;
        else case (state) 
        
        0:  if (START) begin
                axi_araddr   <= TOKENS_ADDR;
                AXI_ARVALID  <= 1;
                throw_away   <= 0;
                state        <= 1;
            end else begin
                AXI_ARVALID  <= 0;
            end

        1:  begin

                // If we've seen the address handshake, lower "address valid"
                if (AR_HANDSHAKE) begin
                    AXI_ARVALID <= 0;
                end

                // If the slave has provided us the data we asked for...
                if (R_HANDSHAKE) begin

                    // If we just encountered a token that is all zero bits, throw away
                    // the rest of the burst (i.e., don't write it to the FIFO)
                    if (axi_rdata == 0) throw_away = 1;

                    // Determine the read address for next beat
                    axi_araddr <= axi_araddr + TOKEN_BYTES;
                    
                    // If this was the last beat of the burst, we're done
                    if (AXI_RLAST) state <= 0; 

                end

            end

        endcase

    end
    //===============================================================================================


    //<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><
    //<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><
    //         This FIFO serves as a buffer for tokens that our IPC handler should process
    //<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><
    //<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><

    xpm_fifo_sync#
    (
      .CASCADE_HEIGHT       (0),
      .DOUT_RESET_VALUE     ("0"),
      .ECC_MODE             ("no_ecc"),
      .FIFO_MEMORY_TYPE     ("auto"),
      .FIFO_READ_LATENCY    (1),
      .FIFO_WRITE_DEPTH     (FIFO_DEPTH),
      .FULL_RESET_VALUE     (0),
      .PROG_EMPTY_THRESH    (0),
      .PROG_FULL_THRESH     (0),
      .RD_DATA_COUNT_WIDTH  (1),
      .READ_DATA_WIDTH      (TOKEN_WIDTH),
      .READ_MODE            ("std"),
      .SIM_ASSERT_CHK       (0),
      .USE_ADV_FEATURES     ("1010"),
      .WAKEUP_TIME          (0),
      .WRITE_DATA_WIDTH     (TOKEN_WIDTH),
      .WR_DATA_COUNT_WIDTH  (1)

      //------------------------------------------------------------
      // These exist only in xpm_fifo_async, not in xpm_fifo_sync
      //.CDC_SYNC_STAGES(2),       // DECIMAL
      //.RELATED_CLOCKS(0),        // DECIMAL
      //------------------------------------------------------------
    )
    data_fifo
    (
        .rst        (~resetn   ),
        .wr_clk     (clk       ), 

        .full       (fifo_full ),
        .din        (axi_rdata ),
        .wr_en      (fifo_wr_en),

        .empty      (FIFO_EMPTY),
        .dout       (FIFO_DATA ),
        .rd_en      (FIFO_RD_EN),

      //------------------------------------------------------------
      // This only exists in xpm_fifo_async, not in xpm_fifo_sync
      // .rd_clk    (CLK               ),
      //------------------------------------------------------------

        .data_valid(),
        .sleep(),
        .injectdbiterr(),
        .injectsbiterr(),
        .overflow(),
        .prog_empty(),
        .prog_full(),
        .rd_data_count(),
        .rd_rst_busy(),
        .sbiterr(),
        .underflow(),
        .wr_ack(),
        .wr_data_count(),
        .wr_rst_busy(),
        .almost_empty(),
        .almost_full(),
        .dbiterr()
    );


endmodule