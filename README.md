# Radxa U-Boot

使用来自 Radxa 仓库的 U-Boot，编译以及使用的方法。

# 编译

获取代码：

```bash
git pull --branch=u-boot-radxa --depth=1 https://github.com/jiehui555/sbc-rock-2f.git
```

构建 Docker 编译环境：

```bash
make builder
```

编译 U-Boot：

```bash
make build
```

编译成功后，会在 `output` 文件夹生成 `idblock.img` 和 `u-boot.itb` 文件。

# 使用

将读卡器（TF 卡）插入编译主机，以 `/dev/sdb` 设备名为例：

```bash
sudo dd if=output/idblock.img of=/dev/sdb seek=64
sudo dd if=output/u-boot.itb of=/dev/sdb seek=16384
```

插入开发板，连接串口工具，启动测试...

# 开发

获取代码：

```bash
git pull https://github.com/jiehui555/sbc-rock-2f.git
git checkout u-boot-radxa
```

在 `overlay/u-boot` 中存放修改后的代码，它会在编译时覆盖到 u-boot 代码。

# 参考

- https://opensource.rock-chips.com/wiki_U-Boot
- https://opensource.rock-chips.com/wiki_Boot_option
