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
PUBLISH         = get_env_var('PUBLISH')
CMSSW_VERSION   = get_env_var('CMSSW_VERSION')
CMSSW_BASE      = get_env_var('CMSSW_BASE')
RUN_NANO        = get_env_var('RUN_NANO')

if RUN_NANO == "yes":
  raise RuntimeError("Running NanoAOD step enabled")
pset_suffix = "mini" if RUN_NANO != "yes" else "nano"

TODAY         = datetime.date.today().strftime("%Y%b%d")
BASEDIR       = os.path.join(CMSSW_BASE, 'src/Configuration/CustomResonantHHProduction')
PSET_LOC      = os.path.join(BASEDIR, 'test', 'dummy_pset_{}.py'.format(pset_suffix))
SCRIPTEXE_LOC = os.path.join(BASEDIR, 'scripts', 'run_job.sh')
CRAB_LOC      = os.path.join(os.path.expanduser('~'), 'crab_projects')

if not os.path.isdir(CRAB_LOC):
  os.makedirs(CRAB_LOC)

last_step = 2
if RUN_NANO == "yes":
  last_step = 3
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
  'cleanup=true',
  'cmsswVersion={}'.format(CMSSW_VERSION),
  'runNano={}'.format(RUN_NANO),
]
config.JobType.allowUndistributedCMSSW = True
config.JobType.numCores                = 1
config.JobType.maxMemoryMB             = 2500
config.JobType.eventsPerLumi           = int(NEVENTS_PER_JOB)
config.JobType.inputFiles              = PAYLOAD
config.JobType.sendPythonFolder        = True

config.Site.storageSite          = 'T2_EE_Estonia'
config.Data.outputPrimaryDataset = DATASET
config.Data.splitting            = 'EventBased'
config.Data.unitsPerJob          = int(NEVENTS_PER_JOB)
config.Data.totalUnits           = int(NEVENTS)

config.Data.outLFNDirBase    = '/store/user/%s/CustomResonantHHProduction/%s' % (crabUserName, VERSION)
config.Data.publication      = PUBLISH == "true"
config.Data.outputDatasetTag = ID
