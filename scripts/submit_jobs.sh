#!/bin/bash

# Usage: submit_jobs.sh [crab|slurm] [prod|test] [2016|2017|2018] [0|2] [sl|dl] mass [yes|no]
# [crab|slurm] -- submit to the grid or to local cluster
# [prod|test] -- for full production or testing
# [2016|2017|2018] -- era
# [0|2] -- spin
# [sl|dl] -- decay mode
# mass -- resonant mass point
# [yes|no] -- run NanoAOD step
#
# In case you want to dryrun first, define env variable DRYRUN
# In case you want to switch SLURM partitions, set SBATCH_QUEUE env variable

METHOD=$1;
MODE=$2;
export ERA=$3;
export SPIN=$4;
export DECAY_MODE=$5;
export MASS=$6;
export VERSION=$7;
export RUN_NANO=$8;

if [ -z "$RUN_NANO" ]; then
  export RUN_NANO="no";
fi;

echo "Received the following parameters:"
echo "  submit to  = $METHOD";
echo "  mode       = $MODE";
echo "  era        = $ERA";
echo "  spin       = $SPIN";
echo "  decay mode = $DECAY_MODE";
echo "  mass point = $MASS";
echo "  version    = $VERSION";
echo "  run nano?  = $RUN_NANO";
echo "  "

if [ "$MODE" == "crab" ]; then
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

if [ "$METHOD" == "crab" ]; then
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

  CRAB_CFG=$CMSSW_BASE/src/Configuration/CustomResonantHHProduction/test/crab_cfg.py
  if [ ! -z "$DRYRUN" ]; then
    DRYRUN="--dryrun";
  fi
elif [ "$METHOD" == "slurm" ]; then
  if [ -z "$SBATCH_QUEUE" ]; then
    SBATCH_QUEUE=main;
  fi
else
  echo "Invalid submission method: $METHOD";
  exit 1;
fi;

NOF_JOBS=$(python -c "import math; print(int(math.ceil(float($NEVENTS) / $NEVENTS_PER_JOB)))");
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

if [ "$METHOD" == "crab" ]; then
  crab submit $DRYRUN --config="$CRAB_CFG"
elif [ "$METHOD" == "slurm" ]; then
  PYCMD="from Configuration.CustomResonantHHProduction.aux import get_dataset_name;"
  PYCMD+="get_dataset_name($ERA,$SPIN,'${DECAY_MODE}',$MASS)";
  DATASET=$(python -c "$PYCMD");

  DIR_SUFFIX="$USER/CustomResonantHHProduction/$VERSION/$DATASET"
  LOG_DIR="/home/$DIR_SUFFIX";
  OUTPUT_DIR="/hdfs/local/$DIR_SUFFIX";
  mkdir -pv $OUTPUT_DIR;
  if [ "$MODE" == "test" ]; then
    CLEANUP="false";
  else
    CLEANUP="true";
  fi;

  for i in `seq 1 $NOF_JOBS`; do
    sbatch --partition=$SBATCH_QUEUE --output=$LOG_DIR/out_$i.log --mem=2500M \
      job_wrapper.sh $i $NEVENTS_PER_JOB $NEVENTS $ERA $SPIN $MASS \
                        $DECAY_MODE $CLEANUP $OUTPUT_DIR $RUN_NANO;
  done
else
  # should never happen
  echo "Invalid submission method: $METHOD";
fi
