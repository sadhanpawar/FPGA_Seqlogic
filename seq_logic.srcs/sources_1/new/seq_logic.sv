// Sequential logic example for Xilinx XUP Blackboard rev D (seq_logic.sv)
// Jason Losh
//
// External push button
//   Active low push button on GPIO[16]
// External red and green LEDs
//   Red on GPIO[17]
//   Green on GPIO[19];
//   include pb_pullup.xdc to enable pullups on push button
// Reset
//   Active-high reset on PB0
// Shift input
//   Active high shift input on PB1
// Onboard LEDs
//   Out  on LED[0]
//   Count on LED[5:2]
//   Three on LED[9:7]

module seq_logic(
    input CLK100,           // 100 MHz clock input
    output [9:0] LED,       // RGB1, RGB0, LED 9..0 placed from left to right
    output [2:0] RGB0,      
    output [2:0] RGB1,
    output [3:0] SS_ANODE,   // Anodes 3..0 placed from left to right
    output [7:0] SS_CATHODE, // Bit order: DP, G, F, E, D, C, B, A
    input [11:0] SW,         // SWs 11..0 placed from left to right
    input [3:0] PB,          // PBs 3..0 placed from left to right
    inout [23:0] GPIO,       // PMODA-C 1P, 1N, ... 3P, 3N order
    output [3:0] SERVO,      // Servo outputs
    output PDM_SPEAKER,      // PDM signals for mic and speaker
    input PDM_MIC_DATA,      
    output PDM_MIC_CLK,
    output ESP32_UART1_TXD,  // WiFi/Bluetooth serial interface 1
    input ESP32_UART1_RXD,
    output IMU_SCLK,         // IMU spi clk
    output IMU_SDI,          // IMU spi data input
    input IMU_SDO_AG,        // IMU spi data output (accel/gyro)
    input IMU_SDO_M,         // IMU spi data output (mag)
    output IMU_CS_AG,        // IMU cs (accel/gyro) 
    output IMU_CS_M,         // IMU cs (mag)
    input IMU_DRDY_M,        // IMU data ready (mag)
    input IMU_INT1_AG,       // IMU interrupt (accel/gyro)
    input IMU_INT_M,         // IMU interrupt (mag)
    output IMU_DEN_AG        // IMU data enable (accel/gyro)
    );
     
    // Terminate all of the unused outputs or i/o's
    // assign LED = 10'b0000000000;
    assign RGB0 = 3'b000;
    assign RGB1 = 3'b000;
    // assign SS_ANODE = 4'b0000;
    // assign SS_CATHODE = 8'b11111111;
    // assign GPIO = 24'bzzzzzzzzzzzzzzzzzzzzzzzz;
    assign GPIO[15:0] = 16'bzzzzzzzzzzzzzzzz;
    assign GPIO[23:20] = 4'bzzzzz;
    assign GPIO[18] = 1'bz;
    assign SERVO = 4'b0000;
    assign PDM_SPEAKER = 1'b0;
    assign PDM_MIC_CLK = 1'b0;
    assign ESP32_UART1_TXD = 1'b0;
    assign IMU_SCLK = 1'b0;
    assign IMU_SDI = 1'b0;
    assign IMU_CS_AG = 1'b1;
    assign IMU_CS_M = 1'b1;
    assign IMU_DEN_AG = 1'b0;

    // display S on left seven segment display
    assign SS_ANODE = 4'b0111;
    assign SS_CATHODE = 8'b10010010;

    // red and green leds
    reg red_led;
    reg green_led;
    assign red_led = GPIO[17];
    assign green_led = GPIO[19];
    
    // use a simpler clock name
    wire clk = CLK100;
    
    // handle input metastability safely
    reg reset;
    reg pre_reset;
    always_ff @ (posedge(clk))
    begin
        pre_reset <= PB[0];
        reset <= pre_reset;
    end
    reg shift_in;
    reg pre_shift_in;
    always_ff @ (posedge(clk))
    begin
        pre_shift_in <= PB[1];
        shift_in <= pre_shift_in;
    end
    reg pb_in;
    reg pre_pb_in;
    always_ff @ (posedge(clk))
    begin
        pre_pb_in <= GPIO[16];
        pb_in <= pre_pb_in;
    end
    
    // 1 Hz tick
    wire sec_tick;
    reg out;
    reg [3:0] count;
    reg [2:0] three;
    divide_by_100000000(clk, sec_tick);

    // toggle LED, inc count every second    
    always @ (posedge(clk))
    begin
        if (reset)
        begin
            count <= 0;
            three <= 0;
        end
        else
            if (sec_tick)
            begin
                out <= !out;
                count <= count + 1;
                three[2] <= three[1];
                three[1] <= three[0];
                three[0] <= shift_in;
            end
    end 
			  
    assign LED = {three, 1'b0, count, 1'b0, out};
    
    always_ff @ (posedge(clk))
    begin
        if (reset)
        begin
            red_led <= 1;
            green_led <= 0;
        end
        else if (!pb_in)
        begin
            red_led <= 0;
            green_led <= 1;
        end
    end
        
endmodule

// While this example includes this module in the seq_logic.sv file,
// it is best practice to put each module in a separate file with
// a filename matching the module name

module divide_by_100000000(
    input clk,
    output reg out);
    
    reg [26:0] count;
    
    always_ff @ (posedge(clk))
    begin
        if (count < 27'd100000000)
        begin
           count <= count + 1;
           out <= 0;
        end
        else
        begin
            count <= 0;
            out <= 1;
        end
    end    
endmodule
