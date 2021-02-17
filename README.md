# Test container for triSYCL/sycl

## Required step before building 

Write your xilinx user account username in `xilid.txt` and the associated password in `xilpasswd.txt`

+ Download the [Vitis 2020.1 unified linux self extracting web installer](https://www.xilinx.com/member/forms/download/xef.html?filename=Xilinx_Unified_2020.1_0602_1208_Lin64.bin) in `install_files/Xilinx_Unified_2020.1_0602_1208_Lin64.bin`
+ Download the [2020.1 ubuntu 18.04 Alveo U200 deployment target platform](https://www.xilinx.com/bin/public/openDownload?filename=xilinx-u200-xdma-201830.2-2580015_18.04.deb) in `install_files/xilinx-u200-xdma-201830.2-2580015_18.04.deb`
+ Downloaf the [2020.1 ubuntu 18.04 Alveo U200 development target platform](https://www.xilinx.com/member/forms/download/eula-xef.html?filename=xilinx-u200-xdma-201830.2-dev-2580015_18.04.deb) in `install_files/xilinx-u200-xdma-201830.2-dev-2580015_18.04.deb`

## Build the docker image 

```
DOCKER_BUILDKIT=1 docker build --secret id=xilid,src=xilid.txt --secret id=xilpasswd,src=xilpasswd.txt .
```
