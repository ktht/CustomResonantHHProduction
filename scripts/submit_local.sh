#!/bin/bash

#TODO finish the script

# Usage: submit_crab.sh [prod|test] [2016|2017|2018] [0|2] [sl|dl] mass
# [prod|test] -- for full production or testing
# [2016|2017|2018] -- era
# [0|2] -- spin
# [sl|dl] -- decay mode
# mass -- resonant mass point
#
# In case you want to run on a different queue, use SBATCH_QUEUE env variable

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


