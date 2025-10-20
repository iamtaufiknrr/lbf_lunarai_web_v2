# 🔧 MCP Sections

## Overview

Folder ini berisi **workflow sections yang menggunakan pure MCP Tools** untuk akses data terstruktur dari database. Sections ini fokus pada **data retrieval, calculations, dan structured queries**.

## Sections dalam Folder Ini

### 1. Section 4 - Ingredient Breakdown
**File**: `section-04-ingredient-breakdown.json`
- **Purpose**: Query ingredient details dari database
- **MCP Tools**: Database MCP (PostgreSQL)
- **Duration**: ~30 seconds
- **Input**: List of ingredients with percentages
- **Output**: Complete breakdown with INCI names, properties, restrictions

### 2. Section 7 - Pricing Structure
**File**: `section-07-pricing-structure.json`
- **Purpose**: Calculate manufacturing cost dan retail price
- **MCP Tools**: Database MCP + Calculation Functions
- **Duration**: ~25 seconds
- **Input**: Ingredients, packaging type, batch size
- **Output**: Manufacturing cost, retail price, margin, break-even

## Common Workflow Structure

```
┌─────────────────────────────────────────┐
│     WEBHOOK TRIGGER                      │
│  POST /webhook/section-X                │
└─────────────────────────────────────────┘
              ↓
┌─────────────────────────────────────────┐
│     EXTRACT CONTEXT                      │
│  Parse ingredients & parameters         │
└─────────────────────────────────────────┘
              ↓
┌─────────────────────────────────────────┐
│     MCP - QUERY DATABASE                 │
│  Get ingredient details/prices          │
└─────────────────────────────────────────┘
              ↓
┌─────────────────────────────────────────┐
│     MCP - VALIDATE DATA                  │
│  Check percentages, compatibility       │
└─────────────────────────────────────────┘
              ↓
┌─────────────────────────────────────────┐
│     FUNCTION - CALCULATE                 │
│  Perform calculations (if needed)       │
└─────────────────────────────────────────┘
              ↓
┌─────────────────────────────────────────┐
│     FORMAT OUTPUT                        │
│  Structure as JSON                      │
└─────────────────────────────────────────┘
              ↓
┌─────────────────────────────────────────┐
│     STORE RESULT                         │
│  Save to database                       │
└─────────────────────────────────────────┘
              ↓
┌─────────────────────────────────────────┐
│     RETURN RESPONSE                      │
│  Return to main orchestrator            │
└─────────────────────────────────────────┘
```

## MCP Configuration

### Database MCP Server

```json
{
  "mcpServers": {
    "database": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-postgres"],
      "env": {
        "DATABASE_URL": "{{$env.DATABASE_URL}}"
      }
    }
  }
}
```

### Available MCP Tools

#### 1. query_ingredient_details
```sql
SELECT 
  im.name,
  im.inci_name,
  im.category,
  im.function,
  im.typical_usage_min,
  im.typical_usage_max,
  im.ph_range,
  im.restrictions,
  im.allergen_info,
  im.sustainability_score
FROM ingredients_master im
WHERE im.name = ANY($1::text[]);
```

#### 2. query_ingredient_prices
```sql
SELECT 
  im.name,
  im.inci_name,
  si.price_per_kg,
  si.supplier_id,
  s.name as supplier_name,
  s.country,
  si.moq_kg,
  si.in_stock,
  si.price_valid_until
FROM ingredients_master im
JOIN supplier_ingredients si ON im.id = si.ingredient_id
JOIN suppliers s ON si.supplier_id = s.id
WHERE im.name = ANY($1::text[])
  AND si.in_stock = true
  AND (si.price_valid_until IS NULL OR si.price_valid_until >= CURRENT_DATE)
ORDER BY si.price_per_kg ASC;
```

#### 3. validate_percentages
```javascript
function validatePercentages(ingredients) {
  const total = ingredients.reduce((sum, ing) => sum + ing.percentage, 0);
  
  if (Math.abs(total - 100) > 0.1) {
    throw new Error(`Total percentage must be 100%, got ${total}%`);
  }
  
  for (const ing of ingredients) {
    if (ing.percentage < 0 || ing.percentage > 100) {
      throw new Error(`Invalid percentage for ${ing.name}: ${ing.percentage}%`);
    }
  }
  
  return true;
}
```

#### 4. calculate_manufacturing_cost
```javascript
function calculateManufacturingCost(ingredients, prices, packagingCost, wasteFactor = 0.15) {
  // Base ingredient cost
  let baseCost = 0;
  for (const ing of ingredients) {
    const price = prices[ing.name];
    const quantityKg = ing.percentage / 100; // Assuming 1kg batch
    baseCost += quantityKg * price.pricePerKg;
  }
  
  // Add packaging
  baseCost += packagingCost;
  
  // Apply waste factor
  const costWithWaste = baseCost * (1 + wasteFactor);
  
  // Calculate ranges
  const costMin = baseCost * 0.8;  // -20%
  const costMax = baseCost * 1.3;  // +30%
  
  return {
    base: baseCost,
    withWaste: costWithWaste,
    range: { min: costMin, max: costMax }
  };
}
```

