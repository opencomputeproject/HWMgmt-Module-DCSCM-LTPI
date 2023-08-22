`ifndef GUARD_LTPI_DATA_CHANNEL_CONTROLLER_DRIVER
`define GUARD_LTPI_DATA_CHANNEL_CONTROLLER_DRIVER

class ltpi_data_channel_controller_driver;
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

    task WR32(input bit [15:0] addr, input bit [31:0] data);
        @ (this.vif.cb_slave);
        this.vif.cb_slave.write   <= 1;
        this.vif.cb_slave.read    <= 0;
        this.vif.cb_slave.address <= addr;
        for (int b = 0; b < 4; b++) begin
            this.vif.cb_slave.writedata[b]    <= data[b*8 +: 8];
            this.vif.cb_slave.byteenable[b]   <= 1;
        end

        wait (this.vif.cb_slave.waitrequest == 1);
        wait (this.vif.cb_slave.writeresponsevalid == 1);
        this.vif.cb_slave.write   <= 0;
        wait (this.vif.cb_slave.waitrequest == 0);

        this.vif.cb_slave.address <= 0;
        for (int b = 0; b < 4; b++) begin
            this.vif.cb_slave.writedata[b]    <= 0;
            this.vif.cb_slave.byteenable[b]   <= 0;
        end
        @ (this.vif.cb_slave);
    endtask

    task WR8(input bit [15:0] addr, input bit [7:0] data);
        @ (this.vif.cb_slave);
        this.vif.cb_slave.write   <= 1;
        this.vif.cb_slave.read    <= 0;
        this.vif.cb_slave.address <= { 16'h0, addr[15:2], 2'b00 };
        for (int b = 0; b < 4; b++) begin
            if (addr[1:0] == b) begin
                this.vif.cb_slave.writedata[b]    <= data;
                this.vif.cb_slave.byteenable[b]   <= 1;
            end
            else begin
                this.vif.cb_slave.writedata[b]    <= 0;
                this.vif.cb_slave.byteenable[b]   <= 0;
            end
        end

        wait (this.vif.cb_slave.waitrequest == 1);
        wait (this.vif.cb_slave.writeresponsevalid == 1);
        this.vif.cb_slave.write   <= 0;
        wait (this.vif.cb_slave.waitrequest == 0);

        this.vif.cb_slave.write   <= 0;
        this.vif.cb_slave.address <= 0;
        for (int b = 0; b < 4; b++) begin
            this.vif.cb_slave.writedata[b]    <= 0;
            this.vif.cb_slave.byteenable[b]   <= 0;
        end
        @ (this.vif.cb_slave);
    endtask

    task RD32(input bit [15:0] addr, output bit [31:0] data);
        @ (this.vif.cb_slave);
        this.vif.cb_slave.write       <= 0;
        this.vif.cb_slave.read        <= 1;
        this.vif.cb_slave.address     <= addr;
        this.vif.cb_slave.byteenable  <= '1;
        @ (this.vif.cb_slave);
        @ (this.vif.cb_slave);

        wait (this.vif.cb_slave.readdatavalid == 1);

        this.vif.cb_slave.read        <= 0;
        this.vif.cb_slave.address     <= 0;
        this.vif.cb_slave.byteenable  <= 0;

        for (int b = 0; b < 4; b++) begin
            data[b*8 +: 8] = this.vif.cb_slave.readdata[b];
        end

        @ (this.vif.cb_slave);
    endtask

    task RD8(input bit [15:0] addr, output bit [7:0] data);
        @ (this.vif.cb_slave);
        this.vif.cb_slave.write       <= 0;
        this.vif.cb_slave.read        <= 1;
        this.vif.cb_slave.address <= { 16'h0, addr[15:2], 2'b00 };
        for (int b = 0; b < 4; b++) begin
            
            if (addr[1:0] == b) begin
                this.vif.cb_slave.byteenable[b]   <= 1;
            end
            else begin
                this.vif.cb_slave.byteenable[b]   <= 0;
            end
        end

        wait (this.vif.cb_slave.readdatavalid == 1);

        for (int b = 0; b < 4; b++) begin
            if (addr[1:0] == b) begin
                data = this.vif.cb_slave.readdata[b];
            end
        end
        this.vif.cb_slave.read        <= 0;
        this.vif.cb_slave.address     <= 0;
        this.vif.cb_slave.byteenable  <= 0;

        @ (this.vif.cb_slave);
    endtask

    task get_status(ref bit [7:0] status);
        RD8(16'h418, status);
    endtask

    task wait_for_req_ready();
        bit [7:0] status;
        while(1) begin
            get_status(status);
            if (status[2]) break;
        end
    endtask

    task send_req();
        bit [7:0] status = 0;
        status[3] = 1;
        WR8(16'h418, status);
        while(1) begin
            get_status(status);
            if (!status[3]) break;
        end
    endtask

    task wait_for_resp_ready();
        bit [7:0] status;
        while(1) begin
            get_status(status);
            if (status[0]) break;
        end
    endtask

    task recv_resp();
        bit [7:0] status = 0;
        status[1] = 1;
        WR8(16'h418, status);
        while(1) begin
            get_status(status);
            if (!status[1]) break;
        end
    endtask

    task write_cmd(logic [7:0] cmd);
        WR8(16'h400, cmd);
    endtask

    task write_tag(logic [7:0] tag);
        WR8(16'h401, tag);
    endtask

    task write_address(logic [31:0] address);
        WR32(16'h404, address);
    endtask

    task write_data(logic [31:0] data, logic [3:0] ben = 4'hF);
        WR32(16'h408, data);
        WR8(16'h402, ben);
    endtask

    task request_write(logic [31:0] address, logic [31:0] data, logic [3:0] ben, logic [7:0] tag);
        wait_for_req_ready();
        write_cmd(ltpi_pkg::WRITE_REQ);
        write_address(address);
        write_data(data, ben);
        write_tag(tag);
        send_req();
    endtask

    task request_read(logic [31:0] address, logic [3:0] ben, logic [7:0] tag);
        wait_for_req_ready();
        write_address(address);
        write_data(0, ben);
        write_tag(tag);
        write_cmd(ltpi_pkg::READ_REQ);
        send_req();
    endtask

    task read_cmd(output bit [7:0] cmd);
        RD8(16'h40C, cmd);
    endtask

    task read_tag(output bit [7:0] tag);
        RD8(16'h40D, tag);
    endtask

    task read_ben(output bit [7:0] ben);
        RD8(16'h40E, ben);
    endtask

    task read_status(output bit [7:0] status);
        RD8(16'h40F, status);
    endtask

    task read_address(output bit [31:0] address);
        RD32(16'h410, address);
    endtask

    task read_data(output bit [31:0] data);
        RD32(16'h414, data);
    endtask

    task response(output bit [7:0] cmd, output bit [31:0] address, output bit [31:0] data, output bit [7:0] ben, output bit [7:0] status, output bit [7:0] tag);
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

`endif // GUARD_LTPI_DATA_CHANNEL_CONTROLLER_DRIVER