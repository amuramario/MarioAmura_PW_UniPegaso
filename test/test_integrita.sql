-- Test di integrita'

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

ALTER TABLE audit_log       AUTO_INCREMENT = 1;
ALTER TABLE Responsabilita  AUTO_INCREMENT = 1;
ALTER TABLE Dipendenza      AUTO_INCREMENT = 1;
ALTER TABLE Asset_Servizio  AUTO_INCREMENT = 1;
ALTER TABLE Soggetto        AUTO_INCREMENT = 1;
ALTER TABLE Servizio        AUTO_INCREMENT = 1;
ALTER TABLE Asset           AUTO_INCREMENT = 1;
ALTER TABLE Ubicazione      AUTO_INCREMENT = 1;
ALTER TABLE FornitoreTerzo  AUTO_INCREMENT = 1;
ALTER TABLE Organizzazione  AUTO_INCREMENT = 1;


-- Setup: due organizzazioni, con una dotazione minima per poi testare i cross-tenant.
INSERT INTO Organizzazione (ragione_sociale, codice_fiscale, partita_iva, pec, allegato, settore_nis2, categoria_nis2)
VALUES ('Acme Banking', '12345678901', '12345678901', 'acme@pec.it', 'I', 'BANCARIO', 'ESSENZIALE');
INSERT INTO Organizzazione (ragione_sociale, codice_fiscale, partita_iva, pec, allegato, settore_nis2, categoria_nis2)
VALUES ('Beta Hospital', '98765432109', '98765432109', 'beta@pec.it', 'I', 'SANITA', 'ESSENZIALE');

INSERT INTO FornitoreTerzo (organizzazione_id, denominazione, identificativo_fiscale, paese_sede, categoria, rilevanza_nis2, criterio_rilevanza, cpv_principale)
VALUES (1, 'AWS Acme', 'LU10000001', 'LU', 'CLOUD_PROVIDER', TRUE, 'infra', '72000000-5');
INSERT INTO FornitoreTerzo (organizzazione_id, denominazione, identificativo_fiscale, paese_sede, categoria, rilevanza_nis2, criterio_rilevanza, cpv_principale)
VALUES (2, 'AWS Beta', 'LU10000002', 'LU', 'CLOUD_PROVIDER', TRUE, 'infra', '72000000-5');

INSERT INTO Ubicazione (organizzazione_id, denominazione, tipo, tipo_gestione, paese, indirizzo)
VALUES (1, 'Acme Roma', 'SEDE_LEGALE', 'PROPRIETARIA', 'IT', 'Via Roma 1');
INSERT INTO Ubicazione (organizzazione_id, denominazione, tipo, tipo_gestione, paese, indirizzo)
VALUES (2, 'Beta Milano', 'SEDE_LEGALE', 'PROPRIETARIA', 'IT', 'Via Milano 1');

INSERT INTO Asset (organizzazione_id, ubicazione_id, codice_interno, denominazione, tipo, classificazione_c, classificazione_i, classificazione_a)
VALUES (1, 1, 'ACME-DB-01', 'DB Acme', 'DATABASE', 'ALTO', 'ALTO', 'ALTO');
INSERT INTO Asset (organizzazione_id, ubicazione_id, codice_interno, denominazione, tipo, classificazione_c, classificazione_i, classificazione_a)
VALUES (2, 2, 'BETA-DB-01', 'DB Beta', 'DATABASE', 'ALTO', 'ALTO', 'ALTO');

INSERT INTO Servizio (organizzazione_id, codice_interno, denominazione, descrizione, criticita, ambito_nis2, uptime_target, rto_ore, rpo_ore, orario_copertura)
VALUES (1, 'ACME-HB', 'Home banking Acme', 'servizio online', 'ALTA', TRUE, 99.9, 2, 1, 'H24');
INSERT INTO Servizio (organizzazione_id, codice_interno, denominazione, descrizione, criticita, ambito_nis2, uptime_target, rto_ore, rpo_ore, orario_copertura)
VALUES (2, 'BETA-CAR', 'Cartella clinica Beta', 'servizio ospedaliero', 'ALTA', TRUE, 99.9, 2, 1, 'H24');

