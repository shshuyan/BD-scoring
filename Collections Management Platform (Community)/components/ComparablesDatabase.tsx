import React, { useState } from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from './ui/card';
import { Button } from './ui/button';
import { Input } from './ui/input';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from './ui/select';
import { Badge } from './ui/badge';
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from './ui/table';
import { 
  Database, 
  Search, 
  Filter, 
  Download, 
  Plus,
  TrendingUp,
  Calendar,
  DollarSign
} from 'lucide-react';

export function ComparablesDatabase() {
  const [searchTerm, setSearchTerm] = useState('');
  const [selectedFilters, setSelectedFilters] = useState({
    therapeuticArea: '',
    stage: '',
    dealType: '',
    yearRange: ''
  });

  const comparableDeals = [
    {
      id: 1,
      targetCompany: "BioPharma Alpha",
      acquirer: "MegaPharma Inc",
      dealValue: 2400,
      dealType: "Acquisition",
      therapeuticArea: "Oncology",
      stage: "Phase III",
      date: "2024-03-15",
      multiple: "8.2x",
      indication: "Lung Cancer",
      score: 4.3
    },
    {
      id: 2,
      targetCompany: "Gene Therapeutics",
      acquirer: "Big Biotech Corp",
      dealValue: 1800,
      dealType: "Partnership",
      therapeuticArea: "Rare Disease",
      stage: "Phase II",
      date: "2024-01-22",
      multiple: "12.1x",
      indication: "Duchenne MD",
      score: 4.1
    },
    {
      id: 3,
      targetCompany: "Neuro Solutions",
      acquirer: "Pharma Giant",
      dealValue: 950,
      dealType: "Acquisition",
      therapeuticArea: "CNS",
      stage: "Phase I",
      date: "2023-11-08",
      multiple: "15.3x",
      indication: "Alzheimer's",
      score: 3.8
    },
    {
      id: 4,
      targetCompany: "Immuno Tech",
      acquirer: "Global Health Co",
      dealValue: 3200,
      dealType: "Merger",
      therapeuticArea: "Immunology",
      stage: "Phase III",
      date: "2023-09-14",
      multiple: "6.7x",
      indication: "Autoimmune",
      score: 4.5
    },
    {
      id: 5,
      targetCompany: "Cardio Innovations",
      acquirer: "Heart Health Inc",
      dealValue: 1400,
      dealType: "Partnership",
      therapeuticArea: "Cardiovascular",
      stage: "Phase II",
      date: "2023-07-03",
      multiple: "9.8x",
      indication: "Heart Failure",
      score: 3.9
    }
  ];

  const filteredDeals = comparableDeals.filter(deal => {
    const matchesSearch = deal.targetCompany.toLowerCase().includes(searchTerm.toLowerCase()) ||
                         deal.acquirer.toLowerCase().includes(searchTerm.toLowerCase()) ||
                         deal.indication.toLowerCase().includes(searchTerm.toLowerCase());
    
    const matchesTherapeuticArea = !selectedFilters.therapeuticArea || 
                                  deal.therapeuticArea === selectedFilters.therapeuticArea;
    
    const matchesStage = !selectedFilters.stage || deal.stage === selectedFilters.stage;
    
    const matchesDealType = !selectedFilters.dealType || deal.dealType === selectedFilters.dealType;

    return matchesSearch && matchesTherapeuticArea && matchesStage && matchesDealType;
  });

  return (
    <div className="flex-1 space-y-6 p-6">
      <div className="flex items-center justify-between">
        <div>
          <h1>Comparables Database</h1>
          <p className="text-muted-foreground">
            Historical transaction data for biotech valuation benchmarking
          </p>
        </div>
        <div className="flex gap-2">
          <Button variant="outline">
            <Download className="w-4 h-4 mr-2" />
            Export Data
          </Button>
          <Button>
            <Plus className="w-4 h-4 mr-2" />
            Add Transaction
          </Button>
        </div>
      </div>

      {/* Summary Cards */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-6">
        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Total Deals</CardTitle>
            <Database className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">1,247</div>
            <p className="text-xs text-muted-foreground">
              Since 2020
            </p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Total Value</CardTitle>
            <DollarSign className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">$247B</div>
            <p className="text-xs text-muted-foreground">
              Aggregate deal value
            </p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Avg Multiple</CardTitle>
            <TrendingUp className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">9.7x</div>
            <p className="text-xs text-muted-foreground">
              Revenue multiple
            </p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Recent Activity</CardTitle>
            <Calendar className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">23</div>
            <p className="text-xs text-muted-foreground">
              Deals this quarter
            </p>
          </CardContent>
        </Card>
      </div>

      {/* Search and Filters */}
      <Card>
        <CardHeader>
          <CardTitle>Search & Filter</CardTitle>
          <CardDescription>Find relevant comparable transactions</CardDescription>
        </CardHeader>
        <CardContent>
          <div className="space-y-4">
            <div className="flex gap-4">
              <div className="flex-1 relative">
                <Search className="absolute left-3 top-3 h-4 w-4 text-muted-foreground" />
                <Input 
                  placeholder="Search by company, acquirer, or indication..." 
                  className="pl-10"
                  value={searchTerm}
                  onChange={(e) => setSearchTerm(e.target.value)}
                />
              </div>
              <Button variant="outline">
                <Filter className="w-4 h-4 mr-2" />
                Advanced Filters
              </Button>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
              <Select 
                value={selectedFilters.therapeuticArea}
                onValueChange={(value) => setSelectedFilters({...selectedFilters, therapeuticArea: value})}
              >
                <SelectTrigger>
                  <SelectValue placeholder="Therapeutic Area" />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="Oncology">Oncology</SelectItem>
                  <SelectItem value="Rare Disease">Rare Disease</SelectItem>
                  <SelectItem value="CNS">CNS</SelectItem>
                  <SelectItem value="Cardiovascular">Cardiovascular</SelectItem>
                  <SelectItem value="Immunology">Immunology</SelectItem>
                </SelectContent>
              </Select>

              <Select 
                value={selectedFilters.stage}
                onValueChange={(value) => setSelectedFilters({...selectedFilters, stage: value})}
              >
                <SelectTrigger>
                  <SelectValue placeholder="Development Stage" />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="Preclinical">Preclinical</SelectItem>
                  <SelectItem value="Phase I">Phase I</SelectItem>
                  <SelectItem value="Phase II">Phase II</SelectItem>
                  <SelectItem value="Phase III">Phase III</SelectItem>
                  <SelectItem value="Approved">Approved</SelectItem>
                </SelectContent>
              </Select>

              <Select 
                value={selectedFilters.dealType}
                onValueChange={(value) => setSelectedFilters({...selectedFilters, dealType: value})}
              >
                <SelectTrigger>
                  <SelectValue placeholder="Deal Type" />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="Acquisition">Acquisition</SelectItem>
                  <SelectItem value="Merger">Merger</SelectItem>
                  <SelectItem value="Partnership">Partnership</SelectItem>
                  <SelectItem value="Licensing">Licensing</SelectItem>
                </SelectContent>
              </Select>

              <Select 
                value={selectedFilters.yearRange}
                onValueChange={(value) => setSelectedFilters({...selectedFilters, yearRange: value})}
              >
                <SelectTrigger>
                  <SelectValue placeholder="Year Range" />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="2024">2024</SelectItem>
                  <SelectItem value="2023">2023</SelectItem>
                  <SelectItem value="2022">2022</SelectItem>
                  <SelectItem value="2021-2020">2021-2020</SelectItem>
                </SelectContent>
              </Select>
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Results Table */}
      <Card>
        <CardHeader>
          <CardTitle>Comparable Transactions</CardTitle>
          <CardDescription>
            Showing {filteredDeals.length} of {comparableDeals.length} transactions
          </CardDescription>
        </CardHeader>
        <CardContent>
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>Target Company</TableHead>
                <TableHead>Acquirer</TableHead>
                <TableHead>Deal Value</TableHead>
                <TableHead>Type</TableHead>
                <TableHead>Area</TableHead>
                <TableHead>Stage</TableHead>
                <TableHead>Multiple</TableHead>
                <TableHead>Score</TableHead>
                <TableHead>Date</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {filteredDeals.map((deal) => (
                <TableRow key={deal.id}>
                  <TableCell>
                    <div>
                      <p className="font-medium">{deal.targetCompany}</p>
                      <p className="text-sm text-muted-foreground">{deal.indication}</p>
                    </div>
                  </TableCell>
                  <TableCell>{deal.acquirer}</TableCell>
                  <TableCell className="font-medium">${deal.dealValue}M</TableCell>
                  <TableCell>
                    <Badge variant="outline">{deal.dealType}</Badge>
                  </TableCell>
                  <TableCell>
                    <Badge variant="secondary">{deal.therapeuticArea}</Badge>
                  </TableCell>
                  <TableCell>{deal.stage}</TableCell>
                  <TableCell className="font-medium">{deal.multiple}</TableCell>
                  <TableCell>
                    <Badge className={
                      deal.score >= 4 ? 'bg-green-100 text-green-800' :
                      deal.score >= 3.5 ? 'bg-yellow-100 text-yellow-800' :
                      'bg-red-100 text-red-800'
                    }>
                      {deal.score}
                    </Badge>
                  </TableCell>
                  <TableCell className="text-muted-foreground">
                    {new Date(deal.date).toLocaleDateString()}
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </CardContent>
      </Card>
    </div>
  );
}