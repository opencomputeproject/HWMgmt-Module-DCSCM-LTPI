# LTPI IP Implementation
This repository contains:
- Verilog Source Code of standalone LTPI IP (SCM + HPM)
- Intel® Quartus® Example Project File for Intel® MAX® 10 CPLD
- Complete set of LTPI Unit Tests Implementation Package

LTPI IP that is compliant with the DC-SCM 2.x LTPI Specification. The DC-SCM 2.x LTPI specification is developed under Hardware Management Module Sub-project: https://www.opencompute.org/w/index.php?title=Server/MHS/DC-SCM-Specs-and-Designs

# Documentation:
The architecure details and a user guide covering how to build LTPI IP and run all unit tests under simulation is located in [docs/LTPI_User_Guide.pdf](docs/LTPI_User_Guide.pdf)

# Tests:
The list of unit tests implemented for LTPI IP is located [docs/LTPI_test_plan.xlsx](docs/LTPI_test_plan.xlsx)
        
# License:
Unless otherwise identified in the header file, all source code in ths repository is under MIT license and all documentation is under Creative Commons Attribution 4.0 International License available at http://creativecommons.org/licenses/by/4.0/

# Versions

| Version       | Date                  | Description |
| -----------   | -----------           | ----------- |
| 1.0           | 22 August, 2023       | Initial public relese, LTPI 1.0     |
| 1.05          | 24 November, 2023     |  OCP 2023 LTPI Interoperability Demo version:<br>  - Added clarification regarding CRC algorithm (no inversion/reflection) <br>  - Added clarification regarding Total Number on NL GPIOs <br>  - Increased the LTPI Advertise Frame Alignment timeout to 100ms|
| 1.09          | 16 May, 2025          |- Exposed to the top LTPI modules data channel and CSR access signals <br>  - Increased data channel timeout to 10ms <br>  - Synchronize lvds phy reset signals   <br>  - Changed SMBUSs timing parameters <br>  - Added gpio ltpi top module and ltpi top module parameterized unit test |
| 1.10          | 19 May, 2025          |- Added requirement for Data Echo and Data Received Echo to be sent at least 3 times and received at least once correctly <br> Implementation compliant with 1.1 LTPI Specification. |




