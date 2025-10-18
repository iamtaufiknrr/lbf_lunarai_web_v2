-- ============================================================================
-- SUPPLIER & PRICING DATABASE SCHEMA - LunarAI Beauty
-- ============================================================================
-- Purpose: Manage supplier data, ingredient pricing, and cost calculations
-- Version: 1.0.0
-- Date: 2025-10-18
-- ============================================================================

-- ============================================
-- TABLE: suppliers
-- ============================================
-- Stores supplier information and contact details
CREATE TABLE suppliers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    code VARCHAR(50) UNIQUE NOT NULL,
    country VARCHAR(100) NOT NULL,
    contact_person VARCHAR(255),
    email VARCHAR(255),
    phone VARCHAR(50),
    website TEXT,
    payment_terms VARCHAR(100),
    lead_time_days INTEGER,
    minimum_order_quantity DECIMAL(10,2),
    rating DECIMAL(3,2) CHECK (rating >= 0 AND rating <= 5),
    is_active BOOLEAN DEFAULT true,
    notes TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_suppliers_code ON suppliers(code);
CREATE INDEX idx_suppliers_country ON suppliers(country);
CREATE INDEX idx_suppliers_is_active ON suppliers(is_active);

-- ============================================
-- TABLE: ingredients_master
-- ============================================
-- Master list of all cosmetic ingredients
CREATE TABLE ingredients_master (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    inci_name VARCHAR(255) NOT NULL,
    category VARCHAR(100), -- e.g., 'Active', 'Emulsifier', 'Preservative', 'Thickener'
    function TEXT, -- Primary function
    typical_usage_min DECIMAL(5,2), -- Minimum percentage
    typical_usage_max DECIMAL(5,2), -- Maximum percentage
    ph_range VARCHAR(50),
    solubility VARCHAR(100), -- 'Water', 'Oil', 'Both'
    origin VARCHAR(100), -- 'Natural', 'Synthetic', 'Biotechnology'
    restrictions TEXT, -- Regulatory restrictions
    allergen_info TEXT,
    vegan BOOLEAN DEFAULT true,
    halal BOOLEAN DEFAULT true,
    cruelty_free BOOLEAN DEFAULT true,
    description TEXT,
    benefits TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_ingredients_name ON ingredients_master(name);
CREATE INDEX idx_ingredients_inci ON ingredients_master(inci_name);
CREATE INDEX idx_ingredients_category ON ingredients_master(category);
CREATE INDEX idx_ingredients_function ON ingredients_master USING GIN(to_tsvector('english', function));

-- ============================================
-- TABLE: supplier_ingredients
-- ============================================
-- Links suppliers to ingredients with pricing
CREATE TABLE supplier_ingredients (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    supplier_id UUID NOT NULL REFERENCES suppliers(id) ON DELETE CASCADE,
    ingredient_id UUID NOT NULL REFERENCES ingredients_master(id) ON DELETE CASCADE,
    supplier_product_code VARCHAR(100),
    grade VARCHAR(50), -- e.g., 'Cosmetic', 'Pharmaceutical', 'Food'
    purity_percentage DECIMAL(5,2),
    
    -- Pricing (per kg)
    price_per_kg DECIMAL(10,2) NOT NULL,
    currency VARCHAR(10) DEFAULT 'IDR',
    
    -- Minimum order
    moq_kg DECIMAL(10,2),
    
    -- Stock info
    in_stock BOOLEAN DEFAULT true,
    stock_quantity_kg DECIMAL(10,2),
    
    -- Dates
    price_valid_from DATE NOT NULL,
    price_valid_until DATE,
    last_updated TIMESTAMP NOT NULL DEFAULT NOW(),
    
    -- Additional info
    lead_time_days INTEGER,
    notes TEXT,
    
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW(),
    
    UNIQUE(supplier_id, ingredient_id, grade)
);

CREATE INDEX idx_supplier_ingredients_supplier ON supplier_ingredients(supplier_id);
CREATE INDEX idx_supplier_ingredients_ingredient ON supplier_ingredients(ingredient_id);
CREATE INDEX idx_supplier_ingredients_price ON supplier_ingredients(price_per_kg);
CREATE INDEX idx_supplier_ingredients_stock ON supplier_ingredients(in_stock);

-- ============================================
-- TABLE: formulation_costs
-- ============================================
-- Stores calculated costs for formulations
CREATE TABLE formulation_costs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    submission_id UUID REFERENCES submissions(id) ON DELETE CASCADE,
    formulation_id VARCHAR(100), -- Reference to RnD formulation ID
    
    -- Ingredient costs
    total_ingredient_cost DECIMAL(10,2) NOT NULL,
    ingredient_cost_breakdown JSONB, -- Detailed breakdown per ingredient
    
    -- Waste factor (10-20%)
    waste_percentage DECIMAL(5,2) DEFAULT 15.0,
    waste_cost DECIMAL(10,2),
    
    -- Total manufacturing cost
    manufacturing_cost_base DECIMAL(10,2) NOT NULL,
    manufacturing_cost_with_waste DECIMAL(10,2) NOT NULL,
    
    -- Cost range (-20% to +30%)
    cost_range_min DECIMAL(10,2), -- -20%
    cost_range_max DECIMAL(10,2), -- +30%
    
    -- Packaging cost
    packaging_cost DECIMAL(10,2),
    
    -- Labor cost
    labor_cost DECIMAL(10,2),
    
    -- Overhead
    overhead_percentage DECIMAL(5,2) DEFAULT 10.0,
    overhead_cost DECIMAL(10,2),
    
    -- Total cost
    total_cost DECIMAL(10,2) NOT NULL,
    
    -- Pricing
    target_margin_percentage DECIMAL(5,2),
    recommended_retail_price DECIMAL(10,2),
    retail_price_range_min DECIMAL(10,2),
    retail_price_range_max DECIMAL(10,2),
    
    -- Break-even analysis
    break_even_units INTEGER,
    
    -- Batch info
    batch_size INTEGER,
    cost_per_unit DECIMAL(10,2),
    
    -- Metadata
    calculation_date TIMESTAMP NOT NULL DEFAULT NOW(),
    calculated_by VARCHAR(100), -- 'AI Agent' or user ID
    notes TEXT,
    
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_formulation_costs_submission ON formulation_costs(submission_id);
CREATE INDEX idx_formulation_costs_formulation ON formulation_costs(formulation_id);
CREATE INDEX idx_formulation_costs_date ON formulation_costs(calculation_date DESC);

-- ============================================
-- TABLE: packaging_costs
-- ============================================
-- Stores packaging material costs
CREATE TABLE packaging_costs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    packaging_type VARCHAR(100) NOT NULL, -- 'Dropper', 'Jar', 'Tube', etc.
    material VARCHAR(100), -- 'Glass', 'Plastic', 'Aluminum'
    size_ml INTEGER,
    supplier_id UUID REFERENCES suppliers(id),
    
    -- Pricing
    price_per_unit DECIMAL(10,2) NOT NULL,
    currency VARCHAR(10) DEFAULT 'IDR',
    moq INTEGER,
    
    -- Additional components
    includes_cap BOOLEAN DEFAULT true,
    includes_dropper BOOLEAN DEFAULT false,
    includes_pump BOOLEAN DEFAULT false,
    includes_box BOOLEAN DEFAULT false,
    
    -- Stock
    in_stock BOOLEAN DEFAULT true,
    lead_time_days INTEGER,
    
    -- Dates
    price_valid_from DATE NOT NULL,
    price_valid_until DATE,
    
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_packaging_costs_type ON packaging_costs(packaging_type);
CREATE INDEX idx_packaging_costs_material ON packaging_costs(material);
CREATE INDEX idx_packaging_costs_size ON packaging_costs(size_ml);

-- ============================================
-- TABLE: cost_calculation_logs
-- ============================================
-- Audit trail for cost calculations
CREATE TABLE cost_calculation_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    formulation_cost_id UUID REFERENCES formulation_costs(id) ON DELETE CASCADE,
    action VARCHAR(50) NOT NULL, -- 'CALCULATE', 'UPDATE', 'RECALCULATE'
    input_data JSONB,
    output_data JSONB,
    calculation_method VARCHAR(100), -- 'AI_AGENT', 'MANUAL', 'BATCH'
    executed_by VARCHAR(100),
    execution_time_ms INTEGER,
    status VARCHAR(50), -- 'SUCCESS', 'ERROR', 'WARNING'
    error_message TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_cost_logs_formulation ON cost_calculation_logs(formulation_cost_id);
CREATE INDEX idx_cost_logs_action ON cost_calculation_logs(action);
CREATE INDEX idx_cost_logs_status ON cost_calculation_logs(status);
CREATE INDEX idx_cost_logs_date ON cost_calculation_logs(created_at DESC);

-- ============================================
-- TABLE: price_history
-- ============================================
-- Track price changes over time
CREATE TABLE price_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    supplier_ingredient_id UUID REFERENCES supplier_ingredients(id) ON DELETE CASCADE,
    old_price DECIMAL(10,2),
    new_price DECIMAL(10,2) NOT NULL,
    price_change_percentage DECIMAL(5,2),
    reason TEXT,
    changed_by VARCHAR(100),
    effective_date DATE NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_price_history_supplier_ingredient ON price_history(supplier_ingredient_id);
CREATE INDEX idx_price_history_date ON price_history(effective_date DESC);

-- ============================================
-- VIEWS
-- ============================================

-- View: Current ingredient prices with supplier info
CREATE VIEW v_current_ingredient_prices AS
SELECT 
    im.id AS ingredient_id,
    im.name AS ingredient_name,
    im.inci_name,
    im.category,
    s.id AS supplier_id,
    s.name AS supplier_name,
    s.code AS supplier_code,
    s.country AS supplier_country,
    si.price_per_kg,
    si.currency,
    si.moq_kg,
    si.grade,
    si.purity_percentage,
    si.in_stock,
    si.price_valid_until,
    si.last_updated
FROM ingredients_master im
JOIN supplier_ingredients si ON im.id = si.ingredient_id
JOIN suppliers s ON si.supplier_id = s.id
WHERE si.in_stock = true
  AND s.is_active = true
  AND (si.price_valid_until IS NULL OR si.price_valid_until >= CURRENT_DATE)
ORDER BY si.price_per_kg ASC;

-- View: Formulation cost summary
CREATE VIEW v_formulation_cost_summary AS
SELECT 
    fc.id,
    fc.submission_id,
    fc.formulation_id,
    fc.manufacturing_cost_base,
    fc.manufacturing_cost_with_waste,
    fc.waste_percentage,
    fc.cost_range_min,
    fc.cost_range_max,
    fc.recommended_retail_price,
    fc.retail_price_range_min,
    fc.retail_price_range_max,
    fc.target_margin_percentage,
    fc.break_even_units,
    fc.batch_size,
    fc.cost_per_unit,
    fc.calculation_date,
    s.brand_name,
    s.status AS submission_status
FROM formulation_costs fc
LEFT JOIN submissions s ON fc.submission_id = s.id
ORDER BY fc.calculation_date DESC;

-- ============================================
-- FUNCTIONS
-- ============================================

-- Function: Calculate cost with waste factor
CREATE OR REPLACE FUNCTION calculate_cost_with_waste(
    base_cost DECIMAL,
    waste_percentage DECIMAL
) RETURNS DECIMAL AS $$
BEGIN
    RETURN base_cost * (1 + (waste_percentage / 100));
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Function: Calculate price range
CREATE OR REPLACE FUNCTION calculate_price_range(
    base_price DECIMAL,
    min_percentage DECIMAL DEFAULT -20,
    max_percentage DECIMAL DEFAULT 30
) RETURNS TABLE(min_price DECIMAL, max_price DECIMAL) AS $$
BEGIN
    RETURN QUERY SELECT 
        ROUND(base_price * (1 + (min_percentage / 100)), 2) AS min_price,
        ROUND(base_price * (1 + (max_percentage / 100)), 2) AS max_price;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Function: Calculate retail price from cost and margin
CREATE OR REPLACE FUNCTION calculate_retail_price(
    total_cost DECIMAL,
    margin_percentage DECIMAL
) RETURNS DECIMAL AS $$
BEGIN
    RETURN ROUND(total_cost / (1 - (margin_percentage / 100)), 2);
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Function: Calculate break-even units
CREATE OR REPLACE FUNCTION calculate_break_even(
    fixed_costs DECIMAL,
    price_per_unit DECIMAL,
    variable_cost_per_unit DECIMAL
) RETURNS INTEGER AS $$
BEGIN
    IF (price_per_unit - variable_cost_per_unit) <= 0 THEN
        RETURN NULL; -- Cannot break even
    END IF;
    RETURN CEIL(fixed_costs / (price_per_unit - variable_cost_per_unit));
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- ============================================
-- TRIGGERS
-- ============================================

-- Trigger: Update timestamp on suppliers
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_suppliers_updated_at
    BEFORE UPDATE ON suppliers
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_ingredients_master_updated_at
    BEFORE UPDATE ON ingredients_master
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_supplier_ingredients_updated_at
    BEFORE UPDATE ON supplier_ingredients
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_formulation_costs_updated_at
    BEFORE UPDATE ON formulation_costs
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Trigger: Log price changes
CREATE OR REPLACE FUNCTION log_price_change()
RETURNS TRIGGER AS $$
BEGIN
    IF OLD.price_per_kg <> NEW.price_per_kg THEN
        INSERT INTO price_history (
            supplier_ingredient_id,
            old_price,
            new_price,
            price_change_percentage,
            effective_date
        ) VALUES (
            NEW.id,
            OLD.price_per_kg,
            NEW.price_per_kg,
            ROUND(((NEW.price_per_kg - OLD.price_per_kg) / OLD.price_per_kg * 100), 2),
            CURRENT_DATE
        );
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER track_price_changes
    AFTER UPDATE ON supplier_ingredients
    FOR EACH ROW
    WHEN (OLD.price_per_kg IS DISTINCT FROM NEW.price_per_kg)
    EXECUTE FUNCTION log_price_change();

-- ============================================
-- SAMPLE DATA (Optional - for testing)
-- ============================================

-- Insert sample suppliers
INSERT INTO suppliers (name, code, country, contact_person, email, phone, rating, is_active) VALUES
('PT Bahan Kosmetik Indonesia', 'BKI001', 'Indonesia', 'Budi Santoso', 'budi@bki.co.id', '+62-21-1234567', 4.5, true),
('Global Ingredients Supply', 'GIS002', 'Singapore', 'Jane Tan', 'jane@gis.com.sg', '+65-6123-4567', 4.8, true),
('Natural Extracts Co', 'NEC003', 'Indonesia', 'Siti Nurhaliza', 'siti@nec.co.id', '+62-22-7654321', 4.3, true);

-- Insert sample ingredients
INSERT INTO ingredients_master (name, inci_name, category, function, typical_usage_min, typical_usage_max, ph_range, solubility, origin, vegan, halal) VALUES
('Niacinamide', 'Niacinamide', 'Active', 'Brightening, pore refinement', 2.0, 10.0, '5.0-7.0', 'Water', 'Synthetic', true, true),
('Hyaluronic Acid', 'Sodium Hyaluronate', 'Active', 'Hydration, plumping', 0.1, 2.0, '5.0-7.0', 'Water', 'Biotechnology', true, true),
('Vitamin C', 'Ascorbic Acid', 'Active', 'Brightening, antioxidant', 5.0, 20.0, '2.0-3.5', 'Water', 'Synthetic', true, true),
('Centella Asiatica Extract', 'Centella Asiatica Extract', 'Active', 'Soothing, repair', 1.0, 5.0, '5.0-6.0', 'Water', 'Natural', true, true),
('Glycerin', 'Glycerin', 'Humectant', 'Moisturizing', 3.0, 10.0, '5.0-7.0', 'Water', 'Natural', true, true);

-- Insert sample supplier ingredients with pricing
INSERT INTO supplier_ingredients (supplier_id, ingredient_id, supplier_product_code, grade, purity_percentage, price_per_kg, moq_kg, in_stock, price_valid_from, price_valid_until, lead_time_days) 
SELECT 
    s.id,
    im.id,
    'PROD-' || SUBSTRING(im.inci_name, 1, 5),
    'Cosmetic',
    99.0,
    CASE im.name
        WHEN 'Niacinamide' THEN 850000
        WHEN 'Hyaluronic Acid' THEN 2500000
        WHEN 'Vitamin C' THEN 650000
        WHEN 'Centella Asiatica Extract' THEN 1200000
        WHEN 'Glycerin' THEN 45000
    END,
    1.0,
    true,
    CURRENT_DATE,
    CURRENT_DATE + INTERVAL '6 months',
    14
FROM suppliers s
CROSS JOIN ingredients_master im
WHERE s.code = 'BKI001'
LIMIT 5;

-- Insert sample packaging costs
INSERT INTO packaging_costs (packaging_type, material, size_ml, price_per_unit, moq, includes_cap, includes_dropper, in_stock, price_valid_from, lead_time_days) VALUES
('Dropper', 'Glass', 30, 15000, 500, true, true, true, CURRENT_DATE, 21),
('Jar', 'Glass', 50, 12000, 500, true, false, true, CURRENT_DATE, 21),
('Tube', 'Plastic', 30, 5000, 1000, true, false, true, CURRENT_DATE, 14),
('Spray', 'Plastic', 50, 8000, 500, true, false, true, CURRENT_DATE, 14),
('Pump Bottle', 'Plastic', 100, 18000, 500, true, true, true, CURRENT_DATE, 21);

-- ============================================
-- COMMENTS
-- ============================================

COMMENT ON TABLE suppliers IS 'Master list of ingredient and packaging suppliers';
COMMENT ON TABLE ingredients_master IS 'Master database of cosmetic ingredients with properties';
COMMENT ON TABLE supplier_ingredients IS 'Links suppliers to ingredients with current pricing';
COMMENT ON TABLE formulation_costs IS 'Calculated costs for product formulations';
COMMENT ON TABLE packaging_costs IS 'Packaging material costs from suppliers';
COMMENT ON TABLE cost_calculation_logs IS 'Audit trail for all cost calculations';
COMMENT ON TABLE price_history IS 'Historical tracking of ingredient price changes';

-- ============================================
-- GRANTS (Optional - adjust based on your security model)
-- ============================================

-- Grant read access to application user
-- GRANT SELECT ON ALL TABLES IN SCHEMA public TO app_user;
-- GRANT INSERT, UPDATE ON formulation_costs, cost_calculation_logs TO app_user;

-- ============================================
-- END OF SCHEMA
-- ============================================

-- Verification queries
SELECT 'Suppliers created: ' || COUNT(*) FROM suppliers;
SELECT 'Ingredients created: ' || COUNT(*) FROM ingredients_master;
SELECT 'Supplier ingredients created: ' || COUNT(*) FROM supplier_ingredients;
SELECT 'Packaging options created: ' || COUNT(*) FROM packaging_costs;
