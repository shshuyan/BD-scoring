import React, { useState } from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from './ui/card';
import { Button } from './ui/button';
import { Badge } from './ui/badge';
import { Progress } from './ui/progress';
import { Tabs, TabsContent, TabsList, TabsTrigger } from './ui/tabs';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from './ui/select';
import { 
  FileText, 
  Download, 
  Share2, 
  BarChart3, 
  PieChart, 
  TrendingUp,
  Calendar,
  Filter,
  Eye
} from 'lucide-react';

export function ReportsAnalytics() {
  const [selectedTimeframe, setSelectedTimeframe] = useState('last-quarter');
  
  const reports = [
    {
      id: 1,
      title: "BioTech Alpha - Investment Analysis",
      type: "Executive Summary",
      status: "completed",
      score: 4.2,
      recommendation: "Strong Buy",
      created: "2024-01-15",
      company: "BioTech Alpha"
    },
    {
      id: 2,
      title: "Q1 2024 Portfolio Review",
      type: "Portfolio Analysis",
      status: "completed",
      score: 3.8,
      recommendation: "Mixed",
      created: "2024-01-10",
      company: "Multiple"
    },
    {
      id: 3,
      title: "Genomics Beta - Due Diligence",
      type: "Detailed Report",
      status: "draft",
      score: 3.6,
      recommendation: "Hold",
      created: "2024-01-08",
      company: "Genomics Beta"
    }
  ];

  const analyticsData = [
    { metric: "Total Evaluations", value: "247", change: "+12", trend: "up" },
    { metric: "Average Score", value: "3.84", change: "+0.15", trend: "up" },
    { metric: "Strong Buy Rate", value: "32%", change: "+5%", trend: "up" },
    { metric: "Success Accuracy", value: "68%", change: "+3%", trend: "up" }
  ];

  const scoreDistribution = [
    { range: "4.5 - 5.0", count: 42, percentage: 17, color: "bg-green-500" },
    { range: "4.0 - 4.5", count: 74, percentage: 30, color: "bg-green-400" },
    { range: "3.5 - 4.0", count: 86, percentage: 35, color: "bg-yellow-400" },
    { range: "3.0 - 3.5", count: 32, percentage: 13, color: "bg-orange-400" },
    { range: "< 3.0", count: 13, percentage: 5, color: "bg-red-400" }
  ];

  const therapeuticBreakdown = [
    { area: "Oncology", count: 89, percentage: 36, avgScore: 4.1 },
    { area: "Rare Disease", count: 42, percentage: 17, avgScore: 4.3 },
    { area: "CNS", count: 35, percentage: 14, avgScore: 3.6 },
    { area: "Immunology", count: 53, percentage: 21, avgScore: 4.0 },
    { area: "Other", count: 28, percentage: 11, avgScore: 3.8 }
  ];

  return (
    <div className="flex-1 space-y-6 p-6">
      <div className="flex items-center justify-between">
        <div>
          <h1>Reports & Analytics</h1>
          <p className="text-muted-foreground">
            Generate comprehensive reports and analyze evaluation trends
          </p>
        </div>
        <div className="flex gap-2">
          <Button variant="outline">
            <Share2 className="w-4 h-4 mr-2" />
            Share
          </Button>
          <Button>
            <FileText className="w-4 h-4 mr-2" />
            New Report
          </Button>
        </div>
      </div>

      <Tabs defaultValue="reports" className="w-full">
        <TabsList>
          <TabsTrigger value="reports">Reports</TabsTrigger>
          <TabsTrigger value="analytics">Analytics</TabsTrigger>
          <TabsTrigger value="trends">Trends</TabsTrigger>
          <TabsTrigger value="benchmarks">Benchmarks</TabsTrigger>
        </TabsList>

        <TabsContent value="reports" className="space-y-6">
          <div className="flex items-center justify-between">
            <div className="flex gap-4">
              <Select value={selectedTimeframe} onValueChange={setSelectedTimeframe}>
                <SelectTrigger className="w-48">
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="last-week">Last Week</SelectItem>
                  <SelectItem value="last-month">Last Month</SelectItem>
                  <SelectItem value="last-quarter">Last Quarter</SelectItem>
                  <SelectItem value="last-year">Last Year</SelectItem>
                </SelectContent>
              </Select>
              <Button variant="outline">
                <Filter className="w-4 h-4 mr-2" />
                Filter
              </Button>
            </div>
          </div>

          <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
            {reports.map((report) => (
              <Card key={report.id}>
                <CardHeader>
                  <div className="flex items-start justify-between">
                    <div>
                      <CardTitle className="text-lg">{report.title}</CardTitle>
                      <CardDescription>{report.company}</CardDescription>
                    </div>
                    <Badge variant={
                      report.status === 'completed' ? 'default' : 'secondary'
                    }>
                      {report.status}
                    </Badge>
                  </div>
                </CardHeader>
                <CardContent>
                  <div className="space-y-4">
                    <div className="flex items-center justify-between">
                      <span className="text-sm">Type:</span>
                      <Badge variant="outline">{report.type}</Badge>
                    </div>
                    
                    <div className="flex items-center justify-between">
                      <span className="text-sm">Score:</span>
                      <span className="font-semibold">{report.score}/5.0</span>
                    </div>
                    
                    <div className="flex items-center justify-between">
                      <span className="text-sm">Recommendation:</span>
                      <Badge className={
                        report.recommendation === 'Strong Buy' ? 'bg-green-100 text-green-800' :
                        report.recommendation === 'Hold' ? 'bg-yellow-100 text-yellow-800' :
                        'bg-gray-100 text-gray-800'
                      }>
                        {report.recommendation}
                      </Badge>
                    </div>
                    
                    <div className="flex items-center justify-between text-sm text-muted-foreground">
                      <span>Created:</span>
                      <span>{new Date(report.created).toLocaleDateString()}</span>
                    </div>
                    
                    <div className="flex gap-2 pt-2">
                      <Button size="sm" variant="outline" className="flex-1">
                        <Eye className="w-4 h-4 mr-1" />
                        View
                      </Button>
                      <Button size="sm" variant="outline" className="flex-1">
                        <Download className="w-4 h-4 mr-1" />
                        Export
                      </Button>
                    </div>
                  </div>
                </CardContent>
              </Card>
            ))}
          </div>
        </TabsContent>

        <TabsContent value="analytics" className="space-y-6">
          <div className="grid grid-cols-1 md:grid-cols-4 gap-6">
            {analyticsData.map((metric, index) => (
              <Card key={index}>
                <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                  <CardTitle className="text-sm font-medium">{metric.metric}</CardTitle>
                  <TrendingUp className={`h-4 w-4 ${
                    metric.trend === 'up' ? 'text-green-500' : 'text-red-500'
                  }`} />
                </CardHeader>
                <CardContent>
                  <div className="text-2xl font-bold">{metric.value}</div>
                  <p className={`text-xs ${
                    metric.trend === 'up' ? 'text-green-600' : 'text-red-600'
                  }`}>
                    {metric.change} from last period
                  </p>
                </CardContent>
              </Card>
            ))}
          </div>

          <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
            <Card>
              <CardHeader>
                <CardTitle>Score Distribution</CardTitle>
                <CardDescription>Distribution of evaluation scores</CardDescription>
              </CardHeader>
              <CardContent>
                <div className="space-y-4">
                  {scoreDistribution.map((item, index) => (
                    <div key={index} className="space-y-2">
                      <div className="flex justify-between text-sm">
                        <span>{item.range}</span>
                        <span>{item.count} companies ({item.percentage}%)</span>
                      </div>
                      <div className="w-full bg-gray-200 rounded-full h-2">
                        <div 
                          className={`h-2 rounded-full ${item.color}`}
                          style={{ width: `${item.percentage * 2.5}%` }}
                        ></div>
                      </div>
                    </div>
                  ))}
                </div>
              </CardContent>
            </Card>

            <Card>
              <CardHeader>
                <CardTitle>Therapeutic Area Breakdown</CardTitle>
                <CardDescription>Evaluations by therapeutic focus</CardDescription>
              </CardHeader>
              <CardContent>
                <div className="space-y-4">
                  {therapeuticBreakdown.map((area, index) => (
                    <div key={index} className="flex items-center justify-between p-3 border rounded-lg">
                      <div>
                        <p className="font-medium">{area.area}</p>
                        <p className="text-sm text-muted-foreground">
                          {area.count} companies ({area.percentage}%)
                        </p>
                      </div>
                      <div className="text-right">
                        <div className="font-semibold">{area.avgScore}</div>
                        <div className="text-sm text-muted-foreground">avg score</div>
                      </div>
                    </div>
                  ))}
                </div>
              </CardContent>
            </Card>
          </div>
        </TabsContent>

        <TabsContent value="trends" className="space-y-6">
          <Card>
            <CardHeader>
              <CardTitle>Evaluation Trends</CardTitle>
              <CardDescription>Historical trends in scoring and recommendations</CardDescription>
            </CardHeader>
            <CardContent>
              <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
                <Card>
                  <CardHeader className="pb-2">
                    <CardTitle className="text-base">Monthly Evaluations</CardTitle>
                  </CardHeader>
                  <CardContent>
                    <div className="text-2xl font-bold">23</div>
                    <p className="text-xs text-muted-foreground">+12% vs last month</p>
                    <Progress value={65} className="mt-2 h-2" />
                  </CardContent>
                </Card>

                <Card>
                  <CardHeader className="pb-2">
                    <CardTitle className="text-base">Score Trend</CardTitle>
                  </CardHeader>
                  <CardContent>
                    <div className="text-2xl font-bold">↗ 3.84</div>
                    <p className="text-xs text-muted-foreground">+0.15 improvement</p>
                    <Progress value={77} className="mt-2 h-2" />
                  </CardContent>
                </Card>

                <Card>
                  <CardHeader className="pb-2">
                    <CardTitle className="text-base">Success Rate</CardTitle>
                  </CardHeader>
                  <CardContent>
                    <div className="text-2xl font-bold">68%</div>
                    <p className="text-xs text-muted-foreground">Recommendations approved</p>
                    <Progress value={68} className="mt-2 h-2" />
                  </CardContent>
                </Card>
              </div>
            </CardContent>
          </Card>
        </TabsContent>

        <TabsContent value="benchmarks" className="space-y-6">
          <Card>
            <CardHeader>
              <CardTitle>Industry Benchmarks</CardTitle>
              <CardDescription>Compare performance against industry standards</CardDescription>
            </CardHeader>
            <CardContent>
              <div className="space-y-6">
                <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                  <div className="space-y-4">
                    <h4 className="font-medium">Scoring Accuracy</h4>
                    <div className="space-y-2">
                      <div className="flex justify-between text-sm">
                        <span>Our Performance</span>
                        <span className="font-medium">68%</span>
                      </div>
                      <Progress value={68} className="h-2" />
                      <div className="flex justify-between text-sm text-muted-foreground">
                        <span>Industry Average</span>
                        <span>61%</span>
                      </div>
                    </div>
                  </div>

                  <div className="space-y-4">
                    <h4 className="font-medium">Deal Success Rate</h4>
                    <div className="space-y-2">
                      <div className="flex justify-between text-sm">
                        <span>Our Performance</span>
                        <span className="font-medium">72%</span>
                      </div>
                      <Progress value={72} className="h-2" />
                      <div className="flex justify-between text-sm text-muted-foreground">
                        <span>Industry Average</span>
                        <span>58%</span>
                      </div>
                    </div>
                  </div>
                </div>

                <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                  <Card>
                    <CardContent className="p-4 text-center">
                      <div className="text-2xl font-bold text-green-600">+14%</div>
                      <p className="text-sm text-muted-foreground">Above Average Accuracy</p>
                    </CardContent>
                  </Card>
                  <Card>
                    <CardContent className="p-4 text-center">
                      <div className="text-2xl font-bold text-green-600">+24%</div>
                      <p className="text-sm text-muted-foreground">Above Success Rate</p>
                    </CardContent>
                  </Card>
                  <Card>
                    <CardContent className="p-4 text-center">
                      <div className="text-2xl font-bold text-blue-600">92%</div>
                      <p className="text-sm text-muted-foreground">Client Satisfaction</p>
                    </CardContent>
                  </Card>
                </div>
              </div>
            </CardContent>
          </Card>
        </TabsContent>
      </Tabs>
    </div>
  );
}