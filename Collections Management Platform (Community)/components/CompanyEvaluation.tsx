import React, { useState } from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from './ui/card';
import { Button } from './ui/button';
import { Input } from './ui/input';
import { Label } from './ui/label';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from './ui/select';
import { Textarea } from './ui/textarea';
import { Badge } from './ui/badge';
import { Progress } from './ui/progress';
import { Tabs, TabsContent, TabsList, TabsTrigger } from './ui/tabs';
import { 
  Building2, 
  Plus, 
  Search, 
  Filter,
  Star,
  TrendingUp,
  Calculator,
  FileText,
  AlertCircle
} from 'lucide-react';

export function CompanyEvaluation() {
  const [selectedCompany, setSelectedCompany] = useState<string | null>(null);
  const [evaluationStep, setEvaluationStep] = useState('basic-info');

  const companies = [
    { 
      id: '1', 
      name: 'BioTech Alpha', 
      stage: 'Phase II', 
      indication: 'Oncology',
      lastScore: 4.2,
      status: 'completed' 
    },
    { 
      id: '2', 
      name: 'Genomics Beta', 
      stage: 'Phase III', 
      indication: 'Rare Disease',
      lastScore: 3.8,
      status: 'in-progress' 
    },
    { 
      id: '3', 
      name: 'Neuro Gamma', 
      stage: 'Phase I', 
      indication: 'CNS',
      lastScore: null,
      status: 'new' 
    }
  ];

  const scoringPillars = [
    { name: 'Asset Quality', score: 4.2, weight: 25, confidence: 0.85 },
    { name: 'Market Outlook', score: 3.8, weight: 20, confidence: 0.78 },
    { name: 'Capital Intensity', score: 3.5, weight: 15, confidence: 0.82 },
    { name: 'Strategic Fit', score: 4.0, weight: 20, confidence: 0.90 },
    { name: 'Financial Readiness', score: 3.2, weight: 10, confidence: 0.75 },
    { name: 'Regulatory Risk', score: 3.7, weight: 10, confidence: 0.80 }
  ];

  const renderCompanySelection = () => (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h2>Select Company</h2>
          <p className="text-muted-foreground">Choose a company to evaluate or create a new evaluation</p>
        </div>
        <Button>
          <Plus className="w-4 h-4 mr-2" />
          New Company
        </Button>
      </div>

      <div className="flex gap-4">
        <div className="flex-1 relative">
          <Search className="absolute left-3 top-3 h-4 w-4 text-muted-foreground" />
          <Input placeholder="Search companies..." className="pl-10" />
        </div>
        <Button variant="outline">
          <Filter className="w-4 h-4 mr-2" />
          Filter
        </Button>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
        {companies.map((company) => (
          <Card 
            key={company.id} 
            className={`cursor-pointer transition-all hover:shadow-md ${
              selectedCompany === company.id ? 'ring-2 ring-primary' : ''
            }`}
            onClick={() => setSelectedCompany(company.id)}
          >
            <CardHeader className="pb-2">
              <div className="flex items-center justify-between">
                <CardTitle className="text-lg">{company.name}</CardTitle>
                <Badge variant={
                  company.status === 'completed' ? 'default' :
                  company.status === 'in-progress' ? 'secondary' : 'outline'
                }>
                  {company.status}
                </Badge>
              </div>
              <CardDescription>{company.indication} • {company.stage}</CardDescription>
            </CardHeader>
            <CardContent>
              {company.lastScore ? (
                <div className="flex items-center gap-2">
                  <Star className="w-4 h-4 text-yellow-500" />
                  <span className="font-semibold">{company.lastScore}/5.0</span>
                  <span className="text-sm text-muted-foreground">Overall Score</span>
                </div>
              ) : (
                <div className="flex items-center gap-2 text-muted-foreground">
                  <AlertCircle className="w-4 h-4" />
                  <span className="text-sm">No evaluation yet</span>
                </div>
              )}
            </CardContent>
          </Card>
        ))}
      </div>

      {selectedCompany && (
        <div className="flex justify-end">
          <Button onClick={() => setEvaluationStep('basic-info')}>
            Continue Evaluation
          </Button>
        </div>
      )}
    </div>
  );

  const renderBasicInfo = () => (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h2>Basic Information</h2>
          <p className="text-muted-foreground">Enter fundamental company details</p>
        </div>
        <Button variant="outline" onClick={() => setSelectedCompany(null)}>
          Back to Selection
        </Button>
      </div>

      <Card>
        <CardHeader>
          <CardTitle>Company Details</CardTitle>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div className="space-y-2">
              <Label htmlFor="company-name">Company Name</Label>
              <Input id="company-name" placeholder="Enter company name" />
            </div>
            <div className="space-y-2">
              <Label htmlFor="ticker">Ticker Symbol</Label>
              <Input id="ticker" placeholder="Optional ticker symbol" />
            </div>
            <div className="space-y-2">
              <Label htmlFor="stage">Development Stage</Label>
              <Select>
                <SelectTrigger>
                  <SelectValue placeholder="Select stage" />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="preclinical">Preclinical</SelectItem>
                  <SelectItem value="phase1">Phase I</SelectItem>
                  <SelectItem value="phase2">Phase II</SelectItem>
                  <SelectItem value="phase3">Phase III</SelectItem>
                  <SelectItem value="approved">Approved</SelectItem>
                </SelectContent>
              </Select>
            </div>
            <div className="space-y-2">
              <Label htmlFor="therapeutic-area">Therapeutic Area</Label>
              <Select>
                <SelectTrigger>
                  <SelectValue placeholder="Select area" />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="oncology">Oncology</SelectItem>
                  <SelectItem value="rare-disease">Rare Disease</SelectItem>
                  <SelectItem value="cns">CNS</SelectItem>
                  <SelectItem value="cardiovascular">Cardiovascular</SelectItem>
                  <SelectItem value="immunology">Immunology</SelectItem>
                </SelectContent>
              </Select>
            </div>
          </div>
          <div className="space-y-2">
            <Label htmlFor="description">Company Description</Label>
            <Textarea id="description" placeholder="Brief description of the company and its focus areas" />
          </div>
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <CardTitle>Financial Information</CardTitle>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
            <div className="space-y-2">
              <Label htmlFor="cash-position">Cash Position ($M)</Label>
              <Input id="cash-position" type="number" placeholder="Current cash" />
            </div>
            <div className="space-y-2">
              <Label htmlFor="burn-rate">Monthly Burn Rate ($M)</Label>
              <Input id="burn-rate" type="number" placeholder="Monthly burn" />
            </div>
            <div className="space-y-2">
              <Label htmlFor="runway">Runway (Months)</Label>
              <Input id="runway" type="number" placeholder="Calculated runway" disabled />
            </div>
          </div>
        </CardContent>
      </Card>

      <div className="flex justify-end">
        <Button onClick={() => setEvaluationStep('scoring')}>
          Continue to Scoring
        </Button>
      </div>
    </div>
  );

  const renderScoring = () => (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h2>Scoring Evaluation</h2>
          <p className="text-muted-foreground">Assess the company across all scoring pillars</p>
        </div>
        <div className="flex gap-2">
          <Button variant="outline" onClick={() => setEvaluationStep('basic-info')}>
            Back
          </Button>
          <Button>
            <Calculator className="w-4 h-4 mr-2" />
            Calculate Score
          </Button>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <div className="space-y-4">
          {scoringPillars.map((pillar, index) => (
            <Card key={index}>
              <CardHeader className="pb-2">
                <div className="flex items-center justify-between">
                  <CardTitle className="text-base">{pillar.name}</CardTitle>
                  <Badge variant="outline">{pillar.weight}% weight</Badge>
                </div>
              </CardHeader>
              <CardContent>
                <div className="space-y-3">
                  <div className="flex items-center justify-between">
                    <span className="text-sm">Score: {pillar.score}/5.0</span>
                    <span className="text-sm text-muted-foreground">
                      Confidence: {Math.round(pillar.confidence * 100)}%
                    </span>
                  </div>
                  <Progress value={pillar.score * 20} className="h-2" />
                  <Button variant="outline" size="sm" className="w-full">
                    Review Details
                  </Button>
                </div>
              </CardContent>
            </Card>
          ))}
        </div>

        <Card>
          <CardHeader>
            <CardTitle>Overall Assessment</CardTitle>
            <CardDescription>Comprehensive evaluation summary</CardDescription>
          </CardHeader>
          <CardContent>
            <div className="space-y-6">
              <div className="text-center">
                <div className="text-4xl font-bold text-primary mb-2">3.84</div>
                <p className="text-muted-foreground">Overall Score</p>
                <Progress value={76.8} className="mt-4" />
              </div>

              <div className="space-y-4">
                <div className="flex justify-between items-center">
                  <span>Investment Recommendation</span>
                  <Badge className="bg-green-100 text-green-800">Strong Buy</Badge>
                </div>
                <div className="flex justify-between items-center">
                  <span>Risk Level</span>
                  <Badge variant="outline">Medium</Badge>
                </div>
                <div className="flex justify-between items-center">
                  <span>Confidence Level</span>
                  <span className="font-medium">82%</span>
                </div>
              </div>

              <div className="pt-4 border-t">
                <h4 className="font-medium mb-2">Key Strengths</h4>
                <ul className="text-sm text-muted-foreground space-y-1">
                  <li>• Strong intellectual property portfolio</li>
                  <li>• Large addressable market opportunity</li>
                  <li>• Experienced management team</li>
                </ul>
              </div>

              <div className="pt-4 border-t">
                <h4 className="font-medium mb-2">Areas of Concern</h4>
                <ul className="text-sm text-muted-foreground space-y-1">
                  <li>• Limited cash runway</li>
                  <li>• Competitive landscape intensity</li>
                  <li>• Regulatory pathway uncertainty</li>
                </ul>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>

      <div className="flex justify-end gap-2">
        <Button variant="outline">
          <FileText className="w-4 h-4 mr-2" />
          Generate Report
        </Button>
        <Button>
          Save Evaluation
        </Button>
      </div>
    </div>
  );

  return (
    <div className="flex-1 p-6">
      {!selectedCompany && renderCompanySelection()}
      {selectedCompany && evaluationStep === 'basic-info' && renderBasicInfo()}
      {selectedCompany && evaluationStep === 'scoring' && renderScoring()}
    </div>
  );
}