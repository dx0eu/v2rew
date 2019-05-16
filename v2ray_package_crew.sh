#!/bin/sh


BIN_PATH=$(dirname $(readlink -f $0))

USER=dx0eu
REPO=v2rew

V2RAY_VERSION=$(curl -sL https://github.com/v2ray/v2ray-core/releases/latest | pup '.release-header:first-child .f1 a text{}')
_V2REW_VERSION=$(curl -sL https://github.com/$USER/$REPO/releases/latest | pup '.release-header:first-child .f1 a text{}')

_DIST_PREFIX=https://github.com/v2ray/v2ray-core/releases/download
DIST_ARCH_32=$_DIST_PREFIX/$V2RAY_VERSION/v2ray-linux-32.zip
DIST_ARCH_64=$_DIST_PREFIX/$V2RAY_VERSION/v2ray-linux-64.zip
DIST_ARCH_ARM=$_DIST_PREFIX/$V2RAY_VERSION/v2ray-linux-arm.zip
DIST_ARCH_ARM64=$_DIST_PREFIX/$V2RAY_VERSION/v2ray-linux-arm64.zip
DIST_SRC=https://github.com/v2ray/v2ray-core/archive/$V2RAY_VERSION.zip

OK_SH="sh -f $BIN_PATH/ok.sh"



build_pkg_crew() {
  URL=$1
  ARCH=$2


  echo 'Download v2ray -> '$URL
  curl -sL -o v2ray.zip $URL

  mkdir -p usr/local/share/v2ray
  mkdir -p usr/local/bin

  echo 'Unzip origin package'
  unzip v2ray.zip -d usr/local/share/v2ray

  ln -s /usr/local/share/v2ray/v2ray usr/local/bin/
  ln -s /usr/local/share/v2ray/v2ctl usr/local/bin/
  chmod +x usr/local/share/v2ray
  chmod +x usr/local/share/v2ctl

  echo 'Generate dlist'
  gen_filelist

  echo 'Generate filelist'
  gen_dirlist


  TAR_XZ=$BIN_PATH/v2ray-chromeos-$ARCH.tar.xz
  TAR_SIG=$TAR_XZ.sha256.txt

  echo 'Create v2ray crew package -> '$TAR_XZ
  tar -cvf $TAR_XZ usr dlist filelist
  echo $(sha256sum $TAR_XZ | head -c 64) > $TAR_SIG


  echo 'Create v2ray crew package complete. -> '$ARCH
  # cd ..
  # mkdir 

  viewpkg $TAR_XZ

  clear_build $ARCH
}


viewpkg() {
  echo '================= VIEWPKG =================='
  TMP_PATH=/tmp/v2ray
  mkdir $TMP_PATH
  tar -xvf $1 -C $TMP_PATH
  tree $TMP_PATH
  echo '===> dlist'
  echo "`cat $TMP_PATH/dlist`"
  echo '===> filelist'
  echo "`cat $TMP_PATH/filelist`"
  rm -rf $TMP_PATH
  echo '================= VIEWPKG =================='
}

clear_build() {
  ARCH=$1
  rm -rf v2ray.zip
  rm -rf tmp
  rm -rf usr
  # rm -rf v2ray-chromeos-$ARCH.tar.xz
  rm -rf dlist
  rm -rf filelist
}

gen_filelist() {
  CONTENT=`tree -ifF --noreport usr | grep -v '/$'`
  CONTENT=`echo "$CONTENT" | sed 's/usr/\/usr/g'`
  CONTENT=`echo "$CONTENT" | sed 's/ -> \/\/.*//g'`

  echo "$CONTENT" > filelist
}

gen_dirlist() {
  CONTENT=`tree -dif --noreport usr`
  CONTENT=`echo "$CONTENT" | sed 's/usr/\/usr/g' | sed '1d'`

  echo "$CONTENT" > dlist
}


release() {
#  TAG=`cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1`
  TAG=$V2RAY_VERSION

#  echo $OK_SH create_release $USER $REPO $TAG
  $OK_SH create_release $USER $REPO $TAG

  upload_assets i686 $TAG
  upload_assets x86_64 $TAG
  upload_assets armv7l $TAG
  upload_assets aarch64 $TAG

  upload_assets_source $TAG
}

upload_assets_source() {

  TAG=$1

  SRC_F=$V2RAY_VERSION.zip
  SRC_F_SIG=$SRC_F.sha256.txt

  curl -sL -o $BIN_PATH/$SRC_F $DIST_SRC
  echo $(sha256sum $SRC_F | head -c 64) > $SRC_F_SIG

  $OK_SH list_releases "$USER" "$REPO" \
    | awk -v "tag=$TAG" -F'\t' '$2 == tag { print $3 }' \
    | xargs -I@ $OK_SH release "$USER" "$REPO" @ _filter='.upload_url' \
    | sed 's/{.*$/?name='"$SRC_F"'/' \
    | xargs -I@ $OK_SH upload_asset @ "$BIN_PATH/$SRC_F" mime_type='application/x-tar'

  $OK_SH list_releases "$USER" "$REPO" \
    | awk -v "tag=$TAG" -F'\t' '$2 == tag { print $3 }' \
    | xargs -I@ $OK_SH release "$USER" "$REPO" @ _filter='.upload_url' \
    | sed 's/{.*$/?name='"$SRC_F_SIG"'/' \
    | xargs -I@ $OK_SH upload_asset @ "$BIN_PATH/$SRC_F_SIG" mime_type='text/plain'
}

upload_assets() {
  ARCH=$1
  TAG=$2
  FILE=v2ray-chromeos-$ARCH.tar.xz
  SIG=$FILE.sha256.txt

  $OK_SH list_releases "$USER" "$REPO" \
    | awk -v "tag=$TAG" -F'\t' '$2 == tag { print $3 }' \
    | xargs -I@ $OK_SH release "$USER" "$REPO" @ _filter='.upload_url' \
    | sed 's/{.*$/?name='"$FILE"'/' \
    | xargs -I@ $OK_SH upload_asset @ "$BIN_PATH/$FILE" mime_type='application/x-tar'

  $OK_SH list_releases "$USER" "$REPO" \
    | awk -v "tag=$TAG" -F'\t' '$2 == tag { print $3 }' \
    | xargs -I@ $OK_SH release "$USER" "$REPO" @ _filter='.upload_url' \
    | sed 's/{.*$/?name='"$SIG"'/' \
    | xargs -I@ $OK_SH upload_asset @ "$BIN_PATH/$SIG" mime_type='text/plain'

}

pkg_sig() {
  echo $(cat $BIN_PATH/v2ray-chromeos-$1.tar.xz.sha256.txt)
}

build_crew() {
  V2RAY_RB=$(cat $BIN_PATH/v2ray.rb)
  CT=$(echo "$V2RAY_RB" | sed -e "s/{{VERSION}}/${V2RAY_VERSION}/g")
  CT=$(echo "$CT" | sed -e "s/{{SHA256_I686}}/$(pkg_sig i686)/g")
  CT=$(echo "$CT" | sed -e "s/{{SHA256_X86_64}}/$(pkg_sig x86_64)/g")
  CT=$(echo "$CT" | sed -e "s/{{SHA256_ARMV7L}}/$(pkg_sig armv7l)/g")
  CT=$(echo "$CT" | sed -e "s/{{SHA256_AARCH64}}/$(pkg_sig aarch64)/g")

  CT=$(echo "$CT" | sed -e "s/{{SOURCE_SHA256}}/$(cat $BIN_PATH/$V2RAY_VERSION.zip.sha256.txt)/g")
  CT=$(echo "$CT" | sed -e "s/{{USER}}/${USER}/g")
  CT=$(echo "$CT" | sed -e "s/{{REPO}}/${REPO}/g")
  echo "$CT" > $BIN_PATH/v2ray.rb
  cat $BIN_PATH/v2ray.rb
}


chromebrew() {
  # cd /tmp
  # git clone https://github.com/dx0eu/chromebrew.git
  # cd chromebrew
  # cp $BIN_PATH/v2ray.rb packages/

  # RNG=`cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1`
  # echo $RNG > $RNG.txt
  # git add .
  # git commit -m "$RNG"
  # git push origin master

  cd /tmp
  git clone git@github.com:dx0eu/chromebrew.git
  cd chromebrew

  git remote add skyc https://github.com/skycocker/chromebrew.git
  git fetch skyc
  git pull skyc master

  cp $BIN_PATH/v2ray.rb packages/
  git add .
  git commit -m "v2ray $V2RAY_VERSION"
  git push origin master
  
  $OK_SH create_pull_request skycocker/chromebrew "v2ray package" dx0eu:master master body="v2ray package"

  cd $BIN_PATH
}

main() {

  if [ "$V2RAY_VERSION" = "$_V2REW_VERSION" ];
  then
    echo 'This version is already build to crew package.'
    exit 0
  fi

  curl -sL -o $BIN_PATH/ok.sh https://raw.githubusercontent.com/dx0eu/ok.sh/master/ok.sh

  build_pkg_crew $DIST_ARCH_32 i686
  build_pkg_crew $DIST_ARCH_64 x86_64
  build_pkg_crew $DIST_ARCH_ARM armv7l
  build_pkg_crew $DIST_ARCH_ARM64 aarch64
  echo '------------------------'

  ls

  release

  #  https://gist.github.com/stefanbuck/ce788fee19ab6eb0b4447a85fc99f447

  # sh -f upload-github-release-asset.sh github_api_token=92c97dbfa713f51e7683d1193701ee7a5f6d9a70 owner=dx0eu repo=citest tag=v0.0.2 filename=./aaa.txt

  build_crew

  chromebrew

}


main
