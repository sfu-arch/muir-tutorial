.. _aws_shell:

AWS Shell
============

A quick tutorial on how to setting up AWS for Custom Logic (CL) development.


Introduction
-------------

This guide includes the instructions included in AWS EC2 FPGA Hardware and Software Development Kit as well as information that I have written by trying out the examples myself.
At the time of writing, I could not find such a step-by-step guide and I ran into issues here and there so we think that this guide will allow one to easily try out the F1 instances without getting stuck in some setup issue.

In this guide, I will go over two examples:

1. :ref:`cl_hello_world` : A simple example which writes to some FPGA registers from CPU, then reads them back.
2. :ref:`cl_dram_dma` :DMA data to FPGA DDR4 memories then DMA them back to verify correctness.

The same steps for running the cl_hello_world can be applied to cl_dram_dma example, except that for the cl_dram_dma example, you will need to install DMA drivers at the end before executing the software to communicate with the FPGA. Hence, I will describe all the steps for the cl_hello_world first then have additional instructions at the end for installing the DMA drivers and running the cl_dram_dma example.

But before explaining each of these example, I first go trought the steps that are needed to set up and run EC2 F1 instances. This guide is divided into two parts:

1. setting up and synthesizing the examples in HDL with Xilinx Vivado
2. Running the example on an Amazon EC2 F1 instance.



.. toctree::
   :maxdepth: 1
   :caption: AWS CL examples:

   AWS-setup-account 
   Synthesize-Example
   hello_world/CL-Hello-World
   cl_dram_dma/CL-DRAM-DMA

