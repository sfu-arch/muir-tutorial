.. _aws_synthesize:

Synthesizing the Example with Xilinx Vivado
=============================================

Change into an example directory and se the CL_DIR environment variable to the path of the example. You will need to set this again if you change examples:

.. code-block:: bash

    cd $HDK_DIR/cl/examples/cl_hello_world
    export CL_DIR=$(PWD)

Verify if Vivado is installed.

.. code-block:: bash

    vivado -mode batch

Run Vivado synthesis

.. code-block:: bash

    cd $CL_DIR/build/scripts
    ./aws_build-dcp_from_cl.sh

Note that this can take a long time. If you want to be notified by email when synthesis is done, do this before running the synthesis:

.. code-block:: bash

    pip2 install --user boto3
    export EMAIL=your.email@example.com
    $HDK_COMMON_DIR/scripts/notify_via_sns.py

For the email to work, you need to set your region name properly during "aws configure". We set our region name as "us-east-1".

No you can run synthesis with:


.. code-block:: bash

    ./aws_build_dcp_from_cl.sh -notify

By default, the build runs in the background, but it can be nice to be able to see the synthesis messages to see what's going on. If you want to run it in foreground:


.. code-block:: bash

    ./aws_build_dcp_from_cl.sh -notify -foreground

# Creating an Amazon FPGA Image (AFI)

Now that synthesis is done, we need to create an Amazon FPGA Image (AFI) from the specified design checkpoint (DCP). The AFI contains the FPGA bitstream that will be programmed on the FPGA F1 instance.

* To create an AFI, the DCP must be stored on S3. So we first need to create and s3 bucket. Make sure your credentials are set up correctly for this (aws configure).


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

* :red:`DON'T REMEMBER:` Go to the EC2 Management Console from AWS console and stop your EC2 instance.