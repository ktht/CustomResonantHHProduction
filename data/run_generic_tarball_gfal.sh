#!/bin/bash

# Modified version of GeneratorInterface/LHEInterface/data/run_generic_tarball_xrootd.sh
# Uses gfal-copy instead of xrdcp to copy the gridpack from an external server

echo "Architecture: ${SCRAM_ARCH}"
echo "CMSSW version: ${CMSSW_VERSION}"
echo "gLite location: ${GLITE_LOCATION}"

set -e

echo "   ______________________________________     "

if [ $# -lt 1 ]; then
    echo "%MSG-ExternalLHEProducer-subprocess ERROR in external process. The gridpack path must be passed as an argument"
fi
if [[ $1 != "gsiftp://"* ]]; then
    echo "%MSG-ExternalLHEProducer-subprocess ERROR in external process. Path must have format gsiftp://<gfal_path>/<path>"
    exit 1
fi 

gfal_path=$1
gridpack=$(basename $gfal_path)

if [ -e $gridpack ]; then
    echo "%MSG-ExternalLHEProducer-subprocess WARNING: File $gridpack already exists, it will be overwritten."
    rm $gridpack
fi

echo "%MSG-ExternalLHEProducer-subprocess INFO: Copying gridpack $gfal_path locally using xrootd"
LD_LIBRARY_PATH=${GLITE_LOCATION}/lib64:${GLITE_LOCATION}/lib gfal-copy $gfal_path .

path=`pwd`/$gridpack
generic_script=/cvmfs/cms.cern.ch/${SCRAM_ARCH}/cms/cmssw/${CMSSW_VERSION}/src/GeneratorInterface/LHEInterface/data/run_generic_tarball_cvmfs.sh
. $generic_script $path ${@:2}
