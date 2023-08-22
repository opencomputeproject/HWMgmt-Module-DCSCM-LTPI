`timescale 100 ps / 100 ps
`include "svunit_defines.svh"

module ltpi_data_channel_controller_csr_unit_test;
    import svunit_pkg::svunit_testcase;
    import ltpi_pkg::*;
    import ltpi_data_channel_controller_csr_rdl_pkg::*;
    import ltpi_data_channel_controller_model_pkg::*;

    string name = "ltpi_data_channel_controller_csr_unit_test";
    svunit_testcase svunit_ut;

    logic                   clk         = 0;
    logic                   reset       = 1;
    
    logic                   req_valid;
    logic                   req_ack;
    Data_channel_payload_t  req;
    logic                   resp_valid;
    Data_channel_payload_t  resp;

    logic_avalon_mm_if #(
        .DATA_BYTES     (4),
        .ADDRESS_WIDTH  (32),
        .BURST_WIDTH    (0)
    ) u_avmm (
        .aclk           (clk),
        .areset_n       (~reset)
    );

    ltpi_data_channel_controller_csr dut (
        .clk            (clk),
        .reset          (reset),
        .avalon_mm_s    (u_avmm),
        .req_valid      (req_valid),
        .req_ack        (req_ack),
        .req            (req),
        .resp_valid     (resp_valid),
        .resp           (resp)
    );

    ltpi_data_channel_controller_phy_model phy_model (
        .clk            (clk),
        .reset          (reset),
        .req_valid      (req_valid),
        .req_ack        (req_ack),
        .req            (req),
        .resp_valid     (resp_valid),
        .resp           (resp)
    );

    ltpi_data_channel_controller_driver u_controller_driver = new (u_avmm);

    initial forever #10 clk = ~clk;

    function void build(); 
        svunit_ut = new (name);
    endfunction
    
    task setup();
        svunit_ut.setup();
        reset = 1;
        u_controller_driver.reset();
        #100;
        @(posedge clk); 
        reset = 0;
    endtask

    task teardown();
        svunit_ut.teardown();
        reset = 1;
    endtask

    `SVUNIT_TESTS_BEGIN
        `SVTEST(basic)
            int size;

            bit [31:0] req_addr [];
            bit [31:0] req_data [];
            bit [ 7:0] req_tag  [];

            bit [ 7:0] resp_cmd;
            bit [ 7:0] resp_status;
            bit [ 7:0] resp_tag;
            bit [31:0] resp_address;
            bit [31:0] resp_data;
            bit [ 7:0] resp_ben;

            //VCS
            // void'(randomize (size) with {
            //     size inside {[10:50]};
            // });

            // void'(randomize (req_tag) with {
            //     req_tag.size() == size;
            // });

            // void'(randomize (req_addr) with {
            //     req_addr.size() == size;
            //     unique {req_addr};
            //     foreach (req_addr[i]) req_addr[i] < 4096;
            // });

            // void'(randomize (req_data) with {
            //     req_data.size() == size;
            // });

            //MODELSI & VCS
            size = 10;
            req_tag = new[size];
            foreach (req_tag[i]) req_tag[i] = $urandom_range(0, 8'hFF);
            req_addr = new[size];
            foreach(req_addr[i]) req_addr[i] = $urandom_range(0, 4096);
            req_data = new[size];
            foreach (req_data[i]) req_data[i] = $urandom_range(0, 32'hFFFF_FFFF);

            foreach (req_addr[i]) begin
                u_controller_driver.request_write(req_addr[i], req_data[i], 4'hF, req_tag[i]);
                u_controller_driver.response(resp_cmd, resp_address, resp_data, resp_ben, resp_status, resp_tag);

                `FAIL_UNLESS_EQUAL(data_chnl_comand_t'(resp_cmd), WRITE_COMP)
                `FAIL_UNLESS_EQUAL(resp_address, req_addr[i])
                `FAIL_UNLESS_EQUAL(resp_data, req_data[i])
                `FAIL_UNLESS_EQUAL(resp_ben, 4'hF)
                `FAIL_UNLESS_EQUAL(resp_status, 0)
                `FAIL_UNLESS_EQUAL(resp_tag, req_tag[i])
            end
            foreach (req_addr[i]) begin
                u_controller_driver.request_read(req_addr[i], 4'hF, req_tag[i]);
                u_controller_driver.response(resp_cmd, resp_address, resp_data, resp_ben, resp_status, resp_tag);

                `FAIL_UNLESS_EQUAL(data_chnl_comand_t'(resp_cmd), READ_COMP)
                `FAIL_UNLESS_EQUAL(resp_address, req_addr[i])
                `FAIL_UNLESS_EQUAL(resp_data, req_data[i])
                `FAIL_UNLESS_EQUAL(resp_ben, 4'hF)
                `FAIL_UNLESS_EQUAL(resp_status, 0)
                `FAIL_UNLESS_EQUAL(resp_tag, req_tag[i])
            end
        `SVTEST_END
    `SVUNIT_TESTS_END
endmodule