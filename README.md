# D3NVER BUILD ENVIRONMENT

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

To push to the *BETA* channel, just accept the question at the end of the script or use :

```bash
# push to BETA
./push.sh build/image/<image-release> beta

# push to STABLE
./push.sh build/image/<image-release> stable
```
