.. _dandelion-basics:

Dandelion Basics
===================================
Dandelion is a library of hardware components to implement parallel dataflow accelerators.

Getting started:
--------------------------

This will walk you through installing Chisel and its dependencies:

#. sbt: which is the preferred Scala build system and what Chisel uses.

#. Verilator:, which compiles Verilog down to C++ for simulation. The included unit testing infrastructure uses this.

Linux build
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Code example::

    sudo apt-get install default-jdk

Background/Terminology
---------------------------

.. figure:: img/dandelion.png
   :alt: Dandelion Infrastructure Setup

   DandelionInfrastructure Diagram

**Dandelion-lib** (``dandelion``)
  This program (available on your path as ``firesim``
  once we source necessary scripts) automates the work required to launch FPGA
  builds and run simulations. Most users will only have to interact with the
  manager most of the time. If you're familiar with tools like Vagrant or Docker, the ``firesim``
  command is just like the ``vagrant`` and ``docker`` commands, but for FPGA simulators
  instead of VMs/containers.
