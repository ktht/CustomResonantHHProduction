import FWCore.ParameterSet.Config as cms
import os

def customize(process, seed, eventsPerLumi, gridpack, dumpFile):
  process.RandomNumberGeneratorService.externalLHEProducer.initialSeed = seed
  process.RandomNumberGeneratorService.generator.initialSeed = seed
  process.source.firstRun = cms.untracked.uint32(1)
  process.source.firstLuminosityBlock = cms.untracked.uint32(seed)
  process.source.firstEvent = cms.untracked.uint32((seed - 1) * eventsPerLumi + 1)
  process.source.numberEventsInLuminosityBlock = cms.untracked.uint32(eventsPerLumi)
  process.externalLHEProducer.args = cms.vstring(gridpack)
  if gridpack.startswith('gsiftp://'):
    assert('DATASCRIPT_BASE' in os.environ)
    process.externalLHEProducer.scriptName = cms.FileInPath(os.environ['DATASCRIPT_BASE'])
  if dumpFile:
    with open(dumpFile, 'w') as dump:
      dump.write(process.dumpPython())
  return process
