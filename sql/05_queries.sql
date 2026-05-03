-- Query operative per il profilo ACN.

SET @org = 1;


-- 1. Inventario asset critici con classificazione C-I-A.
SELECT
    a.codice_interno,
    a.denominazione,
    a.tipo,
    u.denominazione AS ubicazione,
    u.tipo          AS tipo_ubicazione,
    a.classificazione_c,
    a.classificazione_i,
    a.classificazione_a,
    a.stato_ciclo_vita,
    a.esposto_internet,
    a.contiene_dati_personali
FROM Asset a
JOIN Ubicazione u ON u.id = a.ubicazione_id AND u.is_current = TRUE
WHERE a.organizzazione_id = @org
  AND a.is_current   = TRUE
  AND a.rilevanza_nis2 = TRUE
ORDER BY
    FIELD(a.classificazione_a, 'ALTO', 'MEDIO', 'BASSO'),
    FIELD(a.classificazione_c, 'ALTO', 'MEDIO', 'BASSO'),
    a.codice_interno;


-- 2. Catalogo servizi NIS2 con SLA e criticita'.
SELECT
    s.codice_interno,
    s.denominazione,
    s.criticita,
    CONCAT(s.uptime_target, '%') AS uptime_target,
    s.rto_ore,
    s.rpo_ore,
    s.orario_copertura,
    s.stato_erogazione,
    s.data_attivazione
FROM Servizio s
WHERE s.organizzazione_id = @org
  AND s.is_current  = TRUE
  AND s.ambito_nis2 = TRUE
ORDER BY FIELD(s.criticita, 'ALTA', 'MEDIA', 'BASSA'), s.codice_interno;


-- 3. Mappa dipendenze da fornitori terzi .
SELECT
    CASE d.sorgente_tipo
        WHEN 'ASSET'    THEN a.codice_interno
        WHEN 'SERVIZIO' THEN s.codice_interno
    END AS sorgente,
    d.sorgente_tipo,
    f.denominazione        AS fornitore,
    f.identificativo_fiscale,
    f.paese_sede,
    f.categoria,
    f.cpv_principale,
    f.rilevanza_nis2,
    d.tipo                 AS tipo_dipendenza,
    d.criticita,
    d.descrizione
FROM Dipendenza d
JOIN FornitoreTerzo f ON f.id = d.destinazione_fornitore_id AND f.is_current = TRUE
LEFT JOIN Asset    a ON a.id = d.sorgente_asset_id    AND a.is_current = TRUE
LEFT JOIN Servizio s ON s.id = d.sorgente_servizio_id AND s.is_current = TRUE
WHERE d.organizzazione_id = @org
  AND d.is_current        = TRUE
  AND d.destinazione_tipo = 'FORNITORE'
ORDER BY f.rilevanza_nis2 DESC, f.denominazione;


-- 4. Matrice RACI per servizio NIS2.
SELECT
    s.codice_interno,
    s.denominazione,
    MAX(CASE WHEN r.ruolo_raci = 'RESPONSIBLE' THEN sg.denominazione END) AS responsible,
    MAX(CASE WHEN r.ruolo_raci = 'ACCOUNTABLE' THEN sg.denominazione END) AS accountable,
    GROUP_CONCAT(DISTINCT CASE WHEN r.ruolo_raci = 'CONSULTED' THEN sg.denominazione END
                 ORDER BY sg.denominazione SEPARATOR ', ')                AS consulted,
    GROUP_CONCAT(DISTINCT CASE WHEN r.ruolo_raci = 'INFORMED' THEN sg.denominazione END
                 ORDER BY sg.denominazione SEPARATOR ', ')                AS informed
FROM Servizio s
LEFT JOIN Responsabilita r ON r.target_servizio_id = s.id
                          AND r.is_current = TRUE
                          AND r.target_tipo = 'SERVIZIO'
LEFT JOIN Soggetto sg      ON sg.id = r.soggetto_id AND sg.is_current = TRUE
WHERE s.organizzazione_id = @org
  AND s.is_current  = TRUE
  AND s.ambito_nis2 = TRUE
GROUP BY s.id, s.codice_interno, s.denominazione
ORDER BY s.codice_interno;


-- 5. Snapshot storico: stato degli asset NIS2 a una data arbitraria.
SET @snapshot_at = '2026-04-24 00:00:00';

SELECT
    a.codice_interno,
    a.denominazione,
    a.classificazione_c,
    a.classificazione_i,
    a.classificazione_a,
    a.stato_ciclo_vita,
    a.valid_from,
    COALESCE(a.valid_to, '—') AS valid_to
FROM Asset a
WHERE a.organizzazione_id = @org
  AND a.rilevanza_nis2    = TRUE
  AND a.valid_from <= @snapshot_at
  AND (a.valid_to IS NULL OR a.valid_to > @snapshot_at)
ORDER BY a.codice_interno;
