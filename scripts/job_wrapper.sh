#!/bin/bash

JOB_IDX=$1;
NEVENTS_PER_SAMPLE=$2;
NEVENTS=$3;
ERA=$4;
SPIN=$5;
MASS=$6;
DECAY_MODE=$7;
CLEANUP=$8;
OUTPUT_DIR=$9;
RUN_NANO=${10};

TMP_ID=$SLURM_JOBID
if [ -z "$TMP_ID" ]; then
  # running interactively
  TMP_ID=tmp;
fi

TMP_DIR=/scratch/$USER/$TMP_ID;
mkdir -pv $TMP_DIR;
cd $TMP_DIR;

run_job.sh $JOB_IDX \
  eventsPerLumi=$NEVENTS_PER_SAMPLE \
  maxEvents=$NEVENTS \
  era=$ERA \
  spin=$SPIN \
  mass=$MASS \
  decayMode=$DECAY_MODE \
  cleanup=$CLEANUP \
  cmsswVersion=$CMSSW_VERSION \
  runNano=$RUN_NANO \
  method=local;

if [ "$RUN_NANO" == "yes" ]; then
  cp -v tree.root $OUTPUT_DIR/tree_${JOB_IDX}.root;
else
  cp -v mini.root $OUTPUT_DIR/mini_${JOB_IDX}.root;
fi;

sleep 60
cd -
if [ "$CLEANUP" == "true" ]; then
  rm -rfv $TMP_DIR
fi
