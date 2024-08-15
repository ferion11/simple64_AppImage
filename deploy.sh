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

sudo aptitude -y -d -o dir::cache::archives="${pkgcachedir}" install libsdl2-2.0 libsdl2-net libhidapi-hidraw0 libhidapi-libusb0
#-------------------------------------------------

sudo apt install -y libsdl2-dev libsdl2-net-dev libhidapi-dev
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

cd "$WORKDIR" || die "ERROR: Directory don't exist: ${WORKDIR}"


sudo chmod 777 ${pkgcachedir} -R

#extras
#wget -nv -c http://ftp.osuosl.org/pub/ubuntu/pool/main/libf/libffi/libffi6_3.2.1-4_amd64.deb -P $pkgcachedir

find ${pkgcachedir} -name '*deb' ! -name 'mesa*' -exec dpkg -x {} . \;
echo "All files in ${pkgcachedir}: $(ls ${pkgcachedir})"
#-------------------------------------------------

##clean some packages to use natives ones:
#rm -rf $pkgcachedir ; rm -rf share/man ; rm -rf usr/share/doc ; rm -rf usr/share/lintian ; rm -rf var ; rm -rf sbin ; rm -rf usr/share/man
#rm -rf usr/share/mime ; rm -rf usr/share/pkgconfig; rm -rf lib; rm -rf etc;
#-------------------------------------------------
#===========================================================================================

##fix something here:

#===========================================================================================
# appimage
cd ..

wget -nv -c "https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage" -O  appimagetool.AppImage
chmod +x appimagetool.AppImage

cat > "AppRun" << EOF
#!/bin/bash
HERE="\$(dirname "\$(readlink -f "\${0}")")"
#-------------------------------------------------

MAIN="\$HERE/simple64-${P_VERSION}/simple64"

export PATH="\$HERE/simple64-${P_VERSION}":\$PATH
"\$MAIN" "\$@" | cat
EOF
chmod +x AppRun

cp AppRun $WORKDIR
cp resource/* $WORKDIR

./appimagetool.AppImage --appimage-extract

export ARCH=x86_64; squashfs-root/AppRun -v $WORKDIR -u 'gh-releases-zsync|ferion11|${P_NAME}_Appimage|continuous|${P_NAME}-v${P_VERSION}-*arch*.AppImage.zsync' ${P_NAME}-v${P_VERSION}-${ARCH}.AppImage

rm -rf appimagetool.AppImage

echo "All files at the end of script: $(ls)"
