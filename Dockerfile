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
COPY ./install_files/board_dep_files/*.deb /deb_files
RUN mkdir /tmp_clone ;\
    cd /tmp_clone ;\
    git clone --depth=1 https://github.com/Xilinx/XRT.git ;\
    cd XRT/build ;\
    ../src/runtime_src/tools/scripts/xrtdeps.sh -docker ;\
    ./build.sh -opt ;\
    mv ./Release/xrt_*-amd64-xrt.deb xrt_amd64.deb ;\
    apt-get install -y xrt_amd64.deb ;\
    rm -rf /tmp_clone
RUN apt-get install -y /deb_files/xilinx*.deb
ENV XILINX_XRT=/opt/xilinx/xrt
ENTRYPOINT ["bash", "-c", "source /xilinx/Vitis/2021.2/settings64.sh && exec \"$@\"", "bash"]
