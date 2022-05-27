module receiver(clk_9600hz, in, reset, data, data_received);

input clk_9600hz, in, reset;
output data_received;
reg data_received = 1'b0;
output [7:0]data;
reg [7:0]data;	
reg [1:0]state;
	parameter START = 0, 
				 DATA = 1,
				 STOP = 2;			 

integer counter = 0;


always @ (state) begin
	case(state)
		START:
			data_received = 1'b0;
		DATA:
			data_received = 1'b0;
		STOP:
			data_received = 1'b1;
	endcase		
end
		

always @ (posedge clk_9600hz or posedge reset) begin
if (reset)
state <= START;
else
case (state)
	START:
		begin
			//Verifica o bit de start da transmissão
			if(in)
				state <= START;
			else
				state <= DATA;
		end
	DATA:
		begin
			//Lê e armazena cada bit contido na entrada
			if(counter > 7)
				state <= STOP;
			else begin			
				data[counter] = in;
				state <= DATA;
				counter = counter + 1;				
			end	
		end
	STOP:
		begin
			//Finaliza a leitura e retorna ao estado de espera
			counter = 0;
			state <= START;
		end
endcase
end
endmodule