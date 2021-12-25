
ERAS = {
  2016 : 'RunIISummer16',
  2017 : 'RunIIFall17',
  2018 : 'RunIIAutumn18',
}

GLOBAL_TAGS = {
  2016 : '102X_mcRun2_asymptotic_v8',
  2017 : '102X_mc2017_realistic_v8',
  2018 : '102X_upgrade2018_realistic_v21',
}

def get_nanov7_str(era):
  assert(era in ERAS)
  return '{}NanoAODv7'.format(ERAS[era])

def get_gt(era):
  assert(era in GLOBAL_TAGS)
  return GLOBAL_TAGS[era]

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
