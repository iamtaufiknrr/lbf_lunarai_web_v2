# 📁 Folder Structure - n8n Workflows

## Struktur Folder yang Rapi

```
02-N8N-Workflows/
│
├── 00-FOLDER-STRUCTURE.md (this file)
├── 00-WORKFLOW-ARCHITECTURE.md (architecture overview)
├── TOOL-SELECTION-ANALYSIS.md (tool selection guide)
├── WORKFLOW-STRUCTURE-GUIDE.md (technical guide)
├── GEMINI-AI-PROMPTS.md (AI prompts)
├── COMPLETE-WORKFLOW-SUMMARY.md (complete summary)
│
├── 01-Main-Orchestrator/
│   ├── README.md
│   └── main-orchestrator.json (INDUK - Main workflow)
│
├── 02-AI-Agent-Sections/
│   ├── README.md
│   ├── section-01-product-header.json
│   ├── section-02-product-description.json
│   ├── section-03-alternative-names.json
│   ├── section-06-marketing-copy.json
│   └── section-11-next-steps.json
│
├── 03-MCP-Sections/
│   ├── README.md
│   ├── section-04-ingredient-breakdown.json
│   └── section-07-pricing-structure.json
│
├── 04-Hybrid-Sections/
│   ├── README.md
│   ├── section-05-market-analysis.json
│   ├── section-08-regulatory-compliance.json
│   ├── section-09-production-timeline.json
│   └── section-10-sustainability.json
│
├── 05-Shared-Components/
│   ├── README.md
│   ├── gemini-ai-agent-template.json
│   ├── mcp-database-template.json
│   ├── mcp-web-search-template.json
│   └── error-handler-template.json
│
└── 06-Import-Order/
    ├── README.md
    └── import-sequence.txt
```

## Penjelasan Struktur

### 01-Main-Orchestrator/
**Main workflow** yang menjadi induk dari semua section workflows.
- Menerima webhook dari Next.js
- Validasi payload
- Store ke database
- Trigger semua section workflows
- Aggregate results
- Callback ke Next.js

### 02-AI-Agent-Sections/
**Pure AI Agent workflows** menggunakan Gemini Pro.
- Section 1: Product Header
- Section 2: Product Description
- Section 3: Alternative Names
- Section 6: Marketing Copy
- Section 11: Next Steps

### 03-MCP-Sections/
**Pure MCP workflows** untuk data terstruktur.
- Section 4: Ingredient Breakdown (Database MCP)
- Section 7: Pricing Structure (Database + Calculation MCP)

### 04-Hybrid-Sections/
**Hybrid workflows** kombinasi AI Agent + MCP.
- Section 5: Market Analysis (Gemini + Web Search MCP)
- Section 8: Regulatory Compliance (Gemini + Database MCP)
- Section 9: Production Timeline (Gemini + Database MCP)
- Section 10: Sustainability (Gemini + Database MCP)

### 05-Shared-Components/
**Template components** yang bisa digunakan ulang.
- Gemini AI Agent configuration
- MCP server configurations
- Error handler templates
- Retry logic templates

### 06-Import-Order/
**Import sequence** untuk n8n.
- Urutan import yang benar
- Dependencies antar workflows
- Testing checklist

## Import Sequence

1. **First**: Import Main Orchestrator
2. **Second**: Import Shared Components
3. **Third**: Import Section Workflows (any order)
4. **Fourth**: Configure credentials
5. **Fifth**: Test each section
6. **Sixth**: Test complete flow

## Naming Convention

### Workflow Names
- `main-orchestrator.json` - Main workflow
- `section-XX-name.json` - Section workflows
- `template-name.json` - Reusable templates

### Node Names (dalam workflow)
- `Webhook Trigger` - Entry point
- `AI Agent - [Purpose]` - Gemini AI nodes
- `MCP - [Tool Name]` - MCP tool nodes
- `Function - [Purpose]` - JavaScript functions
- `Database - [Action]` - PostgreSQL nodes
- `HTTP Request - [Target]` - HTTP calls

## Connection Pattern

```
Main Orchestrator
    ↓
    ├─→ Section Workflow 1
    │   ├─→ AI Agent Node
    │   │   ├─→ Chat Model (Gemini)
    │   │   ├─→ Memory (PostgreSQL)
    │   │   └─→ Tools
    │   │       ├─→ MCP Server (if needed)
    │   │       └─→ Custom Functions
    │   └─→ Return Result
    │
    ├─→ Section Workflow 2
    │   └─→ ...
    │
    └─→ Aggregate Results
```

## File Size Guidelines

- Main Orchestrator: ~50-100 KB
- Section Workflows: ~20-40 KB each
- Templates: ~10-20 KB each

## Version Control

- Each JSON file has version number in metadata
- Track changes in git
- Document breaking changes

---

**This structure makes it easy to find, maintain, and scale workflows! 🚀**
