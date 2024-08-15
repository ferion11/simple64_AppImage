#!/bin/bash
MY_VERSION="2024.06.2"
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
sudo apt install -y aptitude wget file bzip2 build-essential ninja-build
#-------------------------------------------------
pkgcachedir='/tmp/.pkgdeploycache'
mkdir -p ${pkgcachedir}

sudo aptitude -y -d -o dir::cache::archives="${pkgcachedir}" install libpng-dev libsdl2-dev libsdl2-net-dev libhidapi-dev libvulkan-dev qt6-base-dev qt6-websockets-dev libcurl3t64-gnutls || die "* Cant install package deps!"

#extras: libcurl3t64-gnutls libssh
wget -nv -c http://security.ubuntu.com/ubuntu/pool/main/c/curl/libcurl3t64-gnutls_8.5.0-2ubuntu10.2_amd64.deb -P $pkgcachedir
wget -nv -c http://mirrors.kernel.org/ubuntu/pool/main/libs/libssh/libssh-4_0.10.6-2build2_amd64.deb -P $pkgcachedir


#rm -rf ${pkgcachedir}/*dev*

#-------------------------------------------------
sudo apt install -y libpng-dev libsdl2-dev libsdl2-net-dev libhidapi-dev libvulkan-dev qt6-base-dev qt6-websockets-dev || die "* Cant install package dev!"
#######-------#######-------#######-------#######-------#######-------#######-------#######-------

# Get simple64 code
wget -nv ${P_URL}

tar xf v${MY_VERSION}.tar.gz || die "* Cant extract source code!"

cd simple64-${MY_VERSION} || die "* Cant enter the source dir!"

./clean.sh || die "* Cant clean compilated!"
./build.sh || die "* Cant build the source!"


cd ..
#######-------#######-------#######-------#######-------#######-------#######-------#######-------


# using the package
mkdir "${WORKDIR}"

cp -r simple64-${MY_VERSION}/simple64 "${WORKDIR}/"

cd "$WORKDIR" || die "ERROR: Directory don't exist: ${WORKDIR}"


sudo chmod 777 ${pkgcachedir} -R

#extras
#wget -nv -c http://ftp.osuosl.org/pub/ubuntu/pool/main/libf/libffi/libffi6_3.2.1-4_amd64.deb -P $pkgcachedir

find ${pkgcachedir} -name '*deb' ! -name 'mesa*' -exec dpkg -x {} . \;
echo "All files in ${pkgcachedir}: $(ls ${pkgcachedir})"

cd ..
#-------------------------------------------------

##clean some packages to use natives ones:
#rm -rf $pkgcachedir ; rm -rf etc ; 
#rm -rf share/man ; rm -rf usr/share/doc ; rm -rf usr/share/lintian ; rm -rf var ; rm -rf sbin ; rm -rf usr/share/man
#rm -rf usr/share/mime ; rm -rf usr/share/pkgconfig; rm -rf lib; rm -rf etc;
#-------------------------------------------------
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

export LD_LIBRARY_PATH="\$HERE/usr/lib/x86_64-linux-gnu":\$LD_LIBRARY_PATH
export LD_LIBRARY_PATH="\${HERE}/usr/lib/x86_64-linux-gnu/libproxy":\$LD_LIBRARY_PATH
export LD_LIBRARY_PATH="\$HERE/lib":\$LD_LIBRARY_PATH
export LD_LIBRARY_PATH="\$HERE/simple64":\$LD_LIBRARY_PATH

MAIN="\$HERE/simple64/simple64-gui"

export PATH="\$HERE/simple64":\$PATH
"\$MAIN" "\$@" | cat
EOF
chmod +x AppRun

cp AppRun $WORKDIR
cp resource/* $WORKDIR

./appimagetool.AppImage --appimage-extract

export ARCH=x86_64; squashfs-root/AppRun -v $WORKDIR -u 'gh-releases-zsync|ferion11|${P_NAME}_Appimage|continuous|${P_NAME}-v${P_VERSION}-*arch*.AppImage.zsync' ${P_NAME}-v${P_VERSION}-${ARCH}.AppImage

rm -rf appimagetool.AppImage

echo "All files at the end of script: $(ls)"
