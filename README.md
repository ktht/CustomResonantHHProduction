# Resonant HH production

## Known issues

Not going to fix them because the production is basically over but still worth mentioning:

- Memory requirements increase for 2017 and (especially for) 2018.
Probably need to use 2 cores when asking more than 2500M of memory.
- A handful of 2018 jobs failed with Geant4 errors ("Track stuck, not moving for 25 steps in volume").
The most efficient way to get rid of this error is by using a different seed at the LHE+GEN-SIM step,
so that a different configuration of particles enter the detector simulation that doesn't cause any issues.
- A small number of 2018 jobs failed because the files from MinBias sample were no simply accessible.
No other way around it other than reshuffling the file list with a different seed or resubmitting the same job
(in case the issue was due to temporary loss of connection).
- The LFN paths (including the `file:` prefix) to MiniAOD files that are later Ntupelized must be less than
255 characters long. A temporary solution is to rename the directories created by CRAB to respect this requirement.
A long-term solution would be rethinking how to construct request ID such that it won't violate this rule.

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

2017 and 2018 are missing gridpacks for 340 GeV mass point, however, there's little point in producing them at all since
we already have samples for 350 GeV mass point. Samples produced for 340 GeV are present only for bbtt decay mode. Thus,
we only need to produce gridpacks for 2016 era, 850 GeV mass point, for both spin-0 and spin-2. The same gridpack can be
used for either SL or DL decay modes, because HH decays are modeled with Pythia.

## Sample production

### Missing samples

There are a total of 21 samples missing, not counting 12 samples for 340 GeV mass point (3 eras, 2 spins, 2 decay modes):
- 400k events for resonant mass < 300 GeV (6 samples)
- 300k events for 300 GeV <= resonant mass < 600 GeV (7 samples)
- 200k events for 600 GeV <= resonant mass < 1000 GeV (8 samples)

Thus, we need to produce 6.1M events in total.

#### 2016

| Spin-0 | Mass points             |
|--------|-------------------------|
| SL     | 280, 320, 750, 850      |
| DL     | 250, 280, 320, 700, 850 |

Gridpack (except for 850): `/cvmfs/cms.cern.ch/phys_generator/gridpacks/slc6_amd64_gcc481/13TeV/madgraph/V5_2.3.2.2/Radion_GF_HH/Radion_GF_HH_M${MASS}_narrow/v1/Radion_GF_HH_M${MASS}_narrow_tarball.tar.xz`

| Spin-2 | Mass points             |
|--------|-------------------------|
| SL     | 280, 320, 750, 850      |
| DL     | 250, 280, 320, 750, 850 |

Gridpack (except for 850): `/cvmfs/cms.cern.ch/phys_generator/gridpacks/slc6_amd64_gcc481/13TeV/madgraph/V5_2.3.3/BulkGraviton_GF_HH_M${MASS}_narrow/v1/BulkGraviton_GF_HH_M${MASS}_narrow_tarball.tar.xz`

#### 2017

Spin-0, DL: 300, 550  
Gridpack: `/cvmfs/cms.cern.ch/phys_generator/gridpacks/2017/13TeV/madgraph/V5_2.4.2/Radion_hh_narrow_M${MASS}/v1/Radion_hh_narrow_M${MASS}_slc6_amd64_gcc481_CMSSW_7_1_30_tarball.tar.xz`

#### 2018

Spin-0, DL, 450  
Gridpack: `/cvmfs/cms.cern.ch/phys_generator/gridpacks/2017/13TeV/madgraph/V5_2.4.2/Radion_hh_narrow_M450/v1/Radion_hh_narrow_M450_slc6_amd64_gcc481_CMSSW_7_1_30_tarball.tar.xz`

### Setup details

