#!/bin/bash

# Usage:
# run_job.sh 123 eventsPerLumi=100 maxEvents=250 era=2016 spin=0 mass=250 decayMode=sl cleanup=true cmsswVersion=$CMSSW_VERSION

set -x

jobId=$1;
eventsPerLumi=$2;
maxEvents=$3;
era=$4;
spin=$5;
mass=$6;
decayMode=$7;
cleanup=$8;
cmsswVersion=$9;
runNano=${10};

eventsPerLumi_nr=$(echo $eventsPerLumi | sed 's/^eventsPerLumi=//g');
maxEvents_nr=$(echo $maxEvents | sed 's/^maxEvents=//g');
era_nr=$(echo $era | sed 's/^era=//g');
spin_nr=$(echo $spin | sed 's/^spin=//g');
mass_nr=$(echo $mass | sed 's/^mass=//g');
decayMode_str=$(echo $decayMode | sed 's/^decayMode=//g');
cleanup_str=$(echo $cleanup | sed 's/^cleanup=//g');
cmsswVersion_str=$(echo $cmsswVersion | sed 's/^cmsswVersion=//g');
runNano_str=$(echo $runNano | sed 's/^runNano=//g');

# use the same container (SLC6)
image=/cvmfs/singularity.opensciencegrid.org/bbockelm/cms:rhel6;
if [ ! -d $image ]; then
  echo "Image $d does not exist";
  exit 1;
fi

extra_bind="";
if [ -d "$cmsswVersion_str" ]; then
  # CMSSW has been packed into the sandbox, so it should be in cwd
  cmssw_host=$cmsswVersion_str;
else
  # we're running locally or on the cluster
  cmssw_host=$CMSSW_BASE;
  if [[ ! $PWD =~ ^/home.*  ]]; then
    extra_bind="--bind /home";
  fi;
fi;

# copy necessary inputs to cwd that otherwise are added to the sandbox
input_files="scripts/run_step0.sh scripts/run_step1.sh scripts/run_step2.sh extra/pu_${era_nr}.txt";
if [ "$runNano_str" == "yes" ]; then
  input_files+=" scripts/run_step3.sh"
fi;
for input_file in $input_files; do
  if [ ! -f $(basename $input_file) ]; then
    cp -v $cmssw_host/src/Configuration/CustomResonantHHProduction/$input_file .;
  fi
done;

echo "Singularity image: $image";
echo "CMSSW host: $cmssw_host";

ls -lh;

echo "Running LHE and GEN+SIM step (`date`)";
singularity run --home $PWD --bind /cvmfs $extra_bind --contain --ipc --pid $image \
  ./run_step0.sh $jobId $eventsPerLumi_nr $maxEvents_nr $era_nr $spin_nr $mass_nr  \
                 $decayMode_str $cmssw_host $cleanup_str step0;
exit_code=$?;
if [ ! -f step0.root ]; then
  echo "No output file was produced at step 0 -> exiting";
  exit 1;
fi
if [[ $exit_code -ne 0 ]]; then
  exit $exit_code;
fi;


echo "Running PU premixing and AODSIM step (`date`)";
./run_step1.sh $jobId $era_nr $cmssw_host $cleanup_str step0 step1;
exit_code=$?;
if [ "$cleanup_str" == "true" ]; then
  rm -fv step0.root;
fi;
if [ ! -f step1.root ]; then
  echo "No output file was produced at step 1 -> exiting";
  exit 1;
fi
if [[ $exit_code -ne 0 ]]; then
  exit $exit_code;
fi;

echo "Running MiniAODSIM step (`date`)";
./run_step2.sh $era_nr $cmssw_host $cleanup_str step1 step2;
exit_code=$?;
if [ "$cleanup_str" == "true" ]; then
  rm -fv step1.root;
fi;
if [ ! -f step2.root ]; then
  echo "No output file was produced at step 2 -> exiting";
  exit 1;
fi
if [[ $exit_code -ne 0 ]]; then
  exit $exit_code;
fi;

if [ "$runNano_str" == "yes" ]; then
  ./run_step3.sh $era_nr $cmssw_host step2 step3;
  exit_code=$?;
  mv -v step3.root tree.root;
else:
  mv -v step2.root mini.root;
fi;
if [[ $exit_code -ne 0 ]]; then
  exit $exit_code;
fi;

echo "All done (`date`)";

ls -lh;
