# Auto generated configuration file
# Revision: 1.19
import FWCore.ParameterSet.Config as cms

# needed for crab

process = cms.Process('PRODUCTION')

process.maxEvents = cms.untracked.PSet(
    input = cms.untracked.int32(-1)
)

# Input source
process.source = cms.Source("EmptySource",
)
