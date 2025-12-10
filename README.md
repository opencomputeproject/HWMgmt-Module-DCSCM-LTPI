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
| 1.0           | 22 August, 2023       | Initial public release, LTPI 1.0     |
| 1.05          | 24 November, 2023     |  OCP 2023 LTPI Interoperability Demo version:<br>  - Added clarification regarding CRC algorithm (no inversion/reflection) <br>  - Added clarification regarding Total Number on NL GPIOs <br>  - Increased the LTPI Advertise Frame Alignment timeout to 100ms|
| 1.09          | 16 May, 2025          |- Exposed to the top LTPI modules data channel and CSR access signals <br>  - Increased data channel timeout to 10ms <br>  - Synchronize lvds phy reset signals   <br>  - Changed SMBUSs timing parameters <br>  - Added gpio ltpi top module and ltpi top module parameterized unit test |
| 1.10          | 19 May, 2025          |- Added requirement for Data Echo and Data Received Echo to be sent at least 3 times and received at least once correctly <br> Implementation compliant with 1.1 LTPI Specification. |
| 1.20          | 12 December, 2025          | Implementation compliant with 1.2 LTPI Specification. <br> LTPI IP 1v2 version updates:<br>1. Extend CRC and Other Errors Handling with details for all LTPI error types and handling:<br>  - Added Frame lost error - Frame CRC verification failed or Unexpected Frame (modules: mgmt_phy_controller.sv and mgmt_phy_target.sv)<br> 2. Changed the LTPI Version name to LTPI Revision to match intended use:<br> - Regenerate CSR packages for all LTPI CSR configurations. (rtl/modules/CSR/RDL directory)<br> - Updated CSR generation packages script to use peakRDL version 1.4.0 (csr_gen.py)<br> 3. Modified Timeout condition for Link Speed (modules: mgmt_phy_controller.sv and mgmt_phy_target.sv)<br> 4. Extended the Link Speed condition for SCM with at least 1 Link Speed received from HPM (modules: mgmt_phy_controller.sv and mgmt_phy_target.sv, mgmt_ltpi_frm_rx.sv, mgmt_ltpi_frm_tx.sv)<br> 5. Updated Link Lost conditions in main controller and target FSM (modules: mgmt_phy_controller.sv and mgmt_phy_target.sv)<br> |