INSERT INTO Soggetto (organizzazione_id, tipo, denominazione, nome, cognome, email)
VALUES (1, 'PERSONA', 'Mario Rossi', 'Mario', 'Rossi', 'mario@acme.it');
INSERT INTO Soggetto (organizzazione_id, tipo, denominazione, nome, cognome, email)
VALUES (2, 'PERSONA', 'Luisa Neri', 'Luisa', 'Neri', 'luisa@beta.it');


-- Organizzazione

-- Test 1: allegato I con settore dell'allegato III
INSERT INTO Organizzazione (ragione_sociale, codice_fiscale, pec, allegato, settore_nis2, categoria_nis2)
VALUES ('X', '11111111111', 'x@pec.it', 'I', 'PA_CENTRALE', 'ESSENZIALE');

-- Test 2: CF con lunghezza invalida
INSERT INTO Organizzazione (ragione_sociale, codice_fiscale, pec, allegato, settore_nis2, categoria_nis2)
VALUES ('X', '1234567890', 'x@pec.it', 'III', 'PA_CENTRALE', 'ESSENZIALE');

-- Test 3: SCD2 record corrente con valid_to valorizzato
INSERT INTO Organizzazione (ragione_sociale, codice_fiscale, pec, allegato, settore_nis2, categoria_nis2, is_current, valid_to)
VALUES ('X', '22222222222', 'x@pec.it', 'III', 'PA_CENTRALE', 'ESSENZIALE', TRUE, '2030-01-01');

-- Test 4: codice fiscale duplicato fra due record correnti
INSERT INTO Organizzazione (ragione_sociale, codice_fiscale, pec, allegato, settore_nis2, categoria_nis2)
VALUES ('Duplicata Acme', '12345678901', 'dup@pec.it', 'I', 'BANCARIO', 'ESSENZIALE');


-- FornitoreTerzo

-- Test 5: categoria ALTRO senza note
INSERT INTO FornitoreTerzo (organizzazione_id, denominazione, identificativo_fiscale, paese_sede, categoria)
VALUES (1, 'Forn X', 'IT20000001', 'IT', 'ALTRO');

-- Test 6: rilevanza NIS2 senza criterio ne CPV
INSERT INTO FornitoreTerzo (organizzazione_id, denominazione, identificativo_fiscale, paese_sede, categoria, rilevanza_nis2)
VALUES (1, 'Forn Y', 'IT20000002', 'IT', 'TELCO', TRUE);

-- Test 7: CPV fuori formato
INSERT INTO FornitoreTerzo (organizzazione_id, denominazione, identificativo_fiscale, paese_sede, categoria, rilevanza_nis2, criterio_rilevanza, cpv_principale)
VALUES (1, 'Forn Z', 'IT20000003', 'IT', 'TELCO', TRUE, 'criterio', '123-45');

-- Test 8: stato CESSATO senza data_fine_rapporto
INSERT INTO FornitoreTerzo (organizzazione_id, denominazione, identificativo_fiscale, paese_sede, categoria, stato_rapporto)
VALUES (1, 'Forn W', 'IT20000004', 'IT', 'TELCO', 'CESSATO');

-- Test 9: paese in minuscolo
INSERT INTO FornitoreTerzo (organizzazione_id, denominazione, identificativo_fiscale, paese_sede, categoria)
VALUES (1, 'Forn K', 'IT20000005', 'it', 'TELCO');

-- Test 10: identificativo fiscale duplicato nella stessa org
INSERT INTO FornitoreTerzo (organizzazione_id, denominazione, identificativo_fiscale, paese_sede, categoria)
VALUES (1, 'Forn doppio', 'LU10000001', 'LU', 'CLOUD_PROVIDER');


