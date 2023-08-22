`ifndef GUARD_I2C_CONTROLLER_BRIDGE_DRIVER
`define GUARD_I2C_CONTROLLER_BRIDGE_DRIVER

localparam I2C_TARGET_ADDR = 7'h55;

class I2C_controller_bridge_driver;
    import ltpi_pkg::*;

    typedef virtual logic_avalon_mm_if #(
        .DATA_BYTES     (4),
        .ADDRESS_WIDTH  (32),
        .BURST_WIDTH    (0)
    ) .cb_slave_modport avmm_vif_t;

    local avmm_vif_t vif;

    function new (avmm_vif_t vif);
        this.vif = vif;
    endfunction

    task reset();
        vif.cb_slave.read               <= 0;
        vif.cb_slave.write              <= 0;
        vif.cb_slave.address            <= 0; 
        for (int b = 0; b < 4; b++) begin
            vif.cb_slave.writedata[b]   <= 0;
        end
        vif.cb_slave.byteenable         <= 0;
    endtask

    task  avmm_write(logic [15:0] address, logic [31:0] data);
        @ (this.vif.cb_slave);
        this.vif.cb_slave.read          <= 0;
        this.vif.cb_slave.write         <= 1;
        this.vif.cb_slave.address       <= address;

        for (int b = 0; b < 4; b++) begin
            this.vif.cb_slave.writedata[b] <=  data[b*8 +: 8];
        end
        this.vif.cb_slave.byteenable    <= '1;
        @ (this.vif.cb_slave);

        this.vif.cb_slave.read          <= 0;
        this.vif.cb_slave.write         <= 0;
        this.vif.cb_slave.address       <= 0;        
        @ (this.vif.cb_slave);
    endtask

    task  avmm_read(logic [15:0] address, ref logic [31:0] data);
        @ (this.vif.cb_slave);
        this.vif.cb_slave.read          <= 1;
        this.vif.cb_slave.write         <= 0;
        this.vif.cb_slave.address       <= address;
        this.vif.cb_slave.byteenable    <= '1;

        @ (this.vif.cb_slave);
        this.vif.cb_slave.read          <= 0;
        this.vif.cb_slave.write         <= 0;
        this.vif.cb_slave.address       <= 0;    

        @ (this.vif.cb_slave);
        @ (this.vif.cb_slave);
        for (int b = 0; b < 4; b++) begin
            data[b*8 +: 8] =  this.vif.cb_slave.readdata[b];
        end
        @ (this.vif.cb_slave);
    endtask

    task i2c_controller_setup();
        logic[31:0] data_rd;
        
        avmm_write(4'h2,0); //Diseble Avalone i2C 
        avmm_write(4'h3,32'h0000_0003);//Configure ISER
        avmm_write(4'h8,32'h0000_007D);//Configure SCL_LOW 0x08 -100k
        avmm_write(4'h9,32'h0000_007D);//Configure SCL_HIGH 0x09 - 100k
        avmm_write(4'hA,32'h0000_000F);//Configure SDA_HOLD 0x0A
        avmm_write(4'h2,32'h0000_000F);//Enable Avalone i2C 

        for (int i = 0 ; i<11 ;i++) begin
            avmm_read(i,data_rd);
            $display("REGISTER adr: %h data %h", i,data_rd);
        end

        data_rd = 0; 
        while(!(data_rd & 32'h0000_0001)) begin
            avmm_read(4'h4, data_rd);
        end
    endtask

    task  i2c_controller_write(logic [15:0] address, logic[31:0] data);
        logic[31:0] data_rd = 0;

        avmm_write(4'h0,{24'h0000_02, I2C_TARGET_ADDR ,1'b0}); //TRANSMIT TARGET ADR BYTE
        while(!(data_rd & 32'h0000_0001)) begin //wait for TX_READY ==1
            avmm_read(4'h4, data_rd);
            //$display("data_rd: %h", data_rd);
        end
        
        avmm_write(4'h0,{24'h0000_00,address[15:8]});//TRANSMIT avalone write adres byte 0
        data_rd = 0;
        while(!(data_rd & 32'h0000_0001)) begin //wait for TX_READY ==1
            avmm_read(4'h4, data_rd);
        end

        avmm_write(4'h0,{24'h0000_00,address[7:0]});//TRANSMIT avalone write adres byte 1
        data_rd = 0;
        while(!(data_rd & 32'h0000_0001)) begin //wait for TX_READY ==1
            avmm_read(4'h4, data_rd);
        end
        for(int b = 0 ; b < 4 ; b++) begin
            
            if( b == 3 ) begin
                avmm_write(4'h0, {24'h0000_01,data[b*8 +: 8]});
            end
            else begin
                avmm_write(4'h0,{4'h0,24'h0000_00,data[b*8 +: 8]});
            end
            data_rd = 0;
            while(!(data_rd & 32'h0000_0001)) begin //wait for TX_READY ==1
                avmm_read(4'h4, data_rd);
            end
        end
        $display("WRITE ADR: %h | DATA : %h", address, data); 
    endtask

    task  i2c_controller_write_8(logic [15:0] address, logic[7:0] data);
        logic[31:0] data_rd = 0;

        avmm_write(4'h0,{24'h0000_02, I2C_TARGET_ADDR ,1'b0}); //TRANSMIT TARGET ADR BYTE
        while(!(data_rd & 32'h0000_0001)) begin //wait for TX_READY ==1
            avmm_read(4'h4, data_rd);
            //$display("data_rd: %h", data_rd);
        end
        
        avmm_write(4'h0,{24'h0000_00,address[15:8]});//TRANSMIT avalone write adres byte 0
        data_rd = 0;
        while(!(data_rd & 32'h0000_0001)) begin //wait for TX_READY ==1
            avmm_read(4'h4, data_rd);
        end

        avmm_write(4'h0,{24'h0000_00,address[7:0]});//TRANSMIT avalone write adres byte 1
        data_rd = 0;
        while(!(data_rd & 32'h0000_0001)) begin //wait for TX_READY ==1
            avmm_read(4'h4, data_rd);
        end

        avmm_write(4'h0, {24'h0000_01,data});

        data_rd = 0;
        while(!(data_rd & 32'h0000_0001)) begin //wait for TX_READY ==1
            avmm_read(4'h4, data_rd);
        end

        $display("WRITE ADR: %h | DATA : %h", address, data); 
    endtask

    task  i2c_controller_read (logic [15:0] address, ref bit[31:0] data);

        logic[31:0] data_rd = 0;
        avmm_write(4'h0,{24'h0000_02, I2C_TARGET_ADDR , 1'b0}); //TRANSMIT TARGET ADR BYTE
        while(!(data_rd & 32'h0000_0001)) begin //wait for TX_READY ==1
            avmm_read(4'h4, data_rd);
            //$display("data_rd: %h", data_rd);
        end
        
        avmm_write(4'h0,{24'h0000_00,address[15:8]});//TRANSMIT avalone read adres byte 0
        data_rd = 0;
        while(!(data_rd & 32'h0000_0001)) begin //wait for TX_READY ==1
            avmm_read(4'h4, data_rd);
        end

        avmm_write(4'h0,{24'h0000_00,address[7:0]});//TRANSMIT avalone read adres byte 1
        data_rd = 0;
        while(!(data_rd & 32'h0000_0001)) begin //wait for TX_READY ==1
            avmm_read(4'h4, data_rd);
        end

        avmm_write(4'h0,{24'h0000_02, I2C_TARGET_ADDR ,1'b1});//TRANSMIT TARGET ADR COMMAND RD
        data_rd = 0;
        while(!(data_rd & 32'h0000_0001)) begin //wait for TX_READY ==1
            avmm_read(4'h4, data_rd);
        end

        for(int b = 0; b < 4; b++) begin
            if(b < 3) begin
                avmm_write(4'h0, 0); //Read 1/2/3 B
            end
            else begin
                avmm_write(4'h0, 32'h0000_0100); //Read 4 B then stop
            end

            data_rd = 0;
            while((data_rd & 32'h0000_0002) != 32'h0000_0002) begin //wait for RX_READY ==1
                avmm_read(4'h4, data_rd);
            end

            avmm_read(4'h1, data_rd);
            data [b*8 +: 8] = data_rd[7:0]; 
        end
        $display("READ ADR: %h | DATA : %h", address , data); 
    endtask

    task  i2c_controller_read_8 (logic [15:0] address, ref bit[7:0] data);
        logic[31:0] data_rd = 0;
        data = 0;
        avmm_write(4'h0,{24'h0000_02, I2C_TARGET_ADDR , 1'b0}); //TRANSMIT TARGET ADR BYTE
        while(!(data_rd & 32'h0000_0001)) begin //wait for TX_READY ==1
            avmm_read(4'h4, data_rd);
            //$display("data_rd: %h", data_rd);
        end
        
        avmm_write(4'h0,{24'h0000_00,address[15:8]});//TRANSMIT avalone read adres byte 0
        data_rd = 0;
        while(!(data_rd & 32'h0000_0001)) begin //wait for TX_READY ==1
            avmm_read(4'h4, data_rd);
        end

        avmm_write(4'h0,{24'h0000_00,address[7:0]});//TRANSMIT avalone read adres byte 1
        data_rd = 0;
        while(!(data_rd & 32'h0000_0001)) begin //wait for TX_READY ==1
            avmm_read(4'h4, data_rd);
        end

        avmm_write(4'h0,{24'h0000_02, I2C_TARGET_ADDR ,1'b1});//TRANSMIT TARGET ADR COMMAND RD
        data_rd = 0;
        while(!(data_rd & 32'h0000_0001)) begin //wait for TX_READY ==1
            avmm_read(4'h4, data_rd);
        end

        avmm_write(4'h0, 32'h0000_0100); //Read 1 B then stop

        data_rd = 0;
        while((data_rd & 32'h0000_0002) != 32'h0000_0002) begin //wait for RX_READY ==1
            avmm_read(4'h4, data_rd);

        end

        avmm_read(4'h1, data_rd);
        data [7:0] = data_rd[7:0]; 

        $display("READ ADR: %h | DATA : %h", address , data); 
    endtask

    task  get_status(ref bit [7:0] status);
        i2c_controller_read_8(15'h418, status);
    endtask

    task  wait_for_req_ready();
        bit [7:0] status;
        while(1) begin
            get_status(status);
            if (status[2]) break;
        end
    endtask

    task  send_req();
        bit [7:0] status = 0;
        status[3] = 1;
        i2c_controller_write_8(16'h418, status);

        while(1) begin
            get_status(status);
            if (!status[3]) break;
        end
    endtask

    task  wait_for_resp_ready();
        bit [7:0] status;
        while(1) begin
            get_status(status);
            if (status[0]) break;
        end
    endtask

    task  recv_resp();
        bit [7:0] status = 0;
        status[1] = 1;
        i2c_controller_write_8(16'h418, status);
        while(1) begin
            get_status(status);
            if (!status[1]) break;
        end
    endtask

    task  write_cmd(logic [7:0] cmd);
        i2c_controller_write_8(16'h400, cmd);
    endtask

    task  write_tag(logic [7:0] tag);
        i2c_controller_write_8(16'h401, tag);
    endtask

    task  write_address(logic [31:0] address);
        i2c_controller_write(16'h404,address);
    endtask

    task  write_data(logic [31:0] data, logic [3:0] ben = 4'hF);
        i2c_controller_write(16'h408,data);
        i2c_controller_write_8(16'h402,ben);
    endtask

    task mm_request_write(logic [31:0] address, logic [31:0] data, logic [3:0] ben, logic [7:0] tag);
        wait_for_req_ready();
        write_cmd(ltpi_pkg::WRITE_REQ);
        write_address(address);
        write_data(data, ben);
        write_tag(tag);
        send_req();
    endtask

    task  mm_request_read(logic [31:0] address, logic [3:0] ben, logic [7:0] tag);
        wait_for_req_ready();
        write_address(address);
        write_data(0, ben);
        write_tag(tag);
        write_cmd(ltpi_pkg::READ_REQ);
        send_req();
    endtask

    task  read_cmd(output bit [7:0] cmd);
        i2c_controller_read_8(16'h40C,cmd);
    endtask

    task  read_tag(output bit [7:0] tag);
        i2c_controller_read_8(16'h40D,tag);
    endtask

    task  read_ben(output bit [7:0] ben);
        i2c_controller_read_8(16'h40E,ben);
    endtask

    task  read_status(output bit [7:0] status);
        i2c_controller_read_8(16'h40F,status);
    endtask

    task  read_address(output bit [31:0] address);
        i2c_controller_read(16'h410, address);

    endtask

    task  read_data(output bit [31:0] data);
        i2c_controller_read(16'h414, data);
    endtask

    task  mm_response(output bit [7:0] cmd, output bit [31:0] address, output bit [31:0] data, output bit [7:0] ben, output bit [7:0] status, output bit [7:0] tag);
        wait_for_resp_ready();
        recv_resp();
        read_cmd(cmd);
        read_tag(tag);
        read_ben(ben);
        read_status(status);
        read_address(address);
        read_data(data);

    endtask
endclass

`endif // GUARD_I2C_CONTROLLER_BRIDGE_DRIVER