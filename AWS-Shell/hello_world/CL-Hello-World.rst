.. _cl_hello_world:

Custom Logic Hello World Example
=================================


The “Hello World” example exercises the :ref:`OCL <ocl>` Shell-to-CL AXI-Lite interface, the Virtual LED outputs and the Virtual DIP switch inputs. This page will walk through the custom logic RTL (Verilog), explain the AXI-lite slave logic, and highlight the PCIe APIs that can be used for accessing the registers behind the AXI-lite interface.


.. contents:: Table of Contents
    :local:

Custom Logic RTL
-----------------

This simple *hello_world* example builds a Custom Logic (CL) that will enable the instance to "peek" and "poke" registers in the Custom Logic (CL).
These registers will be in the memory space behind AppPF BAR0, which is the ocl\_cl\_ AXI-lite bus on the Shell to CL interface.

This example demonstrate a basic use-case of the Virtual LED and Virtual DIP switches.

All of the unused interfaces between AWS Shell and the CL are tied to fixed values, and it is recommended that the developer use similar values for every unused interface in the developer's CL.


Now let’s start with the top-level Verilog module of the example:
``aws-fpga/hdk/cl/examples/cl_hello_world/design/cl_hello_world.sv``

.. code-block:: verilog
    :linenos:

    module cl_hello_world 

    (
       `include "cl_ports.vh" // Fixed port definition

    );

    `include "cl_common_defines.vh"      // CL Defines for all examples
    `include "cl_id_defines.vh"          // Defines for ID0 and ID1 (PCI ID's)
    `include "cl_hello_world_defines.vh" // CL Defines for cl_hello_world

    logic rst_main_n_sync;


    //--------------------------------------------0
    // Start with Tie-Off of Unused Interfaces
    //---------------------------------------------
    // the developer should use the next set of `include
    // to properly tie-off any unused interface
    // The list is put in the top of the module
    // to avoid cases where developer may forget to
    // remove it from the end of the file

    `include "unused_flr_template.inc"
    `include "unused_ddr_a_b_d_template.inc"
    `include "unused_ddr_c_template.inc"
    `include "unused_pcim_template.inc"
    `include "unused_dma_pcis_template.inc"
    `include "unused_cl_sda_template.inc"
    `include "unused_sh_bar1_template.inc"
    `include "unused_apppf_irq_template.inc"

First you will see the above module declaration uses a `include "cl_ports.vh"` statement to declare all the interface ports that are fixed for the CL. The cl_ports.vh file is located at
``aws-fpga/hdk/common/shell_v04261818/design/interfaces/cl_ports.vh``.

Users should tie-off all unused interfaces, by including a list of AWS-provided Verilog files located at
``aws-fpga/hdk/common/shell_v04261818/design/interfaces/unused_*_template.inc``


Then you will see the standard PCIe and PCIe subsystem ID settings, and an always block synchronizing the input reset signal, rst_main_n.

.. code-block:: verilog
    :linenos:

    //-------------------------------------------------
    // ID Values (cl_hello_world_defines.vh)
    //-------------------------------------------------
      assign cl_sh_id0[31:0] = `CL_SH_ID0;
      assign cl_sh_id1[31:0] = `CL_SH_ID1;

    //-------------------------------------------------
    // Reset Synchronization
    //-------------------------------------------------
    logic pre_sync_rst_n;

    always_ff @(negedge rst_main_n or posedge clk_main_a0)
       if (!rst_main_n)
       begin
          pre_sync_rst_n  <= 0;
          rst_main_n_sync <= 0;
       end
       else
       begin
          pre_sync_rst_n  <= 1;
          rst_main_n_sync <= pre_sync_rst_n;
       end


Following that there is the logic for “PCIe OCL AXI-L (SH to CL) Timing Flops”.
It uses an “AXI register slice” core (axi_register_slice_light) to connect all top level OCL Shell-to-CL interface ports to a set of corresponding “local” signals through pipeline registers.
This is for the timing purpose.
The slave access implementation of the PCIe OCL AXI-L interface will interact with this set of “local” signals.

.. code-block:: verilog
    :linenos:

    //-------------------------------------------------
    // PCIe OCL AXI-L (SH to CL) Timing Flops
    //-------------------------------------------------

      axi_register_slice_light AXIL_OCL_REG_SLC (
       .aclk          (clk_main_a0),
       .aresetn       (rst_main_n_sync),

       // CL's top level interface signals connecting to Shell.
       .s_axi_awaddr  (sh_ocl_awaddr),
       .s_axi_awprot   (2'h0),
       .s_axi_awvalid (sh_ocl_awvalid),
       .s_axi_awready (ocl_sh_awready),
       .s_axi_wdata   (sh_ocl_wdata),
       .s_axi_wstrb   (sh_ocl_wstrb),
       .s_axi_wvalid  (sh_ocl_wvalid),
       .s_axi_wready  (ocl_sh_wready),
       .s_axi_bresp   (ocl_sh_bresp),
       .s_axi_bvalid  (ocl_sh_bvalid),
       .s_axi_bready  (sh_ocl_bready),
       .s_axi_araddr  (sh_ocl_araddr),
       .s_axi_arvalid (sh_ocl_arvalid),
       .s_axi_arready (ocl_sh_arready),
       .s_axi_rdata   (ocl_sh_rdata),
       .s_axi_rresp   (ocl_sh_rresp),
       .s_axi_rvalid  (ocl_sh_rvalid),
       .s_axi_rready  (sh_ocl_rready),

       // Local signals connecting to internal CL implementation.
       .m_axi_awaddr  (sh_ocl_awaddr_q),
       .m_axi_awprot  (),
       .m_axi_awvalid (sh_ocl_awvalid_q),
       .m_axi_awready (ocl_sh_awready_q),
       .m_axi_wdata   (sh_ocl_wdata_q),
       .m_axi_wstrb   (sh_ocl_wstrb_q),
       .m_axi_wvalid  (sh_ocl_wvalid_q),
       .m_axi_wready  (ocl_sh_wready_q),
       .m_axi_bresp   (ocl_sh_bresp_q),
       .m_axi_bvalid  (ocl_sh_bvalid_q),
       .m_axi_bready  (sh_ocl_bready_q),
       .m_axi_araddr  (sh_ocl_araddr_q),
       .m_axi_arvalid (sh_ocl_arvalid_q),
       .m_axi_arready (ocl_sh_arready_q),
       .m_axi_rdata   (ocl_sh_rdata_q),
       .m_axi_rresp   (ocl_sh_rresp_q),
       .m_axi_rvalid  (ocl_sh_rvalid_q),
       .m_axi_rready  (sh_ocl_rready_q)
      );


Now let’s take a look at the AXI-lite slave logic.


.. code-block:: verilog
    :linenos:

    // Write Request
    logic        wr_active;
    logic [31:0] wr_addr;

    always_ff @(posedge clk_main_a0)
      if (!rst_main_n_sync) begin
         wr_active <= 0;
         wr_addr   <= 0;
      end
      else begin
         wr_active <=  wr_active && bvalid  && bready ? 1'b0     :
                      ~wr_active && awvalid           ? 1'b1     :
                                                        wr_active;
         wr_addr <= awvalid && ~wr_active ? awaddr : wr_addr     ;
      end

    assign awready = ~wr_active;
    assign wready  =  wr_active && wvalid;

    // Write Response
    always_ff @(posedge clk_main_a0)
      if (!rst_main_n_sync) 
        bvalid <= 0;
      else
        bvalid <=  bvalid &&  bready           ? 1'b0  : 
                             ~bvalid && wready ? 1'b1  :
                                                 bvalid;
    assign bresp = 0;


On the write side, the wr_active register represents whether the write operation is active. It toggles from 0 to 1 on the assertion of the input write address valid signal (awvalid) (line 12); and toggles from 1 to 0 if the write response handshaking signals — output valid (bvalid) and input ready (bready), are high (line 11).
The wr_addr register storing the write address updates its value on the assertion of write address valid (awvalid) if there is no currently active write operation (~wr_active) (line 14)
The write address ready output (awready) is high if and only if there is no active write operation (line 17).
The write data ready (wready) output is asserted when write operation is active and write data valid input is asserted (line 18).
The write response output register (bvalid) toggles from 0 to 1 after wready is asserted (i.e., after write data valid input is received) (line 26); and toggles from 1 to 0 after the Shell master asserts bready signal (line 25).


.. code-block:: verilog
    :linenos:

    // Read Request
    always_ff @(posedge clk_main_a0)
       if (!rst_main_n_sync) begin
          arvalid_q <= 0;
          araddr_q  <= 0;
       end
       else begin
          arvalid_q <= arvalid;
          araddr_q  <= arvalid ? araddr : araddr_q;
       end

    assign arready = !arvalid_q && !rvalid;

    // Read Response
    always_ff @(posedge clk_main_a0)
       if (!rst_main_n_sync)
       begin
          rvalid <= 0;
          rdata  <= 0;
          rresp  <= 0;
       end
       else if (rvalid && rready)
       begin
          rvalid <= 0;
          rdata  <= 0;
          rresp  <= 0;
       end
       else if (arvalid_q) 
       begin
          rvalid <= 1;
          rdata  <= (araddr_q == `HELLO_WORLD_REG_ADDR) ? hello_world_q_byte_swapped[31:0]:
                    (araddr_q == `VLED_REG_ADDR       ) ? {16'b0,vled_q[15:0]            }:
                                                          `UNIMPLEMENTED_REG_VALUE        ;
          rresp  <= 0;
       end


On the read side, the read address register (araddr_q) updates its value if the read address valid input (arvalid) is high (line 9).
The read address ready output (i.e., ready to receive a new read request) goes high only when there is no active read operation, that is, when there is neither an active read request (~arvalid_q) nor an active read response (~rvalid) (line 12).
On reset or when read response handshakes (rvalid && rready), all the read response signals (rvalid, rdata, rresp) are deasserted (line 16-27); when the valid read address is received (arvalid_q), read data valid output is asserted while the read data updates its value accordingly to the read address (line 28-35).



.. code-block:: verilog
    :linenos:

    //-------------------------------------------------
    // Hello World Register
    //-------------------------------------------------
    // When read it, returns the byte-flipped value.

    always_ff @(posedge clk_main_a0)
       if (!rst_main_n_sync) begin                    // Reset
          hello_world_q[31:0] <= 32'h0000_0000;
       end
       else if (wready & (wr_addr == `HELLO_WORLD_REG_ADDR)) begin  
          hello_world_q[31:0] <= wdata[31:0];
       end
       else begin                                // Hold Value
          hello_world_q[31:0] <= hello_world_q[31:0];
       end

    assign hello_world_q_byte_swapped[31:0] = {hello_world_q[7:0],   hello_world_q[15:8],
                                               hello_world_q[23:16], hello_world_q[31:24]};


The “Hello World” register (hello_world_q) simply updates the value to the input write data upon the write to the corresponding address (HELLO_WORLD_REG_ADDR). The hello_world_q_byte_swapped is a byte-swapped version of the register.


.. code-block:: verilog
    :linenos:

    //-------------------------------------------------
    // Virtual LED Register
    //-------------------------------------------------
    // Flop/synchronize interface signals
    always_ff @(posedge clk_main_a0)
       if (!rst_main_n_sync) begin                    // Reset
          sh_cl_status_vdip_q[15:0]  <= 16'h0000;
          sh_cl_status_vdip_q2[15:0] <= 16'h0000;
          cl_sh_status_vled[15:0]    <= 16'h0000;
       end
       else begin
          sh_cl_status_vdip_q[15:0]  <= sh_cl_status_vdip[15:0];
          sh_cl_status_vdip_q2[15:0] <= sh_cl_status_vdip_q[15:0];
          cl_sh_status_vled[15:0]    <= pre_cl_sh_status_vled[15:0];
       end

    // The register contains 16 read-only bits corresponding to 16 LED's.
    // For this example, the virtual LED register shadows the hello_world
    // register.
    // The same LED values can be read from the CL to Shell interface
    // by using the linux FPGA tool: $ fpga-get-virtual-led -S 0

    always_ff @(posedge clk_main_a0)
       if (!rst_main_n_sync) begin                    // Reset
          vled_q[15:0] <= 16'h0000;
       end
       else begin
          vled_q[15:0] <= hello_world_q[15:0];
       end

    // The Virtual LED outputs will be masked with the Virtual DIP switches.
    assign pre_cl_sh_status_vled[15:0] = vled_q[15:0] & sh_cl_status_vdip_q2[15:0];


For the interface signals, the virtual DIP switch inputs and the virtual LED outputs are first synchronized (line 5-15).
The virtual LED outputs are set to the AND output between virtual DIP switches and the hello world registers.


Host Software
----------------

Now we have seen the RTL implementation of the AXI-lite slave. To read/write the registers (i.e., the hello world register) behind the AXI-lite interface from an EC2 instance host, we can use the provided PCIe APIs.
Here are the five main APIs (also see sdk/userspace/include/fpga_pci.h for more details):


.. code-block: c

    /**
     * Initialize the pci library.
     * @returns 0 on success, non-zero on error
     */
    int fpga_pci_init(void);
    
    /**
     * Attach to an FPGA memory space.
     *
     * @param[in]  slot_id  logical slot index
     * @param[in]  pf_id    physical function id, e.g. FPGA_APP_PF
     * @param[in]  bar_id   base address register, e.g. APP_PF_BAR4
     * @param[in]  flags    set various options (flags defined below)
     * @param[out] handle   used to identify fpga attachment for future library
     *                      calls
     *
     * @returns 0 on success, non-zero on error
     */
    int fpga_pci_attach(int slot_id, int pf_id, int bar_id, uint32_t flags,
                        pci_bar_handle_t *handle);
    
    /**
     * Write a value to a register.
     *
     * @param[in]  handle  handle provided by fpga_pci_attach
     * @param[in]  offset  memory location offset for register to write
     * @param[in]  value   value to write to the register
     * @returns 0 on success, non-zero on error
     */
    int fpga_pci_poke(pci_bar_handle_t handle, uint64_t offset, uint32_t value);
    
    /**
     * Read a value from a register.
     *
     * @param[in]  handle  handle provided by fpga_pci_attach
     * @param[in]  offset  memory location offset for register to read
     * @param[out] value   value read from the register (32-bit)
     * @returns 0 on success, non-zero on error
     */
    int fpga_pci_peek(pci_bar_handle_t handle, uint64_t offset, uint32_t *value);
    
    /**
     * Detach from an FPGA memory space.
     *
     * @param[in]  handle  the value provided by fpga_pci_attach corresponding to
     *                     the memory space to detach
     * @returns 0 on success, non-zero on error
     */
    int fpga_pci_detach(pci_bar_handle_t handle);


Below I use an example to explain the use of the APIs:

.. code-block: c

    /* Initialize the fpga_pci library so we could have access to FPGA PCIe from
     * this application. */
    int rc = fpga_pci_init();
    
    /* fpga_pci_init() returns a non-zero rc on error. fail_on is a MACRO function
     * that logs the error message (3rd argument) and jumps to code label (2nd
     * argument, i.e., "out" on line 40) when rc (1st argument) is non-zero. */
    fail_on(rc, out, "Unable to initialize the fpga_pci library");
    
    /* pci_bar_handle_t is a handler for an address space exposed by one PCI BAR on
     * one of the PCI PFs of the FPGA */
    pci_bar_handle_t pci_bar_handle = PCI_BAR_HANDLE_INIT;
    
    /* attach to the fpga, with a pci_bar_handle out param
     * To attach to multiple slots or BARs, call this function multiple times,
     * saving the pci_bar_handle to specify which address space to interact with in
     * other API calls.
     * This function accepts the slot_id, physical function, and bar number.
     */
    int slot_id = 0;           /* The first FPGA at slot 0. */
    int pf_id = FPGA_APP_PF;   /* The application physical function (https://github.com/aws/aws-fpga/blob/master/hdk/docs/AWS_Shell_Interface_Specification.md#application-pf-apppf) */
    int bar_id = APP_PF_BAR0;  /* AppPF BAR0 maps to the OCL AXI-lite interface. */
    rc = fpga_pci_attach(slot_id, pf_id, bar_id, 0, &pci_bar_handle);
    fail_on(rc, out, "Unable to attach to the AFI on slot id %d", slot_id);
    
    /* The hello world register address is defined at hdk/cl/examples/common/design/cl_common_defines.vh */
    #define HELLO_WORLD_REG_ADDR UINT64_C(0x500)
    
    /* write a value into the mapped address space */
    uint32_t value = 0xefbeadde;
    rc = fpga_pci_poke(pci_bar_handle, HELLO_WORLD_REG_ADDR, value);
    fail_on(rc, out, "Unable to write to the fpga !");
    
    /* read it back and print it out; you should expect the byte order to be
     * reversed (That's what this CL does) */
    rc = fpga_pci_peek(pci_bar_handle, HELLO_WORLD_REG_ADDR, &value);
    fail_on(rc, out, "Unable to read read from the fpga !");
    printf("register: 0x%x\n", value); /* Expect to see byte swapped: 0xdeadbeef. */
    
    out:  /* Jumps to here on error. */
    /* clean up */
    if (pci_bar_handle >= 0) {
        rc = fpga_pci_detach(pci_bar_handle);
        if (rc) {
            printf("Failure while detaching from the fpga.\n");
        }
    }


For more details or a complete example, you can refer to hdk/cl/examples/cl_hello_world/software/runtime/test_hello_world.c.
``aws-fpga/hdk/cl/examples/cl_hello_world/software/runtime/test_hello_world.c``:


Loading the existing example hello world afi image
----------------------------------------------------

These instructions can mostly be found here(https://github.com/aws/aws-fpga/blob/master/hdk/cl/examples/README.md) along with some implicit knowledge about understanding the aws cli describe-fgpa-instances command. (https://github.com/aws/aws-fpga/blob/master/hdk/docs/describe_fpga_images.md)
Find the existing example `FpgaImageGlobalId` Hello World AFI image using the describe-fpga-images aws cli command.
If your aws cli is not set up, install (http://docs.aws.amazon.com/cli/latest/userguide/installing.html) and configure(http://docs.aws.amazon.com/cli/latest/userguide/cli-chap-getting-started.html#cli-quick-configuration) it.


::

    $ aws ec2 describe-fpga-images
    # Example response
    {
      "FpgaImages": [
        ...
        {
          "OwnerAlias": "amazon",
          "UpdateTime": "2017-07-26T19:09:24.000Z",
          "Name": "hello_world_1.3.0",
          "PciId": {
            "SubsystemVendorId": "0xfedd",
            "VendorId": "0x1d0f",
            "DeviceId": "0xf000",
            "SubsystemId": "0x1d51"
          },
          "FpgaImageGlobalId": "agfi-088bffb3ab91ca2d1",
          "Public": true,
          "State": {
            "Code": "available"
          },
          "ShellVersion": "0x071417d3",
          "OwnerId": "095707098027",
          "FpgaImageId": "afi-01a7ea9bafe3ef8cc", 
          "CreateTime": "2017-07-26T18:42:42.000Z",
          "Description": "Hello World AFI"
        },
        ...
      ]
    }


Install the FPGA Management tools. This installs he shell commands which will load an AFI onto an FPGA. Depending on your AMI used to run the F1 instance, these steps may have been completed already.


.. code-block:: bash

    git clone https://github.com/aws/aws-fpga.git $AWS_FPGA_REPO_DIR
    cd $AWS_FPGA_REPO_DIR
    source sdk_setup.sh


Use the FPGA Management tools commands with the FpgaImageGlobalId to load the AFI:

.. code-block:: bash

    # clear the fpga slot
    $ sudo fpga-clear-local-image  -S 0
    # load the fpga by FpgaImageGlobalId
    $ sudo fpga-load-local-image -S 0 -I <FpgaImageGlobalId>
    # verify it worked by seeing StatusName is loaded
    $ sudo fpga-describe-local-image -S 0 -R -H


Run the custom logic
---------------------

There are two things to see once the Hello World AFI is loaded:

.. code-block:: bash

    $ cd $AWS_FPGA_REPO_DIR/hdk/cl/examples/cl_hello_world/software/runtime
    $ make all
    $ sudo ./test_hello_world
    AFI PCI  Vendor ID: 0x1d0f, Device ID 0xf000
    ===== Starting with peek_poke_example =====
    register: 0xdeadbeef
    Resulting value matched expected value 0xdeadbeef. It worked!
    ....

The hello world AFI also connects the virtual dip switches to the virtual leds as another example.

.. code-block:: bash

    $ sudo fpga-get-virtual-led -S 0
    FPGA slot id 0 have the following Virtual LED:
    0000-0000-0000-0000
    $ sudo fpga-set-virtual-dip-switch -S 0 -D 101010101010101010
    $ sudo fpga-get-virtual-led -S 0
    FPGA slot id 0 have the following Virtual LED:
    1010-1000-1000-1010

That is all for this tutorial. To summarize, we talked about the CL port declaration and tie-off, the use of AXI register slice core for improving circuit timing, the AXI-lite slave logic implementation, accessing the virtual LED/DIP ports, and the host APIs for accessing registers behind the AXI-lite interface. We hope you find this blog post useful and please leave comments/suggestions below!
Meanwhile, you can check out this blog post that discusses the custom logic of the more sophisticated “CL_DRAM_DMA” example.