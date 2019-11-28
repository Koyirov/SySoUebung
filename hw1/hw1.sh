#/bin/ sh

KERNEL_LOCATION=https://cdn.kernel.org/pub/linux/kernel/v4.x/linux-4.11.tar.xz
KERNEL_TAR_NAME=linux-4.11.tar.xz
KERNEL_DIR=linux-4.11
BUSYBOX_LOCATION=http://busybox.net/downloads/busybox-1.26.2.tar.bz2
BUSYBOX_TAR_NAME=busybox-1.26.2.tar.bz2
BUSYBOX_DIR=busybox-1.26.2

download_kernel()
{
    cd artifacts
    wget $KERNEL_LOCATION
    cd ..
}

download_busybox()
{
    cd artifacts
    wget $BUSYBOX_LOCATION
    cd ..
}

build_kernel() 
{
    #extracting kernel
    cd artifacts
    tar xvf $KERNEL_TAR_NAME
    cd ..
    cp kernel/.config artifacts/$KERNEL_DIR/.config #replacing config
    cd artifacts/$KERNEL_DIR
    make -j5
	cp arch/x86/boot/bzImage ../
    cd ../..
}

build_busybox() 
{
	#extracting busybox
	cd artifacts
	tar xvf $BUSYBOX_TAR_NAME
	cd ..
	cp busybox/.config artifacts/$BUSYBOX_DIR/.config #replacing config
	cd artifacts/$BUSYBOX_DIR
	make -j5
	cp busybox ../
	cd ../..
}

build_sysinfo()
{
    cd sysinfo/src
    make
    cd ../..
    rm sysinfo/src/sysinfo.o    
}

build_initrd_sysinfo()
{
    build_sysinfo
    cd initrd-sysinfo
    find | cpio -L -v -o -H newc > ../artifacts/initrd-sysinfo.cpio
    cd ..
}

build_initrd_busybox()
{
    build_sysinfo
    cd initrd-busybox
    find | cpio -L -v -o -H newc > ../artifacts/initrd-busybox.cpio
    cd ..
}

build_artifacts()
{
    mkdir artifacts
    
    download_kernel 
    build_kernel
    build_initrd_sysinfo

    download_busybox
    build_busybox
    build_initrd_busybox
}

clean()
{
    rm -rf artifacts
}

run_kernel_initrd()
{
    qemu-system-x86_64 -m 64 \
    -nographic \
    -kernel artifacts/bzImage \
    -initrd artifacts/initrd-sysinfo.cpio \
    -append "console=ttyS0 init=/bin/sysinfo"
}

run_busybox_initrd()
{
    qemu-system-x86_64 -m 64 \
    -nographic \
    -kernel artifacts/bzImage \
    -initrd artifacts/initrd-busybox.cpio \
    -append "root=/dev/vda1 rw console=ttyS0 init=/init"
}

if [ "$1" = "clean" ]; then
	clean
else
	if [ "$1" = "qemu_sysinfo" ]; then
		run_kernel_initrd
	else
		if [ "$1" = "qemu_busybox" ]; then
 			run_busybox_initrd
		else
			if [ $# -eq 0 ]; then
				build_artifacts
			else
				echo "invalid option"
			fi
		fi
	fi
fi
