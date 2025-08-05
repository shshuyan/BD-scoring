import React, { useState } from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from './ui/card';
import { Button } from './ui/button';
import { Input } from './ui/input';
import { Label } from './ui/label';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from './ui/select';
import { Badge } from './ui/badge';
import { Progress } from './ui/progress';
import { Tabs, TabsContent, TabsList, TabsTrigger } from './ui/tabs';
import { 
  Calculator, 
  TrendingUp, 
  BarChart3, 
  Target,
  DollarSign,
  Lightbulb,
  AlertTriangle
} from 'lucide-react';

export function ValuationEngine() {
  const [selectedCompany, setSelectedCompany] = useState('');
  const [valuationMethod, setValuationMethod] = useState('comparable');

  const companies = [
    { id: '1', name: 'BioTech Alpha', score: 4.2, stage: 'Phase II' },
    { id: '2', name: 'Genomics Beta', score: 3.8, stage: 'Phase III' },
    { id: '3', name: 'Neuro Gamma', score: 3.5, stage: 'Phase I' }
  ];

  const valuationScenarios = [
    { scenario: 'Bear Case', probability: 20, valuation: 850, multiple: '6.2x' },
    { scenario: 'Base Case', probability: 50, valuation: 1200, multiple: '8.7x' },
    { scenario: 'Bull Case', probability: 30, valuation: 1650, multiple: '12.1x' }
  ];

  const comparableMetrics = [
    { metric: 'Revenue Multiple', value: '8.7x', benchmark: '7.2x - 12.4x' },
    { metric: 'EBITDA Multiple', value: '15.2x', benchmark: '12.1x - 18.8x' },
    { metric: 'Peak Sales Multiple', value: '3.4x', benchmark: '2.8x - 4.9x' },
    { metric: 'R&D Multiple', value: '12.8x', benchmark: '9.5x - 16.2x' }
  ];

  return (
    <div className="flex-1 space-y-6 p-6">
      <div className="flex items-center justify-between">
        <div>
          <h1>Valuation Engine</h1>
          <p className="text-muted-foreground">
            Generate comprehensive valuations using multiple methodologies
          </p>
        </div>
        <Button>
          <Calculator className="w-4 h-4 mr-2" />
          Run Valuation
        </Button>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Input Panel */}
        <div className="lg:col-span-1 space-y-6">
          <Card>
            <CardHeader>
              <CardTitle>Valuation Inputs</CardTitle>
              <CardDescription>Select company and methodology</CardDescription>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="space-y-2">
                <Label htmlFor="company">Target Company</Label>
                <Select value={selectedCompany} onValueChange={setSelectedCompany}>
                  <SelectTrigger>
                    <SelectValue placeholder="Select company" />
                  </SelectTrigger>
                  <SelectContent>
                    {companies.map((company) => (
                      <SelectItem key={company.id} value={company.id}>
                        {company.name} ({company.stage})
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>

              <div className="space-y-2">
                <Label htmlFor="method">Valuation Method</Label>
                <Select value={valuationMethod} onValueChange={setValuationMethod}>
                  <SelectTrigger>
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="comparable">Comparable Transactions</SelectItem>
                    <SelectItem value="dcf">Discounted Cash Flow</SelectItem>
                    <SelectItem value="riskadjusted">Risk-Adjusted NPV</SelectItem>
                    <SelectItem value="peak-sales">Peak Sales Multiple</SelectItem>
                  </SelectContent>
                </Select>
              </div>

              <div className="space-y-2">
                <Label htmlFor="risk-rate">Risk-Free Rate (%)</Label>
                <Input id="risk-rate" type="number" placeholder="2.5" />
              </div>

              <div className="space-y-2">
                <Label htmlFor="discount-rate">Discount Rate (%)</Label>
                <Input id="discount-rate" type="number" placeholder="12.0" />
              </div>

              <Button className="w-full">
                Calculate Valuation
              </Button>
            </CardContent>
          </Card>

          <Card>
            <CardHeader>
              <CardTitle>Key Assumptions</CardTitle>
            </CardHeader>
            <CardContent className="space-y-3">
              <div className="space-y-2">
                <Label htmlFor="peak-sales">Peak Sales ($M)</Label>
                <Input id="peak-sales" type="number" placeholder="500" />
              </div>
              <div className="space-y-2">
                <Label htmlFor="probability">Success Probability (%)</Label>
                <Input id="probability" type="number" placeholder="65" />
              </div>
              <div className="space-y-2">
                <Label htmlFor="time-to-peak">Time to Peak (Years)</Label>
                <Input id="time-to-peak" type="number" placeholder="8" />
              </div>
            </CardContent>
          </Card>
        </div>

        {/* Results Panel */}
        <div className="lg:col-span-2">
          <Tabs defaultValue="summary" className="w-full">
            <TabsList className="grid w-full grid-cols-4">
              <TabsTrigger value="summary">Summary</TabsTrigger>
              <TabsTrigger value="scenarios">Scenarios</TabsTrigger>
              <TabsTrigger value="comparables">Comparables</TabsTrigger>
              <TabsTrigger value="sensitivity">Sensitivity</TabsTrigger>
            </TabsList>

            <TabsContent value="summary" className="space-y-6">
              <Card>
                <CardHeader>
                  <CardTitle>Valuation Summary</CardTitle>
                  <CardDescription>
                    {selectedCompany ? companies.find(c => c.id === selectedCompany)?.name : 'No company selected'}
                  </CardDescription>
                </CardHeader>
                <CardContent>
                  <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                    <div className="text-center p-6 border rounded-lg">
                      <div className="text-3xl font-bold text-primary mb-2">$1,200M</div>
                      <p className="text-muted-foreground">Base Case Valuation</p>
                      <Badge className="mt-2">8.7x Revenue</Badge>
                    </div>
                    <div className="text-center p-6 border rounded-lg">
                      <div className="text-3xl font-bold text-green-600 mb-2">$850M - $1,650M</div>
                      <p className="text-muted-foreground">Valuation Range</p>
                      <Badge variant="outline" className="mt-2">High Confidence</Badge>
                    </div>
                  </div>

                  <div className="mt-6 space-y-4">
                    <div className="flex justify-between items-center">
                      <span>Recommendation</span>
                      <Badge className="bg-green-100 text-green-800">Strong Buy</Badge>
                    </div>
                    <div className="flex justify-between items-center">
                      <span>Confidence Level</span>
                      <span className="font-medium">82%</span>
                    </div>
                    <div className="flex justify-between items-center">
                      <span>Risk Level</span>
                      <Badge variant="outline">Medium</Badge>
                    </div>
                  </div>
                </CardContent>
              </Card>

              <Card>
                <CardHeader>
                  <CardTitle>Key Value Drivers</CardTitle>
                </CardHeader>
                <CardContent>
                  <div className="space-y-4">
                    <div className="space-y-2">
                      <div className="flex justify-between text-sm">
                        <span>Market Size Impact</span>
                        <span>35%</span>
                      </div>
                      <Progress value={35} className="h-2" />
                    </div>
                    <div className="space-y-2">
                      <div className="flex justify-between text-sm">
                        <span>Competitive Position</span>
                        <span>28%</span>
                      </div>
                      <Progress value={28} className="h-2" />
                    </div>
                    <div className="space-y-2">
                      <div className="flex justify-between text-sm">
                        <span>Development Risk</span>
                        <span>22%</span>
                      </div>
                      <Progress value={22} className="h-2" />
                    </div>
                    <div className="space-y-2">
                      <div className="flex justify-between text-sm">
                        <span>Regulatory Timeline</span>
                        <span>15%</span>
                      </div>
                      <Progress value={15} className="h-2" />
                    </div>
                  </div>
                </CardContent>
              </Card>
            </TabsContent>

            <TabsContent value="scenarios" className="space-y-6">
              <Card>
                <CardHeader>
                  <CardTitle>Scenario Analysis</CardTitle>
                  <CardDescription>Probability-weighted valuation scenarios</CardDescription>
                </CardHeader>
                <CardContent>
                  <div className="space-y-4">
                    {valuationScenarios.map((scenario, index) => (
                      <div key={index} className="border rounded-lg p-4">
                        <div className="flex items-center justify-between mb-2">
                          <div className="flex items-center gap-3">
                            <Badge variant={
                              scenario.scenario === 'Bull Case' ? 'default' :
                              scenario.scenario === 'Base Case' ? 'secondary' : 'outline'
                            }>
                              {scenario.scenario}
                            </Badge>
                            <span className="text-sm text-muted-foreground">
                              {scenario.probability}% probability
                            </span>
                          </div>
                          <div className="text-right">
                            <div className="font-semibold">${scenario.valuation}M</div>
                            <div className="text-sm text-muted-foreground">{scenario.multiple}</div>
                          </div>
                        </div>
                        <Progress value={scenario.probability * 5} className="h-2" />
                      </div>
                    ))}
                  </div>

                  <div className="mt-6 p-4 bg-muted rounded-lg">
                    <div className="flex items-center gap-2 mb-2">
                      <Target className="w-5 h-5" />
                      <span className="font-medium">Expected Value</span>
                    </div>
                    <div className="text-2xl font-bold">$1,245M</div>
                    <p className="text-sm text-muted-foreground">
                      Probability-weighted average valuation
                    </p>
                  </div>
                </CardContent>
              </Card>
            </TabsContent>

            <TabsContent value="comparables" className="space-y-6">
              <Card>
                <CardHeader>
                  <CardTitle>Comparable Multiples</CardTitle>
                  <CardDescription>Benchmarking against similar transactions</CardDescription>
                </CardHeader>
                <CardContent>
                  <div className="space-y-4">
                    {comparableMetrics.map((metric, index) => (
                      <div key={index} className="flex items-center justify-between p-3 border rounded-lg">
                        <div>
                          <p className="font-medium">{metric.metric}</p>
                          <p className="text-sm text-muted-foreground">Industry Range: {metric.benchmark}</p>
                        </div>
                        <div className="text-right">
                          <div className="font-semibold text-lg">{metric.value}</div>
                          <Badge variant="outline" className="text-xs">Within Range</Badge>
                        </div>
                      </div>
                    ))}
                  </div>
                </CardContent>
              </Card>
            </TabsContent>

            <TabsContent value="sensitivity" className="space-y-6">
              <Card>
                <CardHeader>
                  <CardTitle>Sensitivity Analysis</CardTitle>
                  <CardDescription>Impact of key variables on valuation</CardDescription>
                </CardHeader>
                <CardContent>
                  <div className="space-y-6">
                    <div className="space-y-3">
                      <div className="flex justify-between">
                        <span className="font-medium">Peak Sales Sensitivity</span>
                        <span className="text-sm text-muted-foreground">±20% impact</span>
                      </div>
                      <div className="grid grid-cols-3 gap-2 text-sm">
                        <div className="text-center p-2 border rounded">
                          <div className="font-medium">$400M</div>
                          <div className="text-muted-foreground">$960M</div>
                        </div>
                        <div className="text-center p-2 border rounded bg-primary/10">
                          <div className="font-medium">$500M</div>
                          <div className="text-muted-foreground">$1,200M</div>
                        </div>
                        <div className="text-center p-2 border rounded">
                          <div className="font-medium">$600M</div>
                          <div className="text-muted-foreground">$1,440M</div>
                        </div>
                      </div>
                    </div>

                    <div className="space-y-3">
                      <div className="flex justify-between">
                        <span className="font-medium">Success Probability Sensitivity</span>
                        <span className="text-sm text-muted-foreground">±15% impact</span>
                      </div>
                      <div className="grid grid-cols-3 gap-2 text-sm">
                        <div className="text-center p-2 border rounded">
                          <div className="font-medium">50%</div>
                          <div className="text-muted-foreground">$920M</div>
                        </div>
                        <div className="text-center p-2 border rounded bg-primary/10">
                          <div className="font-medium">65%</div>
                          <div className="text-muted-foreground">$1,200M</div>
                        </div>
                        <div className="text-center p-2 border rounded">
                          <div className="font-medium">80%</div>
                          <div className="text-muted-foreground">$1,480M</div>
                        </div>
                      </div>
                    </div>
                  </div>
                </CardContent>
              </Card>
            </TabsContent>
          </Tabs>
        </div>
      </div>
    </div>
  );
}