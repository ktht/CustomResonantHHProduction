#!/bin/bash

#TODO create the list of PU files before

set -x

era=$1;
cmssw_host=$(realpath -e $8);
previous_step=$2;
current_step=$3;

CWD=$PWD;
echo "Current working directory is: $CWD";
echo "Home is: $HOME";
echo "Host CMSSW: $cmssw_host";

# determine runtime options
if [ "$era" == "2016" ]; then
  SCRAM_ARCH="slc6_amd64_gcc530";
  CMSSW_RELEASE="CMSSW_8_0_21";
  GLOBAL_TAG="80X_mcRun2_asymptotic_2016_TrancheIV_v6";
  ERA="Run2_2016";
  STEP_PMX="@frozen2016";
  STEP_AOD="RAW2DIGI,RECO,EI";
  PILEUP="/Neutrino_E-10_gun/RunIISpring15PrePremix-PUMoriond17_80X_mcRun2_asymptotic_2016_TrancheIV_v2-v2/GEN-SIM-DIGI-RAW";
  EXTRA_ARGS_PMX="";
  EXTRA_ARGS_AOD="";
elif [ "$era" == "2017" ]; then
  SCRAM_ARCH="slc6_amd64_gcc630";
  CMSSW_RELEASE="CMSSW_9_4_7";
  GLOBAL_TAG="94X_mc2017_realistic_v11";
  ERA="Run2_2017";
  STEP_PMX="2e34v40";
  STEP_AOD="RAW2DIGI,RECO,RECOSIM,EI";
  PILEUP="/Neutrino_E-10_gun/RunIISummer17PrePremix-MCv2_correctPU_94X_mc2017_realistic_v9-v1/GEN-SIM-DIGI-RAW";
  EXTRA_ARGS_PMX="";
  EXTRA_ARGS_AOD="";
elif [ "$era" == "2018" ]; then
  SCRAM_ARCH="slc6_amd64_gcc700";
  CMSSW_RELEASE="CMSSW_10_2_5";
  GLOBAL_TAG="102X_upgrade2018_realistic_v15";
  ERA="Run2_2018";
  STEP_PMX="@relval2018";
  STEP_AOD="RAW2DIGI,L1Reco,RECO,RECOSIM,EI";
  PILEUP="/Neutrino_E-10_gun/RunIISummer17PrePremix-PUAutumn18_102X_upgrade2018_realistic_v15-v1/GEN-SIM-DIGI-RAW";
  EXTRA_ARGS_PMX="--procModifiers premix_stage2 --geometry DB:Extended";
  EXTRA_ARGS_AOD="--procModifiers premix_stage2";
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

# prepare customization
CUSTOMIZATION_NAME="customize.py";

REPO_DIR="Configuration/CustomResonantHHProduction";
PYTHON_TARGET_DIR="${REPO_DIR}/python";

CUSTOMIZATION_LOCATION="$cmssw_host/src/$PYTHON_TARGET_DIR/$CUSTOMIZATION_NAME";

mkdir -pv $PYTHON_TARGET_DIR;
cp -v $CUSTOMIZATION_LOCATION $PYTHON_TARGET_DIR;

scram b;

CUSTOMIZATION_MODULE=$(echo "$REPO_DIR" | tr '/' '.');
CUSTOMIZATION="from ${CUSTOMIZATION_MODULE}.${CUSTOMIZATION_NAME%%.*} import debug"

# define the remaining invariant
tmpStep="${current_step}.tmp";
psetTmp="${tmpStep}.py";
dumpFileTmp="${tmpStep}.log";
fileInTmp="$CWD/${previous_step}.root";
if [ ! -f $fileInTmp ]; then
  echo "No such file: $fileInTmp";
  exit 1;
fi;
fileOutTmp="${tmpStep}.root";
fwFileTmp="FrameworkJobReport.${tmpStep}.xml";

