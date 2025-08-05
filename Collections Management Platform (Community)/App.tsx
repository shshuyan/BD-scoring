import React, { useState } from 'react';
import { Sidebar } from './components/Sidebar';
import { Dashboard } from './components/Dashboard';
import { CompanyEvaluation } from './components/CompanyEvaluation';
import { ScoringPillars } from './components/ScoringPillars';
import { ComparablesDatabase } from './components/ComparablesDatabase';
import { ValuationEngine } from './components/ValuationEngine';
import { ReportsAnalytics } from './components/ReportsAnalytics';
import { Settings } from './components/Settings';

export default function App() {
  const [activeSection, setActiveSection] = useState('dashboard');

  const renderContent = () => {
    switch (activeSection) {
      case 'dashboard':
        return <Dashboard />;
      case 'evaluation':
        return <CompanyEvaluation />;
      case 'pillars':
        return <ScoringPillars />;
      case 'comparables':
        return <ComparablesDatabase />;
      case 'valuation':
        return <ValuationEngine />;
      case 'reports':
        return <ReportsAnalytics />;
      case 'settings':
        return <Settings />;
      default:
        return <Dashboard />;
    }
  };

  return (
    <div className="flex h-screen bg-background">
      <Sidebar activeSection={activeSection} onSectionChange={setActiveSection} />
      <main className="flex-1 overflow-auto">
        {renderContent()}
      </main>
    </div>
  );
}