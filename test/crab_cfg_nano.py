from CRABClient.UserUtilities import config, getUsernameFromCRIC

from Configuration.CustomResonantHHProduction.aux import get_dataset_name, get_nanov7_str, get_gt

import os
import glob
import math
import re

def test_positive_int(arg):
  return arg.isdigit() and int(arg) > 0

def test_int(arg):
  return test_positive_int(arg) or (arg.startswith('-') and test_positive_int(arg[1:]))

def get_env_var(env_var, fail_if_not_exists = True, test_type = None):
  if env_var not in os.environ:
    if fail_if_not_exists:
      raise ValueError("$%s not defined" % env_var)
    else:
      return ''
  env_val = os.environ[env_var]
  if test_type != None:
    if not test_type(env_val):
      raise RuntimeError("Got invalid type for variable: %s (val: %s)" % (env_var, env_val))
  return env_val

NFILES_PER_JOB  = int(get_env_var('NFILES_PER_JOB', test_type = test_positive_int))
NOF_MAX_FILES   = int(get_env_var('NOF_MAX_FILES', test_type = test_int))
ERA             = int(get_env_var('ERA'))
SPIN            = int(get_env_var('SPIN'))
DECAY_MODE      = get_env_var('DECAY_MODE')
MASS            = get_env_var('MASS')
VERSION         = get_env_var('VERSION')
INPUT_PATH      = get_env_var('INPUT_PATH')
CMSSW_BASE      = get_env_var('CMSSW_BASE')
CRAB_STATUS_DIR = get_env_var('CRAB_STATUS_DIR')

BASEDIR  = os.path.join(CMSSW_BASE, 'src/Configuration/CustomResonantHHProduction')
PSET_LOC = os.path.join(BASEDIR, 'test', 'nano_cfg.py')

NANO_STR     = get_nanov7_str(ERA)
GLOBAL_TAG   = get_gt(ERA)
DATASET      = get_dataset_name(ERA, SPIN, DECAY_MODE, MASS)
ID           = '{}_{}_{}'.format(NANO_STR, GLOBAL_TAG, VERSION)
HOME_SITE    = 'T2_EE_Estonia'
crabUserName = getUsernameFromCRIC()

INPUT_GLOB = glob.glob(os.path.join(INPUT_PATH, '000*', '*.root'))
INPUT_GLOB_SORTED = list(sorted(
  INPUT_GLOB,
  key = lambda fileName: int(re.match('step2_(?P<idx>\d+).root', os.path.basename(fileName)).group('idx'))
))
INPUT_FILES = [ 'file:{}'.format(path) for path in INPUT_GLOB_SORTED ]
assert(INPUT_FILES)
if NOF_MAX_FILES > 0:
  INPUT_FILES = INPUT_FILES[:NOF_MAX_FILES]

nof_inputs = len(INPUT_FILES)
nof_jobs = int(math.ceil(float(nof_inputs) / NFILES_PER_JOB))
print("Found {} input file(s), generating {} job(s):".format(nof_inputs, nof_jobs))
if nof_inputs > 10:
  print('\n'.join([ '  {}'.format(path) for path in INPUT_FILES[:5] ]))
  print('...')
  print('\n'.join([ '  {}'.format(path) for path in INPUT_FILES[-5:] ]))
else:
  print('\n'.join([ '  {}'.format(path) for path in INPUT_FILES ]))

config = config()

requestName = '{}_{}'.format(DATASET, ID)
requestName_lenDiff = len(requestName) - 100
if requestName_lenDiff > 0:
  requestName = '{}_{}'.format(DATASET[:-requestName_lenDiff], ID)
assert(len(requestName) <= 100)

config.General.requestName     = requestName
config.General.workArea        = CRAB_STATUS_DIR
config.General.transferOutputs = True
config.General.transferLogs    = True

config.JobType.pluginName              = 'Analysis'
config.JobType.psetName                = PSET_LOC
config.JobType.pyCfgParams             = [ "era={}".format(ERA), 'globalTag={}'.format(GLOBAL_TAG) ]
config.JobType.allowUndistributedCMSSW = True
config.JobType.numCores                = 1
config.JobType.maxMemoryMB             = 2000

config.Site.storageSite = HOME_SITE
config.Site.whitelist   = [ HOME_SITE ]

config.Data.outputPrimaryDataset = DATASET
config.Data.splitting            = 'FileBased'
config.Data.userInputFiles       = INPUT_FILES
config.Data.unitsPerJob          = NFILES_PER_JOB
config.Data.outLFNDirBase        = '/store/user/{}/CustomResonantHHProduction/{}'.format(crabUserName, VERSION)
config.Data.publication          = False
config.Data.publishDBS           = 'phys03'
config.Data.outputDatasetTag     = ID
