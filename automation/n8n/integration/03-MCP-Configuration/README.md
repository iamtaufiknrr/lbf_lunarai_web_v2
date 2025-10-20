# MCP (Model Context Protocol) Configuration

## Overview
MCP servers menyediakan tools untuk AI agents mengakses database, web search, filesystem, dan API eksternal.

## Available MCP Servers

### 1. PostgreSQL MCP Server
**Purpose**: Query dan manipulasi database

**Capabilities**:
- Execute SQL queries
- List tables and schemas
- Describe table structure
- Insert, update, delete operations

**Installation**:
```bash
npm install -g @modelcontextprotocol/server-postgres
```

**Configuration**:
```json
{
  "postgres": {
    "command": "npx",
    "args": ["-y", "@modelcontextprotocol/server-postgres"],
    "env": {
      "POSTGRES_CONNECTION_STRING": "postgresql://..."
    }
  }
}
```

---

### 2. Tavily Search MCP Server
**Purpose**: Web search untuk market research dan competitor analysis

**Capabilities**:
- Advanced web search
- Domain-specific search
- Real-time data retrieval
- Source credibility scoring

**Installation**:
```bash
npm install -g @modelcontextprotocol/server-tavily
```

**Get API Key**:
1. Visit https://tavily.com
2. Sign up for free account
3. Get API key from dashboard

**Configuration**:
```json
{
  "tavily-search": {
    "command": "npx",
    "args": ["-y", "@modelcontextprotocol/server-tavily"],
    "env": {
      "TAVILY_API_KEY": "tvly-..."
    }
  }
}
```

---

### 3. Filesystem MCP Server
**Purpose**: Read dan analyze dokumen referensi

**Capabilities**:
- Read files
- List directories
- Search files
- File metadata

**Installation**:
```bash
npm install -g @modelcontextprotocol/server-filesystem
```

**Configuration**:
```json
{
  "filesystem": {
    "command": "npx",
    "args": [
      "-y",
      "@modelcontextprotocol/server-filesystem",
      "/path/to/documents"
    ]
  }
}
```

---

### 4. Fetch MCP Server
**Purpose**: HTTP requests ke external APIs

**Capabilities**:
- GET, POST, PUT, DELETE requests
- Custom headers
- JSON/XML parsing
- Rate limiting

**Installation**:
```bash
npm install -g @modelcontextprotocol/server-fetch
```

**Configuration**:
```json
{
  "fetch": {
    "command": "npx",
    "args": ["-y", "@modelcontextprotocol/server-fetch"]
  }
}
```

---

## Setup Instructions

### For n8n Integration

1. **Install MCP Servers**:
```bash
npm install -g @modelcontextprotocol/server-postgres
npm install -g @modelcontextprotocol/server-tavily
npm install -g @modelcontextprotocol/server-filesystem
npm install -g @modelcontextprotocol/server-fetch
```

2. **Configure in n8n**:
   - Add MCP configuration to n8n settings
   - Set environment variables
   - Test each MCP server

3. **Use in Workflows**:
```javascript
// Example: Query database via MCP
const result = await $mcp.postgres.query({
  query: 'SELECT * FROM submissions WHERE id = $1',
  params: [submissionId]
});

// Example: Web search via MCP
const searchResults = await $mcp.tavily.search({
  query: 'cosmetic market trends Indonesia 2025',
  search_depth: 'advanced',
  max_results: 5
});
```

---

## Usage Examples

### Database Queries
```javascript
// List all tables
const tables = await $mcp.postgres.list_tables();

// Describe table structure
const schema = await $mcp.postgres.describe_table('submissions');

// Execute query
const submissions = await $mcp.postgres.query({
  query: 'SELECT * FROM submissions WHERE status = $1',
  params: ['completed']
});

// Insert data
await $mcp.postgres.execute({
  query: 'INSERT INTO audit_logs (action, actor_type) VALUES ($1, $2)',
  params: ['workflow_started', 'system']
});
```

### Web Search
```javascript
// Basic search
const results = await $mcp.tavily.search({
  query: 'BPOM cosmetic regulations 2025'
});

// Advanced search with domain filter
const competitorData = await $mcp.tavily.search({
  query: 'beauty brands Indonesia market share',
  search_depth: 'advanced',
  include_domains: ['beautypackaging.com', 'cosmeticsdesign-asia.com'],
  max_results: 10
});
```

