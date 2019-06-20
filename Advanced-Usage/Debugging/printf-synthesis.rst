Printf Synthesis
===================

Enabling Printf Synthesis
----------------------------

To synthesize a printf, in your Chisel source you need to annotate the specific
printfs you'd like to capture.  Presently, due to a limitation in Chisel and
FIRRTL's annotation system, you need to annotate the arguments to the printf, not the printf itself,
like so:

::

    printf(midas.targetutils.SynthesizePrintf("x%d p%d 0x%x\n", rf_waddr, rf_waddr, rf_wdata))

