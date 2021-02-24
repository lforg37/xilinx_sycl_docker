FROM ubuntu:latest as uptodate_ubuntu 
# Install the xilinx runtime 
ENV DEBIAN_FRONTEND="noninteractive" TZ="Europe/Paris"
RUN apt-get update;

FROM uptodate_ubuntu as build_xrt
RUN apt-get install -y git wget
RUN mkdir /local_install 
WORKDIR  /local_install
RUN git clone https://github.com/Xilinx/XRT.git 
WORKDIR /local_install/XRT/build
RUN ../src/runtime_src/tools/scripts/xrtdeps.sh -docker
RUN ./build.sh ;\
    mv ./Release/xrt_*-amd64-xrt.deb /xilinx_xrt_amd64.deb 
    
FROM uptodate_ubuntu as install_vitis
RUN apt-get install -y expect
COPY ./install_files/Xilinx_Unified_2020.1_0602_1208_Lin64.bin /Xilinx_Unified_2020.1_0602_1208_Lin64.bin
COPY ./install_files/install_config.txt /install_config.txt
COPY expect_script.us /expect_script.us
RUN --mount=type=secret,id=xilid --mount=type=secret,id=xilpasswd expect /expect_script.us 

FROM uptodate_ubuntu as sycl_conf
RUN apt-get install -y git cmake python python3 pkg-config ninja-build g++ opencl-headers ocl-icd-opencl-dev libboost-all-dev
#RUN git clone --depth=1 --branch sycl/unified/next https://github.com/triSYCL/sycl.git xilinx_sycl 
RUN git clone --depth=1 --branch TestCompile https://github.com/lforg37/sycl.git /xilinx_sycl
WORKDIR /xilinx_sycl/buildbot
RUN python configure.py

FROM sycl_conf as sycl_compile
RUN python compile.py

FROM uptodate_ubuntu
COPY --from=build_xrt /xilinx_xrt_amd64.deb /xilinx_xrt_amd64.deb
COPY --from=install_vitis /xilinx /xilinx
COPY --from=sycl_compile /xilinx_sycl /xilinx_sycl
ENV SYCL_HOME=/xilinx_sycl XILINX_VERSION=2020.1 XILINX_PLATFORM=xilinx_u200_xdma_201830_2 XILINX_ROOT=/xilinx SYCL_BIN_DIR=$SYCL_HOME/build/bin XILINX_VITIS=$XILINX_ROOT/Vitis/$XILINX_VERSION XILINX_VIVADO=$XILINX_ROOT/Vivado/$XILINX_VERSION PATH=$PATH:$SYCL_BIN_DIR:$XILINX_VITIS/bin:$XILINX_VIVADO/bin LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$SYCL_HOME/build/lib
COPY ./install_files/xilinx-u200-xdma-201830.2-2580015_18.04.deb /deb_install/xilinx-u200-xdma-201830.2-2580015_18.04.deb 
COPY ./install_files/xilinx-u200-xdma-201830.2-dev-2580015_18.04.deb /deb_install/xilinx-u200-xdma-201830.2-dev-2580015_18.04.deb
RUN apt install -y /xilinx_xrt_amd64.deb /deb_install/xilinx-u200-xdma-201830.2-2580015_18.04.deb /deb_install/xilinx-u200-xdma-201830.2-dev-2580015_18.04.deb

