#!/bin/bash

set -x

jobId=$1;
eventsPerLumi=$2;
maxEvents=$3;
era=$4;
spin=$5;
mass=$6;
decayMode=$7;
cmssw_host=$(realpath -e $8);
step_name=$9;

CWD=$PWD;
echo "Current working directory is: $CWD";
echo "Home is: $HOME";
echo "Host CMSSW: $cmssw_host";

# determine CMSSW release, arch, GT, gridpack
if [ "$era" == "2016" ]; then
  SCRAM_ARCH="slc6_amd64_gcc481";
  CMSSW_RELEASE="CMSSW_7_1_26";
  GLOBAL_TAG="MCRUN2_71_V1::All";
  ERA="";
  if [ "$spin" == "0" ]; then
    GRIDPACK="/cvmfs/cms.cern.ch/phys_generator/gridpacks/slc6_amd64_gcc481/13TeV/madgraph/V5_2.3.2.2/Radion_GF_HH/Radion_GF_HH_M${mass}_narrow/v1/Radion_GF_HH_M${mass}_narrow_tarball.tar.xz";
  elif [ "$spin" == "2" ]; then
    GRIDPACK="/cvmfs/cms.cern.ch/phys_generator/gridpacks/slc6_amd64_gcc481/13TeV/madgraph/V5_2.3.3/BulkGraviton_GF_HH_M${mass}_narrow/v1/BulkGraviton_GF_HH_M${mass}_narrow_tarball.tar.xz";
  else
    echo "Invalid spin: $spin";
    exit 1;
  fi;
  if [ "$mass" == "850" ]; then
    GRIDPACK_PREFIX="gsiftp://ganymede.hep.kbfi.ee:2811/cms/store/user/kaehatah/gridpacks";
    if [ "$spin" == "0" ]; then
      GRIDPACK="${GRIDPACK_PREFIX}/Radion_GF_HH_M${mass}_narrow_tarball.tar.xz";
    elif [ "$spin" == "2" ]; then
      GRIDPACK="${GRIDPACK_PREFIX}/BulkGraviton_GF_HH_M${mass}_narrow_tarball.tar.xz";
    else
      # should never happen
      echo "Invalid spin: $spin";
      exit 1;
  fi;
  BEAMSPOT="Realistic50ns13TeVCollision";
  EXTRA_ARGS="--magField 38T_PostLS1";
  EXTRA_CUSTOMS="SLHCUpgradeSimulations/Configuration/postLS1Customs.customisePostLS1";
elif [ "$era" == "2017" ]; then
  SCRAM_ARCH="slc6_amd64_gcc630";
  CMSSW_RELEASE="CMSSW_9_3_10";
  GLOBAL_TAG="93X_mc2017_realistic_v3";
  ERA="Run2_2017";
  if [ "$spin" == "0" ]; then
    GRIDPACK="/cvmfs/cms.cern.ch/phys_generator/gridpacks/2017/13TeV/madgraph/V5_2.4.2/Radion_hh_narrow_M${mass}/v1/Radion_hh_narrow_M${mass}_slc6_amd64_gcc481_CMSSW_7_1_30_tarball.tar.xz";
  else
    # we only need spin-0 here
    echo "Invalid spin: $spin";
    exit 1;
  fi;
  BEAMSPOT="Realistic25ns13TeVEarly2017Collision";
  EXTRA_ARGS="--geometry DB:Extended";
  EXTRA_CUSTOMS="";
