# UEFI-ToyOS开发环境

　　学习的第一步是准备适合我的开发环境。我计划使用 Docker 容器化我的编译工具，使用 VSCode 写代码。稍后决定使用什么虚拟机运行编译的 EFI。

## 准备编译工具

　　 [谭玉刚的开发环境](https://www.bilibili.com/read/readlist/rl437726) 提到第一步是拉取 EDK2 的代码仓库并编译。他使用了一些不必要 python 配置步骤，我直接按照 [EDK2的文档](https://github.com/tianocore/tianocore.github.io/wiki/Getting-Started-with-EDK-II) 配置依赖软件。

　　在仓库目录下创建一个 Dockerfile，配置基本描述，使用 RUN 指令下载软件，使用 ENTRYPOINT 指令配置默认进入 bash：

```dockerfile
FROM linkin/ubuntu

LABEL description=“学习 UEFI-ToyOS 的开发环境。”
LABEL org.opencontainers.image.authors=“杨林青”

RUN DEBIAN_FRONTEND=noninteractive apt-get update && \
    apt-get install -y build-essential uuid-dev iasl nasm python-is-python3 && \
    apt-get autoremove -y; apt-get clean; rm /var/lib/apt/lists/* -r

ENTRYPOINT [ “/bin/bash” ]
```

**代码说明：**

　　第一行指定我自己的 ubuntu 镜像，该镜像配置了时区和语言。接下来安装 [EDK2的文档](https://github.com/tianocore/tianocore.github.io/wiki/Getting-Started-with-EDK-II) 中除 git 外的所有依赖。最后指定入口为 bash。

　　使用 `docker build` 命令编译容器镜像，使用 `docker run —rm -it —volume $(pwd)/src/:/root/src image-tag` 启动镜像并进入 shell。

## 尝试编译

　　在容器外按照《Common Instructions》拉取仓库。在 VSCode 中修改文档中提到的配置，最后在容器中编译基础工具和 HelloWorld.efi。

## 使用Git子模块组织代码

　　在之前的步骤中，我直接拉取了 EDK2 的仓库。由于我想要把整个学习的代码也做成一个 Git 仓库，我决定使用  [Git 子模块](https://git-scm.com/book/en/v2/Git-Tools-Submodules) 功能组织代码。 `Git submodule add` 命令可以识别已有的 git 仓库。因此，我直接使用此命令添加子模块：

```bash
git submodule add https://github.com/tianocore/edk2.git src/edk2
```

## 运行编译的代码

　　QEMU 是一个开源的虚拟机模拟器，可以模拟任意架构的 CPU。它的 [虚拟 FAT 磁盘镜像](https://www.qemu.org/docs/master/system/images.html#virtual-fat-disk-images) 功能可以将主机上的目录模拟为一个FAT磁盘镜像，非常适合调试我们编译好的 efi 程序。 

**批注：**

　　谭玉刚在这一步描述的不是很详细，而且有很多无关步骤。他的操作主要是：

1. 编译 QEMU 使用的 UEFI 运行时，使虚拟机支持 UEFI 引导。
1. 使用 `-hda fat:/path/to/hda-contents` 参数将目录模拟为虚拟硬盘中的一个 FAT 分区。

   见  [https://www.qemu.org/docs/master/system/images.html#virtual-fat-disk-images](https://www.qemu.org/docs/master/system/images.html#virtual-fat-disk-images) 

　　[UTM](https://mac.getutm.app) 是 iOS/iPadOS/macOS 中的一个虚拟机 APP，底层调用 qemu 和 Virtualization 框架。这个 APP 可以很方便地在 macOS 上用 qemu 运行虚拟机。因此我使用 UTM 运行编译的 efi 程序。

　　在 UTM 中创建好虚拟机后，在虚拟机配置的 “QEMU” 部分可以配置 QEMU 参数。勾选 “UEFI” 启动，这样我们就不需要手动编译一个 UEFI 运行时了。可以在下方的参数列表中看到 UTM 已经提供了一个 edk2 的 UEFI 启动环境。

![](UEFI-ToyOS%E5%BC%80%E5%8F%91%E7%8E%AF%E5%A2%83/Pasted%20Graphic%201.png)

![](UEFI-ToyOS%E5%BC%80%E5%8F%91%E7%8E%AF%E5%A2%83/Pasted%20Graphic.png)

　　经过反复尝试，QEMU 的虚拟 FAT 分区无法被虚拟机挂载。经过各种尝试发现，QEMU 和 macOS 都支持 RAW 格式的虚拟磁盘文件。为了便于开发，我打算让虚拟机直接使用这个原始磁盘镜像，删除了默认创建的 qcow2 硬盘，重新创建了 RAW 格式的硬盘。在虚拟机文件包（位于 `$HOME/Library/Containers/com.utmapp.UTM/Data/Documents/<虚拟机名称>.utm`）的 `Images` 目录中可以看到新建的 RAW 后缀的硬盘文件，直接重命名为 img 后缀即可被 macOS 识别。未初始化的虚拟磁盘无法被 macOS 挂载，因此我使用 Ubuntu Live CD 启动虚拟机，将虚拟磁盘初始化为 GPT 分区表，并将所有空间划分为一个 FAT 格式的分区。不要将分区类型改为 EFI，保持 Microsoft Basic Data 不变，否则 macOS 不会显示分区。

　　完成分区工作后将虚拟机关机，在 macOS 的访达中找到虚拟磁盘文件，双击挂载，即可将编译好的 efi 文件放入虚拟磁盘。然后在 macOS 中卸载虚拟磁盘，在 UTM 中启动虚拟机，EFI 成功识别，并且成功打印 Hello World。

![](UEFI-ToyOS%E5%BC%80%E5%8F%91%E7%8E%AF%E5%A2%83/Pasted%20Graphic%203.png)

如图，进入 UEFI Shell 后提示已经检测到了虚拟机硬盘中的 FAT 文件系统并映射为 `FS0`.在 `FS0` 中发现了编译好的 HelloWorld.efi 文件，输入文件名即可执行并打印字符串。

## 相关内容

### 学习材料

* **谭玉刚的开发环境**

  [https://www.bilibili.com/read/readlist/rl437726](https://www.bilibili.com/read/readlist/rl437726) 

  质量不是很高。

### EFI Develop Kit II文档

* **Getting Started with EDK II**

  [https://github.com/tianocore/tianocore.github.io/wiki/Getting-Started-with-EDK-II](https://github.com/tianocore/tianocore.github.io/wiki/Getting-Started-with-EDK-II) 

* **Using EDK II with Native GCC**

  [https://github.com/tianocore/tianocore.github.io/wiki/Using-EDK-II-with-Native-GCC](https://github.com/tianocore/tianocore.github.io/wiki/Using-EDK-II-with-Native-GCC) 

* **Common Instructions**

  [https://github.com/tianocore/tianocore.github.io/wiki/Common-instructions](https://github.com/tianocore/tianocore.github.io/wiki/Common-instructions) 

### 编译工具

* **Git子模块**

  [https://git-scm.com/book/en/v2/Git-Tools-Submodules](https://git-scm.com/book/en/v2/Git-Tools-Submodules) 

### 运行代码

* **UTM网站**

  [https://mac.getutm.app](https://mac.getutm.app) 

## 修订记录
### 2022-05-07T14:41:19+08:00
* 创建。
### 2022-05-08T17:00:00+08:00
* 使用Git子模块组织代码。
### 2022-05-08T12:49:12+08:00
* 添加运行代码的说明。
### 2022-05-08T21:27:19+08:00
* 运行代码改为制作原始磁盘镜像的方式。
