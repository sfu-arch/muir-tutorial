.. _aws_account:

First-time AWS User Setup [1]_
================================

If you've never used AWS before and don't have an account, follow the instructions
below to get started.

Creating an AWS Account
-----------------------

First, you'll need an AWS account. Create one by going to
`aws.amazon.com <https://aws.amazon.com>`__ and clicking "Sign Up."
You'll want to create a personal account. You will have to give it a
credit card number.

AWS Credit at SFU
----------------------

If you're an internal user at SFU and work with ``Computer-Architecture Lab`` please see the SFU Arch Lab Wiki  for instructions on getting access to the AWS credit. Otherwise, continue with the following section.

.. _limitincrease:

Requesting Limit Increases
--------------------------

In our experience, new AWS accounts do not have access to EC2 F1 instances by default. In order to get access, you should file a limit increase request. You can learn more about EC2 instance limits here: https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-on-demand-instances.html#ec2-on-demand-instances-limits

To request a limit increase, follow these steps:

https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-resource-limits.html

You'll probably want to start out with the following request, depending on your existing limits:

::

    Limit Type:                EC2 Instances
    Region:                    US East (Northern Virginia)
    Primary Instance Type:     All F instances
    Limit:                     Instance Limit
    New limit value:           64


This limit of 64 vCPUs for F instances allows you to run one node on the ``f1.2xlarge`` or eight nodes on the
``f1.16xlarge``.

For the "Use Case Description", you should describe your project and write
something about hardware simulation and mention that information about the tool
you're using can be found at: https://github.com/sfu-arch/muir

This process has a human in the loop, so you should submit it ASAP. At
this point, you should wait for the response to this request.

If you're at Berkeley/UCB-BAR, you also need to wait until your account has
been added to the RISE billing pool, otherwise your personal CC will be charged
for AWS usage.

Hit Next below to continue.

Configuring Required Infrastructure in Your AWS Account
---------------------------------------------------------

Once we have an AWS Account setup, we need to perform some advance setup
of resources on AWS. You will need to follow these steps even if you
already had an AWS account as these are Dandelion-specific.

Select a region
~~~~~~~~~~~~~~~

Head to the `EC2 Management
Console <https://console.aws.amazon.com/ec2/v2/home>`__. In the top
right corner, ensure that the correct region is selected. You should
select one of: ``us-east-1`` (N. Virginia), ``us-west-2`` (Oregon), or ``eu-west-1``
(Ireland), since F1 instances are only available in those regions.

Once you select a region, it's useful to bookmark the link to the EC2
console, so that you're always sent to the console for the correct
region.

Key Setup
~~~~~~~~~

In order to enable automation, you will need to create a key named
``dandelion``, which we will use to launch all instances (Manager
Instance, Build Farm, Run Farm).

To do so, click "Key Pairs" under "Network & Security" in the
left-sidebar. Follow the prompts, name the key ``aws-dandelion``, and save the
private key locally as ``aws-dandelion.pem``. You can use this key to access
all instances from your local machine. We will copy this file to our
manager instance later, so that the manager can also use it.

Check your EC2 Instance Limits
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

