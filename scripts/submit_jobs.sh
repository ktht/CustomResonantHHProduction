#!/bin/bash

# Usage: submit_jobs.sh [prod|test] [2016|2017|2018] [0|2] [sl|dl] mass
# [prod|test] -- for full production or testing
# [2016|2017|2018] -- era
# [0|2] -- spin
# [sl|dl] -- decay mode
# mass -- resonant mass point
#
# In case you want to dryrun first, define env variable DRYRUN

MODE=$1;
export ERA=$2;
export SPIN=$3;
export DECAY_MODE=$4;
export MASS=$5;
export VERSION=$6;

echo "Received the following parameters:"
echo "  mode       = $MODE";
echo "  era        = $ERA";
echo "  spin       = $SPIN";
echo "  decay mode = $DECAY_MODE";
echo "  mass point = $MASS";
echo "  version    = $VERSION";

if [ "$MODE" == "prod" ]; then
  export NEVENTS_PER_JOB=250;
  if [ $MASS -lt 300 ]; then
    export NEVENTS=400000;
  elif [ $MASS -lt 600 ]; then
    export NEVENTS=300000;
  elif [ $MASS -lt 1000 ]; then
    export NEVENTS=200000;
  else
    echo "Invalid mass point: $MASS";
    exit 1;
  fi
  export PUBLISH=true;
elif [ "$MODE" == "test" ]; then
  export NEVENTS_PER_JOB=10;
  export NEVENTS=100;
  export PUBLISH=false;
else
  echo "Invalid mode: $MODE";
  exit 1;
fi

echo "Checking if crab is available ..."
CRAB_AVAILABLE=$(which crab 2>/dev/null)
if [ -z "$CRAB_AVAILABLE" ]; then
  echo "crab not available! please do: source /cvmfs/cms.cern.ch/crab3/crab.sh"
  exit 1;
fi

echo "Checking if VOMS is available ..."
VOMS_PROXY_AVAILABLE=$(which voms-proxy-info 2>/dev/null)
if [ -z "$VOMS_PROXY_AVAILABLE" ]; then
  echo "VOMS proxy not available! please do: source /cvmfs/grid.cern.ch/glite/etc/profile.d/setup-ui-example.sh";
  exit 1;
fi

echo "Checking if VOMS is open long enough ..."
MIN_HOURSLEFT=160
MIN_TIMELEFT=$((3600 * $MIN_HOURSLEFT))
VOMS_PROXY_TIMELEFT=$(voms-proxy-info --timeleft)
if [ "$VOMS_PROXY_TIMELEFT" -lt "$MIN_TIMELEFT" ]; then
  echo "Less than $MIN_HOURSLEFT hours left for the proxy to be open: $VOMS_PROXY_TIMELEFT seconds";
  echo "Please update your proxy: voms-proxy-init -voms cms -valid 192:00";
  exit 1;
fi

echo "Checking crab user name ...";
CRAB_USERNAME=$(crab checkusername | grep "^Username" | awk '{print $NF}');
echo "Crab user name is: $CRAB_USERNAME";

CRAB_CFG=$CMSSW_BASE/src/Configuration/CustomResonantHHProduction/test/crab_cfg.py
if [ ! -z "$DRYRUN" ]; then
  DRYRUN="--dryrun";
fi

NOF_JOBS=$(( $NEVENTS / $NEVENTS_PER_JOB ));
if [ $(( $NOF_JOBS * $NEVENTS_PER_JOB )) -lt  $NOF_JOBS ]; then
  $NOF_JOBS+=1;
fi
echo "Submitting jobs with the following parameters:"
echo "Number of events:         $NEVENTS";
echo "Number of events per job: $NEVENTS_PER_JOB";
echo "Number of jobs:           $NOF_JOBS";
echo -ne "Dryrun:                   ";
if [ -z "$DRYRUN" ]; then echo "no"; else echo "yes"; fi

read -p "Submitting jobs? [y/N]" -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
  [[ "$0" = "$BASH_SOURCE" ]] && exit 1 || return 1
fi

crab submit $DRYRUN --config="$CRAB_CFG"
