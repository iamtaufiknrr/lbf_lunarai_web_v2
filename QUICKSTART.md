# Quick Start Guide

## PowerShell Execution Policy Issue

If you encounter "running scripts is disabled" error, run PowerShell as Administrator and execute:

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

Then restart your terminal.

## Installation Steps

```bash
# Install dependencies (use npm if pnpm is not available)
npm install
# or
pnpm install

# Set up environment variables
cp .env.example .env
# Edit .env with your credentials

# Start development server
npm run dev
# or
pnpm dev
```

## Access the Application

Open http://localhost:3000 in your browser.

## Important Notes

1. **Database Setup**: You need a Neon Postgres database. Sign up at https://neon.tech
2. **n8n Webhooks**: Optional for local development. The app will work without them but submissions won't be processed.
3. **Environment Variables**: At minimum, set `DATABASE_URL` to test database operations.

## Testing Without Full Setup

You can explore the UI without database/webhook configuration:
- The form will validate and show errors
- The landing page sections are fully functional
- The design system components work independently

## Next Steps

1. Configure environment variables (see `docs/environment_setup.md`)
2. Run database migrations: `npm run db:migrate`
3. Start the dev server: `npm run dev`
4. Open http://localhost:3000

## Troubleshooting

**Port 3000 already in use?**
```bash
# Kill the process using port 3000
npx kill-port 3000
```

**Module not found errors?**
```bash
# Clear cache and reinstall
rm -rf node_modules .next
npm install
```

**TypeScript errors?**
```bash
# Check types
npm run type-check
```
