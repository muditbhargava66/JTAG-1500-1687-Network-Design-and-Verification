-- JTAG Network IEEE 1500 Hardware Description (ICL) File
-- This file describes the IEEE 1500 network for the JTAG controller.

Network JTAG_NETWORK {
    // Interface definition
    Interface {
        Signals {
            in bit TCK;  // Test Clock
            in bit TMS;  // Test Mode Select
            in bit TDI;  // Test Data In
            out bit TDO; // Test Data Out
        }
    }

    // Modules within the network
    Module JTAG_CONTROLLER {
        Interface {
            Signals {
                in bit TCK;  // Test Clock
                in bit TMS;  // Test Mode Select
                in bit TDI;  // Test Data In
                out bit TDO; // Test Data Out
            }
        }
    }

    // Connections
    Connection {
        from Interface.TCK to JTAG_CONTROLLER.TCK;
        from Interface.TMS to JTAG_CONTROLLER.TMS;
        from Interface.TDI to JTAG_CONTROLLER.TDI;
        from JTAG_CONTROLLER.TDO to Interface.TDO;
    }

    // Boundary-Scan register definitions
    BoundaryScanRegister {
        Cell {
            ScanIn = Interface.TDI;
            ScanOut = Interface.TDO;
            Clock = Interface.TCK;
            Mode = Interface.TMS;
        }
    }
}