### Filesystem Operations
```javascript
// Read file
const content = await $mcp.filesystem.read_file({
  path: '/documents/product-specs.pdf'
});

// List directory
const files = await $mcp.filesystem.list_directory({
  path: '/documents/references'
});
```

### HTTP Requests
```javascript
// GET request
const data = await $mcp.fetch.fetch({
  url: 'https://api.example.com/data',
  method: 'GET',
  headers: {
    'Authorization': 'Bearer token'
  }
});

// POST request
const response = await $mcp.fetch.fetch({
  url: 'https://api.example.com/submit',
  method: 'POST',
  headers: {
    'Content-Type': 'application/json'
  },
  body: JSON.stringify({ data: 'value' })
});
```

---

## Security Best Practices

### 1. API Key Management
- Store API keys in environment variables
- Never commit keys to git
- Rotate keys regularly
- Use separate keys for test/production

### 2. Database Access
- Use read-only credentials when possible
- Implement row-level security
- Audit all database operations
- Limit query complexity

### 3. Web Search
- Validate search queries
- Filter results by domain
- Implement rate limiting
- Cache frequent searches

### 4. Filesystem Access
- Restrict to specific directories
- Validate file paths
- Scan for malicious content
- Log all file operations

---

## Troubleshooting

### MCP Server Not Starting
```bash
# Check if MCP server is installed
npm list -g @modelcontextprotocol/server-postgres

# Test MCP server manually
npx @modelcontextprotocol/server-postgres

# Check logs
tail -f ~/.n8n/logs/mcp.log
```

### Connection Issues
```bash
# Test database connection
psql "$POSTGRES_CONNECTION_STRING"

# Test Tavily API
curl -X POST https://api.tavily.com/search \
  -H "Content-Type: application/json" \
  -d '{"api_key": "your-key", "query": "test"}'
```

### Permission Errors
```bash
# Fix filesystem permissions
chmod +x /path/to/documents

# Check n8n user permissions
ls -la /path/to/documents
```

---

## Performance Optimization

### Caching Strategy
```javascript
// Cache database queries
const cacheKey = `query_${queryHash}`;
let result = await redis.get(cacheKey);

if (!result) {
  result = await $mcp.postgres.query({...});
  await redis.setex(cacheKey, 3600, JSON.stringify(result));
}

// Cache web search results
const searchCacheKey = `search_${searchQuery}`;
let searchResults = await redis.get(searchCacheKey);

if (!searchResults) {
  searchResults = await $mcp.tavily.search({...});
  await redis.setex(searchCacheKey, 86400, JSON.stringify(searchResults));
}
```

### Rate Limiting
```javascript
const Bottleneck = require('bottleneck');

// Limit Tavily API calls
const tavilyLimiter = new Bottleneck({
  maxConcurrent: 5,
  minTime: 200 // 200ms between requests
});

const rateLimitedSearch = tavilyLimiter.wrap(async (query) => {
  return await $mcp.tavily.search({ query });
});
```

---

## Monitoring

### Track MCP Usage
```sql
-- Create MCP usage tracking table
CREATE TABLE mcp_usage (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    server_name VARCHAR(50) NOT NULL,
    operation VARCHAR(100) NOT NULL,
    duration_ms INTEGER,
    success BOOLEAN,
    error_message TEXT,
    created_at TIMESTAMP DEFAULT NOW()
);

-- Query MCP usage statistics
SELECT 
    server_name,
    operation,
    COUNT(*) as total_calls,
    AVG(duration_ms) as avg_duration,
    SUM(CASE WHEN success THEN 1 ELSE 0 END)::float / COUNT(*) as success_rate
FROM mcp_usage
WHERE created_at > NOW() - INTERVAL '24 hours'
GROUP BY server_name, operation;
```

---

## Additional Resources

- [MCP Documentation](https://modelcontextprotocol.io)
- [n8n MCP Integration](https://docs.n8n.io/integrations/mcp/)
- [Tavily API Docs](https://docs.tavily.com)
- [PostgreSQL MCP Server](https://github.com/modelcontextprotocol/servers/tree/main/src/postgres)
