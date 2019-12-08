#/bin/ sh

KERNEL_DIR=linux-4.11
KERNEL_TAR_NAME=$KERNEL_DIR.tar.xz
KERNEL_LOCATION=https://cdn.kernel.org/pub/linux/kernel/v4.x/$KERNEL_TAR_NAME
BUSYBOX_DIR=busybox-1.26.2
BUSYBOX_TAR_NAME=$BUSYBOX_DIR.tar.bz2
BUSYBOX_LOCATION=http://busybox.net/downloads/$BUSYBOX_TAR_NAME
DROPBEAR_DIR=dropbear-2016.74
DROPBEAR_TAR_NAME=$DROPBEAR_DIR.tar.bz2
DROPBEAR_LOCATION=https://matt.ucc.asn.au/dropbear/releases/$DROPBEAR_TAR_NAME

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

download_dropbear()
{
    cd artifacts
    wget $DROPBEAR_LOCATION
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
	cp arch/x86/boot/bzImage ..
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
	cp busybox ..
	cd ../..
}

build_dropbear()
{
    #extracting dropbear
    cd artifacts
    tar xvf $DROPBEAR_TAR_NAME
    cp ../dropbear/options.h $DROPBEAR_DIR
    cd $DROPBEAR_DIR
    ./configure --disable-shadow --disable-wtmp --disable-wtmpx --disable-utmpx
    make PROGRAMS="dropbear dbclient dropbearkey dropbearconvert scp" MULTI=1 STATIC=1
    cp dropbearmulti ..
    cd ..
    ln -s $(pwd)/dropbearmulti ../initrd/bin 
    cd /..
}

build_sysinfo()
{
    mkdir ../hw1/artifacts
    cd ../hw1/sysinfo/src
    make
    cd ../../../hw2
    cp ../hw1/artifacts/sysinfo artifacts
    rm ../hw1/sysinfo/src/sysinfo.o ../hw1/artifacts
}

build_initrd()
{
    build_sysinfo
    cd initrd
    mkdir lib
    ldlinux=$(gcc -print-file-name=ld-linux-x86-64.so.2)
    libc=$(gcc -print-file-name=libc.so.6)
    libnss=$(gcc -print-file-name=libnss_files.so.2)
    ln -s $ldlinux lib/
    ln -s $libc lib/
    ln -s $libnss lib/
    find | cpio -L -v -o -H newc > ../artifacts/initrd.cpio
    cd ..
}

build_artifacts()
{
    mkdir artifacts
    
    download_kernel 
    build_kernel
    download_busybox
    build_busybox
    download_dropbear
    build_dropbear
    build_initrd
}

clean()
{
    rm -rf artifacts ../hw1/artifacts initrd/lib
}

run_initrd()
{
    qemu-system-x86_64 -m 64 \
    -nographic \
    -kernel artifacts/bzImage \
    -initrd artifacts/initrd.cpio \
    -netdev user,id=mynet0,net=192.168.10.0/24,dhcpstart=192.168.10.10,hostfwd=tcp::22222-:22 \
    -device virtio-net,netdev=mynet0 \
    -append "root=/dev/vda1 rw console=ttyS0 init=/init"
}

run_ssh_cmd()
{
    if [ -z "$arg2" ]; then
        artifacts/dropbearmulti dbclient -y -p 22222 -l root -i ~/.ssh/id_rsa_dropbear localhost
    else
        artifacts/dropbearmulti dbclient -y -p 22222 -l root -i ~/.ssh/id_rsa_dropbear localhost $arg2
    fi
}

if [ "$1" = "clean" ]; then
	clean
else
	if [ "$1" = "qemu" ]; then
		run_initrd
	else
		if [ "$1" = "ssh_cmd" ]; then
 			run_ssh_cmd
		else
			if [ $# -eq 0 ]; then
				build_artifacts
			else
				echo "invalid option"
			fi
		fi
	fi
fi
