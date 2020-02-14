.. _aws_synthesize:

Synthesizing the Example with Xilinx Vivado
=============================================


Install the HDK and setup environment
----------------------------------------

The AWS FPGA HDK can be cloned to your EC2 instance or server by executing:

When using the developer AMI:  ``AWS_FPGA_REPO_DIR=/home/centos/src/project_data/aws-fpga``

.. code-block::bash

    git clone https://github.com/aws/aws-fpga.git $AWS_FPGA_REPO_DIR
    cd $AWS_FPGA_REPO_DIR
    source sdk_setup.sh
    source hdk_setup.sh

**Note:** that sourcing ``hdk_setup.sh`` will set required environment variables that are used throughout the examples in the HDK.  DDR simulation models and DCP(s) are downloaded from S3 during hdk setup.  New terminal or xterm requires `hdk_setup.sh` to be rerun. 


How To Create an Amazon FPGA Image (AFI) From One of The CL Examples: Step-by-Step Guide
------------------------------------------------------------------------------------------


**Step 1. Pick cl_hello_world example and start in the example directory**

Change into an example directory and se the CL_DIR environment variable to the path of the example. You will need to set this again if you change examples:

.. code-block:: bash

    cd $HDK_DIR/cl/examples/cl_hello_world
    export CL_DIR=$(PWD)


**Step 2. Build the CL**

This `checklist <https://github.com/aws/aws-fpga/blob/master/hdk/cl/CHECKLIST_BEFORE_BUILDING_CL.md>`_ should be consulted before you start the build process.

**Note:** This step requires you to have Xilinx Vivado Tools and Licenses installed

.. code-block:: bash

    vivado -mode batch

Run Vivado synthesis. Executing the aws_build_dcp_from_cl.sh script will perform the entire implementation process converting the CL design into a completed Design Checkpoint that meets timing and placement constrains of the target FPGA. The output is a tarball file comprising the DCP file, and other log/manifest files, formatted as YY_MM_DD-hhmm.Developer_CL.tar. This file would be submitted to AWS to create an AFI.
.. code-block:: bash

    cd $CL_DIR/build/scripts
    ./aws_build-dcp_from_cl.sh

**Note:** that this can take a long time. If you want to be notified by email when synthesis is done, do this before running the synthesis:

.. code-block:: bash

    pip2 install --user boto3
    export EMAIL=your.email@example.com
    $AWS_FPGA_REPO_DIR/shared/bin/scripts/notify_via_sns.py

For the email to work, you need to set your region name properly during "aws configure". We set our region name as "us-east-1".

No you can run synthesis with:


.. code-block:: bash

    ./aws_build_dcp_from_cl.sh -notify

By default, the build runs in the background, but it can be nice to be able to see the synthesis messages to see what's going on. If you want to run it in foreground:


.. code-block:: bash

    ./aws_build_dcp_from_cl.sh -notify -foreground


**Step 3. Submit the Design Checkpoint to AWS to Create the AFI**

Now that synthesis is done, we need to create an Amazon FPGA Image (AFI) from the specified design checkpoint (DCP). The AFI contains the FPGA bitstream that will be programmed on the FPGA F1 instance.

To submit the DCP, create an S3 bucket for submitting the design and upload the tarball file into that bucket. You need to prepare the following information:

1. Name of the logic design (Optional).
2. Generic description of the logic design (Optional).
3. Location of the tarball file object in S3.
4. Location of an S3 directory where AWS would write back logs of the AFI creation.

To create an AFI, the DCP must be stored on S3. So we first need to create and s3 bucket. Make sure your credentials are set up correctly for this (aws configure).


.. code-block:: bash

    aws s3 mb s3://<bucket-name> --region <region-name> # Create an S3 bucket. Choose a unique bucket name (e.g., aws s3 mb s3://your_awsfpga --region us-east-1
    aws s3 mb s3://<bucket-name>/<dcp-folder-name> # Create a folder for your tarball files (e.g.,aws s3 mb s3://your_awsfpga/dcp)

Now copy the output files from synthesis to the new s3 bucket.

