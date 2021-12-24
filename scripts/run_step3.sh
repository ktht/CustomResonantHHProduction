#!/bin/bash

# Usage: run_step3.sh [2016|2017|2018] $CMSSW_BASE step2 step3

set -x;

era=$1;
cmssw_host=$2;
previous_step=$3;
current_step=$4;

CWD=$PWD;

if [ "$era" == "2016" ]; then
  GLOBAL_TAG="102X_mcRun2_asymptotic_v8";
  ERA="Run2_2016,run2_nanoAOD_94X2016";
elif [ "$era" == "2016" ]; then
  GLOBAL_TAG="102X_mc2017_realistic_v8";
  ERA="Run2_2017,run2_nanoAOD_94XMiniAODv2";
elif [ "$era" == "2016" ]; then
  GLOBAL_TAG="102X_upgrade2018_realistic_v21";
  ERA="Run2_2018,run2_nanoAOD_102Xv1";
else
  echo "Invalid era: $era";
  exit 1;
fi;

if [ ! -d $cmssw_host ]; then
  echo "No such directory: $cmssw_host";
  exit 1;
fi;

source /cvmfs/cms.cern.ch/cmsset_default.sh;
cd $cmssw_host/src;
eval `scram runtime -sh`; # cmsenv

cd $CWD;

fwFile="FrameworkJobReport.xml";
pset="${current_step}.py";
inputFile="${previous_step}.root";
outputFile="${current_step}.root";

if [ ! -f $inputFile ]; then
  echo "No such file: $inputFile";
  exit 1;
fi;

cmsDriver.py \
  --python_filename $pset \
  --eventcontent NANOAODSIM \
  --customise Configuration/DataProcessing/Utils.addMonitoring \
  --datatier NANOAODSIM \
  --fileout "file:$outputFile" \
  --conditions $GLOBAL_TAG \
  --step NANO \
  --filein "file:$inputFile" \
  --era $ERA \
  --no_exec \
  --mc \
  -n -1

/usr/bin/time --verbose cmsRun -j $fwFile $pset;
exit_code=$?;

if [[ $exit_code -ne 0 ]]; then
  exit $exit_code;
fi;
