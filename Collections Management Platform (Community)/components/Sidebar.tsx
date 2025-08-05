import React from 'react';
import { 
  BarChart3, 
  Building2, 
  Calculator, 
  Database, 
  FileText, 
  Settings, 
  Target,
  TrendingUp
} from 'lucide-react';

interface SidebarProps {
  activeSection: string;
  onSectionChange: (section: string) => void;
}

export function Sidebar({ activeSection, onSectionChange }: SidebarProps) {
  const menuItems = [
    { id: 'dashboard', label: 'Dashboard', icon: BarChart3 },
    { id: 'evaluation', label: 'Company Evaluation', icon: Building2 },
    { id: 'pillars', label: 'Scoring Pillars', icon: Target },
    { id: 'comparables', label: 'Database', icon: Database },
    { id: 'valuation', label: 'Valuation Engine', icon: Calculator },
    { id: 'reports', label: 'Reports & Analytics', icon: FileText },
    { id: 'settings', label: 'Settings', icon: Settings },
  ];

  return (
    <div className="w-64 bg-sidebar border-r border-sidebar-border flex flex-col">
      <div className="p-6 border-b border-sidebar-border">
        <div className="flex items-center gap-3">
          <div className="w-8 h-8 bg-sidebar-primary rounded-lg flex items-center justify-center">
            <TrendingUp className="w-5 h-5 text-sidebar-primary-foreground" />
          </div>
          <div>
            <h1 className="text-lg font-semibold text-sidebar-foreground">BD & IPO Scoring</h1>
            <p className="text-sm text-muted-foreground">Biotech Investment Platform</p>
          </div>
        </div>
      </div>
      
      <nav className="flex-1 p-4">
        <ul className="space-y-2">
          {menuItems.map((item) => {
            const Icon = item.icon;
            const isActive = activeSection === item.id;
            
            return (
              <li key={item.id}>
                <button
                  onClick={() => onSectionChange(item.id)}
                  className={`w-full flex items-center gap-3 px-3 py-2 rounded-md transition-colors ${
                    isActive
                      ? 'bg-sidebar-accent text-sidebar-accent-foreground'
                      : 'text-sidebar-foreground hover:bg-sidebar-accent/50 hover:text-sidebar-accent-foreground'
                  }`}
                >
                  <Icon className="w-5 h-5" />
                  <span>{item.label}</span>
                </button>
              </li>
            );
          })}
        </ul>
      </nav>

      <div className="p-4 border-t border-sidebar-border">
        <div className="bg-sidebar-accent rounded-lg p-3">
          <h3 className="text-sm font-medium text-sidebar-accent-foreground mb-1">
            Quick Stats
          </h3>
          <div className="space-y-1 text-xs text-muted-foreground">
            <div className="flex justify-between">
              <span>Companies Evaluated:</span>
              <span className="font-medium">247</span>
            </div>
            <div className="flex justify-between">
              <span>Active Deals:</span>
              <span className="font-medium">12</span>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}