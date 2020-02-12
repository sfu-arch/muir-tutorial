.. _appendix_aws:

Appendinx
===========

AXI-Lite interfaces for register access -- (SDA, OCL, BAR1)
-------------------------------------------------------------

There are three AXI-L master interfaces (Shell is master) that can be used for register access interfaces. Each interface is sourced from a different PCIe PF/BAR. Breaking this into multiple interfaces allows for different software entities to have a control interface into the CL:

.. _ocl:

* SDA AXI-L: Associated with MgmtPF, BAR4. If the developer is using AWS OpenCL runtime Lib (as in SDAccel case), this interface will be used for performance monitors etc.
* OCL: AXI-L: Associated with AppPF, BAR0. If the developer is using AWS OpenCL runtime lib(as in SDAccel case), this interface will be used for openCL Kernel access
* BAR1 AXI-L: Associated with AppPF, BAR1.

Please refer to PCI Address map for a more detailed view of the address map.