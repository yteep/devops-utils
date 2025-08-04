#!/bin/bash
set -x

echo "The app build is starting !!!"

HOMEDIR=/opt/emp-manage
REPO=emp-manage-backend
GITDIR=$HOMEDIR/repos/$REPO
ENVDIR=$HOMEDIR/env

BINDIR=emp_binaries
KEYDIR=$HOMEDIR/.keys
CONFIGDIR=$HOMEDIR/configs
BRANCH="svc-test"
SRCKEY="emp-manage-backend-key"

ls -al $HOMEDIR/$BINDIR/
$HOMEDIR/$BINDIR/clone-repos

git_pull() {
  KEY=$KEYDIR/$SRCKEY
  eval "$(ssh-agent -s)"
  ssh-add $KEY
  cd $GITDIR
  git stash
  git pull origin $BRANCH
}

build_emp_manage_backend() {
  git_pull

  APP=emp-manage-backend
  APPDIR=/opt/emp-manage/apps/$APP
  VENV=/opt/emp-manage/env/$APP
  APPCONFIG=config.ini
  CONFIG=$CONFIGDIR/$APP/$APPCONFIG
  
  mkdir -p "$APPDIR"
  cp -r $GITDIR/* $APPDIR

   # Create venv if not exists
  if [ ! -d "$VENV" ]; then
    echo "Creating virtual environment at $VENV..."
    python3 -m venv "$VENV"
  fi

  # Activate venv
  source "$VENV/bin/activate"

  pip install --upgrade pip
  
  # Check if gunicorn is installed; install if missing
  if ! python -m pip show gunicorn > /dev/null 2>&1; then
       echo "gunicorn not found, installing..."
       pip install gunicorn
  else
     echo "gunicorn already installed."
  fi

  # Install dependencies
  REQ="$APPDIR/requirements.txt"
  if [ -f "$REQ" ]; then
    echo "Installing requirements from $REQ..."
    #pip install --upgrade pip
    pip install -r "$REQ"
  fi

  cp $CONFIG $APPDIR/app/config/
 
  sudo systemctl restart $APP.service
  sudo systemctl status $APP.service
}

build_emp_manage_backend

