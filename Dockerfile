FROM ubuntu:21.04 as uptodate_ubuntu 
ENV DEBIAN_FRONTEND="noninteractive" TZ="Europe/Paris"
RUN apt-get update;
#Install all dependancies
RUN apt-get install -y expect git wget clang ninja-build locales libtinfo5 libc6-dev-i386 ;\
    echo "en_US.UTF-8 UTF-8" > /etc/locale.gen ;\
    locale-gen

FROM uptodate_ubuntu as config_vitis
COPY ./install_files/Xilinx_Unified_2021.2_1021_0703_Lin64.bin /Xilinx_Unified_2021.2_1021_0703_Lin64.bin
COPY ./install_files/install_config.txt /install_config.txt
COPY expect_script.us /expect_script.us
RUN --mount=type=secret,id=xilid --mount=type=secret,id=xilpasswd expect /expect_script.us 

FROM config_vitis as install_vitis
RUN /Xilinx_Unified_2021.2_1021_0703_Lin64.bin -- -b Install -c /install_config.txt /xilinx --agree XilinxEULA,3rdPartyEULA

FROM install_vitis as run_env
RUN mkdir /deb_files 
RUN mkdir /tmp_clone ;\
    cd /tmp_clone ;\
    git clone --depth=1 https://github.com/Xilinx/XRT.git ;\
    cd XRT/build ;\
    ../src/runtime_src/tools/scripts/xrtdeps.sh -docker ;\
    ./build.sh -opt ;\
    mv ./Release/xrt_*-amd64-xrt.deb /deb_files/xrt_amd64.deb ;\
    rm -rf /tmp_clone
RUN apt-get install -y /deb_files/xrt_amd64.deb
COPY ./install_files/board_dep_files/*.deb /deb_files
RUN apt-get install -y /deb_files/xilinx*.deb ;\
    rm -rf /root/.Xilinx
ENV XILINX_XRT="/opt/xilinx/xrt" XILINX_VERSION="2021.2" XILINX_PLATFORM="xilinx_u200_xdma_201830_2" 
ENV XILINX_VITIS="/xilinx/Vitis/2021.2" XILINX_VIVADO="/xilinx/Vivado/2021.2" XILINX_SDX="/xilinx/Vitis_HLS/2021.2"
ENV PATH="$PATH:$XILINX_XRT/bin:$XILINX_VITIS/bin:$XILINX_VIVADO/bin" LD_LIBRARY_PATH="$LD_LIBRARY_PATH:$XILINX_XRT/lib:$XILINX_VITIS/lib/lnx64.o" EMCONFIG_PATH="/xilinxconfig"
ENV USER="root" LIBRARY_PATH="$LD_LIBRARY_PATH"
RUN emconfigutil --platform $XILINX_PLATFORM --od $EMCONFIG_PATH --save-temps
RUN update-alternatives --set c++ /usr/bin/clang++
