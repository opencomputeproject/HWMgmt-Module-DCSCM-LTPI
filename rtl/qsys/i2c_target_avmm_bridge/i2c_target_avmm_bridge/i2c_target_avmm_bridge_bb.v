
module i2c_target_avmm_bridge (
	address,
	read,
	readdata,
	readdatavalid,
	waitrequest,
	write,
	byteenable,
	writedata,
	clk,
	i2c_data_in,
	i2c_clk_in,
	i2c_data_oe,
	i2c_clk_oe,
	rst_n);	

	output	[31:0]	address;
	output		read;
	input	[31:0]	readdata;
	input		readdatavalid;
	input		waitrequest;
	output		write;
	output	[3:0]	byteenable;
	output	[31:0]	writedata;
	input		clk;
	input		i2c_data_in;
	input		i2c_clk_in;
	output		i2c_data_oe;
	output		i2c_clk_oe;
	input		rst_n;
endmodule
