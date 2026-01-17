
# ChisFlash

- [Discord](https://discord.gg/Hq8PSSpnEM)

- ChisFlash是开源GBA烧录卡，它的灵感来自[opencartgba](https://github.com/laqieer/opencartgba)项目。
- 立创开源项目地址（最新版本PCB在此发布）：[ChisBread](https://oshwhub.com/chisbread/works)
- v1.0(Prometheus)版本适用FRAM，v0.1版本适用SRAM (1Mbit)。

# 功能特性

- ChisFlash的开发目标是实现一个功能齐全的GBA烧录卡

| 特性 | 状态 |
| --- | --- |
| 256Mbit闪存 | ✅ |
| 512Kbit SRAM/FRAM | ✅ |
| 1Mbit SRAM/FRAM（Bank Switching） | ✅ |
| 1Mbit/512Kbit Flash（Bank Switching） | ✅ |
| 实时时钟（RTC） | × |
| 振动反馈 | × |
| 陀螺仪 | × |
| 太阳传感器 | × |

# 效果图

![realcart](./images/realcart.png)
![top_v1.0](./images/top_v1.0.png)
![but_v1.0](./images/but_v1.0.png)
![top_v0.1](./images/top_v0.1.png)
![but_v0.1](./images/but_v0.1.png)

# 原理图

![schematic](./images/sch.png)

# BOM

- [ChisFlash BOM](BOM.md)

# 目录结构   

```
ChisFlash
├── README.md
├── LICENSE
├── hardware
├── firmware
│   └── QuartusII1MSRAM
│   └── QuartusII1MFRAM
│   └── QuartusII1MFlash
├── document-zh
```

#### 补充说明

- ChisFlash/hardware PCB设计文件
- ChisFlash/firmware/QuartusII1MSRAM 固件目录 (适配1M SRAM) [PCB,BOM](https://oshwhub.com/chisbread/chisflash-pichu)
- ChisFlash/firmware/QuartusII1MFRAM 固件目录 (适配1M FRAM) [PCB,BOM](https://oshwhub.com/chisbread/chisflash-prometheus)
- ChisFlash/firmware/QuartusII1MFlash 固件目录 (适配1M Flash, 同时支持 512Kbit Flash) [PCB,BOM](https://oshwhub.com/chisbread/chisflash-celebi) 
- GBA自动无电池存档补丁 [512Kbit ROM patch](https://github.com/ChisBread/gba-auto-batteryless-patcher/tree/custom_flashid)
