#!/bin/bash

#to debug
#set -x

MY_VERSION="2024.08.1"
P_URL="https://github.com/simple64/simple64/archive/refs/tags/v${MY_VERSION}.tar.gz"
#P_NAME=$(echo $P_URL | cut -d/ -f5)
P_NAME="simple64"
P_VERSION=${MY_VERSION}
P_FILENAME=$(echo $P_URL | cut -d/ -f9)
WORKDIR="workdir"

#=================================================
die() { echo >&2 "$*"; exit 1; };
#=================================================

#echo "P_NAME: ${P_NAME}"
#echo "P_VERSION: ${P_VERSION}"
#echo "P_FILENAME: ${P_FILENAME}"

#exit;


#add-apt-repository ppa:mystic-mirage/pycharm -y

#-------------------------------------------------
#dpkg --add-architecture i386
sudo apt update
#apt install -y aptitude wget file bzip2 gcc-multilib
#sudo apt install -y aptitude wget file bzip2 build-essential ninja-build
sudo apt install -y wget file bzip2 build-essential ninja-build
#-------------------------------------------------
pkgcachedir='/tmp/.pkgdeploycache'
mkdir -p ${pkgcachedir}

packages_to_install="libpng-dev libsdl2-dev libsdl2-net-dev libhidapi-dev libvulkan-dev qt6-base-dev qt6-websockets-dev"
packages_to_download="libcurl3t64-gnutls libssh-4 libldap2 libsasl2-2 libc6 libglib2.0-dev libgssapi-krb5-2 libicu74 libkrb5-3 libk5crypto3 libkrb5support0 librtmp1 libselinux1"

#sudo aptitude -y -d -o dir::cache::archives="${pkgcachedir}" download ${packages_to_install} || die "* Cant download package to install deps!"

# download deb files from installed packages using aptitude
#sudo aptitude -y -d -o dir::cache::archives="${pkgcachedir}" download ${packages_to_download} || die "* Cant download package deps!"

sudo apt-get reinstall --download-only ${packages_to_install} ${packages_to_download} || die "* Cant download package deps!"

cp /var/cache/apt/archives/*.deb ${pkgcachedir}

#-------------------------------------------------
sudo apt install -y ${packages_to_install} || die "* Cant install package dev!"
#######-------#######-------#######-------#######-------#######-------#######-------#######-------

# Get simple64 code
wget -nv ${P_URL}

tar xf v${MY_VERSION}.tar.gz || die "* Cant extract source code!"

cd simple64-${MY_VERSION} || die "* Cant enter the source dir!"

./clean.sh || die "* Cant clean compilated!"

####### POG #######
#sed -i 's/wget -q/wget -c/g' build.sh
#sed -i 's/cmake/#cmake/g' build.sh
#sed -i 's/set -e/set -x/g' build.sh
#echo "exit 0" >> build.sh
####### END POG #######

./build.sh || die "* Cant build the source!"


cd ..
#######-------#######-------#######-------#######-------#######-------#######-------#######-------


# using the package
mkdir "${WORKDIR}"

echo "copying simple64 dir"
cp -r simple64-${MY_VERSION}/simple64 "${WORKDIR}/"

cd "$WORKDIR" || die "ERROR: Directory don't exist: ${WORKDIR}"


sudo chmod 777 ${pkgcachedir} -R

# manual copy all usr libs (cancelled because of size: 27GB)
#echo "copying usr dir"
#du -hs /usr
#cp -a -rv /usr ./

#extras
#wget -nv -c http://ftp.osuosl.org/pub/ubuntu/pool/main/libf/libffi/libffi6_3.2.1-4_amd64.deb -P $pkgcachedir


find ${pkgcachedir} -name '*deb' ! -name 'mesa*' -exec dpkg -x {} . \;
echo "All files in ${pkgcachedir}: $(ls ${pkgcachedir})"

#-------------------------------------------------

##clean some packages to use natives ones:
#rm -rf $pkgcachedir ; rm -rf etc ; 
#rm -rf share/man ; rm -rf usr/share/doc ; rm -rf usr/share/lintian ; rm -rf var ; rm -rf sbin ; rm -rf usr/share/man
#rm -rf usr/share/mime ; rm -rf usr/share/pkgconfig; rm -rf lib; rm -rf etc;
#-------------------------------------------------
cd ..
#===========================================================================================

##fix something here:

#===========================================================================================
# appimage

wget -nv -c "https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage" -O  appimagetool.AppImage
chmod +x appimagetool.AppImage

cat > "AppRun" << EOF
#!/bin/bash
HERE="\$(dirname "\$(readlink -f "\${0}")")"
#-------------------------------------------------

##LD
export MAIN64LDLIBRARY="\${HERE}/usr/lib64/ld-linux-x86-64.so.2"

export LD_LIBRARY_PATH="\$HERE/usr/lib/x86_64-linux-gnu":\$LD_LIBRARY_PATH
export LD_LIBRARY_PATH="\${HERE}/usr/lib/x86_64-linux-gnu/libproxy":\$LD_LIBRARY_PATH
export LD_LIBRARY_PATH="\$HERE/lib":\$LD_LIBRARY_PATH
export LD_LIBRARY_PATH="\$HERE/simple64":\$LD_LIBRARY_PATH

MAIN="\$HERE/simple64/simple64-gui"

export PATH="\$HERE/simple64":\$PATH
"\${MAIN64LDLIBRARY}" "\$MAIN" "\$@"
#"\${MAIN64LDLIBRARY}" "\$MAIN" "\$@" | cat
#"\$MAIN" "\$@" | cat
#"\$MAIN" "\$@" 
EOF
chmod +x AppRun

cp AppRun $WORKDIR
cp resource/* $WORKDIR

./appimagetool.AppImage --appimage-extract

export ARCH=x86_64; squashfs-root/AppRun -v $WORKDIR -u 'gh-releases-zsync|ferion11|${P_NAME}_Appimage|continuous|${P_NAME}-v${P_VERSION}-*arch*.AppImage.zsync' ${P_NAME}-v${P_VERSION}-${ARCH}.AppImage

rm -rf appimagetool.AppImage

echo "All files at the end of script: $(ls)"

# test execution
chmod +x ${P_NAME}-v${P_VERSION}-${ARCH}.AppImage
./${P_NAME}-v${P_VERSION}-${ARCH}.AppImage || die "* Cant execute the AppImage!"


