#!/bin/bash

set -e

SCRIPT_DIR=$(dirname "$0")
SCRIPT_NAME=$(basename "$0")
PREFIX="[${SCRIPT_NAME}]"

# dependencies
$SCRIPT_DIR/debase-build.sh
$SCRIPT_DIR/fetch-node.sh

source $SCRIPT_DIR/main.env

if [ -f $WINAS_ENV ]; then
  source $WINAS_ENV
  echo $PREFIX "checking latest winas version..."
  SHA=$(curl -s https://api.github.com/repos/aidingnan/winas/commits/master | jq '.sha')
  if [[ ! "$SHA" =~ ^\"[a-f0-9]{40}\"$ ]]; then
    echo "winas, bad sha: $SHA"
    exit 1
  fi

  SHA=${SHA:1:40}
  if [ "$WINAS_SHA" == "$SHA" ] && [ -f $CACHE/$WINAS_TAR ]; then
    echo $PREFIX "$WINAS_TAR is up-to-date"
  else
    echo $PREFIX "new version found, prepare to build winas"
    BUILD_WINAS=true 
  fi
else
  echo $PREFIX "$WINAS_ENV not found, prepare to build winas"
  BUILD_WINAS=true
fi

if [ -f $WINASD_ENV ]; then
  source $WINASD_ENV
  echo $PREFIX "checking latest winasd version..."
  SHA=$(curl -s https://api.github.com/repos/aidingnan/winasd/commits/master | jq '.sha')
  if [[ ! "$SHA" =~ ^\"[a-f0-9]{40}\"$ ]]; then
    echo $PREFIX "winasd, bad sha: $SHA"
    exit 1
  fi

  SHA=${SHA:1:40}
  if [ "$WINASD_SHA" == "$SHA" ] && [ -f $CACHE/$WINASD_TAR ]; then
    echo "$WINASD_TAR is up-to-date"
  else
    echo "new version found, prepare to build winasd"
    BUILD_WINASD=true 
  fi
else
  echo "$WINASD_ENV not found, prepare to build winasd"
  BUILD_WINASD=true
fi

if [ $BULD_WINAS ] || [ $BUILD_WINASD ]; then
  ROOT=$TMP/build-apps-root
  rm -rf $ROOT
  mkdir -p $ROOT

  tar xf $CACHE/$DEBASE_BUILD_TAR -C $ROOT
  # cp -av /usr/bin/qemu-aarch64-static $ROOT/usr/bin
  tar xf $CACHE/$NODE_TAR -C $ROOT/usr --strip-components=1
  # chroot $ROOT npm install -g npm
  chroot $ROOT npm config set unsafe-perm true
fi

if [ $BUILD_WINAS ]; then
  git clone https://github.com/aidingnan/winas $ROOT/winas
  WINAS_SHA=$(GIT_DIR=$ROOT/winas/.git git rev-parse HEAD)
  WINAS_TAR=winas-master-${WINAS_SHA:0:7}.tar.gz
  echo $WINAS_SHA > $ROOT/winas/.sha
  rm -rf $ROOT/winas/.git
  chroot $ROOT bash -c "cd /winas; PYTHON=/usr/bin/python2.7 npm i"
  tar czf $CACHE/$WINAS_TAR -C $ROOT/winas .

cat > $WINAS_ENV << EOF
WINAS_SHA=$WINAS_SHA
WINAS_TAR=$WINAS_TAR
EOF

fi

if [ $BUILD_WINASD ]; then
  git clone https://github.com/aidingnan/winasd $ROOT/winasd
  WINASD_SHA=$(GIT_DIR=$ROOT/winasd/.git git rev-parse HEAD)
  WINASD_TAR=winasd-master-${WINASD_SHA:0:7}.tar.gz
  echo $WINASD_SHA > $ROOT/winasd/.sha
  rm -rf $ROOT/winasd/.git
  chroot $ROOT bash -c "cd winasd; PYTHON=/usr/bin/python2.7 npm i"
  tar czf $CACHE/$WINASD_TAR -C $ROOT/winasd .

cat > $WINASD_ENV << EOF
WINASD_SHA=$WINASD_SHA
WINASD_TAR=$WINASD_TAR
EOF

fi
