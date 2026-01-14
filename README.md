# RK3588-RedroidPro
适用于瑞芯微RK3588系列SoC的Redroid镜像，针对Redroid进行深度定制

## 测试设备
Orange Pi 5 Pro 16G RAM ，运行Ubuntu Rockchip ，内核版本 5.10.0-1012-rockchip（默认内核），Docker version 27.3.1

## 系统要求
- 内核版本 Ubuntu vendor kernel for RK35XX (linux-image-vendor-rk35xx)
- Mali CSF GPU 内核驱动
- Mali 固件，置于/lib/firmware/下
- CONFIG_PSI=y
- CONFIG_ANDROID_BINDERFS=y
- DMA-BUF设备支持
你可以运行envcheck.sh来检查这些要求。

## 部署
使用docker-compose：
克隆项目：
```
git clone https://github.com/xxx252525/RK3588-RedroidPro.git --depth 1
cd redroid-rk3588
```
使用docker-ce：
```
docker compose up -d
```
使用docker.io：
```
sudo apt install docker-compose
docker-compose up -d
```
手动运行(推荐)：
```
docker run -d -p 5555:5555 -v ~/redroid-data:/data --restart unless-stopped --name redroid --privileged cnflysky/redroid-rk3588:lineage-20 androidboot.redroid_height=1920 androidboot.redroid_width=1080
```
