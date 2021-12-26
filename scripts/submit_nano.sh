#!/bin/bash

# Usage: submit_nano.sh [prod|test] [2016|2017|2018] [0|2] [sl|dl] mass [yes|no]
# [prod|test] -- for full production or testing
# [2016|2017|2018] -- era
# [0|2] -- spin
# [sl|dl] -- decay mode
# mass -- resonant mass point
# [yes|no] -- run NanoAOD step
#
# In case you want to dryrun first, define env variable DRYRUN
# In case you want to switch SLURM partitions, set SBATCH_QUEUE env variable

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

KEY="${ERA}_spin${SPIN}_${MASS}_${DECAY_MODE}";

declare -A INPUTS;
INPUTS["2016_spin0_250_dl"]="v0/GluGluToRadionToHHTo2B2VTo2L2Nu_M-250_narrow_13TeV-madgraph-pythia8/2021Dec25_GluGluToRadionToHHTo2B2VTo2L2Nu_M-250_narrow_13TeV-madgraph-pythia8_v0/211225_020357";
INPUTS["2016_spin0_280_dl"]="v0/GluGluToRadionToHHTo2B2VTo2L2Nu_M-280_narrow_13TeV-madgraph-pythia8/2021Dec25_GluGluToRadionToHHTo2B2VTo2L2Nu_M-280_narrow_13TeV-madgraph-pythia8_v0/211225_020504";
INPUTS["2016_spin0_320_dl"]="v0/GluGluToRadionToHHTo2B2VTo2L2Nu_M-320_narrow_13TeV-madgraph-pythia8/2021Dec25_GluGluToRadionToHHTo2B2VTo2L2Nu_M-320_narrow_13TeV-madgraph-pythia8_v0/211225_020540";
INPUTS["2016_spin0_280_sl"]="v0/GluGluToRadionToHHTo2B2WToLNu2J_M-280_narrow_13TeV-madgraph-pythia8/2021Dec25_GluGluToRadionToHHTo2B2WToLNu2J_M-280_narrow_13TeV-madgraph-pythia8_v0/211225_020019";
INPUTS["2016_spin0_320_sl"]="v0/GluGluToRadionToHHTo2B2WToLNu2J_M-320_narrow_13TeV-madgraph-pythia8/2021Dec25_GluGluToRadionToHHTo2B2WToLNu2J_M-320_narrow_13TeV-madgraph-pythia8_v0/211225_020324";
INPUTS["2016_spin2_280_sl"]="v0/GluGluToBulkGravitonToHHTo2B2WToLNu2J_M-280_narrow_13TeV-madgraph-pythia8/2021Dec25_GluGluToBulkGravitonToHHTo2B2WToLNu2J_M-280_narrow_13TeV-madgraph-pythia8_v0/211225_124141";
INPUTS["2016_spin2_320_sl"]="v0/GluGluToBulkGravitonToHHTo2B2WToLNu2J_M-320_narrow_13TeV-madgraph-pythia8/2021Dec25_GluGluToBulkGravitonToHHTo2B2WToLNu2J_M-320_narrow_13TeV-madgraph-pythia8_v0/211225_124212";
INPUTS["2016_spin2_250_dl"]="v0/GluGluToBulkGravitonToHHTo2B2VTo2L2Nu_M-250_narrow_13TeV-madgraph-pythia8/2021Dec25_GluGluToBulkGravitonToHHTo2B2VTo2L2Nu_M-250_narrow_13TeV-madgraph-pythia8_v0/211225_124242";
INPUTS["2016_spin2_280_dl"]="v0/GluGluToBulkGravitonToHHTo2B2VTo2L2Nu_M-280_narrow_13TeV-madgraph-pythia8/2021Dec25_GluGluToBulkGravitonToHHTo2B2VTo2L2Nu_M-280_narrow_13TeV-madgraph-pythia8_v0/211225_124302";
INPUTS["2016_spin2_320_dl"]="v0/GluGluToBulkGravitonToHHTo2B2VTo2L2Nu_M-320_narrow_13TeV-madgraph-pythia8/2021Dec25_GluGluToBulkGravitonToHHTo2B2VTo2L2Nu_M-320_narrow_13TeV-madgraph-pythia8_v0/211225_124459";
INPUTS["2017_spin0_300_dl"]="v0/GluGluToRadionToHHTo2B2VTo2L2Nu_M-300_narrow_13TeV-madgraph-pythia8/2021Dec25_GluGluToRadionToHHTo2B2VTo2L2Nu_M-300_narrow_13TeV-madgraph-pythia8_v0/211225_124357";
INPUTS["2016_spin0_750_sl"]="v0/GluGluToRadionToHHTo2B2WToLNu2J_M-750_narrow_13TeV-madgraph-pythia8/2021Dec25_GluGluToRadionToHHTo2B2WToLNu2J_M-750_narrow_13TeV-madgraph-pythia8_v0/211225_175418";
INPUTS["2016_spin0_850_sl"]="v0/GluGluToRadionToHHTo2B2WToLNu2J_M-850_narrow_13TeV-madgraph-pythia8/2021Dec25_GluGluToRadionToHHTo2B2WToLNu2J_M-850_narrow_13TeV-madgraph-pythia8_v0/211225_180101";
INPUTS["2016_spin0_700_dl"]="v0/GluGluToRadionToHHTo2B2VTo2L2Nu_M-700_narrow_13TeV-madgraph-pythia8/2021Dec25_GluGluToRadionToHHTo2B2VTo2L2Nu_M-700_narrow_13TeV-madgraph-pythia8_v0/211225_180215";
INPUTS["2016_spin0_850_dl"]="v0/GluGluToRadionToHHTo2B2VTo2L2Nu_M-850_narrow_13TeV-madgraph-pythia8/2021Dec25_GluGluToRadionToHHTo2B2VTo2L2Nu_M-850_narrow_13TeV-madgraph-pythia8_v0/211225_180300";
INPUTS["2016_spin2_750_sl"]="v0/GluGluToBulkGravitonToHHTo2B2WToLNu2J_M-750_narrow_13TeV-madgraph-pythia8/2021Dec25_GluGluToBulkGravitonToHHTo2B2WToLNu2J_M-750_narrow_13TeV-madgraph-pythia8_v0/211225_180325";
INPUTS["2016_spin2_850_sl"]="v0/GluGluToBulkGravitonToHHTo2B2WToLNu2J_M-850_narrow_13TeV-madgraph-pythia8/2021Dec25_GluGluToBulkGravitonToHHTo2B2VTo2L2Nu_M-850_narrow_13TeV-madgraph-pythia8_v0/211225_200533";
INPUTS["2016_spin2_750_dl"]="v0/GluGluToBulkGravitonToHHTo2B2VTo2L2Nu_M-750_narrow_13TeV-madgraph-pythia8/2021Dec25_GluGluToBulkGravitonToHHTo2B2VTo2L2Nu_M-750_narrow_13TeV-madgraph-pythia8_v0/211225_200505";
INPUTS["2016_spin2_850_dl"]="v0/GluGluToBulkGravitonToHHTo2B2VTo2L2Nu_M-850_narrow_13TeV-madgraph-pythia8/2021Dec25_GluGluToBulkGravitonToHHTo2B2VTo2L2Nu_M-850_narrow_13TeV-madgraph-pythia8_v0/211225_200533";
INPUTS["2017_spin0_550_dl"]="v0/GluGluToRadionToHHTo2B2VTo2L2Nu_M-550_narrow_13TeV-madgraph-pythia8/2021Dec25_GluGluToRadionToHHTo2B2VTo2L2Nu_M-550_narrow_13TeV-madgraph-pythia8_v0/211225_200602";
INPUTS["2018_spin0_450_dl"]="";

