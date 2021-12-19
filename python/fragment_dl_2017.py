import FWCore.ParameterSet.Config as cms

# See eg
# https://cms-pdmv.cern.ch/mcm/public/restapi/requests/get_fragment/HIG-RunIIFall17wmLHEGS-02530

externalLHEProducer = cms.EDProducer("ExternalLHEProducer",
  args = cms.vstring(''),
  nEvents = cms.untracked.uint32(250),
  numberOfParameters = cms.uint32(1),
  outputFile = cms.string('cmsgrid_final.lhe'),
  scriptName = cms.FileInPath('GeneratorInterface/LHEInterface/data/run_generic_tarball_cvmfs.sh'),
)

from Configuration.Generator.Pythia8CommonSettings_cfi import pythia8CommonSettingsBlock
from Configuration.Generator.MCTunes2017.PythiaCP5Settings_cfi import pythia8CP5SettingsBlock


generator = cms.EDFilter("Pythia8HadronizerFilter",
  maxEventsToPrint = cms.untracked.int32(1),
  pythiaPylistVerbosity = cms.untracked.int32(1),
  filterEfficiency = cms.untracked.double(1.0),
  pythiaHepMCVerbosity = cms.untracked.bool(False),
  comEnergy = cms.double(13000.),
  PythiaParameters = cms.PSet(
    pythia8CommonSettingsBlock,
    pythia8CP5SettingsBlock,
    #
    processParameters = cms.vstring(
      '23:mMin = 0.05',
      '23:onMode = off',
      '23:onIfAny = 11 12 13 14 15 16',
      '24:mMin = 0.05',
      '24:onMode = off',
      '24:onIfAny = 11 13 15',
      '25:m0 = 125.0',
      '25:onMode = off',
      '25:onIfMatch = 5 -5',
      '25:onIfMatch = 23 23',
      '25:onIfMatch = 24 -24',
      'ResonanceDecayFilter:filter = on',
      'ResonanceDecayFilter:exclusive = on',
      'ResonanceDecayFilter:eMuAsEquivalent = off',
      'ResonanceDecayFilter:eMuTauAsEquivalent = on',
      'ResonanceDecayFilter:allNuAsEquivalent = on',
      'ResonanceDecayFilter:mothers = 25,23,24',
      'ResonanceDecayFilter:daughters = 5,5,11,11,12,12',
    ),
    parameterSets = cms.vstring(
      'pythia8CommonSettings',
      'pythia8CP5Settings',
      'processParameters',
    ),
  ),
)

ProductionFilterSequence = cms.Sequence(generator)
