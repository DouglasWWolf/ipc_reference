// The width of AXI address bus, in bits
`define IPC_AXI_ADDR_WIDTH     64

// The width of a single token in bits.
`define IPC_TOKEN_WIDTH        256

// The maximum number of characters in an ASCII H2F message (including the nul-byte)
`define IPC_INPSTR_MAXLEN      256

// Number of entries in the H2F input queue
`define IPC_INPUT_Q_SIZE       16

// The starting address in RAM for the IPC incoming message queue
`define IPC_H2F_QUEUE_ADDR     64'hC000_0000

// The location in RAM that contains the parsed tokens of a host-to-fpga message
`define IPC_H2F_TOKENS_ADDR    64'hC000_1000

// The maximum number of tokens in a host-to-fpga message
`define IPC_MAX_INPUT_TOKENS   16

// This should be greater or equal to IPC_MAX_INPUT_TOKENS
`define IPC_DEFAULT_FIFO_DEPTH 16
