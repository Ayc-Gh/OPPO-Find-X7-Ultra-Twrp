# PHY110 Recovery 20261010 — 自有 AVB 签名测试版

仅针对 OPPO Find X7 Ultra PHY110 / OP565FL1 / 项目 22111。
设备实际系统为 PHY110_16.0.10.500(CN01)，Android 16，OPlus ROM V16.1.0；不是 ColorOS 17。

已完成完整 Android 编译、14 项 SPL 场景、13 项 libinit 场景以及镜像结构、分区容量和 AVB 签名验证。100 MiB，Android boot header v4，使用现有 boot 内核。签名仅改变 AVB 元数据，原始启动内容逐字节保持一致。

这是未实机启动验证的候选镜像。启动、触摸、FBE 解密、MTP、fastbootd、OTG 与备份恢复尚未确认。USB ADB 保留调试配置，不要求密钥认证；WLAN 和网络 ADB 默认关闭。

使用项目新建 RSA4096 密钥，AVB 算法 SHA256_RSA4096；公钥随附件公开，私钥不发布。该签名不是 OPPO 原厂签名，不能使锁定的 Bootloader 自动接受镜像。设备属性与 bootconfig 对锁定状态的报告存在矛盾，尚未独立确认。

没有刷写、重启、格式化或切换手机槽位。原始 Recovery 备份仅在本地保存，不作为公开附件。

源码来自 adontoo/twrp_device_oplus_sm86xx 的 81061909b76fc6dac1a1ae5c3ddb04b1d4a3e027，Recovery 使用 TWRP-Test 非官方 Android 16 分支；source-lock.json 与 validation/resolved-manifest.xml 记录 392 个依赖版本。源码压缩包是编译所用设备树，加上发布说明和公开验证结果。

签名镜像 SHA256：d15c8272fec97e00a8a945c12f6eed727442d7c59895d58b1fdfe78f9c414c82
公钥 SPKI DER SHA256：1e4d95682a37a423e03991420863bf14d8055ade3c1434f23b7fac54b97e9ef8

核对 SHA256SUMS.txt 中的各附件哈希。AVB 验证时将签名镜像放在单独目录并命名为 recovery.img，再运行：

```sh
python3 avbtool.py verify_image --image recovery.img --key PHY110-release-public-key.pem
```

默认分支旧文件已整体替换；旧提交历史和 refactor/phy110-upstream 分支保留，本地另存完整镜像仓库备份。发布自动导入经过 SHA256 校验的源码包，并把本次标签定位到导入后的源码提交。

---

# PHY110 incremental TWRP device tree

This local fork targets OPPO Find X7 Ultra PHY110 (project 22111), using read-only observations from 2026-10-10. It is based on adontoo's `81061909b76fc6dac1a1ae5c3ddb04b1d4a3e027`.

The original `sm86xx` product name is retained for build compatibility. Other models in the parent's device list are outside this fork's scope.

## Status

Full Android recoveryimage compilation, host failure tests and static image validation passed. This is a **candidate device tree**, not a boot-tested recovery release. No phone was flashed, rebooted, formatted, remounted or switched to another slot during this work.

See [PHY110-NOTES.txt](PHY110-NOTES.txt) for exact changes, tests and remaining limitations, and [validation/phy110-observed.json](validation/phy110-observed.json) for the measured configuration.

## Build

Use a Linux Android build environment with sufficient actual disk space and all prerequisites, then run:

```sh
bash tools/build-phy110.sh /absolute/path/to/new-build-directory
```

The script reads [source-lock.json](source-lock.json), pins the manifest and Recovery candidate commits, records the resolved dependency manifest, and builds `recovery.img`. It does not interact with a phone or publish a release.

## Host verification

```sh
python3 tests/test_spl.py
g++ -std=c++17 -Wall -Wextra -Werror -Itests/stubs tests/libinit_harness.cpp -o /tmp/phy110-libinit-test
/tmp/phy110-libinit-test
```

The C++ harness uses mocked Android APIs; it does not replace a full Android build or device test.

## USB and WLAN

WLAN services and default network ADB are disabled in this validation configuration. USB ADB retains the parent's unauthenticated recovery setting for the initial debugging baseline; secure USB key provisioning is not part of this patch.

Boot and decryption validation require a separately reviewed test plan. Installation commands are intentionally not included in this candidate tree.
