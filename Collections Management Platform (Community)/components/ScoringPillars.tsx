import React, { useState } from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from './ui/card';
import { Button } from './ui/button';
import { Badge } from './ui/badge';
import { Progress } from './ui/progress';
import { Tabs, TabsContent, TabsList, TabsTrigger } from './ui/tabs';
import { Slider } from './ui/slider';
import { Switch } from './ui/switch';
import { Label } from './ui/label';
import { 
  Target, 
  TrendingUp, 
  DollarSign, 
  Users, 
  CreditCard, 
  Shield,
  Settings,
  Info,
  ChevronRight
} from 'lucide-react';

export function ScoringPillars() {
  const [selectedPillar, setSelectedPillar] = useState<string | null>(null);

  const pillars = [
    {
      id: 'asset-quality',
      name: 'Asset Quality',
      icon: Target,
      weight: 25,
      description: 'Evaluates pipeline strength, development stage, and competitive positioning',
      metrics: [
        { name: 'Pipeline Strength', weight: 40, enabled: true },
        { name: 'IP Portfolio', weight: 30, enabled: true },
        { name: 'Competitive Position', weight: 20, enabled: true },
        { name: 'Differentiation', weight: 10, enabled: true }
      ],
      averageScore: 4.2,
      companies: 247
    },
    {
      id: 'market-outlook',
      name: 'Market Outlook',
      icon: TrendingUp,
      weight: 20,
      description: 'Analyzes addressable market size, growth potential, and competitive landscape',
      metrics: [
        { name: 'Market Size', weight: 35, enabled: true },
        { name: 'Growth Rate', weight: 25, enabled: true },
        { name: 'Competition', weight: 25, enabled: true },
        { name: 'Market Access', weight: 15, enabled: true }
      ],
      averageScore: 3.8,
      companies: 247
    },
    {
      id: 'capital-intensity',
      name: 'Capital Intensity',
      icon: DollarSign,
      weight: 15,
      description: 'Assesses development costs, capital requirements, and scalability',
      metrics: [
        { name: 'Development Costs', weight: 40, enabled: true },
        { name: 'Manufacturing', weight: 30, enabled: true },
        { name: 'Clinical Trials', weight: 20, enabled: true },
        { name: 'Scalability', weight: 10, enabled: true }
      ],
      averageScore: 3.5,
      companies: 247
    },
    {
      id: 'strategic-fit',
      name: 'Strategic Fit',
      icon: Users,
      weight: 20,
      description: 'Analyzes alignment with acquirer capabilities and synergy potential',
      metrics: [
        { name: 'Capability Alignment', weight: 35, enabled: true },
        { name: 'Synergy Potential', weight: 30, enabled: true },
        { name: 'Integration Risk', weight: 20, enabled: true },
        { name: 'Geographic Fit', weight: 15, enabled: true }
      ],
      averageScore: 4.0,
      companies: 247
    },
    {
      id: 'financial-readiness',
      name: 'Financial Readiness',
      icon: CreditCard,
      weight: 10,
      description: 'Evaluates financial position, funding needs, and management quality',
      metrics: [
        { name: 'Cash Position', weight: 40, enabled: true },
        { name: 'Burn Rate', weight: 25, enabled: true },
        { name: 'Funding History', weight: 20, enabled: true },
        { name: 'Financial Management', weight: 15, enabled: true }
      ],
      averageScore: 3.2,
      companies: 247
    },
    {
      id: 'regulatory-risk',
      name: 'Regulatory Risk',
      icon: Shield,
      weight: 10,
      description: 'Assesses regulatory pathway complexity, timeline, and compliance risks',
      metrics: [
        { name: 'Pathway Complexity', weight: 35, enabled: true },
        { name: 'Timeline Risk', weight: 30, enabled: true },
        { name: 'Safety Profile', weight: 20, enabled: true },
        { name: 'Precedent Analysis', weight: 15, enabled: true }
      ],
      averageScore: 3.7,
      companies: 247
    }
  ];

  const renderPillarOverview = () => (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1>Scoring Pillars</h1>
          <p className="text-muted-foreground">
            Configure and analyze the six key evaluation criteria for biotech companies
          </p>
        </div>
        <Button>
          <Settings className="w-4 h-4 mr-2" />
          Configure Weights
        </Button>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        {pillars.map((pillar) => {
          const Icon = pillar.icon;
          return (
            <Card 
              key={pillar.id} 
              className="cursor-pointer hover:shadow-md transition-all"
              onClick={() => setSelectedPillar(pillar.id)}
            >
              <CardHeader>
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-3">
                    <div className="w-10 h-10 bg-primary/10 rounded-lg flex items-center justify-center">
                      <Icon className="w-5 h-5 text-primary" />
                    </div>
                    <div>
                      <CardTitle className="text-lg">{pillar.name}</CardTitle>
                      <Badge variant="outline">{pillar.weight}% weight</Badge>
                    </div>
                  </div>
                  <ChevronRight className="w-5 h-5 text-muted-foreground" />
                </div>
                <CardDescription className="mt-2">
                  {pillar.description}
                </CardDescription>
              </CardHeader>
              <CardContent>
                <div className="space-y-3">
                  <div className="flex items-center justify-between">
                    <span className="text-sm font-medium">Average Score</span>
                    <span className="text-lg font-bold">{pillar.averageScore}/5.0</span>
                  </div>
                  <Progress value={pillar.averageScore * 20} className="h-2" />
                  <div className="text-xs text-muted-foreground">
                    Based on {pillar.companies} companies
                  </div>
                </div>
              </CardContent>
            </Card>
          );
        })}
      </div>

      <Card>
        <CardHeader>
          <CardTitle>Weight Distribution</CardTitle>
          <CardDescription>Current allocation across all scoring pillars</CardDescription>
        </CardHeader>
        <CardContent>
          <div className="space-y-4">
            {pillars.map((pillar) => (
              <div key={pillar.id} className="space-y-2">
                <div className="flex justify-between text-sm">
                  <span>{pillar.name}</span>
                  <span>{pillar.weight}%</span>
                </div>
                <Progress value={pillar.weight * 4} className="h-2" />
              </div>
            ))}
          </div>
        </CardContent>
      </Card>
    </div>
  );

  const renderPillarDetails = () => {
    const pillar = pillars.find(p => p.id === selectedPillar);
    if (!pillar) return null;

    const Icon = pillar.icon;

    return (
      <div className="space-y-6">
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-3">
            <Button variant="outline" onClick={() => setSelectedPillar(null)}>
              ← Back
            </Button>
            <div className="w-10 h-10 bg-primary/10 rounded-lg flex items-center justify-center">
              <Icon className="w-5 h-5 text-primary" />
            </div>
            <div>
              <h1>{pillar.name}</h1>
              <p className="text-muted-foreground">{pillar.description}</p>
            </div>
          </div>
          <Badge variant="outline" className="text-lg px-4 py-2">
            {pillar.weight}% weight
          </Badge>
        </div>

        <Tabs defaultValue="configuration" className="w-full">
          <TabsList>
            <TabsTrigger value="configuration">Configuration</TabsTrigger>
            <TabsTrigger value="analytics">Analytics</TabsTrigger>
            <TabsTrigger value="benchmarks">Benchmarks</TabsTrigger>
          </TabsList>

          <TabsContent value="configuration" className="space-y-6">
            <Card>
              <CardHeader>
                <CardTitle>Metric Configuration</CardTitle>
                <CardDescription>Adjust weights and enable/disable metrics for this pillar</CardDescription>
              </CardHeader>
              <CardContent className="space-y-6">
                {pillar.metrics.map((metric, index) => (
                  <div key={index} className="space-y-3">
                    <div className="flex items-center justify-between">
                      <div className="flex items-center gap-3">
                        <Switch checked={metric.enabled} />
                        <Label className="font-medium">{metric.name}</Label>
                      </div>
                      <span className="text-sm text-muted-foreground">{metric.weight}%</span>
                    </div>
                    <Slider
                      value={[metric.weight]}
                      max={100}
                      step={5}
                      className="w-full"
                      disabled={!metric.enabled}
                    />
                  </div>
                ))}
              </CardContent>
            </Card>

            <Card>
              <CardHeader>
                <CardTitle>Scoring Criteria</CardTitle>
                <CardDescription>Define the evaluation criteria for each score level</CardDescription>
              </CardHeader>
              <CardContent>
                <div className="space-y-4">
                  {[5, 4, 3, 2, 1].map((score) => (
                    <div key={score} className="border rounded-lg p-4">
                      <div className="flex items-center gap-3 mb-2">
                        <Badge variant={score >= 4 ? 'default' : score >= 3 ? 'secondary' : 'destructive'}>
                          Score: {score}
                        </Badge>
                        <span className="font-medium">
                          {score === 5 && 'Excellent'}
                          {score === 4 && 'Good'}
                          {score === 3 && 'Average'}
                          {score === 2 && 'Below Average'}
                          {score === 1 && 'Poor'}
                        </span>
                      </div>
                      <p className="text-sm text-muted-foreground">
                        Define criteria for score level {score}...
                      </p>
                    </div>
                  ))}
                </div>
              </CardContent>
            </Card>
          </TabsContent>

          <TabsContent value="analytics" className="space-y-6">
            <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
              <Card>
                <CardHeader className="pb-2">
                  <CardTitle className="text-base">Average Score</CardTitle>
                </CardHeader>
                <CardContent>
                  <div className="text-2xl font-bold">{pillar.averageScore}</div>
                  <p className="text-xs text-muted-foreground">Across all companies</p>
                </CardContent>
              </Card>
              <Card>
                <CardHeader className="pb-2">
                  <CardTitle className="text-base">Standard Deviation</CardTitle>
                </CardHeader>
                <CardContent>
                  <div className="text-2xl font-bold">0.73</div>
                  <p className="text-xs text-muted-foreground">Score variability</p>
                </CardContent>
              </Card>
              <Card>
                <CardHeader className="pb-2">
                  <CardTitle className="text-base">Correlation</CardTitle>
                </CardHeader>
                <CardContent>
                  <div className="text-2xl font-bold">0.67</div>
                  <p className="text-xs text-muted-foreground">With overall score</p>
                </CardContent>
              </Card>
            </div>

            <Card>
              <CardHeader>
                <CardTitle>Score Distribution</CardTitle>
              </CardHeader>
              <CardContent>
                <div className="space-y-4">
                  {[
                    { range: '4.5 - 5.0', count: 42, percentage: 17 },
                    { range: '4.0 - 4.5', count: 74, percentage: 30 },
                    { range: '3.5 - 4.0', count: 86, percentage: 35 },
                    { range: '3.0 - 3.5', count: 32, percentage: 13 },
                    { range: '2.5 - 3.0', count: 10, percentage: 4 },
                    { range: '< 2.5', count: 3, percentage: 1 }
                  ].map((dist, index) => (
                    <div key={index} className="flex items-center gap-4">
                      <div className="w-20 text-sm">{dist.range}</div>
                      <div className="flex-1">
                        <Progress value={dist.percentage * 4} className="h-2" />
                      </div>
                      <div className="w-16 text-sm text-right">{dist.count} cos.</div>
                      <div className="w-12 text-sm text-right text-muted-foreground">{dist.percentage}%</div>
                    </div>
                  ))}
                </div>
              </CardContent>
            </Card>
          </TabsContent>

          <TabsContent value="benchmarks" className="space-y-6">
            <Card>
              <CardHeader>
                <CardTitle>Industry Benchmarks</CardTitle>
                <CardDescription>Compare scores across different therapeutic areas</CardDescription>
              </CardHeader>
              <CardContent>
                <div className="space-y-4">
                  {[
                    { area: 'Oncology', score: 4.1, companies: 89 },
                    { area: 'Rare Disease', score: 4.3, companies: 42 },
                    { area: 'CNS', score: 3.6, companies: 35 },
                    { area: 'Cardiovascular', score: 3.9, companies: 28 },
                    { area: 'Immunology', score: 4.0, companies: 53 }
                  ].map((benchmark, index) => (
                    <div key={index} className="flex items-center justify-between p-3 border rounded-lg">
                      <div>
                        <p className="font-medium">{benchmark.area}</p>
                        <p className="text-sm text-muted-foreground">{benchmark.companies} companies</p>
                      </div>
                      <div className="text-right">
                        <p className="font-semibold">{benchmark.score}/5.0</p>
                        <Progress value={benchmark.score * 20} className="w-24 h-2" />
                      </div>
                    </div>
                  ))}
                </div>
              </CardContent>
            </Card>
          </TabsContent>
        </Tabs>
      </div>
    );
  };

  return (
    <div className="flex-1 p-6">
      {!selectedPillar && renderPillarOverview()}
      {selectedPillar && renderPillarDetails()}
    </div>
  );
}