-- Ubicazione

-- Test 11: CLOUD_PUBBLICO senza fornitore_terzo_id
INSERT INTO Ubicazione (organizzazione_id, denominazione, tipo, tipo_gestione, paese)
VALUES (1, 'Cloud orfano', 'CLOUD_REGION', 'CLOUD_PUBBLICO', 'IT');

-- Test 12: PROPRIETARIA con fornitore valorizzato
INSERT INTO Ubicazione (organizzazione_id, denominazione, tipo, tipo_gestione, paese, indirizzo, fornitore_terzo_id)
VALUES (1, 'DC proprio+fornitore', 'DATACENTER', 'PROPRIETARIA', 'IT', 'Via X', 1);

-- Test 13: SEDE_LEGALE senza indirizzo
INSERT INTO Ubicazione (organizzazione_id, denominazione, tipo, tipo_gestione, paese)
VALUES (1, 'Sede senza indirizzo', 'SEDE_LEGALE', 'AFFITTATA', 'IT');

-- Test 14: seconda SEDE_LEGALE corrente per la stessa organizzazione
INSERT INTO Ubicazione (organizzazione_id, denominazione, tipo, tipo_gestione, paese, indirizzo)
VALUES (1, 'Altra sede legale Acme', 'SEDE_LEGALE', 'AFFITTATA', 'IT', 'Via Altra 1');

-- Test 15: trigger multi-tenant — ubicazione Acme con fornitore Beta
INSERT INTO Ubicazione (organizzazione_id, denominazione, tipo, tipo_gestione, paese, fornitore_terzo_id)
VALUES (1, 'Cross DC', 'DATACENTER', 'CLOUD_PUBBLICO', 'IT', 2);


-- Asset

-- Test 16: tipo ALTRO senza descrizione
INSERT INTO Asset (organizzazione_id, ubicazione_id, codice_interno, denominazione, tipo, classificazione_c, classificazione_i, classificazione_a)
VALUES (1, 1, 'ACME-ALTRO', 'Roba', 'ALTRO', 'BASSO', 'BASSO', 'BASSO');

-- Test 17: asset DISMESSO ma rilevanza NIS2 ancora TRUE
INSERT INTO Asset (organizzazione_id, ubicazione_id, codice_interno, denominazione, tipo, classificazione_c, classificazione_i, classificazione_a, stato_ciclo_vita, rilevanza_nis2)
VALUES (1, 1, 'ACME-DISM', 'Dismesso', 'SERVER', 'BASSO', 'BASSO', 'BASSO', 'DISMESSO', TRUE);

-- Test 18: data_dismissione_prevista precedente a data_introduzione
INSERT INTO Asset (organizzazione_id, ubicazione_id, codice_interno, denominazione, tipo, classificazione_c, classificazione_i, classificazione_a, data_introduzione, data_dismissione_prevista)
VALUES (1, 1, 'ACME-DATE', 'Date invertite', 'SERVER', 'BASSO', 'BASSO', 'BASSO', '2026-01-01', '2025-01-01');

-- Test 19: codice_interno duplicato fra due record correnti della stessa org
INSERT INTO Asset (organizzazione_id, ubicazione_id, codice_interno, denominazione, tipo, classificazione_c, classificazione_i, classificazione_a)
VALUES (1, 1, 'ACME-DB-01', 'Duplicato', 'SERVER', 'ALTO', 'ALTO', 'ALTO');


-- Servizio

-- Test 20: ambito NIS2 con criticita BASSA
INSERT INTO Servizio (organizzazione_id, codice_interno, denominazione, descrizione, criticita, ambito_nis2, uptime_target, rto_ore, rpo_ore, orario_copertura)
VALUES (1, 'ACME-NIS-LOW', 'NIS basso', 'desc', 'BASSA', TRUE, 99, 2, 1, 'H24');

