/////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2022 Intel Corporation
//
// Permission is hereby granted, free of charge, to any person obtaining a
// copy of this software and associated documentation files (the "Software"),
// to deal in the Software without restriction, including without limitation
// the rights to use, copy, modify, merge, publish, distribute, sublicense,
// and/or sell copies of the Software, and to permit persons to whom the
// Software is furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
// FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
// DEALINGS IN THE SOFTWARE.
/////////////////////////////////////////////////////////////////////////////////

module LTPI_top_gpio_unit_test_runner;
    logic test_passed = 0;

    import svunit_pkg::svunit_testrunner;
    import svunit_pkg::svunit_testsuite;

    svunit_testrunner svunit_tr;
    svunit_testsuite svunit_ts;

    LTPI_top_gpio_unit_test ut();

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
