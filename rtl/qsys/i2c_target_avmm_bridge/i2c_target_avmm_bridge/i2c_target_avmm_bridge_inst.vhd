	component i2c_target_avmm_bridge is
		port (
			address       : out std_logic_vector(31 downto 0);                    -- address
			read          : out std_logic;                                        -- read
			readdata      : in  std_logic_vector(31 downto 0) := (others => 'X'); -- readdata
			readdatavalid : in  std_logic                     := 'X';             -- readdatavalid
			waitrequest   : in  std_logic                     := 'X';             -- waitrequest
			write         : out std_logic;                                        -- write
			byteenable    : out std_logic_vector(3 downto 0);                     -- byteenable
			writedata     : out std_logic_vector(31 downto 0);                    -- writedata
			clk           : in  std_logic                     := 'X';             -- clk
			i2c_data_in   : in  std_logic                     := 'X';             -- conduit_data_in
			i2c_clk_in    : in  std_logic                     := 'X';             -- conduit_clk_in
			i2c_data_oe   : out std_logic;                                        -- conduit_data_oe
			i2c_clk_oe    : out std_logic;                                        -- conduit_clk_oe
			rst_n         : in  std_logic                     := 'X'              -- reset_n
		);
	end component i2c_target_avmm_bridge;

	u0 : component i2c_target_avmm_bridge
		port map (
			address       => CONNECTED_TO_address,       -- avalon_master.address
			read          => CONNECTED_TO_read,          --              .read
			readdata      => CONNECTED_TO_readdata,      --              .readdata
			readdatavalid => CONNECTED_TO_readdatavalid, --              .readdatavalid
			waitrequest   => CONNECTED_TO_waitrequest,   --              .waitrequest
			write         => CONNECTED_TO_write,         --              .write
			byteenable    => CONNECTED_TO_byteenable,    --              .byteenable
			writedata     => CONNECTED_TO_writedata,     --              .writedata
			clk           => CONNECTED_TO_clk,           --         clock.clk
			i2c_data_in   => CONNECTED_TO_i2c_data_in,   --   conduit_end.conduit_data_in
			i2c_clk_in    => CONNECTED_TO_i2c_clk_in,    --              .conduit_clk_in
			i2c_data_oe   => CONNECTED_TO_i2c_data_oe,   --              .conduit_data_oe
			i2c_clk_oe    => CONNECTED_TO_i2c_clk_oe,    --              .conduit_clk_oe
			rst_n         => CONNECTED_TO_rst_n          --         reset.reset_n
		);

