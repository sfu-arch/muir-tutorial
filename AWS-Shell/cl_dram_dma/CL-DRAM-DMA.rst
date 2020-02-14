.. _cl_dram_dma:

Custom Logic DRAM DMA
======================

.. Defining colors:

.. raw:: html

    <style> .coral {color:coral} </style>

.. role:: coral


.. raw:: html

    <style> .limegreen {color:limegreen} </style>

.. role:: limegreen


.. raw:: html

    <style> .turquoise {color:turquoise} </style>

.. role:: turquoise

.. raw:: html

    <style> .mediumblue {color:mediumblue} </style>

.. role:: mediumblue





The CL_DRAM_DMA example demonstrates lots of the Shell/CL interfaces and functionality.
This page will walk through the custom logic (CL) portion of the example.You may have found that this example has more than 6000 lines of SystemVerilog code but with very little comments.
To help you quickly understand the example from a high level, I created some block diagrams to overview the CL’s hierarchy, interface, connectivity, and functionality.
We will also dive into some major modules and go through the implementations.
Following is the block diagram legends used in the rest of the page:

.. thumbnail:: ../figures/dma_legends.png
    :width: 400px
    :height: 40px
    :align: center

    Figure legends

.. centered::  **Figure 1: legends**

An arrow represents the connection from master to slave.
There are four major types of signal interfaces in the example.
The interfaces are defined as the SystemVerilog ``Interface`` constructs in *cl_dram_dma_pkg.sv*, namely **axi_bus_t** (used for :coral:`AXI-4` and :limegreen:`AXI-lite` signals), :turquoise:`cfg_bus_t`, and :mediumblue:`scrb_bus_t`.
The signals surrounded by grey hexagons are the input or output ports of the module. Black boxes represent RTL modules and the dash-lined circles represent the logic within current module.

Now let’s start with the top level block diagram of the CL_DRAM_DMA.

.. thumbnail:: ../figures/CL_DRAM_DMA.png
    :width: 700px
    :height: 150px
    :align: center

    Top-Level block diagram of CL_DRAM_DMA

.. centered::  **Figure 2: Top-level block diagram of CL_DRAM_DMA**

The left side of the diagram shows five major incoming interfaces from Shell to CL:

1. The :limegreen:`sda_cl_bus` AXI-lite interface accesses a 1KB RAM inside the CL_SDA_SLV module;
2. The :coral:`sh_cl_dma_pcis_bus` AXI-4 interface is for the access to the `four DDR DRAMs <https://github.com/aws/aws-fpga/blob/master/hdk/docs/AWS_Shell_Interface_Specification.md#external-memory-interfaces-implemented-in-cl>`_;
3. The lower four bits of the *sh_cl_ctl0* input port drive the enable ports of the four :mediumblue:`ddr*_scrb_bus`;
4. The :limegreen:`sh_ocl_bus` AXI-lite interface talks to the CL_OCL_SLV module which then accordingly controls six test config buses *(:turquoise:`\*_tst_cfg_bus`)*, that are used for the four DDRs, the PCIM master *(CL_PCIM_MSTR)*, and the interrupt generator/checker *(CL_INT_SLV)*;
5. Lastly, the interrupt request acknowledge input (sh_cl_apppf_irq_ack) goes into the interrupt generator/checker *(CL_INT_SLV)* in response to the interrupt request output (cl_sh_apppf_irq_req).


Here are the five custom logic modules instantiated by this top-level RTL,

1. The **CL_DMA_PCIS_SLV** module (we will dive in later) takes in three sets of inputs, the :coral:`sh_cl_dma_pcis_bus` AXI-4 interface, the :mediumblue:`ddr*_scrb_bus`.enable, and the :turquoise:`ddr*_tst_cfg_bus`; and outputs four sets of AXI-4 buses (:coral:`lcl_cl_sh_ddr(a/b/d), cl_sh_ddr_bus`) to interface with the four DDR DRAMs. The :coral:`cl_sh_ddr_bus` goes out from CL to Shell in order to access DDRC that resides in the Shell. The other three buses, :coral:`lcl_cl_sh_ddr(a/b/d)`, are combined into a 2-dimensional bus (:coral:`lcl_cl_sh_ddr_2d`) feeding into the `SH_DDR <https://github.com/aws/aws-fpga/blob/master/hdk/docs/AWS_Shell_Interface_Specification.md#external-memory-interfaces-implemented-in-cl>`_ module that instantiates the three DRAM interfaces in the CL (A, B, D).  The *CL_DMA_PCIS_SLV* module also outputs the memory scrubbing status (:mediumblue:`ddr*_scrb_bus.addr/state/done`) for debugging purpose.  Another output of the module, :coral:`sh_cl_dma_pcis_q`, is the pipelined version of :coral:`sh_cl_dma_pcis_bus`, also exposed for debugging purpose.
2. The **CL_SDA_SLV** module instantiates an on-FPGA memory (BRAM) along with the AXI-Lite slave logic that is accessed by the :limegreen:`sda_cl_bus` AXI-lite master.
3. The **CL_OCL_SLV** module implements the slave logic facing the :limegreen:`sh_ocl_bus` AXI-lite master and accordingly outputs six test config buses (:turquoise:`*_tst_cfg_bus`).
4. The **CL_INT_SLV** module receives interrupt test config signals via :turquoise: `int_tst_cfg_bus` and demonstrates the interrupt request feature.
5. The **CL_PCIM_MSTR** module receives PCIM test config signals via :turquoise:`pcim_tst_cfg_bus` and demonstrates the PCIM master interface for outbound PCIe transactions (CL to Shell).



