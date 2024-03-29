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
    
FROM uptodate_ubuntu as config_vitis
RUN apt-get install -y expect
COPY ./install_files/Xilinx_Unified_2021.2_1021_0703_Lin64.bin /Xilinx_Unified_2021.2_1021_0703_Lin64.bin
COPY ./install_files/install_config.txt /install_config.txt
COPY expect_script.us /expect_script.us
RUN --mount=type=secret,id=xilid --mount=type=secret,id=xilpasswd expect /expect_script.us 

FROM config_vitis as install_vitis
RUN /Xilinx_Unified_2021.2_1021_0703_Lin64.bin -- -b Install -c /install_config.txt /xilinx --agree XilinxEULA,3rdPartyEULA

FROM uptodate_ubuntu
RUN mkdir /deb_files 
COPY --from=build_xrt /xilinx_xrt_amd64.deb /deb_files
COPY --from=install_vitis /xilinx /xilinx
ENV XILINX_VERSION=2021.2 XILINX_PLATFORM=xilinx-u200-gen3x16-xdma-base_1 XILINX_ROOT=/xilinx XILINX_VITIS=$XILINX_ROOT/Vitis/$XILINX_VERSION XILINX_VIVADO=$XILINX_ROOT/Vivado/$XILINX_VERSION PATH=$PATH:$XILINX_VITIS/bin:$XILINX_VIVADO/bin LD_LIBRARY_PATH=$LD_LIBRARY_PATH
COPY ./install_files/board_dep_files/*.deb /deb_files
RUN apt install -y /deb_files/*.deb

