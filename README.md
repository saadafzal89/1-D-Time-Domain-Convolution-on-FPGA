# 1-D-Time-Domain-Convolution-on-FPGA

This project creats a custom circuit implemented on the Zedboard that exploits a significant amount of
parallelism to improve performance compared to a microprocessor. 

Convolution takes as input a signal (shown as the x array) and a kernel (shown as the h array).
The output is another signal (y array), where each element of the output signal is the sum of the
products formed by multiplying all the elements of the kernel with appropriate elements of the
input signal. Specifically, the x array will be accessed outside of its bounds both at the beginning of execution 
where i-j is negative and towards the end of execution, where i-j is larger than the x array (the output size is sum of the
input size and the kernel minus 1). Also, I used 16-bit unsigned integer operations,
which need to be “clipped” to the maximum possible 16-bit value in case of overflow.


The FPGA implementation stores the input signal in DRAM (currently a fake DRAM model
implemented in blockRAM), and reads in a kernel (up to 128 elements) through the memory
map. The FPGA will then executes using a go and size input from the memory
map, while writing all results to another DRAM. The datapath fully unrolls the inner loop, and
then pipeline the outer loop. Due to resource limitations of the FPGA, the kernel size is
limited to 128 elements. 
