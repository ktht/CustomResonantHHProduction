from CRABClient.UserUtilities import config, getUsernameFromCRIC

import os
import datetime

def test_positive_int(arg):
  return arg.isdigit() and int(arg) > 0

def get_env_var(env_var, fail_if_not_exists = True, test_type = None):
  if env_var not in os.environ:
    if fail_if_not_exists:
      raise ValueError("$%s not defined" % env_var)
    else:
      return ''
  env_val = os.environ[env_var]
  if test_type != None:
    assert(test_type(env_val))
  return env_val

def get_dataset_name(era, spin, decay_mode, mass):
  assert(spin in [ 0, 2 ])
  assert(decay_mode in [ "sl", "dl" ])
  assert(era in [ 2016, 2017, 2018 ])
  result = "GluGluTo{}ToHHTo{}_M-{}_narrow_{}13TeV-madgraph-pythia8".format(
    "Radion" if spin == 0 else "BulkGraviton",
    "2B2VTo2L2Nu" if decay_mode == "dl" else "2B2WToLNu2J",
    mass,
    'TuneCP5_PSWeights_' if era == 2018 else '',
  )
  return result

NEVENTS_PER_JOB = get_env_var('NEVENTS_PER_JOB', test_type = test_positive_int)
NEVENTS         = get_env_var('NEVENTS', test_type = test_positive_int)
ERA             = int(get_env_var('ERA'))
SPIN            = int(get_env_var('SPIN'))
DECAY_MODE      = get_env_var('DECAY_MODE')
MASS            = get_env_var('MASS')
VERSION         = get_env_var('VERSION')
PUBLISH         = get_env_var('PUBLISH')
CMSSW_VERSION   = get_env_var('CMSSW_VERSION')

TODAY         = datetime.date.today().strftime("%Y%b%d")
BASEDIR       = os.path.join(CMSSW_VERSION, 'src/Configuration/CustomResonantHHProduction')
PSET_LOC      = os.path.join(BASEDIR, 'test', 'dummy_pset.py')
SCRIPTEXE_LOC = os.path.join(BASEDIR, 'scripts', 'run_job.sh')
CRAB_LOC      = os.path.join(os.path.expanduser('~'), 'crab_projects')

if not os.path.isdir(CRAB_LOC):
  os.makedirs(CRAB_LOC)
assert(os.path.isfile(PSET_LOC))
assert(os.path.isfile(SCRIPTEXE_LOC))

DATASET      = get_dataset_name(SPIN, DECAY_MODE, MASS)
ID           = '{}_{}_{}'.format(TODAY, DATASET, VERSION)
crabUserName = getUsernameFromCRIC()

config = config()

config.General.requestName     = ID
config.General.workArea        = CRAB_LOC
config.General.transferOutputs = True
config.General.transferLogs    = True

config.JobType.pluginName              = 'PrivateMC'
config.JobType.psetName                = PSET_LOC
config.JobType.scriptExe               = SCRIPTEXE_LOC
config.JobType.scriptArgs              = [
  'eventsPerLumi={}'.format(NEVENTS_PER_JOB),
  'maxEvents={}'.format(NEVENTS),
  'era={}'.format(ERA),
  'spin={}'.format(SPIN),
  'mass={}'.format(MASS),
  'decayMode={}'.format(DECAY_MODE),
]
config.JobType.allowUndistributedCMSSW = True
config.JobType.numCores                = 1
config.JobType.maxMemoryMB             = 2500
config.JobType.eventsPerLumi           = int(NEVENTS_PER_JOB)
config.JobType.inputFiles              = [ SCRIPTEXE_LOC, PSET_LOC ]

config.Site.storageSite          = 'T2_EE_Estonia'
config.Data.outputPrimaryDataset = DATASET
config.Data.splitting            = 'EventBased'
config.Data.unitsPerJob          = int(NEVENTS_PER_JOB)
config.Data.totalUnits           = int(NEVENTS)

config.Data.outLFNDirBase    = '/store/user/%s/CustomResonantHHProduction/%s' % (crabUserName, VERSION)
config.Data.publication      = PUBLISH == "true"
config.Data.outputDatasetTag = ID
