# Resonant HH production

## TODO

- adjust for memory requirements

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

### Architecture mapping

There's a glaring problem that has no trivial solution: premixing step needs a minbias sample that's accessible
from DBS, however, access do DBS requires an open proxy which cannot be created in SLC6. So, the only way out is
to use SLC7 build from step 1 onwards. The 0-th step cannot be run in SLC7 because of the library dependencies in
the gridpack. We could produce new gridpacks in SLC7 and run everything in SLC7, but the problem is that the CMSSW
version that the gridpacks were produced in and the 0-th step was run are not available in SLC7.

Anyways, here's the mapping of architectures:

- `slc6_amd64_gcc530` -> `slc7_amd64_gcc530`
- `slc6_amd64_gcc630` -> `slc7_amd64_gcc630`
- `slc6_amd64_gcc700` -> `slc7_amd64_gcc700`

### Instructions

Set up CMSSW:

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

Run the jobs locally:

```bash
# arguments: [crab|slurm] [prod|test] era spin [sl|dl] mass

submit_jobs.sh crab prod 2016 0 sl 280
submit_jobs.sh crab prod 2016 0 sl 320
submit_jobs.sh crab prod 2016 0 sl 750
submit_jobs.sh crab prod 2016 0 sl 850

submit_jobs.sh crab prod 2016 0 dl 250
submit_jobs.sh crab prod 2016 0 dl 280
submit_jobs.sh crab prod 2016 0 dl 320
submit_jobs.sh crab prod 2016 0 dl 700
submit_jobs.sh crab prod 2016 0 dl 850

submit_jobs.sh crab prod 2016 2 sl 280
submit_jobs.sh crab prod 2016 2 sl 320
submit_jobs.sh crab prod 2016 2 sl 750
submit_jobs.sh crab prod 2016 2 sl 850

submit_jobs.sh crab prod 2016 2 dl 250
submit_jobs.sh crab prod 2016 2 dl 280
submit_jobs.sh crab prod 2016 2 dl 320
submit_jobs.sh crab prod 2016 2 dl 750
submit_jobs.sh crab prod 2016 2 dl 850

submit_jobs.sh crab prod 2017 0 dl 300
submit_jobs.sh crab prod 2017 0 dl 550

submit_jobs.sh crab prod 2018 0 dl 450
```

When running locally, replace `crab` with `slurm` in the above commands.
