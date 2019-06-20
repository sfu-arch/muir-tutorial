.. _first-time-aws:

First-time Chisel User
==============================

Chisel is an open-source hardware construction language developed at UC Berkeley that supports advanced hardware design using highly parameterized generators and layered domain-specific hardware languages.

Downloading chisel
-----------------------

While Chisel provides similar base primitives as synthesizable Verilog, and could be used as such:

.. code-block:: scala

    // 3-point moving average implemented in the style of a FIR filter
    class MovingAverage3(bitWidth: Int) extends Module {
      val io = IO(new Bundle {
        val in = Input(UInt(bitWidth.W))
        val out = Output(UInt(bitWidth.W))
      })
    
      val z1 = RegNext(io.in)
      val z2 = RegNext(z0)
    
      io.out := (io.in * 1.U) + (z1 * 1.U) + (z2 * 1.U)
    }

The power of Chisel comes from the ability to create generators, such as n FIR filter that is defined by the list of coefficients:

.. code-block:: scala

    // Generalized FIR filter parameterized by the convolution coefficients
    class FirFilter(bitWidth: Int, coeffs: Seq[UInt]) extends Module {
      val io = IO(new Bundle {
        val in = Input(UInt(bitWidth.W))
        val out = Output(UInt(bitWidth.W))
      })
      // Create the serial-in, parallel-out shift register
      val zs = Wire(Vec(coeffs.length, UInt(bitWidth.W)))
      zs(0) := io.in
      for (i <- 1 until coeffs.length) {
        zs(i) := zs(i-1)
      }
    
      // Do the multiplies
      val products = VecInit.tabulate(coeffs.length)(i => zs(i) * coeffs(i))
    
      // Sum up the products
      io.out := products.reduce(_ + _)
    }

And use and re-use them across designs:

.. code-block:: scala

    val movingAverage3Filter = FirFilter(8.W, Seq(1.U, 1.U, 1.U))  // same 3-point moving average filter as before
    val delayFilter = FirFilter(8.W, Seq(0.U, 1.U))  // 1-cycle delay as a FIR filter
    val triangleFilter = FirFilter(8.W, Seq(1.U, 2.U, 3.U, 2.U, 1.U))  // 5-point FIR filter with a triangle impulse response
