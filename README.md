# D3NVER BUILD ENVIRONMENT

![D3nver BETA RBI build](https://github.com/HybridDevTools/d3nver-rbi-builder/workflows/D3nver%20BETA%20RBI%20build/badge.svg?branch=beta)
![D3nver STABLE RBI build](https://github.com/HybridDevTools/d3nver-rbi-builder/workflows/D3nver%20STABLE%20RBI%20build/badge.svg?branch=master)
[![GitHub license](https://img.shields.io/github/license/HybridDevTools/d3nver-rbi-builder.svg)](https://github.com/HybridDevTools/d3nver-rbi-builder/blob/master/LICENSE)
[![GitHub release](https://img.shields.io/github/release/HybridDevTools/d3nver-rbi-builder.svg)](https://GitHub.com/HybridDevTools/d3nver-rbi-builder/releases/)

Requirements:

- ansible 2.8+
- awscli
- debootstrap
- lbzip2
- qemu-utils
- sfdisk 

## How to build an image

Building a 32Gb virtual hard disk image with Ubuntu Bionic (18.04) as base distro :

```bash
sudo ./build.sh -c ubuntu:bionic -s 32
```

To push automatically to the *BETA* channel, just accept the question at the end of the script or use :

```bash
# push to BETA
./push.sh build/image/<image-release> beta

# push to STABLE
./push.sh build/image/<image-release> stable
```