CMSDRIVER_OPTS_COMMON="";
CMSDRIVER_OPTS_COMMON+=" --conditions $GLOBAL_TAG";
CMSDRIVER_OPTS_COMMON+="  --era $ERA";
CMSDRIVER_OPTS_COMMON+=" --no_exec";
CMSDRIVER_OPTS_COMMON+=" --mc";
CMSDRIVER_OPTS_COMMON+=" -n -1";

if [ ! -z "$EXTRA_CUSTOMS" ]; then
  CMSDRIVER_OPTS_COMMON+=" --customise $EXTRA_CUSTOMS";
fi;

CMSDRIVER_OPTS_PMX=$CMSDRIVER_OPTS_COMMON;
CMSDRIVER_OPTS_PMX+=" --python_filename $psetTmp";
CMSDRIVER_OPTS_PMX+=" --eventcontent PREMIXRAW";
CMSDRIVER_OPTS_PMX+=" --datatier GEN-SIM-RAW";
CMSDRIVER_OPTS_PMX+=" --filein file:$fileInTmp";
CMSDRIVER_OPTS_PMX+=" --fileout file:$fileOutTmp";
CMSDRIVER_OPTS_PMX+=" --pileup_input dbs:$pileup";
CMSDRIVER_OPTS_PMX+=" --step DIGIPREMIX_S2,DATAMIX,L1,DIGI2RAW,HLT:$STEP_PMX";
CMSDRIVER_OPTS_PMX+="  --datamix PreMix";
CMSDRIVER_OPTS_PMX+=" --customise_commands \"$CUSTOMIZATION;process=debug(process,'$dumpFileTmp');\"";

if [ ! -z "$EXTRA_ARGS_PMX" ]; then
  CMSDRIVER_OPTS_PMX+=" $EXTRA_ARGS_PMX";
fi

# generate the cfg file
cmsDriver.py $CMSDRIVER_OPTS_PMX;

# dump the parameter sets
python $pset;
if [ -f $dumpFile ]; then
  cat $dumpFile;
else
  echo "File $dumpFile does not exist!";
fi;

# run the job
/usr/bin/time --verbose cmsRun -j $fwFileTmp $psetTmp;

# show the contents of cwd
ls -lh;

if [ ! -f $fileOutTmp ]; then
  echo "No such file: $fileOutTmp";
  exit 1;
fi;
mv -v $fwFileTmp $CWD;

# define the remaining invariant
psetFinal="${current_step}.py";
dumpFileFinal="${current_step}.log";
fileOut="${current_step}.root";
fwFile="FrameworkJobReport.${current_step}.xml";

CMSDRIVER_OPTS_AOD=$CMSDRIVER_OPTS_COMMON;
CMSDRIVER_OPTS_AOD+=" --python_filename $pset";
CMSDRIVER_OPTS_AOD+=" --eventcontent AODSIM";
CMSDRIVER_OPTS_AOD+=" --datatier AODSIM";
CMSDRIVER_OPTS_AOD+=" --filein file:$fileOutTmp";
CMSDRIVER_OPTS_AOD+=" --fileout file:$fileOut";
CMSDRIVER_OPTS_AOD+=" --step $STEP_AOD";
CMSDRIVER_OPTS_AOD+=" --runUnscheduled";
CMSDRIVER_OPTS_AOD+=" --customise_commands \"$CUSTOMIZATION;process=debug(process,'$dumpFileFinal');\"";

if [ ! -z "$EXTRA_ARGS_AOD" ]; then
  CMSDRIVER_OPTS_AOD+=" $EXTRA_ARGS_AOD";
fi;

# dump the parameter sets
python $psetFinal;
if [ -f $dumpFileFinal ]; then
  cat $dumpFileFinal;
else
  echo "File $dumpFileFinal does not exist!";
fi;

# run the job
/usr/bin/time --verbose cmsRun -j $fwFile $psetFinal;

# show the contents of cwd
ls -lh;

mv -v $fileOut $CWD;
mv -v $fwFile $CWD;
