from CRABClient.UserUtilities import config, getUsernameFromCRIC

from Configuration.CustomResonantHHProduction.aux import get_dataset_name

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
    if not test_type(env_val):
      raise RuntimeError("Got invalid type for variable: %s" % env_var)
  return env_val

NEVENTS_PER_JOB = get_env_var('NEVENTS_PER_JOB', test_type = test_positive_int)
NEVENTS         = get_env_var('NEVENTS', test_type = test_positive_int)
ERA             = int(get_env_var('ERA'))
SPIN            = int(get_env_var('SPIN'))
DECAY_MODE      = get_env_var('DECAY_MODE')
MASS            = get_env_var('MASS')
VERSION         = get_env_var('VERSION')
CMSSW_VERSION   = get_env_var('CMSSW_VERSION')
CMSSW_BASE      = get_env_var('CMSSW_BASE')
CRAB_STATUS_DIR = get_env_var('CRAB_STATUS_DIR')

TODAY         = datetime.date.today().strftime("%Y%b%d")
BASEDIR       = os.path.join(CMSSW_BASE, 'src/Configuration/CustomResonantHHProduction')
PSET_LOC      = os.path.join(BASEDIR, 'test', 'dummy_pset.py')
SCRIPTEXE_LOC = os.path.join(BASEDIR, 'scripts', 'run_job.sh')

last_step = 2
PAYLOAD = [ PSET_LOC, SCRIPTEXE_LOC, os.path.join(BASEDIR, 'extra', 'pu_{}.txt'.format(ERA)) ] + \
          [ os.path.join(BASEDIR, 'scripts', 'run_step{}.sh'.format(i)) for i in range(last_step + 1) ]
for payload in PAYLOAD:
  if not os.path.isfile(payload):
    raise RuntimeError("No such file: %s" % payload)

DATASET      = get_dataset_name(ERA, SPIN, DECAY_MODE, MASS)
ID           = '{}_{}_{}'.format(TODAY, DATASET, VERSION)
crabUserName = getUsernameFromCRIC()

config = config()

config.General.requestName     = ID
config.General.workArea        = CRAB_STATUS_DIR
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
  'cleanup=true',
  'cmsswVersion={}'.format(CMSSW_VERSION),
  'runNano=no',
  'method=crab',
]
config.JobType.allowUndistributedCMSSW = True
config.JobType.numCores                = 1
config.JobType.maxMemoryMB             = 2500
config.JobType.eventsPerLumi           = int(NEVENTS_PER_JOB)
config.JobType.inputFiles              = PAYLOAD
config.JobType.sendPythonFolder        = True
config.JobType.outputFiles             = [ 'step2.root' ]

config.Site.storageSite = 'T2_EE_Estonia'
config.Site.blacklist   = [ 'T2_PT_NCG_Lisbon', 'T2_BE_UCL', 'T2_US_Wisconsin', 'T2_IN_TIFR', 'T3_US_PuertoRico', 'T2_US_Florida' ]

config.Data.outputPrimaryDataset = DATASET
config.Data.splitting            = 'EventBased'
config.Data.unitsPerJob          = int(NEVENTS_PER_JOB)
config.Data.totalUnits           = int(NEVENTS)
config.Data.outLFNDirBase        = '/store/user/%s/CustomResonantHHProduction/%s' % (crabUserName, VERSION)
config.Data.publication          = False
config.Data.publishDBS           = 'phys03'
config.Data.outputDatasetTag     = ID
