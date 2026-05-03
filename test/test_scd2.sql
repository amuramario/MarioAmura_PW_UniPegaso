-- Test funzionale SCD2

SET FOREIGN_KEY_CHECKS = 0;
DELETE FROM audit_log;
DELETE FROM Responsabilita;
DELETE FROM Dipendenza;
DELETE FROM Asset_Servizio;
DELETE FROM Soggetto;
DELETE FROM Servizio;
DELETE FROM Asset;
DELETE FROM Ubicazione;
DELETE FROM FornitoreTerzo;
DELETE FROM Organizzazione;
SET FOREIGN_KEY_CHECKS = 1;

ALTER TABLE Asset           AUTO_INCREMENT = 1;
ALTER TABLE Ubicazione      AUTO_INCREMENT = 1;
ALTER TABLE Organizzazione  AUTO_INCREMENT = 1;


-- Setup minimo
INSERT INTO Organizzazione
    (ragione_sociale, codice_fiscale, partita_iva, pec, allegato, settore_nis2, categoria_nis2)
VALUES
    ('Acme Banking', '07812340968', '07812340968', 'acme@pec.it', 'I', 'BANCARIO', 'ESSENZIALE');

INSERT INTO Ubicazione
    (organizzazione_id, denominazione, tipo, tipo_gestione, paese, indirizzo)
VALUES
    (1, 'Sede Roma', 'SEDE_LEGALE', 'PROPRIETARIA', 'IT', 'Via del Corso 142');


-- Versione 1 (classificazione_c = MEDIO).
INSERT INTO Asset
    (organizzazione_id, ubicazione_id, codice_interno, denominazione, tipo,
     classificazione_c, classificazione_i, classificazione_a, rilevanza_nis2)
VALUES
    (1, 1, 'DB-CLI', 'DB clienti', 'DATABASE', 'MEDIO', 'ALTO', 'ALTO', TRUE);

SELECT SLEEP(1);

-- Timestamp intermedio (solo v1 attiva).
SET @t_intermedio = NOW(6);

SELECT SLEEP(1);


-- Chiusura v1 e inserimento v2.
START TRANSACTION;
CALL sp_close_version('Asset', 1);
INSERT INTO Asset
    (organizzazione_id, ubicazione_id, codice_interno, denominazione, tipo,
     classificazione_c, classificazione_i, classificazione_a, rilevanza_nis2)
VALUES
    (1, 1, 'DB-CLI', 'DB clienti', 'DATABASE', 'ALTO', 'ALTO', 'ALTO', TRUE);
COMMIT;


-- Le due righe sull'asset: la v1 chiusa, la v2 corrente.
SELECT id, codice_interno, classificazione_c, is_current, valid_from, valid_to
FROM Asset
ORDER BY id;


-- Snapshot al timestamp intermedio: deve restituire la v1 (MEDIO).
SELECT id, classificazione_c AS c_al_momento, valid_from, valid_to
FROM Asset
WHERE codice_interno = 'DB-CLI'
  AND valid_from <= @t_intermedio
  AND (valid_to IS NULL OR valid_to > @t_intermedio);


-- Snapshot adesso: deve restituire la v2 (ALTO).
SELECT id, classificazione_c AS c_adesso, valid_from, valid_to
FROM Asset
WHERE codice_interno = 'DB-CLI'
  AND valid_from <= NOW(6)
  AND (valid_to IS NULL OR valid_to > NOW(6));


-- Audit trail: INSERT v1, UPDATE di chiusura, INSERT v2.
SELECT operazione, record_id, ts_evento,
       JSON_EXTRACT(payload_precedente, '$.classificazione_c') AS c_prima,
       JSON_EXTRACT(payload_nuovo,      '$.classificazione_c') AS c_dopo,
       JSON_EXTRACT(payload_nuovo,      '$.is_current')        AS is_current_dopo
FROM audit_log
WHERE tabella = 'Asset'
  AND record_id IN (1, 2)
  AND ts_evento >= (SELECT MIN(ts_evento) FROM audit_log WHERE tabella='Asset' AND operazione='INSERT')
ORDER BY id;
