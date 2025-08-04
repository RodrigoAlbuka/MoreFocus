-- MoreFocus Database Schema - Free Tier Optimized
-- Criado automaticamente pelo setup script

-- Extensões necessárias
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Tabela de clientes
CREATE TABLE IF NOT EXISTS customers (
    id SERIAL PRIMARY KEY,
    uuid UUID DEFAULT uuid_generate_v4() UNIQUE,
    company_name VARCHAR(255) NOT NULL,
    contact_email VARCHAR(255) UNIQUE NOT NULL,
    contact_name VARCHAR(255),
    phone VARCHAR(50),
    market CHAR(2) NOT NULL CHECK (market IN ('US', 'EU', 'BR', 'AR')),
    tier VARCHAR(20) NOT NULL DEFAULT 'starter' CHECK (tier IN ('starter', 'professional', 'enterprise')),
    status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'suspended')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Índices otimizados
CREATE INDEX IF NOT EXISTS idx_customers_market ON customers(market);
CREATE INDEX IF NOT EXISTS idx_customers_tier ON customers(tier);
CREATE INDEX IF NOT EXISTS idx_customers_status ON customers(status);
CREATE INDEX IF NOT EXISTS idx_customers_email ON customers(contact_email);

-- Tabela de workflows
CREATE TABLE IF NOT EXISTS workflows (
    id SERIAL PRIMARY KEY,
    customer_id INTEGER REFERENCES customers(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    workflow_id VARCHAR(255), -- ID do workflow no n8n
    status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'error')),
    config JSONB, -- Configuração em JSON para economizar espaço
    last_execution TIMESTAMP,
    execution_count INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_workflows_customer ON workflows(customer_id);
CREATE INDEX IF NOT EXISTS idx_workflows_status ON workflows(status);
CREATE INDEX IF NOT EXISTS idx_workflows_n8n_id ON workflows(workflow_id);

-- Tabela de execuções (com retenção automática)
CREATE TABLE IF NOT EXISTS executions (
    id SERIAL PRIMARY KEY,
    workflow_id INTEGER REFERENCES workflows(id) ON DELETE CASCADE,
    execution_id VARCHAR(255), -- ID da execução no n8n
    status VARCHAR(20) NOT NULL CHECK (status IN ('success', 'error', 'waiting', 'running')),
    start_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    end_time TIMESTAMP,
    duration_ms INTEGER,
    error_message TEXT,
    data_size INTEGER DEFAULT 0 -- Tamanho dos dados processados
);

CREATE INDEX IF NOT EXISTS idx_executions_workflow ON executions(workflow_id);
CREATE INDEX IF NOT EXISTS idx_executions_status ON executions(status);
CREATE INDEX IF NOT EXISTS idx_executions_date ON executions(start_time);

-- Tabela de métricas agregadas (para economizar espaço)
CREATE TABLE IF NOT EXISTS metrics_daily (
    id SERIAL PRIMARY KEY,
    date DATE NOT NULL,
    customer_id INTEGER REFERENCES customers(id) ON DELETE CASCADE,
    executions_count INTEGER DEFAULT 0,
    success_count INTEGER DEFAULT 0,
    error_count INTEGER DEFAULT 0,
    total_duration_ms BIGINT DEFAULT 0,
    data_processed INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_metrics_daily_unique ON metrics_daily(date, customer_id);

-- Tabela de configurações do sistema
CREATE TABLE IF NOT EXISTS system_config (
    key VARCHAR(100) PRIMARY KEY,
    value JSONB NOT NULL,
    description TEXT,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Inserir configurações iniciais
INSERT INTO system_config (key, value, description) VALUES
('retention_days', '30', 'Dias para manter execuções detalhadas'),
('max_executions_per_day', '1000', 'Máximo de execuções por dia por cliente'),
('backup_enabled', 'true', 'Se backup automático está habilitado'),
('monitoring_enabled', 'true', 'Se monitoramento está habilitado')
ON CONFLICT (key) DO NOTHING;

-- Função para limpeza automática de dados antigos
CREATE OR REPLACE FUNCTION cleanup_old_data()
RETURNS void AS $$
DECLARE
    retention_days INTEGER;
BEGIN
    -- Buscar configuração de retenção
    SELECT (value::text)::integer INTO retention_days 
    FROM system_config WHERE key = 'retention_days';
    
    IF retention_days IS NULL THEN
        retention_days := 30;
    END IF;
    
    -- Limpar execuções antigas
    DELETE FROM executions 
    WHERE start_time < NOW() - INTERVAL '1 day' * retention_days;
    
    -- Limpar métricas antigas (manter 90 dias)
    DELETE FROM metrics_daily 
    WHERE date < NOW() - INTERVAL '90 days';
    
    -- Log da limpeza
    RAISE NOTICE 'Cleanup completed. Retention: % days', retention_days;
END;
$$ LANGUAGE plpgsql;

-- Função para atualizar timestamp de updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Triggers para updated_at
CREATE TRIGGER update_customers_updated_at 
    BEFORE UPDATE ON customers 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_workflows_updated_at 
    BEFORE UPDATE ON workflows 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Função para agregar métricas diárias
CREATE OR REPLACE FUNCTION aggregate_daily_metrics()
RETURNS void AS $$
BEGIN
    INSERT INTO metrics_daily (
        date, customer_id, executions_count, success_count, 
        error_count, total_duration_ms, data_processed
    )
    SELECT 
        DATE(e.start_time) as date,
        w.customer_id,
        COUNT(*) as executions_count,
        COUNT(*) FILTER (WHERE e.status = 'success') as success_count,
        COUNT(*) FILTER (WHERE e.status = 'error') as error_count,
        COALESCE(SUM(e.duration_ms), 0) as total_duration_ms,
        COALESCE(SUM(e.data_size), 0) as data_processed
    FROM executions e
    JOIN workflows w ON e.workflow_id = w.id
    WHERE DATE(e.start_time) = CURRENT_DATE - INTERVAL '1 day'
    GROUP BY DATE(e.start_time), w.customer_id
    ON CONFLICT (date, customer_id) DO UPDATE SET
        executions_count = EXCLUDED.executions_count,
        success_count = EXCLUDED.success_count,
        error_count = EXCLUDED.error_count,
        total_duration_ms = EXCLUDED.total_duration_ms,
        data_processed = EXCLUDED.data_processed;
END;
$$ LANGUAGE plpgsql;

-- Inserir cliente de exemplo para testes
INSERT INTO customers (company_name, contact_email, contact_name, market, tier) VALUES
('MoreFocus Demo', 'demo@morefocus.com', 'Demo User', 'BR', 'starter')
ON CONFLICT (contact_email) DO NOTHING;

-- Mensagem de sucesso
DO $$
BEGIN
    RAISE NOTICE 'MoreFocus database initialized successfully!';
    RAISE NOTICE 'Free tier optimizations applied.';
    RAISE NOTICE 'Remember to run cleanup_old_data() periodically.';
END $$;
