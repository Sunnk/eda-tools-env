#!/bin/bash
# Cloud environment setup script: installs the open-source EDA flow used by axi5_1m1s_rob.
#   Verilator 5.052, slang 12.0, Yosys 0.70 (built-in read_slang), Verible v0.0-4296-g0f262651,
#   UVM for Verilator (antmicro/uvm-verilator, current-patches), z3.
# Install paths match the dev scripts (dev/vl_build.sh, dev/slang_lint.sh, syn/syn_eval.sh).
#
# Two ways to install:
#   1. Prebuilt package (about 1 ~ 2 minutes): eda-tools-ubuntu24.04-x86_64.tar.xz, stored in
#      prebuilt/ of this repository as parts below 50 MB; EDA_TARBALL_URL is the URL of the
#      package without the .partNN suffix, the parts are downloaded in order and joined.
#   2. Build from source (about 60 ~ 90 minutes on 4 cores): leave EDA_TARBALL_URL empty.
# The setup script cannot read the environment's variables or secrets, so the URL is written here.
set -euo pipefail

EDA_TARBALL_URL="https://raw.githubusercontent.com/Sunnk/eda-tools-env/main/prebuilt/eda-tools-ubuntu24.04-x86_64.tar.xz"
EDA_TARBALL_PARTS="00 01"
EDA_TARBALL_SHA256="4bb32b7fcb5da3b30a38c3389c85bf51c1c13a1e6719ff2f4a7da1a2198e1dd0"

VERILATOR_TAG=v5.052
SLANG_TAG=v12.0
YOSYS_TAG=v0.70
VERIBLE_TAG=v0.0-4296-g0f262651
UVM_BRANCH=current-patches

export DEBIAN_FRONTEND=noninteractive
JOBS=$(nproc)

# Runtime libraries (Yosys: tcl, readline, ffi) and the formal solver; make / g++ / perl are
# needed by Verilator --binary builds.
apt-get update -qq
apt-get install -y -qq make g++ perl python3 zlib1g libtcl8.6 libreadline8t64 libffi8 z3 xz-utils curl git

install_prebuilt() {
    local tmp
    tmp=$(mktemp -d)
    for part in $EDA_TARBALL_PARTS; do
        curl -fsSL --retry 3 "$EDA_TARBALL_URL.part$part" >> "$tmp/eda.tar.xz"
    done
    echo "$EDA_TARBALL_SHA256  $tmp/eda.tar.xz" | sha256sum -c -
    tar -xJf "$tmp/eda.tar.xz" -C /opt
    rm -rf "$tmp"
}

build_from_source() {
    apt-get install -y -qq build-essential clang cmake autoconf bison flex help2man libfl-dev ccache \
        libreadline-dev gawk tcl-dev libffi-dev pkg-config zlib1g-dev \
        libboost-system-dev libboost-python-dev libboost-filesystem-dev
    mkdir -p /opt/src && cd /opt/src

    if [ ! -x /opt/verilator-5.052/bin/verilator ]; then
        git clone -q --depth 1 -b "$VERILATOR_TAG" https://github.com/verilator/verilator verilator-5.052
        (cd verilator-5.052 && autoconf && ./configure --prefix=/opt/verilator-5.052 \
            && make -j"$JOBS" && make install)
    fi

    if [ ! -x /opt/slang-12.0/bin/slang ]; then
        git clone -q --depth 1 -b "$SLANG_TAG" https://github.com/MikePopoloski/slang slang-12.0
        (cd slang-12.0 && cmake -B build -DCMAKE_BUILD_TYPE=Release -DSLANG_INCLUDE_TESTS=OFF \
            -DCMAKE_INSTALL_PREFIX=/opt/slang-12.0 && cmake --build build -j"$JOBS" && cmake --install build)
    fi

    if [ ! -x /opt/yosys-0.70/bin/yosys ]; then
        git clone -q --depth 1 -b "$YOSYS_TAG" --recurse-submodules --shallow-submodules \
            https://github.com/YosysHQ/yosys yosys-0.70
        (cd yosys-0.70 && cmake -B build -DCMAKE_BUILD_TYPE=Release -DYOSYS_ENABLE_UNIT_TESTS=OFF \
            -DCMAKE_INSTALL_PREFIX=/opt/yosys-0.70 && cmake --build build -j"$JOBS" && cmake --install build)
    fi

    if [ ! -x "/opt/verible-$VERIBLE_TAG/bin/verible-verilog-lint" ]; then
        curl -fsSL "https://github.com/chipsalliance/verible/releases/download/$VERIBLE_TAG/verible-$VERIBLE_TAG-linux-static-x86_64.tar.gz" \
            | tar -xz -C /opt
    fi

    if [ ! -d /opt/src/uvm-verilator/src ]; then
        git clone -q --depth 1 -b "$UVM_BRANCH" https://github.com/antmicro/uvm-verilator /opt/src/uvm-verilator
    fi
}

if [ -x /opt/verilator-5.052/bin/verilator ] && [ -x /opt/slang-12.0/bin/slang ] \
   && [ -x /opt/yosys-0.70/bin/yosys ] && [ -x "/opt/verible-$VERIBLE_TAG/bin/verible-verilog-lint" ] \
   && [ -d /opt/src/uvm-verilator/src ]; then
    echo "EDA tools already installed"
elif [ -n "$EDA_TARBALL_URL" ]; then
    install_prebuilt
else
    build_from_source
fi

# PATH and UVM location for every later shell.
cat > /etc/profile.d/eda.sh <<EOF
export PATH=/opt/verilator-5.052/bin:/opt/slang-12.0/bin:/opt/yosys-0.70/bin:/opt/verible-$VERIBLE_TAG/bin:\$PATH
export UVM_HOME=/opt/src/uvm-verilator/src
EOF

/opt/verilator-5.052/bin/verilator --version
/opt/slang-12.0/bin/slang --version
/opt/yosys-0.70/bin/yosys -V
"/opt/verible-$VERIBLE_TAG/bin/verible-verilog-lint" --version | head -1
