#!/bin/bash

set -e

SCRIPT_DIR=$(dirname "$0")

# dependencies
$SCRIPT_DIR/debase-build.sh
$SCRIPT_DIR/fetch-node.sh

source $SCRIPT_DIR/main.env

if [ -f $SCRIPT_DIR/$WINAS_ENV ]; then
  source $SCRIPT_DIR/$WINAS_ENV

  SHA=$(curl -s https://api.github.com/repos/aidingnan/winas/commits/master | jq '.sha')
  if [[ ! "$SHA" =~ ^\"[a-f0-9]{40}\"$ ]]; then
    echo "winas, bad sha: $SHA"
    exit 1
  fi

  SHA=${SHA:1:40}
  if [ "$WINAS_REV" == "$SHA" ] && [ -f "$WINAS_TAR" ]; then :; else
    BUILD_WINAS=true 
  fi
else
  BUILD_WINAS=true
fi

if [ -f $SCRIPT_DIR/$WINASD_ENV ]; then
  source $SCRIPT_DIR/$WINASD_ENV

  SHA=$(curl -s https://api.github.com/repos/aidingnan/winasd/commits/master | jq '.sha')
  if [[ ! "$SHA" =~ ^\"[a-f0-9]{40}\"$ ]]; then
    echo "winasd, bad sha: $SHA"
    exit 1
  fi

  SHA=${SHA:1:40}
  if [ "$WINASD_SHA" == "$SHA" ] && [ -f "$WINASD_TAR" ]; then :; else
    BUILD_WINASD=true 
  fi
else
  BUILD_WINASD=true
fi

if [ $BULD_WINAS ] || [ $BUILD_WINASD ]; then
  ROOT=$PWD/tmp/node-root
  rm -rf $ROOT
  mkdir -p $ROOT

  tar xf $CACHE/$DEBASE_BUILD -C $ROOT
  tar xf $CACHE/$NODE_TAR -C $ROOT/usr --strip-components=1
  chroot $ROOT npm config set unsafe-perm true
fi

if [ $BUILD_WINAS ]; then
  git clone https://github.com/aidingnan/winas $ROOT/winas
  WINAS_SHA=$(GIT_DIR=$ROOT/winas/.git git rev-parse HEAD)
  WINAS_TAR=winas-master-${WINAS_SHA:0:7}.tar.gz
  echo $WINAS_SHA > $ROOT/winas/.sha
  rm -rf $ROOT/winas/.git
  chroot $ROOT bash -c "cd /winas; PYTHON=/usr/bin/python2.7 npm i"
  tar czf $CACHE/$WINAS_TAR .

cat > $WINAS_ENV << EOF
WINAS_SHA=$WINAS_SHA
WINAS_TAR=$WINAS_TAR
EOF

fi

if [ $BUILD_WINASD ]; then
  git clone https://github.com/aidingnan/winasd $ROOT/winasd
  WINASD_SHA=$(GIT_DIR=$ROOT/winasd/.git git rev-parse HEAD)
  WINASD_TAR=winasd-master-${WINASD_SHA:0:7}.tar.gz
  echo $WINASD_SHA > .sha
  rm -rf $ROOT/winasd/.git
  chroot $ROOT bash -c "cd winasd; PYTHON=/usr/bin/python2.7 npm i"
  tar czf $CACHE/$WINASD_TAR .

cat > $WINASD_ENV << EOF
WINASD_SHA=$WINASD_SHA
WINASD_TAR=$WINASD_TAR
EOF

fi
