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

eventsPerLumi_nr=$(echo $eventsPerLumi | sed 's/^eventsPerLumi=//g');
maxEvents_nr=$(echo $maxEvents | sed 's/^maxEvents=//g');
era_nr=$(echo $era | sed 's/^era=//g');
spin_nr=$(echo $spin | sed 's/^spin=//g');
mass_nr=$(echo $mass | sed 's/^mass=//g');
decayMode_str=$(echo $decayMode | sed 's/^decayMode=//g');
cleanup_str=$(echo $cleanup | sed 's/^cleanup=//g');
cmsswVersion_str=$(echo $cmsswVersion | sed 's/^cmsswVersion=//g');

# use the same container (SLC6)
image=/cvmfs/singularity.opensciencegrid.org/kreczko/workernode:centos6;
if [ -d "$cmsswVersion_str" ]; then
  # CMSSW has been packed into the sandbox, so it should be in cwd
  cmssw_host=$cmsswVersion_str;
  extra_bind="";
else
  # we're running locally or on the cluster
  cmssw_host=$CMSSW_BASE;
  extra_bind="--bind /home";
fi;

# copy necessary inputs to cwd that otherwise are added to the sandbox
input_files="scripts/run_step0.sh scripts/run_step1.sh scripts/run_step2.sh extra/pu_${era_nr}.txt";
for input_file in $input_files; do
  if [ ! -f $(basename $input_file) ]; then
    cp -v $cmssw_host/src/Configuration/CustomResonantHHProduction/$input_file .;
  fi
done;

echo "Singularity image: $(ls $image)";
echo "CMSSW host: $cmssw_host";

ls -lh;

echo "Running LHE and GEN+SIM step (`date`)";
singularity run --home $PWD:/home/$USER --bind /cvmfs $extra_bind --contain --ipc --pid $image \
  ./run_step0.sh $jobId $eventsPerLumi_nr $maxEvents_nr $era_nr $spin_nr $mass_nr  \
                 $decayMode_str $cmssw_host $cleanup_str step0;

echo "Running PU premixing and AODSIM step (`date`)";
singularity run --home $PWD:/home/$USER --bind /cvmfs $extra_bind --contain --ipc --pid $image \
  ./run_step1.sh $era $cmssw_host step0 step1;
if [ "$cleanup" == "true" ]; then
  rm -fv step0.root;
fi;

echo "Running MiniAODSIM step (`date`)";
singularity run --home $PWD:/home/$USER --bind /cvmfs $extra_bind --contain --ipc --pid $image \
  ./run_step2.sh $era $cmssw_host step1 step2;
if [ "$cleanup" == "true" ]; then
  rm -fv step1.root;
fi;

mv -v step2.root mini.root
echo "All done (`date`)";

cat FrameworkJobReport.*.xml > FrameworkJobReport.xml;

ls -lh;
