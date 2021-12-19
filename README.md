# Resonant HH production

## Create missing gridpacks

NB! Do the following in clean environment, no CMSSW:

```bash
cd $HOME
git clone -b 2016HHprod_bbWW https://github.com/ktht/genproductions.git genproductionsHH # using 2.3.3
cd $_/bin/MadGraph5_aMCatNLO

# if case your host is not SLC6
singularity exec --home $HOME:/home/$USER --bind /cvmfs --bind /hdfs \
   --bind /home --bind /scratch --pwd $PWD --contain --ipc --pid \
  /cvmfs/singularity.opensciencegrid.org/kreczko/workernode:centos6 bash

# produce gridpacks for 2016
./gridpack_generation.sh Radion_GF_HH_M850_narrow       cards/production/13TeV/exo_diboson/Spin-0/Radion_GF_HH/Radion_GF_HH_M850_narrow
./gridpack_generation.sh BulkGraviton_GF_HH_M850_narrow cards/production/13TeV/exo_diboson/Spin-2/BulkGraviton_GF_HH/BulkGraviton_GF_HH_M850_narrow

exit # from the singularity

# copy the gridpacks where needed
cp -v *.tar.xz /hdfs/local/$USER/gridpacks/.
ls *.tar.xz | xargs -I {} gfal-copy file://{} gsiftp://$SERVER:$PORT/cms/store/user/$CRAB_USERNAME/gridpacks
```

2017 and 2018 are missing gridpacks for 340 GeV mass point, however, there's little point in producing it since we already have samples for 350 GeV mass point.

