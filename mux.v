module mux(in1, in2, select, out);
	input [4:0] in1, in2;
	input select;
	output reg [4:0] out;
	
	always @(*)
	begin
		if(select)
			begin
				out = in1;
			end
		else
			begin
				out = in2;
			end
	end

endmodule