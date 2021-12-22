
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