.. thumbnail:: ../figures/CL_DRAM_PCIS_SLV.png
    :width: 700px
    :height: 150px
    :align: center

    Block diagram of CL_DRAM_PCIS_SLV

.. centered::  **Figure 3: Block diagram of CL_DRAM_PCIS_SLV**

Now let’s take a closer look at the CL_DMA_PCIS_SLV module. As mentioned above, this module takes in three sets of inputs, the :coral:`sh_cl_dma_pcis_bus` AXI-4 interface, the :mediumblue:`ddr*_scrb_bus`, and :turquoise:`the ddr*_tst_cfg_bus`. The :coral:`sh_cl_dma_pcis_bus` AXI-4 interface signals first go through an “`AXI register slice <https://www.xilinx.com/support/documentation/ip_documentation/axi_interconnect/v2_1/pg059-axi-interconnect.pdf#page=5>`_” module (becomes :coral:`sh_cl_dma_pcis_q`) then feed into an AXI_CROSSBAR module. The AXI crossbar module can arbitrate and steer the request and response traffic between two incoming AXI-4 interfaces (connecting to master) and four outgoing AXI-4 interfaces (connecting to slave).
In this example, only one incoming interface is used and is connected to :coral:`sh_cl_dma_pcis_q`; the other one is unused and tied-off. Each of the four outgoing interfaces (:coral:`lcl_cl_sh_ddr(a/b/d)_q` and :coral:`cl_sh_ddr_q`) is for access to one of the four DDR interfaces. Each of the four AXI-4 interfaces goes through one or two “AXI register slice” cores (namely, ``src_register_slice``, ``dest_register_slice``, and ``axi_register_slice``) and then feeds into a CL_TST_SCRB module. Besides the AXI-4 interface input, each CL_TST_SCRB module receives a :turquoise:`ddr*_tst_cfg_bus` and a :mediumblue:`ddr*_scrb_bus`, that are pipelined using the lib_pipe modules. With these three inputs, the CL_TST_SCRB module outputs a AXI-4 master interface that eventually connects to the DDR modules.


.. thumbnail:: ../figures/CL_TST_SCRB.png
    :width: 700px
    :height: 150px
    :align: center

    Block diagram of CL_TST_SCRB

.. centered::  **Figure 4: Block diagram of CL_TST_SCRB**




Within the CL_TST_SCRB module, a MEM_SCRB module is instantiated to perform memory scrubbing [1]_. The MEM_SCRB module implements an FSM internally that starts when receiving the :mediumblue:`scrb_bus.enable` signal, and controls the :coral:`scrb_\*` AXI-4 master interface to write zeros to the address range from 0 to MAX_ADDR of DDR DRAM. The MEM_SCRB module also outputs the FSM state (:mediumblue:`scrb_bus.state`), scrubbing address (:mediumblue:`scrb_bus.addr`), and scrubbing completion status (:mediumblue:`scrb_bus.done`), which are eventually propagated to the top-level and connected to the cl_sh_status0 and cl_sh_id0/1 output ports (see Figure 2).
Similarly, the CL_TST module performs auto testing for DDR DRAMs by controlling the atg_* AXI-4 master interface based on the cfg_bus input.

Within the CL_TST_SCRB module, the third AXI-4 master interface (:coral:`slv_\*`) is connected to one of the AXI_CROSSBAR‘s four outgoing interfaces, which is initially driven by the :coral:`sh_cl_dma_pcis_bus` that comes from the Shell.

The output :coral:`ddr_axi4` interface of the CL_TST_SCRB module is selected from the three AXI-4 interfaces based on the **scrb_enable** and **atg_enable** signals.

.. [1] Memory scrubbing consists of reading from each computer memory location, correcting bit errors (if any) with an error-correcting code (ECC), and writing the corrected data back to the same location.

Running the cl_dram_dma example
--------------------------------

To run the cl_dram_dma example, follow the same steps describe above to synthesize the HDL, upload the tarball to s3, switch to F1 instance, and program the FPGA.
``cd`` into the cl_dram_dma example directory and try running it.

.. code-block:: bash

    cd $CL_DIR/software/runtime/(CL_DIR is hdk/cl/examples/cl_dram_dma)
    make all
    sudo ./test_dram_dma


If you are running the dma example for the first time, it may not work as you may not have the xmda drivers installed. Look at `Using AWS XDMA in C/C++ application <https://github.com/aws/aws-fpga/tree/master/sdk/linux_kernel_drivers/xdma>`_ link for more details on XDMA driver.

**Note:** usage of XDMA is not mandatory. AWS provides memory-mapped PCIe address space for direct communication between CPU and FPGA.

For a complete description of the different CPU to FPGA communication options and various options available, please review `the Programmers' View <https://github.com/aws/aws-fpga/blob/master/hdk/docs/Programmer_View.md>`_.
