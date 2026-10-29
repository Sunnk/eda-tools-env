# eda-tools-env

Open-source EDA flow for Claude Code cloud sessions (Ubuntu 24.04 x86_64).

| Tool | Version | Install path | Source | License |
|---|---|---|---|---|
| Verilator | 5.052 | `/opt/verilator-5.052` | https://github.com/verilator/verilator (tag v5.052) | LGPL-3.0 / Artistic-2.0 |
| slang | 12.0.0 (545f88b) | `/opt/slang-12.0` | https://github.com/MikePopoloski/slang (tag v12.0) | MIT |
| Yosys | 0.70 (built-in `read_slang`) | `/opt/yosys-0.70` | https://github.com/YosysHQ/yosys (tag v0.70) | ISC |
| Verible | v0.0-4296-g0f262651 | `/opt/verible-v0.0-4296-g0f262651` | https://github.com/chipsalliance/verible (release asset) | Apache-2.0 |
| UVM for Verilator | current-patches (2e667ac) | `/opt/src/uvm-verilator` | https://github.com/antmicro/uvm-verilator | Apache-2.0 |
| z3 | Ubuntu package | system | apt | MIT |

## Use

Paste `setup_eda.sh` into the cloud environment's **Setup script** (environment menu in the
session title bar, then Edit). Each new session then:

1. installs the runtime packages with apt;
2. downloads the prebuilt package from the `eda-v1` release, checks its SHA256 and extracts it
   to `/opt` (about 1 ~ 2 minutes);
3. writes `/etc/profile.d/eda.sh` (PATH and `UVM_HOME`).

With `EDA_TARBALL_URL` empty the script builds every tool from source instead
(60 ~ 90 minutes on 4 cores).

## Prebuilt package

`eda-tools-ubuntu24.04-x86_64.tar.xz` (release `eda-v1`), extract with `tar -xJf ... -C /opt`.
SHA256 `4bb32b7fcb5da3b30a38c3389c85bf51c1c13a1e6719ff2f4a7da1a2198e1dd0`.
Build options: Verilator `./configure --prefix=/opt/verilator-5.052`; slang and Yosys CMake
Release builds (`SLANG_INCLUDE_TESTS=OFF`, `YOSYS_ENABLE_UNIT_TESTS=OFF`) with GCC 13.3.
Rebuild the package when the session image moves to another Ubuntu release.
