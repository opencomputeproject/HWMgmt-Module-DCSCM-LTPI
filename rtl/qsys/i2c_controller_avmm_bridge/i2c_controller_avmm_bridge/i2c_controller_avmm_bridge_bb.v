
module i2c_controller_avmm_bridge (
	i2c_clock_clk,
	i2c_csr_address,
	i2c_csr_read,
	i2c_csr_write,
	i2c_csr_writedata,
	i2c_csr_readdata,
	i2c_irq_irq,
	i2c_reset_reset_n,
	i2c_serial_sda_in,
	i2c_serial_scl_in,
	i2c_serial_sda_oe,
	i2c_serial_scl_oe);	

	input		i2c_clock_clk;
	input	[3:0]	i2c_csr_address;
	input		i2c_csr_read;
	input		i2c_csr_write;
	input	[31:0]	i2c_csr_writedata;
	output	[31:0]	i2c_csr_readdata;
	output		i2c_irq_irq;
	input		i2c_reset_reset_n;
	input		i2c_serial_sda_in;
	input		i2c_serial_scl_in;
	output		i2c_serial_sda_oe;
	output		i2c_serial_scl_oe;
endmodule
