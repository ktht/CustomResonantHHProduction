import FWCore.ParameterSet.Config as cms

externalLHEProducer = cms.EDProducer("ExternalLHEProducer",
  args = cms.vstring(''),
  nEvents = cms.untracked.uint32(250),
  numberOfParameters = cms.uint32(1),
  outputFile = cms.string('cmsgrid_final.lhe'),
  scriptName = cms.FileInPath('GeneratorInterface/LHEInterface/data/run_generic_tarball_cvmfs.sh')
)

from Configuration.Generator.Pythia8CommonSettings_cfi import pythia8CommonSettingsBlock
from Configuration.Generator.MCTunes2017.PythiaCP5Settings_cfi import pythia8CP5SettingsBlock
from Configuration.Generator.PSweightsPythia.PythiaPSweightsSettings_cfi import pythia8PSweightsSettingsBlock

generator = cms.EDFilter("Pythia8HadronizerFilter",
  maxEventsToPrint = cms.untracked.int32(1),
  pythiaPylistVerbosity = cms.untracked.int32(1),
  filterEfficiency = cms.untracked.double(1.0),
  pythiaHepMCVerbosity = cms.untracked.bool(False),
  comEnergy = cms.double(13000.),
  PythiaParameters = cms.PSet(
    pythia8CommonSettingsBlock,
    pythia8CP5SettingsBlock,
    pythia8PSweightsSettingsBlock,
    processParameters = cms.vstring(
      '24:mMin = 0.05',
      '24:onMode = on',
      '25:m0 = 125.0',
      '25:onMode = off',
      '25:onIfMatch = 5 -5',
      '25:onIfMatch = 24 -24',
      'ResonanceDecayFilter:filter = on',
      'ResonanceDecayFilter:exclusive = on',
      'ResonanceDecayFilter:eMuTauAsEquivalent = on',
      'ResonanceDecayFilter:allNuAsEquivalent = on',
      'ResonanceDecayFilter:udscAsEquivalent = on',
      'ResonanceDecayFilter:mothers = 24,25',
      'ResonanceDecayFilter:daughters = 5,5,1,1,11,12',
    ),
    parameterSets = cms.vstring(
      'pythia8CommonSettings',
      'pythia8CP5Settings',
      'pythia8PSweightsSettings',
      'processParameters',
    ),
  ),
)

ProductionFilterSequence = cms.Sequence(generator)
