module sensor_controller(start, data_in, data_out, data_received, clk_9600hz, reset, sensor_data, start_sensor, error);

//Pin definition
input [0:39]sensor_data;
input data_received, clk_9600hz, reset;
input error;
output start, start_sensor;
reg start, start_sensor;

input [0:7]data_in;
output reg [0:7]data_out;

//Sensor data
reg [0:15]humidity;
reg [0:15]temperature;
reg [0:7]checksum;

integer counter;

reg [0:3]state;
		parameter SLEEP = 0,
					 AWAKE = 1,
					 WAIT_ADDRESS= 2,
					 WAIT_COMMAND = 3,
					 WAIT_SENSOR = 4,
					 STORE_DATA = 5,
					 START_DATA = 6,
					 BYTE_1 = 7,
					 BYTE_2 = 8,
					 END = 9;
					 
					 
reg [0:7]address;
reg [0:7]command;



always @ (posedge clk_9600hz or posedge reset) begin
if (reset)
	state <= SLEEP;
else
	case(state)
		SLEEP:
			begin
				start <= 1'b0;
				start_sensor <= 1'b0;
				//Aguarda por uma mensagem de inicialização
				if(data_received == 1'b1 && data_in[0:7] == 8'b00000000) 
					state <= AWAKE;
				else
					state <= SLEEP;
			end
		AWAKE:
			begin
				//Responde a inicialização 
				//TODO modificar para estado wait_address
				start <= 1'b1;
				data_out[0:7] <= 8'b00000001;
				state <= WAIT_ADDRESS;
			end
		WAIT_ADDRESS:
			begin
				//Espera o enderesso enviado pela serial
				start <= 1'b0;
				if(data_received) begin
					address[0:7] <= data_in[0:7];
					state <= WAIT_COMMAND;
				end else begin
					state <= WAIT_ADDRESS;
				end
			end
		WAIT_COMMAND:
			begin
				//Espera o Comando enviado pela serial
				if(data_received) begin
					command[0:7] <= data_in[0:7];
					start_sensor <= 1'b1;
					state <= WAIT_SENSOR;
				end else begin
					state <= WAIT_COMMAND;
				end
			end
		WAIT_SENSOR:
			begin
				//Espera 22ms pela comunicacao com o sensor.
				start_sensor<=1'b0;
				if(counter > 212)begin
					counter = 0;
					state <= STORE_DATA;
				end else begin
					counter = counter + 1;
					state <= WAIT_SENSOR;
				end
				
			end
		STORE_DATA:
			begin
				//Armazena os dados extraidos dos sensores 
				humidity[0:15] = sensor_data[0:15];
				temperature[0:15] = sensor_data[16:31];
				state<=START_DATA;
			end
		START_DATA:
			begin
				start<=1'b1;
				//Verifica qual opção foi enviada e retorna o código correspondente.
				if (command == 8'b00000100) begin
					data_out[0:7] = 8'b00000010;
				end else if (command == 8'b00000101) begin
					data_out[0:7] = 8'b00000001;
				end else if (command == 8'b00000110 && error == 1'b1) begin
					data_out[0:7] = 8'b00001111;
					state <= END;
				end else begin
					data_out[0:7] = 8'b00000000;
					state <= END;
				end
				state <= BYTE_1;
			end
		BYTE_1:
			begin
				if(counter > 9) begin
					//Envia o primeiro byte do dado, sendo este
					//Temperatura ou humidade
					if (command == 8'b00000101) begin
						data_out[0:7] = humidity[0:7];
					end else begin
						data_out[0:7] <= temperature[0:7];
					end
					counter = 0;
					state <= BYTE_2;
				end else begin
					counter = counter + 1;
					state <= BYTE_1;
				end
			end
		BYTE_2:
			begin
				if(counter > 9) begin
					//Envia o segundo byte do dado, sendo este
					if (command == 8'b00000101) begin
						data_out[0:7] = humidity[8:15];
					end else begin
						data_out[0:7] <= temperature[8:15];
					end
					counter = 0;
					state <= END;
				end else begin
					counter = counter + 1;
					state <= BYTE_2;
				end
			end
		END:
			begin
				if(counter > 9) begin
					//Envia o byte de finalização
					data_out[0:7] = 8'b11110000;
					counter = 0;
					state <= SLEEP;
				end else begin
					counter = counter + 1;
					state <= END;
				end
			end
	endcase
end
			 
endmodule