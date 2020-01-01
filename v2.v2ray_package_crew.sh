#!/bin/sh
#
#
#
#

BIN_PATH=$(dirname $(readlink -f $0))

USER=dx0eu
REPO=v2rew

V2RAY_VERSION=$(curl -sL https://github.com/v2ray/v2ray-core/releases/latest | pup '.release-header:first-child .f1 a text{}')
_V2REW_VERSION=$(curl -sL https://github.com/$USER/$REPO/releases/latest | pup '.release-header:first-child .f1 a text{}')


_DIST_PREFIX=https://github.com/v2ray/v2ray-core/releases/download
DIST_ARCH_32=$_DIST_PREFIX/$V2RAY_VERSION/v2ray-linux-32.zip
DIST_ARCH_64=$_DIST_PREFIX/$V2RAY_VERSION/v2ray-linux-64.zip
DIST_ARCH_ARM=$_DIST_PREFIX/$V2RAY_VERSION/v2ray-linux-arm.zip
# DIST_ARCH_ARM64=$_DIST_PREFIX/$V2RAY_VERSION/v2ray-linux-arm64.zip


OK_SH="sh -f $BIN_PATH/ok.sh"


build_pkg_crew() {
  URL=$1
  ARCH=$2
  CK_VAR=$3

  V2RAY_PKG=$BIN_PATH/v2ray.$ARCH.zip
  V2RAY_SIG=$V2RAY_PKG.sha256.txt

  curl -sL -o $V2RAY_PKG $URL

  echo $(sha256sum $V2RAY_PKG | head -c 64) > $V2RAY_SIG
}

pkg_sig() {
  echo $(cat $BIN_PATH/v2ray.$1.zip.sha256.txt)
}

rb_tpl() {
  V2RAY_RB=$(cat $BIN_PATH/v2.v2ray.tpl.rb)
  CT=$(echo "$V2RAY_RB" | sed -e "s/{{VERSION}}/${V2RAY_VERSION}/g")
  CT=$(echo "$CT" | sed -e "s/{{SHA256_ARMV7L}}/$(pkg_sig armv7l)/g")
  CT=$(echo "$CT" | sed -e "s/{{SHA256_I686}}/$(pkg_sig i686)/g")
  CT=$(echo "$CT" | sed -e "s/{{SHA256_X86_64}}/$(pkg_sig x86_64)/g")

  echo "$CT" > $BIN_PATH/v2ray.final.rb
}

chromebrew() {
  cd /tmp
  git clone git@github.com:dx0eu/chromebrew.git
  cd chromebrew

#  git remote add skyc https://github.com/skycocker/chromebrew.git
#  git fetch skyc
#  git pull skyc master

  git checkout -b update-v2ray-package

  cp $BIN_PATH/v2ray.final.rb packages/v2ray.rb

  git add .
  git commit -m "Update v2ray to $V2RAY_VERSION"
  git push origin update-v2ray-package
#  git push origin master

  $OK_SH create_pull_request \
    skycocker/chromebrew \
    "Update v2ray to $V2RAY_VERSION" \
    dx0eu:update-v2ray-package \
    master \
    body="A platform for building proxies to bypass network restrictions. https://www.v2ray.com/ github repo https://github.com/v2ray/v2ray-core"

  cd $BIN_PATH
}

release() {
  $OK_SH create_release $USER $REPO $V2RAY_VERSION
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

  rb_tpl

  chromebrew

  release
}

main