elif [ "$era" == "2018" ]; then
  SCRAM_ARCH="slc6_amd64_gcc700";
  CMSSW_RELEASE="CMSSW_9_3_10";
  GLOBAL_TAG="102X_upgrade2018_realistic_v11";
  ERA="Run2_2018";
  # we're only missing one mass point in this era
  if [ "$spin" != "0" ] || [ "$mass" != "450" ]; then
    echo "Invalid spin and mass: $spin, $mass";
    exit 1;
  fi;
  GRIDPACK="/cvmfs/cms.cern.ch/phys_generator/gridpacks/2017/13TeV/madgraph/V5_2.4.2/Radion_hh_narrow_M${mass}/v1/Radion_hh_narrow_M${mass}_slc6_amd64_gcc481_CMSSW_7_1_30_tarball.tar.xz";
  BEAMSPOT="Realistic25ns13TeVEarly2018Collision";
  EXTRA_ARGS="--geometry DB:Extended";
  EXTRA_CUSTOMS="";
else
  echo "Invalid era: $era";
  exit 1;
fi;

# add keyword
if [ ! -z "$ERA" ]; then
  ERA="--era $ERA";
fi;

EXTRA_CUSTOMS+=" Configuration/DataProcessing/Utils.addMonitoring";
EXTRA_CUSTOMS=$(echo "$EXTRA_CUSTOMS" | sed 's/^ //g' | tr ' ' ',');

# compute runtime variables that ensure the uniqueness of the samples
nEvents=$eventsPerLumi;
nEvents_expected=$(( $jobId * $eventsPerLumi ));
if [ $nEvents_expected -gt $maxEvents ]; then
  nEvents=$(( $maxEvents - ( $jobId - 1 ) * $eventsPerLumi ));
fi;

# define the remaining invariant
pset="${step_name}.py";
dumpFile="${step_name}.log";
fileOut="${step_name}.root"

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

# prepare the fragment
CUSTOMIZATION_NAME="customize.py";
FRAGMENT_NAME="fragment_${decayMode}_${era}.py";

REPO_DIR="Configuration/CustomResonantHHProduction";
PYTHON_TARGET_DIR="${REPO_DIR}/python";
DATA_TARGET_DIR="${REPO_DIR}/data";

FRAGMENT_LOCATION="$cmssw_host/$PYTHON_TARGET_DIR/$FRAGMENT_NAME";
CUSTOMIZATION_LOCATION="$cmssw_host/$PYTHON_TARGET_DIR/$FRAGMENT_NAME";
DATSCRIPT_LOCATION="$cmssw_host/$DATA_TARGET_DIR/run_generic_tarball_gfal.sh";

mkdir -pv $PYTHON_TARGET_DIR;
mkdir -pv $DATA_TARGET_DIR;
cp -v $FRAGMENT_LOCATION $PYTHON_TARGET_DIR;
cp -v $CUSTOMIZATION_LOCATION $PYTHON_TARGET_DIR;
cp -v $DATSCRIPT_LOCATION $DATA_TARGET_DIR;

scram b;

CUSTOMIZATION_MODULE=$(echo "$REPO_DIR" | tr '/' '.');
CUSTOMIZATION="from ${CUSTOMIZATION_MODULE}.${CUSTOMIZATION_NAME%%.*} import customize;"
CUSTOMIZATION+="process=customize(process,$jobId,$eventsPerLumi,'$GRIDPACK','$dumpFile');"

# generate the cfg file
cmsDriver.py \
  $FRAGMENT_LOCATION \
  --python_filename $pset \
  --eventcontent RAWSIM,LHE \
  --customise $EXTRA_CUSTOMS \
  --beamspot $BEAMSPOT \
  --datatier GEN-SIM,LHE \
  --fileout file:$fileOut \
  --conditions $GLOBAL_TAG \
  --customise_commands $CUSTOMIZATION \
  --step LHE,GEN,SIM \
  --no_exec \
  --mc \
  -n $nEvents \
  $EXTRA_ARGS

# dump the parameter sets
python $pset;
if [ -f $dumpFile ]; then
  cat $dumpFile;
else
  echo "File $dumpFile does not exist!";
fi;

# run the job
/usr/bin/time --verbose cmsRun -j FrameworkJobReport.${step_name}.xml $pset;
mv -v $fileOut $CWD;

# show the contents of cwd
ls -lh;
