interface uart_if (
    input clk,
    input rstn
);
    logic data;

    modport master (
        output data
    );

    modport slave (
        input  data
    );

    modport monitor (
        input  data
    );

    //`ifdef SIMULATION
        clocking cb_master @ (posedge clk);
            input  data;
        endclocking

        modport cb_master_modport (
            input rstn,
            clocking cb_master
        );

        clocking cb_slave @ (posedge clk);
            inout  data;
        endclocking

        modport cb_slave_modport (
            input rstn,
            clocking cb_slave
        );

        clocking cb_monitor @ (posedge clk);
            input  data;
        endclocking

        modport cb_monitor_modport (
            input rstn,
            clocking cb_monitor
        );
    //`endif 
endinterface