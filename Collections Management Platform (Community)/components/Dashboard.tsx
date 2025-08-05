import React from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from './ui/card';
import { Badge } from './ui/badge';
import { Button } from './ui/button';
import { Progress } from './ui/progress';
import { 
  Building2, 
  TrendingUp, 
  DollarSign, 
  Target, 
  Clock, 
  AlertTriangle,
  CheckCircle,
  FileText
} from 'lucide-react';

export function Dashboard() {
  const recentEvaluations = [
    {
      id: 1,
      name: "BioTech Alpha",
      stage: "Phase II",
      score: 4.2,
      status: "completed",
      indication: "Oncology",
      lastUpdated: "2 hours ago"
    },
    {
      id: 2,
      name: "Genomics Beta",
      stage: "Phase III",
      score: 3.8,
      status: "in-progress",
      indication: "Rare Disease",
      lastUpdated: "1 day ago"
    },
    {
      id: 3,
      name: "Neuro Gamma",
      stage: "Phase I",
      score: 3.5,
      status: "completed",
      indication: "CNS",
      lastUpdated: "3 days ago"
    }
  ];

  const upcomingDeadlines = [
    { company: "BioTech Alpha", task: "Due Diligence Report", dueIn: "2 days" },
    { company: "Pharma Delta", task: "Valuation Update", dueIn: "5 days" },
    { company: "Gene Epsilon", task: "Competitive Analysis", dueIn: "1 week" }
  ];

  return (
    <div className="flex-1 space-y-6 p-6">
      <div className="flex items-center justify-between">
        <div>
          <h1>Dashboard</h1>
          <p className="text-muted-foreground">
            Overview of biotech investment opportunities and scoring metrics
          </p>
        </div>
        <Button>
          <Building2 className="w-4 h-4 mr-2" />
          New Evaluation
        </Button>
      </div>

      {/* Key Metrics */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Total Companies</CardTitle>
            <Building2 className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">247</div>
            <p className="text-xs text-muted-foreground">
              +12 from last month
            </p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Average Score</CardTitle>
            <Target className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">3.84</div>
            <p className="text-xs text-muted-foreground">
              +0.15 from last quarter
            </p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Deal Value</CardTitle>
            <DollarSign className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">$2.4B</div>
            <p className="text-xs text-muted-foreground">
              Active pipeline value
            </p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Success Rate</CardTitle>
            <TrendingUp className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">68%</div>
            <p className="text-xs text-muted-foreground">
              Recommendations approved
            </p>
          </CardContent>
        </Card>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Recent Evaluations */}
        <Card>
          <CardHeader>
            <CardTitle>Recent Evaluations</CardTitle>
            <CardDescription>Latest company scoring results</CardDescription>
          </CardHeader>
          <CardContent>
            <div className="space-y-4">
              {recentEvaluations.map((evaluation) => (
                <div key={evaluation.id} className="flex items-center justify-between p-3 border rounded-lg">
                  <div className="flex items-center gap-3">
                    <div className="w-2 h-2 rounded-full bg-primary"></div>
                    <div>
                      <p className="font-medium">{evaluation.name}</p>
                      <div className="flex items-center gap-2 text-sm text-muted-foreground">
                        <Badge variant="outline" className="text-xs">
                          {evaluation.stage}
                        </Badge>
                        <span>{evaluation.indication}</span>
                      </div>
                    </div>
                  </div>
                  <div className="text-right">
                    <div className="flex items-center gap-2">
                      <span className="text-lg font-semibold">{evaluation.score}</span>
                      {evaluation.status === 'completed' ? (
                        <CheckCircle className="w-4 h-4 text-green-500" />
                      ) : (
                        <Clock className="w-4 h-4 text-yellow-500" />
                      )}
                    </div>
                    <p className="text-xs text-muted-foreground">{evaluation.lastUpdated}</p>
                  </div>
                </div>
              ))}
            </div>
          </CardContent>
        </Card>

        {/* Scoring Distribution */}
        <Card>
          <CardHeader>
            <CardTitle>Scoring Distribution</CardTitle>
            <CardDescription>Company scores across evaluation criteria</CardDescription>
          </CardHeader>
          <CardContent>
            <div className="space-y-4">
              <div className="space-y-2">
                <div className="flex justify-between text-sm">
                  <span>Asset Quality</span>
                  <span>4.1/5.0</span>
                </div>
                <Progress value={82} className="h-2" />
              </div>
              <div className="space-y-2">
                <div className="flex justify-between text-sm">
                  <span>Market Outlook</span>
                  <span>3.8/5.0</span>
                </div>
                <Progress value={76} className="h-2" />
              </div>
              <div className="space-y-2">
                <div className="flex justify-between text-sm">
                  <span>Financial Readiness</span>
                  <span>3.5/5.0</span>
                </div>
                <Progress value={70} className="h-2" />
              </div>
              <div className="space-y-2">
                <div className="flex justify-between text-sm">
                  <span>Strategic Fit</span>
                  <span>4.0/5.0</span>
                </div>
                <Progress value={80} className="h-2" />
              </div>
              <div className="space-y-2">
                <div className="flex justify-between text-sm">
                  <span>Regulatory Risk</span>
                  <span>3.2/5.0</span>
                </div>
                <Progress value={64} className="h-2" />
              </div>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Upcoming Deadlines and Quick Actions */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <Card>
          <CardHeader>
            <CardTitle>Upcoming Deadlines</CardTitle>
            <CardDescription>Reports and tasks requiring attention</CardDescription>
          </CardHeader>
          <CardContent>
            <div className="space-y-3">
              {upcomingDeadlines.map((deadline, index) => (
                <div key={index} className="flex items-center justify-between p-3 border rounded-lg">
                  <div className="flex items-center gap-3">
                    <AlertTriangle className="w-4 h-4 text-yellow-500" />
                    <div>
                      <p className="font-medium">{deadline.task}</p>
                      <p className="text-sm text-muted-foreground">{deadline.company}</p>
                    </div>
                  </div>
                  <Badge variant="outline">
                    {deadline.dueIn}
                  </Badge>
                </div>
              ))}
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle>Quick Actions</CardTitle>
            <CardDescription>Common tasks and shortcuts</CardDescription>
          </CardHeader>
          <CardContent>
            <div className="grid grid-cols-2 gap-3">
              <Button variant="outline" className="h-20 flex flex-col gap-2">
                <Building2 className="w-6 h-6" />
                <span className="text-sm">New Company</span>
              </Button>
              <Button variant="outline" className="h-20 flex flex-col gap-2">
                <FileText className="w-6 h-6" />
                <span className="text-sm">Generate Report</span>
              </Button>
              <Button variant="outline" className="h-20 flex flex-col gap-2">
                <Target className="w-6 h-6" />
                <span className="text-sm">Score Review</span>
              </Button>
              <Button variant="outline" className="h-20 flex flex-col gap-2">
                <DollarSign className="w-6 h-6" />
                <span className="text-sm">Valuation</span>
              </Button>
            </div>
          </CardContent>
        </Card>
      </div>
    </div>
  );
}