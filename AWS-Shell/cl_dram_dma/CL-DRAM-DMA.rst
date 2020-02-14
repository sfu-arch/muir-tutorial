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