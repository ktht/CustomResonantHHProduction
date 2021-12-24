import FWCore.ParameterSet.Config as cms
import os
import random

def debug(process, dumpFile):
  with open(dumpFile, 'w') as dump:
    dump.write(process.dumpPython())
  return process

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
  process = debug(process, dumpFile)
  return process

def assignPU(process, pu_file, seed = -1):
  pu_files = []
  with open(pu_file, 'r') as pu_fptr:
    for line in pu_fptr:
      pu_files.append(line.strip())
  if seed > 0:
    random.seed(seed)
    random.shuffle(pu_files)
  process.mixData.input.fileNames = cms.untracked.vstring(pu_files)
  return process
