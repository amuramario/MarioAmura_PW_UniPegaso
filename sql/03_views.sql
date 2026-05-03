-- View per l'esportazione CSV del profilo ACN.

CREATE OR REPLACE VIEW v_profilo_asset AS
SELECT
    o.codice_fiscale                       AS organizzazione_cf,
    o.ragione_sociale                      AS organizzazione,
    a.codice_interno                       AS asset_codice,
    a.denominazione                        AS asset_denominazione,
    a.tipo                                 AS asset_tipo,
    u.denominazione                        AS ubicazione,
    u.tipo                                 AS ubicazione_tipo,
    u.paese                                AS ubicazione_paese,
    a.classificazione_c                    AS riservatezza,
    a.classificazione_i                    AS integrita,
    a.classificazione_a                    AS disponibilita,
    a.stato_ciclo_vita,
    IF(a.esposto_internet, 'SI', 'NO')     AS esposto_internet,
    IF(a.contiene_dati_personali,'SI','NO')AS dati_personali,
    a.data_introduzione,
    a.valid_from
FROM Asset a
JOIN Organizzazione o ON o.id = a.organizzazione_id AND o.is_current = TRUE
JOIN Ubicazione u     ON u.id = a.ubicazione_id     AND u.is_current = TRUE
WHERE a.is_current     = TRUE
  AND a.rilevanza_nis2 = TRUE;


CREATE OR REPLACE VIEW v_profilo_servizi AS
SELECT
    o.codice_fiscale                          AS organizzazione_cf,
    o.ragione_sociale                         AS organizzazione,
    s.codice_interno                          AS servizio_codice,
    s.denominazione                           AS servizio_denominazione,
    s.descrizione,
    s.criticita,
    CONCAT(FORMAT(s.uptime_target, 3), ' %')  AS uptime_target,
    s.rto_ore,
    s.rpo_ore,
    s.orario_copertura,
    s.stato_erogazione,
    s.data_attivazione
FROM Servizio s
JOIN Organizzazione o ON o.id = s.organizzazione_id AND o.is_current = TRUE
WHERE s.is_current  = TRUE
  AND s.ambito_nis2 = TRUE;


CREATE OR REPLACE VIEW v_profilo_fornitori_rilevanti AS
SELECT
    o.codice_fiscale                          AS organizzazione_cf,
    o.ragione_sociale                         AS organizzazione,
    f.denominazione                           AS fornitore,
    f.identificativo_fiscale                  AS fornitore_id_fiscale,
    f.paese_sede,
    IF(f.sede_legale_extra_ue, 'SI', 'NO')    AS extra_ue,
    f.categoria,
    f.cpv_principale,
    f.criterio_rilevanza,
    f.certificazioni,
    f.data_inizio_rapporto,
    f.stato_rapporto
FROM FornitoreTerzo f
JOIN Organizzazione o ON o.id = f.organizzazione_id AND o.is_current = TRUE
WHERE f.is_current     = TRUE
  AND f.rilevanza_nis2 = TRUE;


CREATE OR REPLACE VIEW v_profilo_punti_contatto AS
SELECT
    o.codice_fiscale  AS organizzazione_cf,
    o.ragione_sociale AS organizzazione,
    s.denominazione   AS soggetto,
    s.nome,
    s.cognome,
    s.email,
    s.telefono,
    s.ruolo_organizzativo
FROM Soggetto s
JOIN Organizzazione o ON o.id = s.organizzazione_id AND o.is_current = TRUE
WHERE s.is_current            = TRUE
  AND s.is_punto_contatto_acn = TRUE
  AND s.stato                 = 'ATTIVO';


CREATE OR REPLACE VIEW v_profilo_dipendenze_terzi AS
SELECT
    o.codice_fiscale  AS organizzazione_cf,
    o.ragione_sociale AS organizzazione,
    CASE d.sorgente_tipo
        WHEN 'ASSET'    THEN a.codice_interno
        WHEN 'SERVIZIO' THEN s.codice_interno
    END               AS sorgente_codice,
    d.sorgente_tipo,
    f.denominazione   AS fornitore,
    f.identificativo_fiscale,
    f.paese_sede,
    f.cpv_principale,
    d.tipo            AS tipo_dipendenza,
    d.criticita,
    d.descrizione
FROM Dipendenza d
JOIN Organizzazione  o ON o.id = d.organizzazione_id          AND o.is_current = TRUE
JOIN FornitoreTerzo  f ON f.id = d.destinazione_fornitore_id  AND f.is_current = TRUE
LEFT JOIN Asset      a ON a.id = d.sorgente_asset_id          AND a.is_current = TRUE
LEFT JOIN Servizio   s ON s.id = d.sorgente_servizio_id       AND s.is_current = TRUE
WHERE d.is_current        = TRUE
  AND d.destinazione_tipo = 'FORNITORE';



