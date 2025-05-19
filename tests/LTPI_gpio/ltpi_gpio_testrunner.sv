`ifdef RUN_SVUNIT_WITH_UVM
  import uvm_pkg::*;
`endif

module ltpi_gpio_testrunner();
  logic test_passed = 0;

  import svunit_pkg::svunit_testrunner;
  import svunit_pkg::svunit_testsuite;

  svunit_testrunner svunit_tr;
  svunit_testsuite svunit_ts;


  string name = "testrunner";
  //svunit_testrunner svunit_tr;


  //==================================
  // These are the test suites that we
  // want included in this testrunner
  //==================================

  //ltpi_gpio_param_unit_test ltpi_gpio_param_ut();
  ltpi_gpio_unit_test ltpi_gpio_ut();


  //===================================
  // Main
  //===================================
  // initial
  // begin

  //   `ifdef RUN_SVUNIT_WITH_UVM_REPORT_MOCK
  //     uvm_report_cb::add(null, uvm_report_mock::reports);
  //   `endif

  //   build();

  //   `ifdef RUN_SVUNIT_WITH_UVM
  //     svunit_uvm_test_inst("svunit_uvm_test");
  //   `endif

  //   run();
  //   $finish();
  // end


  //===================================
  // Build
  //===================================
  // function void build();
  //   svunit_tr = new(name);
  //   __ts.build();
  //   svunit_tr.add_testsuite(__ts.svunit_ts);
  // endfunction


  // //===================================
  // // Run
  // //===================================
  // task run();
  //   __ts.run();
  //   svunit_tr.report();
  // endtask

    initial begin
        build();
        run();

        unique case (svunit_tr.get_results())
        svunit_pkg::PASS: begin
            test_passed = 1;
            $finish;
        end
        svunit_pkg::FAIL: begin
            test_passed = 0;
            $fatal(1);
        end
        endcase
    end

    function void build();
        svunit_tr = new ("testrunner");
        svunit_ts = new ("testsuite");

        ut.build();
        svunit_ts.add_testcase(ut.svunit_ut);
        svunit_tr.add_testsuite(svunit_ts);
    endfunction

    task run();
        svunit_ts.run();
        ut.run();
        svunit_ts.report();
        svunit_tr.report();
    endtask

endmodule
