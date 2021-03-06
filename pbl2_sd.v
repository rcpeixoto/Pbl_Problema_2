module pbl2_sd(out, in, clk_50mhz, reset, sensor_pin);
		 
input in, clk_50mhz, reset;
output out;
inout sensor_pin;

wire [0:7]data_in;
wire [0:7]data_out;


wire clk_9600hz;

//Divisor de clock para 9600hz
clock_divider divider_0(
	.clk_50mhz(clk_50mhz),
	.clk_9600hz(clk_9600hz)
);

wire start;
wire error;
wire data_received;
//Bloco de recepção de dados serial
receiver receiver_0(
	.clk_9600hz(clk_9600hz),
	.in(in),
	.reset(reset),
	.data(data_in),
	.data_received(data_received)
);

wire [0:39]sensor_data;
wire start_sensor;
wire sensor_ready;
//Controladora principal dos sensores
sensor_controller sensor_controller_0(
	.start(start),
	.data_in(data_in),
	.data_out(data_out),
	.reset(reset),
	.data_received(data_received),
	.sensor_data(sensor_data),
	.clk_9600hz(clk_9600hz),
	.start_sensor(start_sensor),
	.error(error)
);
wire clk_1mhz;

//Divisor de clock para 1Mhz
clock_divider1mhz divider_1(
	.clk_50mhz(clk_50mhz),
	.clk_1mhz(clk_1mhz)
);


//Bloco interface com o sensor de humidade e temperatura
dht11 dht11_0(
	.clk_1mhz(clk_1mhz),
	.sensor_data(sensor_data),
	.start_sensor(start_sensor),
	.sensor_pin(sensor_pin),
	.error(error)
);

//Bloco de transmissão de dados serial
transmitter transmitter_0(
	.clk_9600hz(clk_9600hz),
	.out(out),
	.reset(reset),
	.data(data_out),
	.start(start)
);
endmodule