import FWCore.ParameterSet.Config as cms

externalLHEProducer = cms.EDProducer("ExternalLHEProducer",
  args = cms.vstring(''),
  nEvents = cms.untracked.uint32(250),
  numberOfParameters = cms.uint32(1),
  outputFile = cms.string('cmsgrid_final.lhe'),
  scriptName = cms.FileInPath('GeneratorInterface/LHEInterface/data/run_generic_tarball_cvmfs.sh')
)

from Configuration.Generator.Pythia8CommonSettings_cfi import pythia8CommonSettingsBlock
from Configuration.Generator.Pythia8CUEP8M1Settings_cfi import pythia8CUEP8M1SettingsBlock


generator = cms.EDFilter("Pythia8HadronizerFilter",
  maxEventsToPrint = cms.untracked.int32(1),
  pythiaPylistVerbosity = cms.untracked.int32(1),
  filterEfficiency = cms.untracked.double(1.0),
  pythiaHepMCVerbosity = cms.untracked.bool(False),
  comEnergy = cms.double(13000.),
  PythiaParameters = cms.PSet(
    pythia8CommonSettingsBlock,
    pythia8CUEP8M1SettingsBlock,
    #
    processParameters = cms.vstring(
      '15:onMode = off',
      '15:onIfAny = 11 13',
      '24:mMin = 0.05',
      '24:onMode = on',
      '25:m0 = 125.0',
      '25:onMode = off',
      '25:onIfMatch = 5 -5',
      '25:onIfMatch = 24 -24',
      'ResonanceDecayFilter:filter = on',
      'ResonanceDecayFilter:exclusive = on',
      'ResonanceDecayFilter:eMuAsEquivalent = off',
      'ResonanceDecayFilter:eMuTauAsEquivalent = on',
      'ResonanceDecayFilter:allNuAsEquivalent = on',
      'ResonanceDecayFilter:udscAsEquivalent   = off',
      'ResonanceDecayFilter:udscbAsEquivalent  = on',
      'ResonanceDecayFilter:mothers = 25,24',
      'ResonanceDecayFilter:daughters = 5,5,24,24,11,12,1,1',
    ),
    parameterSets = cms.vstring(
      'pythia8CommonSettings',
      'pythia8CUEP8M1Settings',
      'processParameters',
    ),
  ),
)

ProductionFilterSequence = cms.Sequence(generator)
