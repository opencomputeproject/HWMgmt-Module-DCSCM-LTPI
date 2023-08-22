	i2c_target_avmm_bridge u0 (
		.address       (<connected-to-address>),       // avalon_master.address
		.read          (<connected-to-read>),          //              .read
		.readdata      (<connected-to-readdata>),      //              .readdata
		.readdatavalid (<connected-to-readdatavalid>), //              .readdatavalid
		.waitrequest   (<connected-to-waitrequest>),   //              .waitrequest
		.write         (<connected-to-write>),         //              .write
		.byteenable    (<connected-to-byteenable>),    //              .byteenable
		.writedata     (<connected-to-writedata>),     //              .writedata
		.clk           (<connected-to-clk>),           //         clock.clk
		.i2c_data_in   (<connected-to-i2c_data_in>),   //   conduit_end.conduit_data_in
		.i2c_clk_in    (<connected-to-i2c_clk_in>),    //              .conduit_clk_in
		.i2c_data_oe   (<connected-to-i2c_data_oe>),   //              .conduit_data_oe
		.i2c_clk_oe    (<connected-to-i2c_clk_oe>),    //              .conduit_clk_oe
		.rst_n         (<connected-to-rst_n>)          //         reset.reset_n
	);

