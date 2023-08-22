	i2c_controller_avmm_bridge u0 (
		.i2c_clock_clk     (<connected-to-i2c_clock_clk>),     //  i2c_clock.clk
		.i2c_csr_address   (<connected-to-i2c_csr_address>),   //    i2c_csr.address
		.i2c_csr_read      (<connected-to-i2c_csr_read>),      //           .read
		.i2c_csr_write     (<connected-to-i2c_csr_write>),     //           .write
		.i2c_csr_writedata (<connected-to-i2c_csr_writedata>), //           .writedata
		.i2c_csr_readdata  (<connected-to-i2c_csr_readdata>),  //           .readdata
		.i2c_irq_irq       (<connected-to-i2c_irq_irq>),       //    i2c_irq.irq
		.i2c_reset_reset_n (<connected-to-i2c_reset_reset_n>), //  i2c_reset.reset_n
		.i2c_serial_sda_in (<connected-to-i2c_serial_sda_in>), // i2c_serial.sda_in
		.i2c_serial_scl_in (<connected-to-i2c_serial_scl_in>), //           .scl_in
		.i2c_serial_sda_oe (<connected-to-i2c_serial_sda_oe>), //           .sda_oe
		.i2c_serial_scl_oe (<connected-to-i2c_serial_scl_oe>)  //           .scl_oe
	);