| LHE, GEN+SIM |                                                       2016                                                       |                                                      2017                                                      |                                                      2018                                                      |
|:------------:|:----------------------------------------------------------------------------------------------------------------:|:--------------------------------------------------------------------------------------------------------------:|:--------------------------------------------------------------------------------------------------------------:|
|     CMSSW    |                                                  `CMSSW_7_1_26`\*                                                |                                                 `CMSSW_9_3_10` \*\*                                            |                                                 `CMSSW_10_2_22`                                                |
| Architecture |                                                `slc6_amd64_gcc481`                                               |                                               `slc6_amd64_gcc630`                                              |                                               `slc6_amd64_gcc700`                                              |
|  Global tag  |                                                `MCRUN2_71_V1::All`                                               |                                            `93X_mc2017_realistic_v3`                                           |                                        `102X_upgrade2018_realistic_v11`                                        |
| Era          | -                                                                                                                | `Run2_2017`                                                                                                    | `Run2_2018`                                                                                                    |
| Example      | [spin-0, 260, DL](https://cms-pdmv.cern.ch/mcm/public/restapi/requests/get_setup/HIG-RunIISummer15wmLHEGS-00167) | [spin-0, 500, DL](https://cms-pdmv.cern.ch/mcm/public/restapi/requests/get_setup/HIG-RunIIFall17wmLHEGS-02530) | [spin-0, 400, DL](https://cms-pdmv.cern.ch/mcm/public/restapi/requests/get_setup/HIG-RunIIFall18wmLHEGS-03980) |

\* While some spin-0 samples were produced in `CMSSW_7_1_24`, some spin-2 samples were produced in `CMSSW_7_1_25_patch3`, so the next available release is selected instead  
\*\* Samples appear to be produced in `CMSSW_9_3_9_patch1`, however, it's not available anymore, so the next release is picked instead

|    AODSIM    |                                                         2016                                                        |                                                       2017                                                      |                                                        2018                                                       |
|:------------:|:-------------------------------------------------------------------------------------------------------------------:|:---------------------------------------------------------------------------------------------------------------:|:-----------------------------------------------------------------------------------------------------------------:|
|     CMSSW    |                                                    `CMSSW_8_0_21`                                                   |                                                  `CMSSW_9_4_7`                                                  |                                                   `CMSSW_10_2_5`                                                  |
| Architecture |                                                 `slc6_amd64_gcc530`                                                 |                                               `slc6_amd64_gcc630`                                               |                                                `slc6_amd64_gcc700`                                                |
|  Global tag  |                                      `80X_mcRun2_asymptotic_2016_TrancheIV_v6`                                      |                                            `94X_mc2017_realistic_v11`                                           |                                          `102X_upgrade2018_realistic_v15`                                         |
| Era          |                                                     `Run2_2016`                                                     |                                                   `Run2_2017`                                                   |                                                    `Run2_2018`                                                    |
| Example      | [spin-0, 260, DL](https://cms-pdmv.cern.ch/mcm/public/restapi/requests/get_setup/HIG-RunIISummer16DR80Premix-01408) | [spin-0, 500, DL](https://cms-pdmv.cern.ch/mcm/public/restapi/requests/get_setup/HIG-RunIIFall17DRPremix-03149) | [spin-0, 400, DL](https://cms-pdmv.cern.ch/mcm/public/restapi/requests/get_setup/HIG-RunIIAutumn18DRPremix-03081) |

Pileup files obtained with:

```bash
# pileup_2016.txt
dasgoclient -query="file dataset=/Neutrino_E-10_gun/RunIISpring15PrePremix-PUMoriond17_80X_mcRun2_asymptotic_2016_TrancheIV_v2-v2/GEN-SIM-DIGI-RAW"
# pileup_2017.txt
dasgoclient -query="file dataset=/Neutrino_E-10_gun/RunIISummer17PrePremix-MCv2_correctPU_94X_mc2017_realistic_v9-v1/GEN-SIM-DIGI-RAW"
# pileup_2018.txt
dasgoclient -query="file dataset=/Neutrino_E-10_gun/RunIISummer17PrePremix-PUAutumn18_102X_upgrade2018_realistic_v15-v1/GEN-SIM-DIGI-RAW"
```

|  MiniAODSIM  |                                                        2016                                                        |                                                       2017                                                       |                                                       2018                                                       |
|:------------:|:------------------------------------------------------------------------------------------------------------------:|:----------------------------------------------------------------------------------------------------------------:|:----------------------------------------------------------------------------------------------------------------:|
|     CMSSW    |                                                    `CMSSW_9_4_9`                                                   |                                                   `CMSSW_9_4_7`                                                  |                                                  `CMSSW_10_2_5`                                                  |
| Architecture |                                                 `slc6_amd64_gcc630`                                                |                                                `slc6_amd64_gcc630`                                               |                                                `slc6_amd64_gcc700`                                               |
|  Global tag  |                                             `94X_mcRun2_asymptotic_v3`                                             |                                            `94X_mc2017_realistic_v14`                                            |                                         `102X_upgrade2018_realistic_v15`                                         |
| Era          |                                         `Run2_2016,run2_miniAOD_80XLegacy`                                         |                                        `Run2_2017,run2_miniAOD_94XFall17`                                        |                                                    `Run2_2018`                                                   |
| Example      | [spin-0, 260, DL](https://cms-pdmv.cern.ch/mcm/public/restapi/requests/get_setup/HIG-RunIISummer16MiniAODv3-00356) | [spin-0, 500, DL](https://cms-pdmv.cern.ch/mcm/public/restapi/requests/get_setup/HIG-RunIIFall17MiniAODv2-03080) | [spin-0, 400, DL](https://cms-pdmv.cern.ch/mcm/public/restapi/requests/get_setup/HIG-RunIIAutumn18MiniAOD-03099) |

|   NanoAODv7  |                                                        2016                                                        |                                                       2017                                                       |                                                        2018                                                        |
|:------------:|:------------------------------------------------------------------------------------------------------------------:|:----------------------------------------------------------------------------------------------------------------:|:------------------------------------------------------------------------------------------------------------------:|
|     CMSSW    |                                                   `CMSSW_10_2_22`                                                  |                                                  `CMSSW_10_2_22`                                                 |                                                   `CMSSW_10_2_22`                                                  |
| Architecture |                                                 `slc6_amd64_gcc700`                                                |                                                `slc6_amd64_gcc700`                                               |                                                 `slc6_amd64_gcc700`                                                |
|  Global tag  |                                             `102X_mcRun2_asymptotic_v8`                                            |                                            `102X_mc2017_realistic_v8`                                            |                                          `102X_upgrade2018_realistic_v21`                                          |
| Era          |                                          `Run2_2016,run2_nanoAOD_94X2016`                                          |                                       `Run2_2017,run2_nanoAOD_94XMiniAODv2`                                      |                                           `Run2_2018,run2_nanoAOD_102Xv1`                                          |
| Example      | [spin-0, 260, DL](https://cms-pdmv.cern.ch/mcm/public/restapi/requests/get_setup/HIG-RunIISummer16NanoAODv7-00284) | [spin-0, 500, DL](https://cms-pdmv.cern.ch/mcm/public/restapi/requests/get_setup/HIG-RunIIFall17NanoAODv7-02340) | [spin-0, 400, DL](https://cms-pdmv.cern.ch/mcm/public/restapi/requests/get_setup/HIG-RunIIAutumn18NanoAODv7-02865) |

### Instructions

#### Local submission

This section assumes that your host machine is based on SLC7.
Set up your CMSSW:

```bash
cd $HOME
export SCRAM_ARCH=slc7_amd64_gcc700
source /cvmfs/cms.cern.ch/cmsset_default.sh;
cmsrel CMSSW_10_2_22
cd $_/src
cmsenv
git clone https://github.com/ktht/CustomResonantHHProduction.git Configuration/CustomResonantHHProduction
scram b -j8
```

Set up CRAB and create grid proxy when running locally (needed to access minbias samples):

```bash
source /cvmfs/grid.cern.ch/umd-c7ui-latest/etc/profile.d/setup-c7-ui-example.sh; # for proxy
source /cvmfs/cms.cern.ch/crab3/crab.sh prod; # for crab

# non-standard proxy certificate necessary when running on SLURM
# because /tmp between host and comp nodes is not the same
voms-proxy-init -voms cms -valid 192:00 --out $PWD/voms_proxy.txt
export X509_USER_PROXY=$PWD/voms_proxy.txt
```

Run jobs on the cluster:

```bash
# arguments: [crab|slurm] [prod|test] era spin [sl|dl] mass [version] ([yes|no] -- optional)

submit_jobs.sh slurm prod 2016 0 sl 280 v0
submit_jobs.sh slurm prod 2016 0 sl 320 v0
submit_jobs.sh slurm prod 2016 0 sl 750 v0
submit_jobs.sh slurm prod 2016 0 sl 850 v0

submit_jobs.sh slurm prod 2016 0 dl 250 v0
submit_jobs.sh slurm prod 2016 0 dl 280 v0
submit_jobs.sh slurm prod 2016 0 dl 320 v0
submit_jobs.sh slurm prod 2016 0 dl 700 v0
submit_jobs.sh slurm prod 2016 0 dl 850 v0

submit_jobs.sh slurm prod 2016 2 sl 280 v0
submit_jobs.sh slurm prod 2016 2 sl 320 v0
submit_jobs.sh slurm prod 2016 2 sl 750 v0
submit_jobs.sh slurm prod 2016 2 sl 850 v0

submit_jobs.sh slurm prod 2016 2 dl 250 v0
submit_jobs.sh slurm prod 2016 2 dl 280 v0
submit_jobs.sh slurm prod 2016 2 dl 320 v0
submit_jobs.sh slurm prod 2016 2 dl 750 v0
submit_jobs.sh slurm prod 2016 2 dl 850 v0

submit_jobs.sh slurm prod 2017 0 dl 300 v0
submit_jobs.sh slurm prod 2017 0 dl 550 v0

submit_jobs.sh slurm prod 2018 0 dl 450 v0
```

A compromise is made when submitting native SLC7 jobs:

- `slc6_amd64_gcc530` -> `slc7_amd64_gcc530`
- `slc6_amd64_gcc630` -> `slc7_amd64_gcc630`
- `slc6_amd64_gcc700` -> `slc7_amd64_gcc700`

#### CRAB submission

The only way to run step0 in CRAB worker nodes is to submit the jobs from SLC6.
Spawning a singularity session does not work because of the following error:

```
No setuid installation found, for unprivileged installation use: ./mconfig --without-suid
```

So, instead of launching singularity in the worker nodes, do it in the host machine:

```bash
# could also use:
singularity exec --home $HOME --bind /cvmfs --bind /tmp --bind /hdfs --contain --ipc --pid \
  /cvmfs/singularity.opensciencegrid.org/bbockelm/cms:rhel6 bash
```

And in singularity set up CMSSW:

```bash
export SCRAM_ARCH=slc6_amd64_gcc700 # note slc6, not slc7
source /cvmfs/cms.cern.ch/cmsset_default.sh;
cmsrel CMSSW_10_2_22
cd $_/src
cmsenv
git clone https://github.com/ktht/CustomResonantHHProduction.git Configuration/CustomResonantHHProduction
scram b -j8
```

Set up CRAB and proxy utilities:

```bash
source /cvmfs/grid.cern.ch/emi3ui-latest/etc/profile.d/setup-ui-example.sh; # for proxy
source /cvmfs/cms.cern.ch/crab3/crab.sh pre; # for crab
```

However, you have to create (and renew) the grid proxy in SLC7, because apparently it doesn't work in SLC6:

```bash
voms-proxy-init -voms cms -valid 192:00 --out $PWD/voms_proxy.txt
export X509_USER_PROXY=$PWD/voms_proxy.txt # define the same variable in singularity
```

Finally, submit the jobs:

```bash
# arguments: [crab|slurm] [prod|test] era spin [sl|dl] mass [version] ([yes|no] -- optional)

submit_jobs.sh crab prod 2016 0 sl 280 v0
submit_jobs.sh crab prod 2016 0 sl 320 v0
submit_jobs.sh crab prod 2016 0 sl 750 v0
submit_jobs.sh crab prod 2016 0 sl 850 v0

submit_jobs.sh crab prod 2016 0 dl 250 v0
submit_jobs.sh crab prod 2016 0 dl 280 v0
submit_jobs.sh crab prod 2016 0 dl 320 v0
submit_jobs.sh crab prod 2016 0 dl 700 v0
submit_jobs.sh crab prod 2016 0 dl 850 v0

submit_jobs.sh crab prod 2016 2 sl 280 v0
submit_jobs.sh crab prod 2016 2 sl 320 v0
submit_jobs.sh crab prod 2016 2 sl 750 v0
submit_jobs.sh crab prod 2016 2 sl 850 v0

submit_jobs.sh crab prod 2016 2 dl 250 v0
submit_jobs.sh crab prod 2016 2 dl 280 v0
submit_jobs.sh crab prod 2016 2 dl 320 v0
submit_jobs.sh crab prod 2016 2 dl 750 v0
submit_jobs.sh crab prod 2016 2 dl 850 v0

submit_jobs.sh crab prod 2017 0 dl 300 v0
submit_jobs.sh crab prod 2017 0 dl 550 v0

submit_jobs.sh crab prod 2018 0 dl 450 v0
```

#### NanoAODv7 production

```bash
submit_nano.sh prod 2016 0 sl 280 v0
submit_nano.sh prod 2016 0 sl 320 v0
submit_nano.sh prod 2016 0 sl 750 v0
submit_nano.sh prod 2016 0 sl 850 v0

submit_nano.sh prod 2016 0 dl 250 v0
submit_nano.sh prod 2016 0 dl 280 v0
submit_nano.sh prod 2016 0 dl 320 v0
submit_nano.sh prod 2016 0 dl 700 v0
submit_nano.sh prod 2016 0 dl 850 v0

submit_nano.sh prod 2016 2 sl 280 v0
submit_nano.sh prod 2016 2 sl 320 v0
submit_nano.sh prod 2016 2 sl 750 v0
submit_nano.sh prod 2016 2 sl 850 v0

submit_nano.sh prod 2016 2 dl 250 v0
submit_nano.sh prod 2016 2 dl 280 v0
submit_nano.sh prod 2016 2 dl 320 v0
submit_nano.sh prod 2016 2 dl 750 v0
submit_nano.sh prod 2016 2 dl 850 v0

submit_nano.sh prod 2017 0 dl 300 v0
submit_nano.sh prod 2017 0 dl 550 v0

submit_nano.sh prod 2018 0 dl 450 v0
```
