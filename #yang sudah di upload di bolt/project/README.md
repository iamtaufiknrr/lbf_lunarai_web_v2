# LunarAI Beauty - Business Analysis Platform

Platform ideasi produk kosmetik berbasis AI untuk brand owner Indonesia.

## Features

- 🎨 Modern UI with gradient backgrounds
- 📱 Fully responsive design
- 🚀 AI-powered analysis
- 📊 Live brief preview
- 🔄 Real-time form validation

## Tech Stack

- **Framework:** Next.js 14
- **Styling:** Tailwind CSS
- **UI Components:** Radix UI
- **Animations:** Framer Motion
- **Form Handling:** React Hook Form + Zod
- **Icons:** Lucide React

## Getting Started

### Development

```bash
npm install
npm run dev
```

Open [http://localhost:3000](http://localhost:3000) to view the app.

### Build

```bash
npm run build
npm start
```

## Environment Variables

Copy `.env.example` to `.env.local` and configure:

```env
# N8N Webhook URLs
NEXT_PUBLIC_N8N_WEBHOOK_URL_TEST=your-test-webhook-url
NEXT_PUBLIC_N8N_WEBHOOK_URL_PRODUCTION=your-production-webhook-url
```

## Project Structure

```
src/
├── app/              # Next.js app directory
├── components/       # React components
│   ├── common/      # Reusable components
│   ├── form/        # Form components
│   └── ui/          # UI primitives
├── contexts/        # React contexts
├── hooks/           # Custom hooks
├── lib/             # Utility functions
├── styles/          # Global styles
└── types/           # TypeScript types
```

## License

Private - All rights reserved
