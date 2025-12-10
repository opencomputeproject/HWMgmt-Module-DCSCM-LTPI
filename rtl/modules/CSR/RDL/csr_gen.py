#///////////////////////////////////////////////////////////////////////////////
# Copyright (c) 2022 Intel Corporation
#
# Permission is hereby granted, free of charge, to any person obtaining a
# copy of this software and associated documentation files (the "Software"),
# to deal in the Software without restriction, including without limitation
# the rights to use, copy, modify, merge, publish, distribute, sublicense,
# and/or sell copies of the Software, and to permit persons to whom the
# Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
# FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
# DEALINGS IN THE SOFTWARE.
#///////////////////////////////////////////////////////////////////////////////

from systemrdl import RDLCompiler, RDLCompileError
from peakrdl_regblock import RegblockExporter
from peakrdl_regblock.cpuif.passthrough import PassthroughCpuif
from peakrdl_regblock.cpuif.axi4lite import AXI4Lite_Cpuif
from peakrdl_regblock.udps import ALL_UDPS
import sys

class My_AXI4Lite(AXI4Lite_Cpuif):
    @property
    def port_declaration(self) -> str:
        # Override the port declaration text to use the alternate type name and modport style
        return "axi4_lite_interface.Slave_mp s_axil"

    def signal(self, name:str) -> str:
        # Override the signal names to be lowercase instead
        return "s_axil." + name.lower()


input_files = [
    "CSR_regs_full.rdl"
    #"CSR_regs_light.rdl"
]

# Create an instance of the compiler
rdlc = RDLCompiler()

# Register all UDPs that 'regblock' requires
for udp in ALL_UDPS:
    rdlc.register_udp(udp)

try:
    # Compile your RDL files
    for input_file in input_files:
        rdlc.compile_file(input_file)

    # Elaborate the design
    root = rdlc.elaborate()
except RDLCompileError:
    # A compilation error occurred. Exit with error code
    sys.exit(1)

# Export a SystemVerilog implementation
exporter = RegblockExporter()
exporter.export(
    root, ".",
    cpuif_cls=PassthroughCpuif
    #cpuif_cls=My_AXI4Lite
)