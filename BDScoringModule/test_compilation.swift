import Foundation

// Simple compilation test
func testWeightingEngine() {
    let engine = BDWeightingEngine()
    let weights = WeightConfig()
    
    // Create sample pillar scores
    let pillarScores = PillarScores(
        assetQuality: PillarScore(rawScore: 4.0, confidence: 0.8, factors: [], warnings: []),
        marketOutlook: PillarScore(rawScore: 3.5, confidence: 0.7, factors: [], warnings: []),
        capitalIntensity: PillarScore(rawScore: 2.5, confidence: 0.9, factors: [], warnings: []),
        strategicFit: PillarScore(rawScore: 4.5, confidence: 0.85, factors: [], warnings: []),
        financialReadiness: PillarScore(rawScore: 3.0, confidence: 0.6, factors: [], warnings: []),
        regulatoryRisk: PillarScore(rawScore: 3.8, confidence: 0.75, factors: [], warnings: [])
    )
    
    let weightedScores = engine.applyWeights(pillarScores, weights: weights)
    print("Total weighted score: \(weightedScores.total)")
}