-- Test 21: ambito NIS2 senza SLA completi
INSERT INTO Servizio (organizzazione_id, codice_interno, denominazione, descrizione, criticita, ambito_nis2)
VALUES (1, 'ACME-NIS-NOSLA', 'NIS senza SLA', 'desc', 'ALTA', TRUE);

-- Test 22: servizio DISMESSO ma ambito NIS2 ancora TRUE
INSERT INTO Servizio (organizzazione_id, codice_interno, denominazione, descrizione, criticita, ambito_nis2, uptime_target, rto_ore, rpo_ore, orario_copertura, stato_erogazione)
VALUES (1, 'ACME-DISM-NIS', 'Dismesso NIS', 'desc', 'ALTA', TRUE, 99.9, 2, 1, 'H24', 'DISMESSO');

-- Test 23: uptime_target fuori range
INSERT INTO Servizio (organizzazione_id, codice_interno, denominazione, descrizione, criticita, ambito_nis2, uptime_target, rto_ore, rpo_ore, orario_copertura)
VALUES (1, 'ACME-UP', 'Uptime pazzo', 'desc', 'ALTA', TRUE, 150, 2, 1, 'H24');

-- Test 24: codice_interno servizio duplicato fra record correnti
INSERT INTO Servizio (organizzazione_id, codice_interno, denominazione, descrizione, criticita, ambito_nis2)
VALUES (1, 'ACME-HB', 'Home banking duplicato', 'desc', 'MEDIA', FALSE);


-- Asset_Servizio

-- Test 25: ruolo ALTRO senza note
INSERT INTO Asset_Servizio (asset_id, servizio_id, ruolo)
VALUES (1, 1, 'ALTRO');

-- Test 26: legame (asset, servizio) duplicato fra record correnti
INSERT INTO Asset_Servizio (asset_id, servizio_id, ruolo)
VALUES (1, 1, 'PRIMARIO');
INSERT INTO Asset_Servizio (asset_id, servizio_id, ruolo)
VALUES (1, 1, 'SECONDARIO');

-- Test 27: trigger multi-tenant — asset Acme collegato a servizio Beta
INSERT INTO Asset_Servizio (asset_id, servizio_id, ruolo)
VALUES (1, 2, 'PRIMARIO');


-- Soggetto

-- Test 28: PERSONA senza nome/cognome
INSERT INTO Soggetto (organizzazione_id, tipo, denominazione)
VALUES (1, 'PERSONA', 'Senza nome');

-- Test 29: RUOLO con nome/cognome valorizzati
INSERT INTO Soggetto (organizzazione_id, tipo, denominazione, nome, cognome)
VALUES (1, 'RUOLO', 'Ruolo', 'Tizio', 'Caio');

-- Test 30: punto di contatto ACN marcato come RUOLO
INSERT INTO Soggetto (organizzazione_id, tipo, denominazione, email, is_punto_contatto_acn)
VALUES (1, 'RUOLO', 'PdC ruolo', 'test@acme.it', TRUE);

-- Test 31: secondo punto di contatto ACN corrente per la stessa org
UPDATE Soggetto SET is_punto_contatto_acn = TRUE WHERE id = 1;
INSERT INTO Soggetto (organizzazione_id, tipo, denominazione, nome, cognome, email, is_punto_contatto_acn)
VALUES (1, 'PERSONA', 'Secondo PdC Acme', 'Giulia', 'Verdi', 'giulia@acme.it', TRUE);

-- Test 32: soggetto INATTIVO marcato come punto di contatto ACN
INSERT INTO Soggetto (organizzazione_id, tipo, denominazione, nome, cognome, email, is_punto_contatto_acn, stato)
VALUES (1, 'PERSONA', 'PdC inattivo', 'Inattivo', 'Finto', 'inattivo@acme.it', TRUE, 'INATTIVO');


-- Dipendenza

