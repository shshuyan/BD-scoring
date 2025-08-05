# BD & IPO Scoring Platform

A comprehensive web interface for biotech investment evaluation and scoring, built with React, TypeScript, and Tailwind CSS.

## 🚀 Quick Start

### Prerequisites
- Node.js (v16 or higher)
- npm or yarn

### Launch the Platform

1. **Using the launch script (recommended):**
   ```bash
   ./launch.sh
   ```

2. **Manual setup:**
   ```bash
   npm install
   npm run start
   ```

The platform will be available at `http://localhost:3000`

## 📋 Features

### Core Modules
- **Dashboard** - Overview of key metrics and recent evaluations
- **Company Evaluation** - Detailed company assessment tools
- **Scoring Pillars** - Multi-criteria evaluation framework
- **Comparables Database** - Market comparison and benchmarking
- **Valuation Engine** - Financial modeling and valuation tools
- **Reports & Analytics** - Comprehensive reporting suite
- **Settings** - Platform configuration and preferences

### UI Components
The platform includes a comprehensive UI component library with:
- Modern design system with light/dark mode support
- Responsive layouts optimized for desktop and mobile
- Interactive charts and data visualizations
- Form components with validation
- Navigation and layout components
- Accessibility-compliant components

## 🏗️ Architecture

### Project Structure
```
├── Collections Management Platform (Community)/
│   ├── components/           # React components
│   │   ├── ui/              # Reusable UI components
│   │   ├── settings/        # Settings-specific components
│   │   └── *.tsx            # Feature components
│   ├── styles/              # Global styles and themes
│   └── App.tsx              # Main application component
├── src/                     # Application entry point
├── package.json             # Dependencies and scripts
├── vite.config.ts          # Vite configuration
├── tailwind.config.js      # Tailwind CSS configuration
└── tsconfig.json           # TypeScript configuration
```

### Technology Stack
- **Frontend Framework:** React 18 with TypeScript
- **Build Tool:** Vite
- **Styling:** Tailwind CSS with custom design system
- **UI Components:** Radix UI primitives
- **Icons:** Lucide React
- **Charts:** Recharts
- **Form Handling:** React Hook Form with Zod validation

## 🎨 Design System

The platform uses a sophisticated design system with:
- **Color Palette:** Carefully crafted light and dark themes
- **Typography:** Consistent font sizing and weights
- **Spacing:** Systematic spacing scale
- **Components:** Reusable, accessible UI components
- **Responsive Design:** Mobile-first approach

### Theme Customization
The design system supports extensive customization through CSS custom properties defined in `styles/globals.css`.

## 🔧 Development

### Available Scripts
- `npm run dev` - Start development server
- `npm run build` - Build for production
- `npm run preview` - Preview production build
- `npm run start` - Start development server with host binding

### Component Development
All UI components are built using:
- Radix UI for accessibility and behavior
- Class Variance Authority for component variants
- Tailwind CSS for styling
- TypeScript for type safety

## 📊 Platform Capabilities

### Biotech Investment Features
- **Multi-criteria Scoring:** Asset quality, market outlook, financial readiness
- **Risk Assessment:** Regulatory, technical, and market risk evaluation
- **Comparative Analysis:** Peer benchmarking and market positioning
- **Financial Modeling:** Valuation scenarios and sensitivity analysis
- **Portfolio Management:** Deal tracking and pipeline management

### Data Visualization
- Interactive dashboards with real-time metrics
- Scoring distribution charts
- Progress tracking and deadline management
- Comparative analysis visualizations

## 🚀 Deployment

### Production Build
```bash
npm run build
```

### Preview Production Build
```bash
npm run preview
```

The built files will be in the `dist/` directory, ready for deployment to any static hosting service.

## 🤝 Contributing

This platform is designed to be extensible and customizable for various biotech investment workflows. The modular architecture allows for easy addition of new features and components.

## 📄 License

This project is part of the BD Scoring Module ecosystem for biotech investment evaluation.

---

**Platform Status:** Ready for launch 🚀
**Last Updated:** $(date)
**Version:** 1.0.0