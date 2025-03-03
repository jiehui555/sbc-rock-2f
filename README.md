# Radxa U-Boot

使用来自 Radxa 仓库的 U-Boot，编译以及使用的方法。

# 编译

获取代码：

```bash
git pull --branch=u-boot-radxa --depth=1 https://github.com/jiehui555/sbc-rock-2f.git
git submodule update --init --recursive
```

编译 U-Boot：

```bash
./build.sh
```

# 开发

获取代码：

```bash
git pull https://github.com/jiehui555/sbc-rock-2f.git
git checkout u-boot-radxa
git submodule update --init --recursive

# 拉取最新的子模块代码
git submodule update --remote
```
