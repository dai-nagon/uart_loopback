parameter IDLE  = 3'h0;
parameter START = 3'h1;
parameter BUSY  = 3'h2;
parameter STOP  = 3'h3;
parameter RATE = 115200;
parameter FREQ = 125000000;
parameter N_CYC = FREQ/RATE;//1086;//FREQ/RATE;
parameter D_WIDTH = 8;

module uart_top (
    input wire clk,
    input wire rst,

    //input btn, //for debugging
    //input [3:0]sw, //for debugging
    
    input wire  uart_din,
    output wire uart_dout,
    
    output reg [3:0]ld//for debugging
);

//115200bps, 8b, non-parity, no flow control

//////////////////
//reg [1:0]r_din;
wire [D_WIDTH-1:0]rx_din_data;
wire [D_WIDTH-1:0]tx_dout_data;

reg [1:0]r_state = 0;
reg [10:0]r_cnt = 0;
reg [3:0]r_bit_cnt = 0;

wire rx_busy;
wire [1:0]rx_state;
wire [10:0]rx_cnt;

wire tx_en;

///*
uart_rx rx(
    .clk(clk),
    .rst(rst),
    .rec_din(uart_din),
    .rec_dout(rx_din_data),
    .busy(rx_busy),
    .state_o(rx_state),
    .cnt_o()
);
//*/

//assign tx_dout_data = {sw,sw};
//assign tx_en = btn;
assign tx_dout_data = {rx_din_data[0],rx_din_data[1],rx_din_data[2],rx_din_data[3],rx_din_data[4],rx_din_data[5],rx_din_data[6],rx_din_data[7]};
//assign tx_en = !rx_busy;
assign tx_en = (rx_state == STOP)?1'b1:1'b0;

//assign ld = rx_din_data[3:0];

uart_tx tx(
    .clk(clk),
    .rst(rst),
    .en(tx_en),
    .send_din(tx_dout_data),
    .send_dout(uart_dout),
    .busy()
);

/*
always@(posedge clk)begin
    if(rx_state == IDLE)begin
        ld <= rx_din_data[3:0];        
    end
end
*/

endmodule

module uart_tx (
    input wire clk,
    input wire rst,
    input wire en,
    input wire [D_WIDTH-1:0] send_din,
    output wire send_dout,
    output wire busy
);


reg [1:0]r_state = IDLE;
reg [10:0]r_cnt = 0;
reg [3:0]r_bit_cnt = 0;

reg r_send_dout = 1;
reg [D_WIDTH-1:0]r_send_din;

assign send_dout = r_send_dout;

assign busy = r_state[0]|r_state[1];

always@(posedge clk)begin
    if(en && r_state == IDLE)begin
        r_state <= START;
    end
    else if (r_state == START) begin
        r_send_dout <= 0;
        r_send_din <= send_din;
        
        if(r_cnt < N_CYC-1)begin
            r_cnt <= r_cnt + 1;
        end
        else if (r_cnt == N_CYC-1) begin
            r_cnt <= 0;
            r_state <= BUSY;
        end        
    end
    else if (r_state == BUSY) begin
        if(r_cnt < N_CYC-1)begin
            r_cnt <= r_cnt + 1;
            if (r_cnt == 0) begin
//                rec_dout <= {rec_dout[6:0],rec_din};
                r_send_dout <= r_send_din[r_bit_cnt];
            end
        end
        else if(r_cnt == N_CYC-1)begin
            r_cnt <= 0;
            r_bit_cnt <= r_bit_cnt+1;
            
            if(r_bit_cnt == D_WIDTH-1)begin
               r_bit_cnt <= 0;
               r_state <= STOP;
            end
        end
    end
    else if (r_state == STOP) begin
        r_send_dout <= 1;

        if(r_cnt < N_CYC-1)begin
            r_cnt <= r_cnt + 1;
        end
        else if(r_cnt == N_CYC-1)begin
            r_cnt <= 0;
            r_state <= IDLE;
        end
    end    
end
endmodule


module uart_rx (
    input wire clk,
    input wire rst,
    input wire  rec_din,
    output reg[D_WIDTH-1:0] rec_dout,
    output wire busy,
    output wire [1:0] state_o,
    output wire [10:0]cnt_o
);

reg [1:0]r_din;

reg [1:0]r_state = IDLE;
reg [10:0]r_cnt = 0;
reg [3:0]r_bit_cnt = 0;

assign state_o = r_state;
assign cnt_o = r_cnt; 
assign busy = r_state[0]|r_state[1];

always@(posedge clk)begin
    r_din <= {r_din[0],rec_din};
    
    if (r_din[1] == 1'b1 && r_din[0] == 1'b0 && r_state == IDLE) begin
        r_state <= START;
    end
    else if (r_state == START) begin
        if(r_cnt < N_CYC-1)begin
            r_cnt <= r_cnt + 1;
        end
        else if (r_cnt == N_CYC-1) begin
            r_cnt <= 0;
            r_state <= BUSY;
        end
    end
    else if (r_state == BUSY) begin
        if(r_cnt < N_CYC-1)begin
            r_cnt <= r_cnt + 1;
            if (r_cnt == N_CYC/2) begin
                rec_dout <= {rec_dout[6:0],rec_din};
            end
        end
        else if(r_cnt == N_CYC-1)begin
            r_cnt <= 0;
            r_bit_cnt <= r_bit_cnt+1;
            
            if(r_bit_cnt == D_WIDTH-1)begin
               r_bit_cnt <= 0;
               r_state <= STOP;
            end
        end
    end
    else if (r_state == STOP) begin
        if(r_cnt < N_CYC-1)begin
            r_cnt <= r_cnt + 1;
        end
        else if(r_cnt == N_CYC-1)begin
            r_cnt <= 0;
            r_state <= IDLE;
        end
    end
end
endmodule