AWS limits access to particular instance types for new/infrequently used
accounts to protect their infrastructure. You should make sure that your
account has access to ``f1.2xlarge``, ``f1.4xlarge``, ``f1.16xlarge``,
``m4.16xlarge``, and ``c5.4xlarge`` instances by looking at the "Limits" page
in the EC2 panel, which you can access
`here <https://console.aws.amazon.com/ec2/v2/home#Limits:>`__. The
values listed on this page represent the maximum number of any of these
instances that you can run at once, which will limit the size of
simulations (# of nodes) that you can run. If you need to increase your
limits, follow the instructions on the
:ref:`limitincrease` page.
To follow this guide, you need to be able to run one ``f1.2xlarge`` instance
and two ``c5.4xlarge`` instances.

Start a t2.nano instance to test 
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Launch a ``t2.nano`` by following these instructions:

1. Go to the `EC2 Management
   Console <https://console.aws.amazon.com/ec2/v2/home>`__ and click
   "Launch Instance"
2. On the AMI selection page, select "Amazon Linux AMI...", which should
   be the top option.
3. On the Choose an Instance Type page, select ``t2.nano``.
4. Click "Review and Launch" (we don't need to change any other
   settings)
5. On the review page, click "Launch"
6. Select the ``aws-dandelion`` key pair we created previously, then click
   Launch Instances.
7. Click on the instance name and note its public IP address.
8. Waite for ``instance State`` to become ``running``
9. SSH into the ``t2.nano`` like so:

::

    ssh -i .ssh/aws-dandelion.pem ec2-user@54.158.143.95


Run the following to configure your aws account:

::

    aws configure
    [follow prompts]

See
https://docs.aws.amazon.com/cli/latest/userguide/tutorial-ec2-ubuntu.html#configure-cli-launch-ec2
for more about aws configure. Within the prompt, you should specify the same region that you chose
above (one of ``us-east-1``, ``us-west-2``, ``eu-west-1``) and set the default
output format to ``json``. You will need to generate an AWS access key in the "Security Credentials" menu of your AWS settings (as instructed in https://docs.aws.amazon.com/general/latest/gr/aws-sec-cred-types.html#access-keys-and-secret-access-keys ). 


On the ``t2.nano`` instance, do the following:

::

    sudo yum -y install python-pip
    sudo pip install boto3
    wget https://raw.githubusercontent.com/amsharifian/dandelion-aws/master/scripts/aws-setup.py
    python aws-setup.py

This will create a VPC named ``dandelion`` and a security group named ``dandelion`` in your account.

::

    Creating VPC for Dandelion...
    Success!
    Creating a subnet in the VPC for each availability zone...
    Success!
    Creating a security group for Dandelion...
    Success!


Terminate the t2.nano
~~~~~~~~~~~~~~~~~~~~~

At this point, we are finished with the general account configuration.
You should terminate the t2.nano instance you created, since we do not
need it anymore (and it shouldn't contain any important data).

.. _ami-subscription:

Subscribe to the AWS FPGA Developer AMI
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Go to the `AWS Marketplace page for the FPGA Developer
AMI <https://aws.amazon.com/marketplace/pp/B06VVYBLZZ>`__. Click the
button to subscribe to the FPGA Dev AMI (it should be free) and follow
the prompts to accept the EULA (but do not launch any instances).

Now, hit next to continue on to setting up our Manager Instance.

Launching a "F1 Instance"
------------------------------

Now, we need to launch a "F1 Instance" that we will ``ssh`` or ``mosh`` into to work from.
Since we will deploy the heavy lifting to separate ``c5.4xlarge`` and ``f1`` instances later, the Manager Instance can be a relatively cheap instance. 
In this guide, however, we will use a ``c5.4xlarge``, running the AWS FPGA Developer AMI. (Be sure to subscribe to the AMI  if you have not done so. See :ref:`ami-subscription`. Note that it 
might take a few minutes after subscribing to the AMI to be able to 
launch instances using it.)

Head to the `EC2 Management Console <https://console.aws.amazon.com/ec2/v2/home>`__. In the top
right corner, ensure that the correct region is selected.

To launch a manager instance, follow these steps:

1. From the main page of the EC2 Management Console, click
   ``Launch Instance``. We use an on-demand instance here, so that your
   data is preserved when you stop/start the instance, and your data is
   not lost when pricing spikes on the spot market.
2. When prompted to select an AMI, search in the ``Community AMIs`` tab for
   ``FPGA Developer AMI - 1.7.0`` and select the AMI that appears (there 
   should be only one). **DO NOT USE ANY OTHER VERSION.**
3. When prompted to choose an instance type, select the instance type of
   your choosing. A good choice is a ``c5.4xlarge``.
4. On the "Configure Instance Details" page:

   1. First make sure that the ``dandelion`` VPC is selected in the
      drop-down box next to "Network". Any subnet within the ``dandelion``
      VPC is fine.
   2. Additionally, check the box for "Protect against accidental
      termination." This adds a layer of protection to prevent your
      manager instance from being terminated by accident. You will need
      to disable this setting before being able to terminate the
      instance using usual methods.
   3. Also on this page, expand "Advanced Details" and in the resulting
      text box, paste the following:

      .. include:: ../scripts/machine-launch-script.sh
         :code: bash

      This will pre-install all of the dependencies needed to run Dandelion on your instance.

5. On the next page ("Add Storage"), increase the size of the root EBS
   volume to ~300GB. The default of 65GB can quickly become too small as
   you accumulate large Vivado reports/outputs, large waveforms, XSim outputs,
   and large root filesystems for simulations. You should get rid of the
   small (5GB) secondary volume that is added by default.
6. You can skip the "Add Tags" page, unless you want tags.
7. On the "Configure Security Group" page, select the ``firesim``
   security group that was automatically created for you earlier.
8. On the review page, click the button to launch your instance.

Make sure you select the ``dandelion`` key pair that we setup earlier.

Access your instance
~~~~~~~~~~~~~~~~~~~~

We recommend using `mosh <https://mosh.org/>`__ instead
of ``ssh`` or using ``ssh`` with a screen/tmux session running on your
manager instance to ensure that long-running jobs are not killed by a
bad network connection to your manager instance. On this instance, the
``mosh`` server is installed as part of the setup script we pasted
before, so we need to first ssh into the instance and make sure the
setup is complete.

In either case, ``ssh`` into your instance (e.g. ``ssh -i aws-dandelion.pem centos@YOUR_INSTANCE_IP``) and wait until the
``~/machine-launchstatus`` file contains all the following text:

::

    centos@ip-172-30-2-140.us-west-2.compute.internal:~$ cat machine-launchstatus
    machine launch script started
    machine launch script completed!

Once this line appears, exit and re-``ssh`` into the system. If you want
to use ``mosh``, ``mosh`` back into the system.

Now we are ready to start developing our custom logic designs on AWS F1 instances!



GUI FPGA Development Environment with NICE DCV
================================================
This guide shows steps to setup a GUI FPGA Development Environment using the FPGA Developer AMI using NICE DCV
      
Overview
----------

`NICE DCV <https://docs.aws.amazon.com/dcv/latest/adminguide/what-is-dcv.html>`_ can be used create a virtual desktop on your FPGA Developer AMI instance.

`NICE DCV <https://docs.aws.amazon.com/dcv/latest/adminguide/what-is-dcv.html>`_ is a high-performance remote 
display protocol that provides customers with a secure way to deliver remote desktops and application streaming 
from any cloud or data center to any device, over varying network conditions. 

With NICE DCV and Amazon EC2, customers can run graphics-intensive applications remotely on EC2 instances
and stream the results to simpler client machines, eliminating the need for expensive dedicated workstations.
Customers across a broad range of HPC workloads use NICE DCV for their remote visualization requirements.
The NICE DCV streaming protocol is also utilized by popular services like Amazon AppStream 2.0 and AWS RoboMaker.

The `DCV Administrator guide <https://docs.aws.amazon.com/dcv/latest/adminguide/what-is-dcv.html>`_
and the `User guide <https://docs.aws.amazon.com/dcv/latest/userguide/getting-started.html>`_
are the official resources on how to configure and use DCV.

The installation process is summarized below for your convenience.

**NOTE**:
These steps may change when new versions of the DCV Server and Clients are released.
If you experience issues please refer to the `Official DCV documentation <https://docs.aws.amazon.com/dcv/latest/adminguide/what-is-dcv.html)>`_.

Installation Process
----------------------

1. `Setup your FPGA Developer AMI Instance with an IAM Role <https://docs.aws.amazon.com/dcv/latest/adminguide/setting-up-license.html#setting-up-license-ec2>`_ that grants your instance access to NICE DCV endpoints.

    NICE DCV is available for free to use on EC2.

    The NICE DCV server automatically detects that it is running on an Amazon EC2 instance and periodically connects to an Amazon S3 bucket to determine whether a valid license is available. The IAM role enables this functionality.
    
    Please follow the steps mentioned in the above guide to attach an IAM role to your instance with the following policy:

.. code-block::json

   {
      "Version": "2012-10-17",
      "Statement": [
         {
               "Effect": "Allow",
               "Action": "s3:GetObject",
               "Resource": "arn:aws:s3:::dcv-license.region/*"
         }
      ]
   }

    **NOTE:** Without access to the DCV bucket mentioned in the [NICE DCV licensing setup guide](https://docs.aws.amazon.com/dcv/latest/adminguide/setting-up-license.html#setting-up-license-ec2), your server license is only valid of 15 days.

2. On your FPGA Developer AMI Instance `update the Instance Security Group <https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/using-network-security.html#adding-security-group-rule>`_ to allow TCP Port **8443** Ingress

3. `Install NICE DCV pre-requisites <https://docs.aws.amazon.com/dcv/latest/adminguide/setting-up-installing-linux-prereq.html>`_

.. code-block::bash

   sudo yum -y install kernel-devel
   sudo yum -y groupinstall "GNOME Desktop"
   sudo yum -y install glx-utils

4. `Install NICE DCV Server <https://docs.aws.amazon.com/dcv/latest/adminguide/setting-up-installing-linux-server.html>`_

.. code-block::bash

   sudo rpm --import https://s3-eu-west-1.amazonaws.com/nice-dcv-publish/NICE-GPG-KEY
   wget https://d1uj6qtbmh3dt5.cloudfront.net/2019.0/Servers/nice-dcv-2019.0-7318-el7.tgz
   tar xvf nice-dcv-2019.0-7318-el7.tgz
   cd nice-dcv-2019.0-7318-el7
   sudo yum -y install nice-dcv-server-2019.0.7318-1.el7.x86_64.rpm
   sudo yum -y install nice-xdcv-2019.0.224-1.el7.x86_64.rpm

   sudo systemctl enable dcvserver
   sudo systemctl start dcvserver

5. Setup Password

.. code-block::

   sudo passwd centos


6. Change firewall settings
   
   Options: 
   
   * Disable firewalld to allow all connections

.. code-block::bash

   sudo systemctl stop firewalld
   sudo systemctl disable firewalld

   
   * Open up the firewall only for tcp port 8443
   
.. code-block::bash

   sudo systemctl start firewalld
   sudo systemctl enable firewalld
   sudo firewall-cmd --zone=public --add-port=8443/tcp --permanent
   sudo firewall-cmd --reload

7. Create a virtual session to connect to    
   
   **NOTE: You will have to create a new session if you restart your instance.** 


.. code-block::bash

   dcv create-session --type virtual --user centos centos

8. Connect to the DCV Remote Desktop session

    i. **Using a web browser**
    
       * Make sure that you are using a `supported web browser <https://docs.aws.amazon.com/dcv/latest/adminguide/what-is-dcv.html#what-is-dcv-requirements>`_.
       
       * Use the secure URL, Public IP address, and correct port (8443) to connect. For example: `https://111.222.333.444:8443`
    
          **NOTE:** When you connect make sure you use the `https` protocol to ensure a secure connection.              

    ii. **Using the NICE DCV Client**
    
       * Download and install the `DCV Client <https://download.nice-dcv.com/>`_
       
       * Use the Public IP address, and correct port (8443) to connect

          An example login screen (for the DCV Client you will need to connect first using the IP:Port, for example `111.222.333.444:8443`):
    
          
.. image:: figures/dcv_login.png

9. Logging in should show you your new GUI Desktop:

.. image:: figures/dcv_desktop.png

.. [1] This tutorial is adopted from `FireSim doc <https://docs.fires.im/en/latest/index.html>`_.