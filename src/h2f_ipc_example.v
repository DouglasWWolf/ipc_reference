     //<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>
     //       This module is a demonstration of how to use the h2f_ipc_core module
     //<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>


//===================================================================================================
//                               ------->  Revision History  <------
//===================================================================================================
//
//   Date     Who   Ver  Changes
//===================================================================================================
// 20-Aug-22  DWW  1000  Initial creation
//===================================================================================================
`include "ipc_configuration.vh"

module h2f_ipc_example
( 
    input                       clk, resetn,
    output                      IDLE, 
    input[`IPC_TOKEN_WIDTH-1:0] TOKEN,
    input                       START,

    output LED_START,
    input  LED_IDLE
);

    // The state of the state machine
    reg[1:0] state;
    
    // The IDLE output is high when we're in state 0 and not being told to start
    assign IDLE = (state == 0 && START == 0);

    // Convenient index numbers for the modules we are controlling
    localparam IDX_LED = 0;
    localparam IDX_MAX = 0;

    // One "start" and "idle" pin per module that we are controlling
    reg [IDX_MAX:0] start;
    wire[IDX_MAX:0] idle;

    // An index into the start[] and idle[] fields
    reg[$clog2(IDX_MAX+1):0] index;

    // Drive the "XXX_START" ports from the "start[]" bits
    assign LED_START = start[IDX_LED];
    
    // The "idle[]" bits are driven from the "XXX_IDLE" ports
    assign idle[IDX_LED] = LED_IDLE;

    always @(posedge clk) begin
        if (resetn == 0) begin
            state <= 0;
            start <= 0;
         
        end else case(state)

            0:  if (START) begin
                    state <= 1;
                    case(TOKEN)
                        "led":      index <= IDX_LED;
                        default:    state <= 0;
                    endcase
                end

            1:  begin
                    start[index] <= 1;
                    state        <= state + 1;
                end

            2:  begin
                    start[index] <= 0;
                    if (idle[index]) state <= 0;
                end

        endcase
    end


endmodule