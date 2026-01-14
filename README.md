# RK3588-RedroidPro
适用于瑞芯微RK3588系列SoC的Redroid镜像，针对Redroid进行深度定制

## 测试设备
设备：Orange Pi 5 Pro 1

内存：6G RAM 

系统：Ubuntu Rockchip 

系统内核：5.10.0-1012-rockchip

Docker版本：27.3.1

## 系统要求
- 内核版本 Ubuntu vendor kernel for RK35XX (linux-image-vendor-rk35xx)
- Mali CSF GPU 内核驱动
- Mali 固件，置于/lib/firmware/下
- CONFIG_PSI=y
- CONFIG_ANDROID_BINDERFS=y
- DMA-BUF设备支持
你可以运行envcheck.sh来检查这些要求。

## 部署Redroid
使用docker-compose：
克隆项目：
```shell
git clone https://github.com/xxx252525/RK3588-RedroidPro.git --depth 1
cd redroid-rk3588
```
使用docker-ce：
```shell
docker compose up -d
```
使用docker.io：
```shell
sudo apt install docker-compose
docker-compose up -d
```
手动运行(推荐)：
```shell
docker run -d -p 5555:5555 -v ~/redroid-data:/data --restart unless-stopped --name redroid --privileged cnflysky/redroid-rk3588:lineage-20 androidboot.redroid_height=1920 androidboot.redroid_width=1080
```
