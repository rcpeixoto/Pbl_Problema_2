module transmitter(clk_9600hz, out, reset, data, start);

input clk_9600hz, reset, start;
input [0:7]data;
output out;

reg out;
reg [0:1]state;
	parameter START=0,
				 DATA=1,
				 STOP=2;
					
integer counter = 7;

always @ (posedge clk_9600hz or posedge reset) begin
if (reset)
	state <= START;
else
case(state)
	START:
		begin
			//Aguarda sinal de controle de início
			//de transmissão
			if(start) begin
				//Bit de inicialização
				out = 1'b0;
				state <= DATA;
			end
			else begin
				out = 1'b1;
				state <= START;
			end
		end
	DATA:
		begin
			//Lê os bits do registrador e os envia 
			if (counter < 0) begin
				out = 1'b1;
				state <= STOP;
			end
			else begin
				out = data [counter];
				counter = counter - 1;
				state <= DATA;
			end
		end
	STOP:
		begin
			//finalização da transmissão com um bit de parada
			state <= START;
			counter = 7;
		end
endcase
end

endmodule 