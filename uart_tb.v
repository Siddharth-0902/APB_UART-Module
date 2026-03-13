`timescale 1ns/1ps

module uart_tb();

reg rst;
reg pclk;
reg presetn;
reg psel;
reg [31:0] paddr;
reg [7:0] pwdata;
reg penable;
reg pwrite;

wire [7:0] prdata;
wire pready;
wire tx;
wire pwakeup;
reg rx;

////////////////////////////////////////////////
// DUT Instantiation
////////////////////////////////////////////////
apb_uart dut(
    .rx(rx),
    .tx(tx),
    .rst(rst),
    .pclk(pclk),
    .presetn(presetn),
    .psel(psel),
    .paddr(paddr),
    .pwdata(pwdata),
    .penable(penable),
    .pwrite(pwrite),
    .prdata(prdata),
    .pready(pready),
    .pwakeup(pwakeup)
);

////////////////////////////////////////////////
// Clock generation
////////////////////////////////////////////////
always #5 pclk = ~pclk;

////////////////////////////////////////////////
// Initial block
////////////////////////////////////////////////
initial begin

    // Initialize signals
    pclk    = 0;
    rst     = 1;
    presetn = 0;
    psel    = 0;
    penable = 0;
    pwrite  = 0;
    paddr   = 0;
    pwdata  = 0;
    rx      = 1;     // UART idle

////////////////////////////////////////////////
// RESET
////////////////////////////////////////////////
    #10;
    rst = 0;
    presetn = 0;

    repeat(5) @(posedge pclk);

    rst = 1;
    presetn = 1;

////////////////////////////////////////////////
// APB WRITE TRANSACTION
////////////////////////////////////////////////
    @(posedge pclk);
    psel   = 1;
    penable= 0;
    pwrite = 1;
    paddr  = 0;
    pwdata = $urandom_range(0,255);

    @(posedge pclk);
    penable = 1;

    wait(pready);

    @(posedge pclk);
    psel   = 0;
    penable= 0;
    pwrite = 0;

////////////////////////////////////////////////
// APB READ TRANSACTION
////////////////////////////////////////////////
    @(posedge pclk);
    psel   = 1;
    penable= 0;
    pwrite = 0;
    paddr  = 0;

    @(posedge pclk);
    penable = 1;

////////////////////////////////////////////////
// UART RX FRAME
////////////////////////////////////////////////
    rx = 0;                  // start bit
    @(posedge pclk);

    repeat(8) begin
        rx = $urandom_range(0,1);
        @(posedge pclk);
    end

    rx = 1;                  // stop bit

    wait(pready);

    @(posedge pclk);
    psel    = 0;
    penable = 0;

////////////////////////////////////////////////
// END SIMULATION
////////////////////////////////////////////////
    #20;
    $finish;

end

endmodule
