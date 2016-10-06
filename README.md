# wurc_pcores
HDL and MATLAB/System Generator blocks for digital signal processing.

* Real-time gain control block integrates with LMS6002D and wurc_fw project for 802.11ac-compliant AGC.
* LMS6002D Radio I/Q interface glue used to provide a software interface to digital predistortion calibration coefficients and other command and control interfaces.
* Simple one-port control of radio control line MUX-ing. Another glue logic layer.

The included pcores require MATLAB and System Generator to generate their Xilinx EDK pcore blocks for a Virtex-6 FPGA target.

# Personal Legal Disclaimer & License
The following applies to the code and models in this repository authored by Ryan E. Guerra
(just about all of it, unless otherwise indicated by the comments).

(c) Ryan E. Guerra ryan@guerra.rocks 2012-2016

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE
FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
DEALINGS IN THE SOFTWARE.

The code contained in this repository is licensed under the Apache 2.0 Software License.
http://www.apache.org/licenses/LICENSE-2.0
