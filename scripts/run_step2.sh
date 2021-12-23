#!/bin/bash

set -x

era=$1;
cmssw_host=$2;
cleanup=$3;
previous_step=$4;
current_step=$5;

CWD=$PWD;
echo "Current working directory is: $CWD";
echo "Home is: $HOME";
echo "Host CMSSW: $cmssw_host";

if [ ! -d "$cmssw_host" ]; then
  echo "No such directory: $cmssw_host";
  exit 1;
fi

# go to a separate directory
mkdir -pv $current_step;
cd $_;

# determine runtime options
if [ "$era" == "2016" ]; then
  SCRAM_ARCH="slc6_amd64_gcc630";
  CMSSW_RELEASE="CMSSW_9_4_9";
  GLOBAL_TAG="94X_mcRun2_asymptotic_v3";
  ERA="Run2_2016,run2_miniAOD_80XLegacy	";
  EXTRA_ARGS="";
elif [ "$era" == "2017" ]; then
  SCRAM_ARCH="slc6_amd64_gcc630";
  CMSSW_RELEASE="CMSSW_9_4_7";
  GLOBAL_TAG="94X_mc2017_realistic_v14";
  ERA="Run2_2017,run2_miniAOD_94XFall17";
  EXTRA_ARGS="--scenario pp";
elif [ "$era" == "2018" ]; then
  SCRAM_ARCH="slc6_amd64_gcc700";
  CMSSW_RELEASE="CMSSW_10_2_5";
  GLOBAL_TAG="102X_upgrade2018_realistic_v15";
  ERA="Run2_2018";
  EXTRA_ARGS="--geometry DB:Extended";
else
  echo "Invalid era: $era";
  exit 1;
fi;

EXTRA_CUSTOMS="Configuration/DataProcessing/Utils.addMonitoring";

# set up CMSSW area
export SCRAM_ARCH;
source /cvmfs/cms.cern.ch/cmsset_default.sh;
if [ -r $CMSSW_RELEASE/src ] ; then
  echo "Release $CMSSW_RELEASE already exists";
else
  scram p CMSSW $CMSSW_RELEASE; # cmsrel
fi;
cd $CMSSW_RELEASE/src;
eval `scram runtime -sh`; # cmsenv
scram b;

# prepare customization
CUSTOMIZATION_NAME="customize.py";

REPO_DIR="Configuration/CustomResonantHHProduction";
PYTHON_TARGET_DIR="${REPO_DIR}/python";
CUSTOMIZATION_LOCATION="$cmssw_host/src/$PYTHON_TARGET_DIR/$CUSTOMIZATION_NAME";

mkdir -pv $PYTHON_TARGET_DIR;
cp -v $CUSTOMIZATION_LOCATION $PYTHON_TARGET_DIR;

scram b;

# define the remaining invariant
pset="${current_step}.py";
dumpFile="${current_step}.log";
fileIn="$CWD/${previous_step}.root"
if [ ! -f $fileIn ]; then
  echo "No such file: $fileIn";
  exit 1;
fi;
fileOut="${current_step}.root";
fwFile="FrameworkJobReport.${current_step}.xml";

CMSDRIVER_OPTS="$FRAGMENT_LOCATION";
CMSDRIVER_OPTS+=" --python_filename $pset";
CMSDRIVER_OPTS+=" --eventcontent MINIAODSIM";
CMSDRIVER_OPTS+=" --datatier MINIAODSIM";
CMSDRIVER_OPTS+=" --filein file:$fileIn";
CMSDRIVER_OPTS+=" --fileout file:$fileOut";
CMSDRIVER_OPTS+=" --conditions $GLOBAL_TAG";
CMSDRIVER_OPTS+=" --step PAT";
CMSDRIVER_OPTS+=" --era $ERA";
CMSDRIVER_OPTS+=" --no_exec";
CMSDRIVER_OPTS+=" --mc";
CMSDRIVER_OPTS+=" --runUnscheduled";
CMSDRIVER_OPTS+=" -n -1";

if [ ! -z "$EXTRA_CUSTOMS" ]; then
  CMSDRIVER_OPTS+=" --customise $EXTRA_CUSTOMS";
fi;
if [ ! -z "$EXTRA_ARGS" ]; then
  CMSDRIVER_OPTS+=" $EXTRA_ARGS";
fi;

CUSTOMIZATION_MODULE=$(echo "$REPO_DIR" | tr '/' '.');
CUSTOMIZATION="from ${CUSTOMIZATION_MODULE}.${CUSTOMIZATION_NAME%%.*} import debug"
CUSTOMIZATION+="$CUSTOMIZATION;process=debug(process,'$dumpFile');";

# generate the cfg file
cmsDriver.py $CMSDRIVER_OPTS --customise_commands "$CUSTOMIZATION";

# dump the parameter sets
python $pset;
if [ -f $dumpFile ]; then
  cat $dumpFile;
else
  echo "File $dumpFile does not exist!";
fi;

# run the job
/usr/bin/time --verbose cmsRun -j $fwFile $pset;

# show the contents of cwd
ls -lh;

mv -v $fileOut $CWD;
mv -v $fwFile $CWD;

cd $CWD;
if [ "$cleanup" == "true" ]; then
  rm -rfv $current_step;
fi
