CREATE CATALOG IF NOT EXISTS lh_leadscore_ensaio3 COMMENT 'Lead Score · ensaio 3';
CREATE SCHEMA IF NOT EXISTS lh_leadscore_ensaio3.landing COMMENT 'Porta de entrada dos CSVs';
CREATE SCHEMA IF NOT EXISTS lh_leadscore_ensaio3.bronze  COMMENT 'Dado como veio (Auto Loader)';
CREATE SCHEMA IF NOT EXISTS lh_leadscore_ensaio3.silver  COMMENT 'Limpo, deduplicado e unido';
CREATE SCHEMA IF NOT EXISTS lh_leadscore_ensaio3.gold    COMMENT 'IA + Lead Score + Fila do Dia';
CREATE VOLUME IF NOT EXISTS lh_leadscore_ensaio3.landing.raw;
CREATE VOLUME IF NOT EXISTS lh_leadscore_ensaio3.landing.gabarito