INPUT_VAL=${INPUTS[${KEY}]};
if [ -z "$INPUT_VAL" ]; then
  echo "Invalid arguments: $ERA, $SPIN, $DECAY_MODE, $MASS";
  exit 1;
fi

export INPUT_PATH="/hdfs/cms/store/user/kaehatah/CustomResonantHHProduction/${INPUT_VAL}"
if [ ! -d $INPUT_PATH ]; then
  echo "Directory does not exist: $INPUT_PATH";
  exit 1;
fi;

if [ "$MODE" == "prod" ]; then
  NOF_MAX_FILES=-1;
  NFILES_PER_JOB=150;
elif [ "$MODE" == "test" ]; then
  NOF_MAX_FILES=10;
  NFILES_PER_JOB=2;
else
  echo "Invalid mode: $MODE";
  exit 1;
fi;
export NOF_MAX_FILES NFILES_PER_JOB;

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

CRAB_CFG=$CMSSW_BASE/src/Configuration/CustomResonantHHProduction/test/crab_cfg_nano.py
if [ ! -z "$DRYRUN" ]; then
  DRYRUN="--dryrun";
fi

export CRAB_STATUS_DIR="$HOME/crab_projects";
mkdir -pv $CRAB_STATUS_DIR;

NFILES_TOTAL=$(ls $INPUT_PATH/000*/*.root | wc -l);
if [[ $NOF_MAX_FILES -gt 0 ]] && [[ $NFILES_TOTAL -gt $NOF_MAX_FILES ]]; then
  NFILES=$NOF_MAX_FILES;
else
  NFILES=$NFILES_TOTAL;
fi;

NOF_JOBS=$(python -c "import math; print(int(math.ceil(float($NFILES) / $NFILES_PER_JOB)))");
echo "Submitting jobs with the following parameters:"
echo "Number of files in total: $NFILES_TOTAL"
echo "Number of files:          $NFILES";
echo "Number of files per job:  $NFILES_PER_JOB";
echo "Number of jobs:           $NOF_JOBS";
echo -ne "Dryrun:                   ";
if [ -z "$DRYRUN" ]; then echo "no"; else echo "yes"; fi

read -p "Submitting jobs? [y/N]" -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
  [[ "$0" = "$BASH_SOURCE" ]] && exit 1 || return 1
fi

crab submit $DRYRUN --config="$CRAB_CFG"