-- Test 33: sorgente incoerente 
INSERT INTO Dipendenza (organizzazione_id, sorgente_tipo, sorgente_servizio_id, destinazione_tipo, destinazione_asset_id, tipo, criticita)
VALUES (1, 'ASSET', 1, 'ASSET', 1, 'TECNICA', 'ALTA');

-- Test 34: destinazione con due FK valorizzate
INSERT INTO Dipendenza (organizzazione_id, sorgente_tipo, sorgente_asset_id, destinazione_tipo, destinazione_asset_id, destinazione_servizio_id, tipo, criticita)
VALUES (1, 'ASSET', 1, 'SERVIZIO', 1, 1, 'TECNICA', 'ALTA');

-- Test 35: auto-riferimento (asset 1 dipende da asset 1)
INSERT INTO Dipendenza (organizzazione_id, sorgente_tipo, sorgente_asset_id, destinazione_tipo, destinazione_asset_id, tipo, criticita)
VALUES (1, 'ASSET', 1, 'ASSET', 1, 'TECNICA', 'ALTA');

-- Test 36: dipendenza ORGANIZZATIVA verso un asset invece che un fornitore
INSERT INTO Dipendenza (organizzazione_id, sorgente_tipo, sorgente_servizio_id, destinazione_tipo, destinazione_asset_id, tipo, criticita)
VALUES (1, 'SERVIZIO', 1, 'ASSET', 1, 'ORGANIZZATIVA', 'MEDIA');

-- Test 37: trigger multi-tenant — sorgente Acme, destinazione fornitore Beta
INSERT INTO Dipendenza (organizzazione_id, sorgente_tipo, sorgente_asset_id, destinazione_tipo, destinazione_fornitore_id, tipo, criticita)
VALUES (1, 'ASSET', 1, 'FORNITORE', 2, 'ORGANIZZATIVA', 'ALTA');


-- Responsabilita

-- Test 38: target incoerente 
INSERT INTO Responsabilita (organizzazione_id, soggetto_id, target_tipo, target_servizio_id, ruolo_raci)
VALUES (1, 1, 'ASSET', 1, 'RESPONSIBLE');

-- Test 39: due Accountable sullo stesso target
INSERT INTO Responsabilita (organizzazione_id, soggetto_id, target_tipo, target_asset_id, ruolo_raci)
VALUES (1, 1, 'ASSET', 1, 'ACCOUNTABLE');

INSERT INTO Soggetto (organizzazione_id, tipo, denominazione, nome, cognome, email)
VALUES (1, 'PERSONA', 'Paolo Bianchi', 'Paolo', 'Bianchi', 'paolo@acme.it');
INSERT INTO Responsabilita (organizzazione_id, soggetto_id, target_tipo, target_asset_id, ruolo_raci)
VALUES (1, LAST_INSERT_ID(), 'ASSET', 1, 'ACCOUNTABLE');

-- Test 40: trigger multi-tenant — soggetto Acme su servizio Beta
INSERT INTO Responsabilita (organizzazione_id, soggetto_id, target_tipo, target_servizio_id, ruolo_raci)
VALUES (1, 1, 'SERVIZIO', 2, 'INFORMED');


-- audit_log

-- Test 41: INSERT con payload_precedente valorizzato
INSERT INTO audit_log (tabella, record_id, operazione, utente_db, payload_precedente, payload_nuovo)
VALUES ('Asset', 1, 'INSERT', 'test', '{"a":1}', '{"a":2}');

-- Test 42: DELETE con payload_nuovo valorizzato
INSERT INTO audit_log (tabella, record_id, operazione, utente_db, payload_precedente, payload_nuovo)
VALUES ('Asset', 1, 'DELETE', 'test', '{"a":1}', '{"a":2}');

-- Test 43: UPDATE senza payload (entrambi NULL)
INSERT INTO audit_log (tabella, record_id, operazione, utente_db)
VALUES ('Asset', 1, 'UPDATE', 'test');