.. code-block:: bash

    aws s3 cp $CL_DIR/build/checkpoints/to_aws/*.Developer_CL.tar s3://<bucket-name>/<dcp-folder-name>/

* Create a folder for yor log files

.. code-block:: bash

    aws s3 mb s3://<bucket-name>/<logs-folder-name>  # Create a folder to keep your logs
    touch LOGS_FILES_GO_HERE.txt                     # Create a temp file
    aws s3 cp LOGS_FILES_GO_HERE.txt s3://<bucket-name>/<logs-folder-name>/

* Copying to s3 bucket may not work if your s3 bucket policy is not set up properly. To set the bucket polity, go to https://s3.console.aws.amazon.com/ -> Click on your bucket -> Click on Permissions tab -> Click on Bucket Policy.

* Set the policy as listed below, and try copying the files again.


.. code-block:: json

    {
        "Version": "2012-10-17",
        "Statement": [
        {
            "Sid": "Bucket level permissions",
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::365015490807:root"
            },
           "Action": [
               "s3:ListBucket"
            ],
           "Resource": "arn:aws:s3:::<bucket-name>"
        },
        {
            "Sid": "Object read permissions",
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::365015490807:root"
            },
            "Action": [
                "s3:GetObject"
            ],
            "Resource": "arn:aws:s3:::<bucket-name>/<dcp-folder-name>/*.tar"
        },
        {
            "Sid": "Folder write permissions",
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::365015490807:root"
            },
            "Action": [
                "s3:PutObject"
            ],
            "Resource": "arn:aws:s3:::<bucket-name>/<logs-folder-name>/*"
        }
        ]
    }

* Verify that the bucket policy grants the required permissions by running the following script:


.. code-block:: bash

    check_s3_bucket_policy.py --dcp-bucket <bucket-name> --dcp-key <dcp-folder-name>/<tar-file-name> --logs-bucket <bucket-name> --logs-key <logs-folder-name>

* Once your policy passes the checks, create the Amazon FPGA image (AFI).


.. code-block:: bash

    aws ec2 create-fpga-image --name <afi-name> --description <afi-description> --input-storage-location Bucket=<dcp-bucket-name>,Key=<path-to-tarball> --logs-storage-location Bucket=<logs-bucket-name>,Key=<path-to-logs>      

<path-to-tarball> is <dcp-folder-name>/<tar-file-name>

<path-to-logs> is <logs-folder-name>

The output of this command includes two identifiers that refer to your AFI: Write these down, as you will need them later.

* **FPGA Image Identifier** or **AFI ID**: this is the main ID used to manage your AFI through the AWS EC2 CLI commands and AWS SDK APIs.

This ID is regional, i.e., if an AFI is copied across multiple regions, it will have a different unique AFI ID in each region.  An example AFI ID is **`afi-06d0ffc989feeea2a`**.

* **Glogal FPGA Image Identifier** or **AGFI ID**: this is a global ID that is used to refer to an AFI from within an F1 instance. For example, to load or clear an AFI from an FPGA slot, you use the AGFI ID.

Since the AGFI IDs is global (by design), it allows you to copy a combination of AFI/AMI to multiple regions, and they will work without requiring any extra setup. An example AGFI ID is **`agfi-0f0e045f919413242`**.

* Check if the AFI generation is done. You must provide the **FPGA Image Identifier** returned by `create-fpga-image`:


.. code-block:: bash

    aws ec2 describe-fpga-images --fpga-image-ids <AFI ID>

The AFI can only be loaded to an instance once the AFI generation completes and the AFI state is set to `available`. This can also take some time (Took ~30 minutes for the cl_dram_dma example).

::

    {
        "FpgaImages": [
        {
            ...
            "State": {
                "Code": "available"
            },<
            ...
            "FpgaImageId": "afi-06d0ffc989feeea2a",
            ...
        }
        ]
    }

* Once you have gotten to this point, you have successfully synthesized an HDL design for the EC2 F1. Now you’re ready to program the FPGA and run the example.


.. raw:: html

    <style> .red {color:red} </style>

.. role:: red

* :red:`DON'T REMEMBER: Go to the EC2 Management Console from AWS console and stop your EC2 instance.`


Running the Example on an Amazon EC2 F1 Instance
-------------------------------------------------

Change your Instance Type to f1.2xlarge (this is the one with an FPGA) and start the instance.
To change the instance type:  Right click on your instance shown in the EC2 Management Console -> Click “Instance Settings” -> Change Instance Type -> Choose “f1.2xlarge”. To start the instance again, don’t click “Launch Instance” as this will create a new instance, but right-click on your instance, “Instance State”, then “Start”.
As mentioned above, if this is the first time you’re trying an F1 instance with your AWS account, you may need to request an instance limit increase.

Once the F1 instance is running, SSH into the instance
``cd`` into the cloned aws fpga git repo and run “source sdk_setup.sh”
Run “aws configure” and input your credentials. If you’ve done this before, and your credentials haven’t changed, you don’t need to do it again.
Make sure you clear any AFI you have previously loaded in your slot:

.. code-block:: bash

    sudo fpga-clear-locl-image -S 0

Change your Instance Type to f1.2xlarge (this is the one with an FPGA) and start the instance. To change the instance type:  Right click on your instance shown in the  EC2 Management Console -> Click “Instance Settings” -> Change Instance Type -> Choose “f1.2xlarge”. To start the instance again, don’t click “Launch Instance” as this will create a new instance, but right-click on your instance, “Instance State”, then “Start”.
As mentioned above, if this is the first time you’re trying an F1 instance with your AWS account, you may need to request an instance limit increase.

Once the F1 instance is running, SSH into the instance
CD into the cloned aws fpga git repo and run “source sdk_setup.sh”
Run “aws configure” and input your credentials. If you’ve done this before, and your credentials haven’t changed, you don’t need to do it again.
Make sure you clear any AFI you have previously loaded in your slot:

::

    $sudo fpga-describe-local-image -S 0 -H
 
    Type  FpgaImageSlot  FpgaImageId     StatusName    StatusCode   ErrorName    ErrorCode     ShVersion
    AFI        0            none          cleared          1           ok            0      <shell_version>
    Type        FpgaImageSlot  VendorId   DeviceId        DBDF
    AFIDEVICE        0          0x1d0f    0x1042      0000:00:0f.0


If the describe returns a status ‘Busy’, the FPGA is still performing the previous operation in the background. Please wait until the status is ‘Cleared’ as above.

.. code-block:: bash

    sudo fpga-load-local-image -S 0 -I <FpgaImageGlobalId>

<FpgaImageGlobalId> is the ID that you got before when running “aws ec2 create-fpga-image ..” and starts with agfi-….

Verify that the AFI was loaded properly. The output shows the FPGA in the “loaded” state after the FPGA image “load” operation. The “-R” option performs a PCI device remove and rescan in order to expose the unique AFI Vendor and Device Id.

::

    $sudo fpga-describe-local-image -S 0 -R -H
 
    Type  FpgaImageSlot        FpgaImageId          StatusName    StatusCode   ErrorName    ErrorCode     ShVersion
    AFI        0          agfi-0f0e045f919413242     loaded           0           ok            0      <shell version>
    Type         FpgaImageSlot  VendorId    DeviceId       DBDF
    AFIDEVICE        0           0x6789      0x1d50     0000:00:0f.0


Now validate the example. Each CL Example comes with a runtime software under $CL_DIR/software/runtime/ subdirectory. You will need to build the runtime application that matches your loaded AFI.

.. code-block:: bash

    cd $CL_DIR/software/runtime/ #CL_DIR is hdk/cl/examples/cl_hello_world
    make all
    sudo ./test_hello_world

The cl_hello_world example should show the following output:

::

    AFI PCI  Vendor ID: 0x1d0f, Device ID 0xf000
    ===== Starting with peek_poke_example =====
    register: 0xdeadbeef
    Resulting value matched expected value 0xdeadbeef. It worked!
    Developers are encouraged to modify the Virtual DIP Switch by calling the linux shell command to demonstrate how AWS FPGA Virtual DIP switches can be used to change a CustomLogic functionality:
    $ fpga-set-virtual-dip-switch -S (slot-id) -D (16 digit setting)
    In this example, setting a virtual DIP switch to zero clears the corresponding LED, even if the peek-poke example would set it to 1.
    For instance:
    # fpga-set-virtual-dip-switch -S 0 -D 1111111111111111
    # fpga-get-virtual-led  -S 0
    FPGA slot id 0 have the following Virtual LED:
    1010-1101-1101-1110
    # fpga-set-virtual-dip-switch -S 0 -D 0000000000000000
    # fpga-get-virtual-led  -S 0
    FPGA slot id 0 have the following Virtual LED:
    0000-0000-0000-0000

As suggested in the output, try changing the Virtual DIP switches:


.. code-block:: bash

    sudo fpga-set-virtual-dip-switch -S 0 -D 1111111111111111
    sudo fpga-get-virtual-led  -S 0
    
    FPGA slot id 0 have the following Virtual LED:
    1010-1101-1101-1110
    
    sudo fpga-set-virtual-dip-switch -S 0 -D 0000000000000000
    sudo fpga-get-virtual-led  -S 0
    
    FPGA slot id 0 have the following Virtual LED:
    0000-0000-0000-0000
    
    sudo fpga-set-virtual-dip-switch -S 0 -D 0000000011111111
    sudo fpga-get-virtual-led  -S 0
    
    FPGA slot id 0 have the following Virtual LED:
    0000-0000-1101-1110
    
    sudo fpga-set-virtual-dip-switch -S 0 -D 1111111100000000
    sudo fpga-get-virtual-led  -S 0
    
    FPGA slot id 0 have the following Virtual LED:
    1010-1101-0000-0000

Congratulations! You have successfully run your first examples on the EC2 F1!


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
