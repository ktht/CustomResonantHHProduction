#!/bin/bash

# Usage:
# run_job.sh 123 eventsPerLumi=100 maxEvents=250 era=2016 spin=0 mass=250 decayMode=sl

#TODO adjust for running on /scratch (need more bind arguments)
#TODO clean up after intermediate steps

set -x

jobId=$1;
eventsPerLumi=$2;
maxEvents=$3;
era=$4;
spin=$5;
mass=$6;
decayMode=$7;

eventsPerLumi_nr=$(echo $eventsPerLumi | sed 's/^eventsPerLumi=//g');
maxEvents_nr=$(echo $maxEvents | sed 's/^maxEvents=//g');
era_nr=$(echo $era | sed 's/^era=//g');
spin_nr=$(echo $spin | sed 's/^spin=//g');
mass_nr=$(echo $mass | sed 's/^mass=//g');
decayMode_str=$(echo $decayMode | sed 's/^decayMode=//g');

# use the same container (SLC6)
image=/cvmfs/singularity.opensciencegrid.org/kreczko/workernode:centos6;
cmssw_host=$(realpath --relative-to=$PWD $CMSSW_BASE);

echo "Singularity image: $(ls $image)";
echo "CMSSW version: $CMSSW_VERSION";
echo "CMSSW host: $cmssw_host";

# copy files from $CMSSW_BASE to cwd
BASEDIR="$CMSSW_BASE/src/Configuration/CustomResonantHHProduction/scripts";
cp -v $BASEDIR/run_step*.sh .;

ls -lh;

echo "Running LHE and GEN+SIM step (`date`)";
singularity run --home $PWD:/home/$USER --bind /cvmfs --contain --ipc --pid $image \
  run_step0.sh $jobId $eventsPerLumi_nr $maxEvents_nr $era_nr $spin_nr $mass_nr $decayMode_str $cmssw_host step0;

echo "Running PU premixing and AODSIM step (`date`)";
singularity run --home $PWD:/home/$USER --bind /cvmfs --contain --ipc --pid $image \
  run_step1.sh $era $cmssw_host step0 step1;

echo "Running MiniAODSIM step (`date`)";
singularity run --home $PWD:/home/$USER --bind /cvmfs --contain --ipc --pid $image \
  run_step2.sh $era $cmssw_host step1 step2;

echo "All done (`date`)";

cat FrameworkJobReport.*.xml > FrameworkJobReport.xml;

ls -lh;
