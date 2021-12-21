import FWCore.ParameterSet.Config as cms

def customize(process, seed, eventsPerLumi, gridpack, dumpFile):
  process.RandomNumberGeneratorService.externalLHEProducer.initialSeed = seed
  process.RandomNumberGeneratorService.generator.initialSeed = seed
  process.source.firstRun = cms.untracked.uint32(1)
  process.source.firstLuminosityBlock = cms.untracked.uint32(seed)
  process.source.firstEvent = cms.untracked.uint32((seed - 1) * eventsPerLumi + 1)
  process.source.numberEventsInLuminosityBlock = cms.untracked.uint32(eventsPerLumi)
  process.externalLHEProducer.args = cms.vstring(gridpack)
  if dumpFile:
    with open(dumpFile, 'w') as dump:
      dump.write(process.dumpPython())
  return process
