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
    :width: 500px
    :height: 50px
    :align: center

An arrow represents the connection from master to slave.
There are four major types of signal interfaces in the example.
The interfaces are defined as the SystemVerilog ``Interface`` constructs in *cl_dram_dma_pkg.sv*, namely **axi_bus_t** (used for :coral:`AXI-4` and :limegreen:`AXI-lite` signals), :turquoise:`cfg_bus_t`, and :mediumblue:`scrb_bus_t`.
The signals surrounded by grey hexagons are the input or output ports of the module. Black boxes represent RTL modules and the dash-lined circles represent the logic within current module.

Now let’s start with the top level block diagram of the CL_DRAM_DMA. You might mouse over the image to zoom-in or click to see an enlarged image.