#### 5. calculate_retail_price
```javascript
function calculateRetailPrice(manufacturingCost, margin = 0.40) {
  const retailPrice = manufacturingCost / (1 - margin);
  
  return {
    recommended: retailPrice,
    range: {
      min: retailPrice * 0.8,
      max: retailPrice * 1.3
    }
  };
}
```

#### 6. calculate_break_even
```javascript
function calculateBreakEven(fixedCosts, retailPrice, variableCostPerUnit) {
  const contributionMargin = retailPrice - variableCostPerUnit;
  const breakEvenUnits = Math.ceil(fixedCosts / contributionMargin);
  
  return {
    units: breakEvenUnits,
    revenue: breakEvenUnits * retailPrice,
    contributionMargin: contributionMargin
  };
}
```

## Section 4: Ingredient Breakdown

### Input Format
```json
{
  "submissionId": "uuid-v4",
  "context": {
    "ingredients": [
      {
        "name": "Niacinamide",
        "percentage": 5
      },
      {
        "name": "Hyaluronic Acid",
        "percentage": 2
      }
    ]
  }
}
```

### Output Format
```json
{
  "sectionType": "ingredients",
  "submissionId": "uuid-v4",
  "content": {
    "ingredients": [
      {
        "name": "Niacinamide",
        "inciName": "Niacinamide",
        "percentage": 5,
        "category": "Active",
        "function": "Brightening, Anti-inflammatory",
        "usageRange": "2-10%",
        "phRange": "5.0-7.0",
        "restrictions": "None",
        "allergenInfo": "None",
        "sustainabilityScore": 85
      }
    ],
    "totalPercentage": 100,
    "validation": {
      "valid": true,
      "warnings": []
    }
  }
}
```

## Section 7: Pricing Structure

### Input Format
```json
{
  "submissionId": "uuid-v4",
  "context": {
    "ingredients": [...],
    "product": {
      "packagingType": "Glass Bottle",
      "netto": { "value": 30, "unit": "ml" }
    }
  }
}
```

### Output Format
```json
{
  "sectionType": "pricing",
  "submissionId": "uuid-v4",
  "content": {
    "manufacturingCost": {
      "base": 50000,
      "withWaste": 57500,
      "range": {
        "min": 40000,
        "max": 65000
      }
    },
    "retailPrice": {
      "recommended": 450000,
      "range": {
        "min": 360000,
        "max": 585000
      }
    },
    "margin": 40,
    "breakEven": {
      "units": 250,
      "revenue": 112500000
    },
    "ingredientBreakdown": [
      {
        "name": "Niacinamide",
        "cost": 15000,
        "percentage": 30
      }
    ],
    "packagingCost": 8000
  }
}
```

## Environment Variables

```bash
# Database
DATABASE_URL=postgresql://user:pass@host/db?sslmode=require

# MCP Server
MCP_DATABASE_SERVER=npx @modelcontextprotocol/server-postgres

# Section Webhooks
SECTION_4_WEBHOOK=https://n8n.../webhook/section-4
SECTION_7_WEBHOOK=https://n8n.../webhook/section-7
```

## Testing

### Test Section 4
```bash
curl -X POST https://your-n8n.../webhook/section-4 \
  -H "Content-Type: application/json" \
  -d '{
    "submissionId": "test-uuid",
    "context": {
      "ingredients": [
        {"name": "Niacinamide", "percentage": 5},
        {"name": "Hyaluronic Acid", "percentage": 2}
      ]
    }
  }'
```

### Test Section 7
```bash
curl -X POST https://your-n8n.../webhook/section-7 \
  -H "Content-Type: application/json" \
  -d '{
    "submissionId": "test-uuid",
    "context": {
      "ingredients": [...],
      "product": {
        "packagingType": "Glass Bottle",
        "netto": {"value": 30, "unit": "ml"}
      }
    }
  }'
```

## Performance Optimization

### Caching Strategy
```javascript
// Cache ingredient data for 1 hour
const cacheKey = `ingredients_${ingredientNames.join('_')}`;
const cached = await redis.get(cacheKey);

if (cached) {
  return JSON.parse(cached);
}

const data = await queryIngredients(ingredientNames);
await redis.setex(cacheKey, 3600, JSON.stringify(data));
return data;
```

### Database Indexing
```sql
-- Ensure these indexes exist
CREATE INDEX idx_ingredients_name ON ingredients_master(name);
CREATE INDEX idx_supplier_ingredients_stock ON supplier_ingredients(in_stock);
CREATE INDEX idx_supplier_ingredients_valid ON supplier_ingredients(price_valid_until);
```

## Error Handling

```javascript
try {
  // Query database
  const result = await mcp.query_ingredient_details(ingredients);
  
  if (!result || result.length === 0) {
    throw new Error('No ingredient data found');
  }
  
  return result;
} catch (error) {
  console.error('MCP Error:', error);
  
  // Fallback to cached data
  const cached = await getCachedData(ingredients);
  if (cached) {
    return cached;
  }
  
  throw error;
}
```

## Troubleshooting

### Issue: MCP server not responding
**Solution**: Check DATABASE_URL and MCP server installation

### Issue: Ingredient not found
**Solution**: Verify ingredient name spelling, check ingredients_master table

### Issue: Price calculation incorrect
**Solution**: Verify waste factor, margin percentage, and packaging cost

---

**Pure MCP sections untuk data accuracy! 🔧**
