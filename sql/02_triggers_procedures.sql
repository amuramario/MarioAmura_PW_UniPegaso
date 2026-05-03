-- Trigger e stored procedure



DELIMITER $$

-- Asset_Servizio: asset e servizio stessa org.
CREATE TRIGGER trg_asservizio_mt_insert
BEFORE INSERT ON Asset_Servizio
FOR EACH ROW
BEGIN
    DECLARE v_asset_org    BIGINT UNSIGNED;
    DECLARE v_servizio_org BIGINT UNSIGNED;

    SELECT organizzazione_id INTO v_asset_org    FROM Asset    WHERE id = NEW.asset_id;
    SELECT organizzazione_id INTO v_servizio_org FROM Servizio WHERE id = NEW.servizio_id;

    IF v_asset_org IS NULL OR v_servizio_org IS NULL OR v_asset_org <> v_servizio_org THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Asset_Servizio: asset e servizio di organizzazioni diverse';
    END IF;
END$$

CREATE TRIGGER trg_asservizio_mt_update
BEFORE UPDATE ON Asset_Servizio
FOR EACH ROW
BEGIN
    DECLARE v_asset_org    BIGINT UNSIGNED;
    DECLARE v_servizio_org BIGINT UNSIGNED;

    SELECT organizzazione_id INTO v_asset_org    FROM Asset    WHERE id = NEW.asset_id;
    SELECT organizzazione_id INTO v_servizio_org FROM Servizio WHERE id = NEW.servizio_id;

    IF v_asset_org IS NULL OR v_servizio_org IS NULL OR v_asset_org <> v_servizio_org THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Asset_Servizio: asset e servizio di organizzazioni diverse';
    END IF;
END$$


-- Ubicazione: se valorizzato fornitore_terzo_id, stessa org.
CREATE TRIGGER trg_ubicazione_mt_insert
BEFORE INSERT ON Ubicazione
FOR EACH ROW
BEGIN
    DECLARE v_fornitore_org BIGINT UNSIGNED;

    IF NEW.fornitore_terzo_id IS NOT NULL THEN
        SELECT organizzazione_id INTO v_fornitore_org
        FROM FornitoreTerzo WHERE id = NEW.fornitore_terzo_id;

        IF v_fornitore_org IS NULL OR v_fornitore_org <> NEW.organizzazione_id THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'Ubicazione: fornitore di altra organizzazione';
        END IF;
    END IF;
END$$

CREATE TRIGGER trg_ubicazione_mt_update
BEFORE UPDATE ON Ubicazione
FOR EACH ROW
BEGIN
    DECLARE v_fornitore_org BIGINT UNSIGNED;

    IF NEW.fornitore_terzo_id IS NOT NULL THEN
        SELECT organizzazione_id INTO v_fornitore_org
        FROM FornitoreTerzo WHERE id = NEW.fornitore_terzo_id;

        IF v_fornitore_org IS NULL OR v_fornitore_org <> NEW.organizzazione_id THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'Ubicazione: fornitore di altra organizzazione';
        END IF;
    END IF;
END$$


-- Dipendenza: sorgente, destinazione e dipendenza stessa org.
CREATE TRIGGER trg_dipendenza_mt_insert
BEFORE INSERT ON Dipendenza
FOR EACH ROW
BEGIN
    DECLARE v_sorgente_org     BIGINT UNSIGNED;
    DECLARE v_destinazione_org BIGINT UNSIGNED;

    IF NEW.sorgente_asset_id IS NOT NULL THEN
        SELECT organizzazione_id INTO v_sorgente_org FROM Asset    WHERE id = NEW.sorgente_asset_id;
    ELSEIF NEW.sorgente_servizio_id IS NOT NULL THEN
        SELECT organizzazione_id INTO v_sorgente_org FROM Servizio WHERE id = NEW.sorgente_servizio_id;
    END IF;

    IF NEW.destinazione_asset_id IS NOT NULL THEN
        SELECT organizzazione_id INTO v_destinazione_org FROM Asset         WHERE id = NEW.destinazione_asset_id;
    ELSEIF NEW.destinazione_servizio_id IS NOT NULL THEN
        SELECT organizzazione_id INTO v_destinazione_org FROM Servizio      WHERE id = NEW.destinazione_servizio_id;
    ELSEIF NEW.destinazione_fornitore_id IS NOT NULL THEN
        SELECT organizzazione_id INTO v_destinazione_org FROM FornitoreTerzo WHERE id = NEW.destinazione_fornitore_id;
    END IF;

    IF v_sorgente_org IS NULL OR v_destinazione_org IS NULL
       OR v_sorgente_org <> NEW.organizzazione_id
       OR v_destinazione_org <> NEW.organizzazione_id THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Dipendenza: elementi collegati di organizzazioni diverse';
    END IF;
END$$

CREATE TRIGGER trg_dipendenza_mt_update
BEFORE UPDATE ON Dipendenza
FOR EACH ROW
BEGIN
    DECLARE v_sorgente_org     BIGINT UNSIGNED;
    DECLARE v_destinazione_org BIGINT UNSIGNED;

    IF NEW.sorgente_asset_id IS NOT NULL THEN
        SELECT organizzazione_id INTO v_sorgente_org FROM Asset    WHERE id = NEW.sorgente_asset_id;
    ELSEIF NEW.sorgente_servizio_id IS NOT NULL THEN
        SELECT organizzazione_id INTO v_sorgente_org FROM Servizio WHERE id = NEW.sorgente_servizio_id;
    END IF;

    IF NEW.destinazione_asset_id IS NOT NULL THEN
        SELECT organizzazione_id INTO v_destinazione_org FROM Asset         WHERE id = NEW.destinazione_asset_id;
    ELSEIF NEW.destinazione_servizio_id IS NOT NULL THEN
        SELECT organizzazione_id INTO v_destinazione_org FROM Servizio      WHERE id = NEW.destinazione_servizio_id;
    ELSEIF NEW.destinazione_fornitore_id IS NOT NULL THEN
        SELECT organizzazione_id INTO v_destinazione_org FROM FornitoreTerzo WHERE id = NEW.destinazione_fornitore_id;
    END IF;

    IF v_sorgente_org IS NULL OR v_destinazione_org IS NULL
       OR v_sorgente_org <> NEW.organizzazione_id
       OR v_destinazione_org <> NEW.organizzazione_id THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Dipendenza: elementi collegati di organizzazioni diverse';
    END IF;
END$$


-- Responsabilita: soggetto e target stessa org.
CREATE TRIGGER trg_responsabilita_mt_insert
BEFORE INSERT ON Responsabilita
FOR EACH ROW
BEGIN
    DECLARE v_soggetto_org BIGINT UNSIGNED;
    DECLARE v_target_org   BIGINT UNSIGNED;

    SELECT organizzazione_id INTO v_soggetto_org FROM Soggetto WHERE id = NEW.soggetto_id;

    IF NEW.target_asset_id IS NOT NULL THEN
        SELECT organizzazione_id INTO v_target_org FROM Asset         WHERE id = NEW.target_asset_id;
    ELSEIF NEW.target_servizio_id IS NOT NULL THEN
        SELECT organizzazione_id INTO v_target_org FROM Servizio      WHERE id = NEW.target_servizio_id;
    ELSEIF NEW.target_fornitore_id IS NOT NULL THEN
        SELECT organizzazione_id INTO v_target_org FROM FornitoreTerzo WHERE id = NEW.target_fornitore_id;
    END IF;

    IF v_soggetto_org IS NULL OR v_target_org IS NULL
       OR v_soggetto_org <> NEW.organizzazione_id
       OR v_target_org <> NEW.organizzazione_id THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Responsabilita: soggetto e target di organizzazioni diverse';
    END IF;
END$$

CREATE TRIGGER trg_responsabilita_mt_update
BEFORE UPDATE ON Responsabilita
FOR EACH ROW
BEGIN
    DECLARE v_soggetto_org BIGINT UNSIGNED;
    DECLARE v_target_org   BIGINT UNSIGNED;

    SELECT organizzazione_id INTO v_soggetto_org FROM Soggetto WHERE id = NEW.soggetto_id;

    IF NEW.target_asset_id IS NOT NULL THEN
        SELECT organizzazione_id INTO v_target_org FROM Asset         WHERE id = NEW.target_asset_id;
    ELSEIF NEW.target_servizio_id IS NOT NULL THEN
        SELECT organizzazione_id INTO v_target_org FROM Servizio      WHERE id = NEW.target_servizio_id;
    ELSEIF NEW.target_fornitore_id IS NOT NULL THEN
        SELECT organizzazione_id INTO v_target_org FROM FornitoreTerzo WHERE id = NEW.target_fornitore_id;
    END IF;

    IF v_soggetto_org IS NULL OR v_target_org IS NULL
       OR v_soggetto_org <> NEW.organizzazione_id
       OR v_target_org <> NEW.organizzazione_id THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Responsabilita: soggetto e target di organizzazioni diverse';
    END IF;
END$$

DELIMITER ;


-- Audit trail: ogni modifica su una tabella versionata produce una riga in audit_log.
-- 27 trigger AFTER INSERT/UPDATE/DELETE.

DELIMITER $$

-- Organizzazione
CREATE TRIGGER trg_organizzazione_audit_insert AFTER INSERT ON Organizzazione FOR EACH ROW
BEGIN
    INSERT INTO audit_log (tabella, record_id, operazione, utente_db, organizzazione_id, payload_nuovo)
    VALUES ('Organizzazione', NEW.id, 'INSERT', CURRENT_USER(), NEW.id,
        JSON_OBJECT('id', NEW.id, 'ragione_sociale', NEW.ragione_sociale, 'codice_fiscale', NEW.codice_fiscale,
                    'partita_iva', NEW.partita_iva, 'pec', NEW.pec, 'allegato', NEW.allegato,
                    'settore_nis2', NEW.settore_nis2, 'categoria_nis2', NEW.categoria_nis2,
                    'perimetro_psnc', NEW.perimetro_psnc, 'data_registrazione_acn', NEW.data_registrazione_acn,
                    'stato_registrazione', NEW.stato_registrazione, 'valid_from', NEW.valid_from,
                    'valid_to', NEW.valid_to, 'is_current', NEW.is_current));
END$$

CREATE TRIGGER trg_organizzazione_audit_update AFTER UPDATE ON Organizzazione FOR EACH ROW
BEGIN
    INSERT INTO audit_log (tabella, record_id, operazione, utente_db, organizzazione_id, payload_precedente, payload_nuovo)
    VALUES ('Organizzazione', NEW.id, 'UPDATE', CURRENT_USER(), NEW.id,
        JSON_OBJECT('id', OLD.id, 'ragione_sociale', OLD.ragione_sociale, 'codice_fiscale', OLD.codice_fiscale,
                    'partita_iva', OLD.partita_iva, 'pec', OLD.pec, 'allegato', OLD.allegato,
                    'settore_nis2', OLD.settore_nis2, 'categoria_nis2', OLD.categoria_nis2,
                    'perimetro_psnc', OLD.perimetro_psnc, 'data_registrazione_acn', OLD.data_registrazione_acn,
                    'stato_registrazione', OLD.stato_registrazione, 'valid_from', OLD.valid_from,
                    'valid_to', OLD.valid_to, 'is_current', OLD.is_current),
        JSON_OBJECT('id', NEW.id, 'ragione_sociale', NEW.ragione_sociale, 'codice_fiscale', NEW.codice_fiscale,
                    'partita_iva', NEW.partita_iva, 'pec', NEW.pec, 'allegato', NEW.allegato,
                    'settore_nis2', NEW.settore_nis2, 'categoria_nis2', NEW.categoria_nis2,
                    'perimetro_psnc', NEW.perimetro_psnc, 'data_registrazione_acn', NEW.data_registrazione_acn,
                    'stato_registrazione', NEW.stato_registrazione, 'valid_from', NEW.valid_from,
                    'valid_to', NEW.valid_to, 'is_current', NEW.is_current));
END$$

CREATE TRIGGER trg_organizzazione_audit_delete AFTER DELETE ON Organizzazione FOR EACH ROW
BEGIN
    INSERT INTO audit_log (tabella, record_id, operazione, utente_db, organizzazione_id, payload_precedente)
    VALUES ('Organizzazione', OLD.id, 'DELETE', CURRENT_USER(), OLD.id,
        JSON_OBJECT('id', OLD.id, 'ragione_sociale', OLD.ragione_sociale, 'codice_fiscale', OLD.codice_fiscale,
                    'partita_iva', OLD.partita_iva, 'pec', OLD.pec, 'allegato', OLD.allegato,
                    'settore_nis2', OLD.settore_nis2, 'categoria_nis2', OLD.categoria_nis2,
                    'perimetro_psnc', OLD.perimetro_psnc, 'data_registrazione_acn', OLD.data_registrazione_acn,
                    'stato_registrazione', OLD.stato_registrazione, 'valid_from', OLD.valid_from,
                    'valid_to', OLD.valid_to, 'is_current', OLD.is_current));
END$$

-- FornitoreTerzo
CREATE TRIGGER trg_fornitore_audit_insert AFTER INSERT ON FornitoreTerzo FOR EACH ROW
BEGIN
    INSERT INTO audit_log (tabella, record_id, operazione, utente_db, organizzazione_id, payload_nuovo)
    VALUES ('FornitoreTerzo', NEW.id, 'INSERT', CURRENT_USER(), NEW.organizzazione_id,
        JSON_OBJECT('id', NEW.id, 'organizzazione_id', NEW.organizzazione_id, 'denominazione', NEW.denominazione,
                    'identificativo_fiscale', NEW.identificativo_fiscale, 'paese_sede', NEW.paese_sede,
                    'categoria', NEW.categoria, 'note', NEW.note, 'rilevanza_nis2', NEW.rilevanza_nis2,
                    'criterio_rilevanza', NEW.criterio_rilevanza, 'cpv_principale', NEW.cpv_principale,
                    'certificazioni', NEW.certificazioni, 'sede_legale_extra_ue', NEW.sede_legale_extra_ue,
                    'data_inizio_rapporto', NEW.data_inizio_rapporto, 'data_fine_rapporto', NEW.data_fine_rapporto,
                    'stato_rapporto', NEW.stato_rapporto, 'valid_from', NEW.valid_from,
                    'valid_to', NEW.valid_to, 'is_current', NEW.is_current));
END$$

CREATE TRIGGER trg_fornitore_audit_update AFTER UPDATE ON FornitoreTerzo FOR EACH ROW
BEGIN
    INSERT INTO audit_log (tabella, record_id, operazione, utente_db, organizzazione_id, payload_precedente, payload_nuovo)
    VALUES ('FornitoreTerzo', NEW.id, 'UPDATE', CURRENT_USER(), NEW.organizzazione_id,
        JSON_OBJECT('id', OLD.id, 'organizzazione_id', OLD.organizzazione_id, 'denominazione', OLD.denominazione,
                    'identificativo_fiscale', OLD.identificativo_fiscale, 'paese_sede', OLD.paese_sede,
                    'categoria', OLD.categoria, 'note', OLD.note, 'rilevanza_nis2', OLD.rilevanza_nis2,
                    'criterio_rilevanza', OLD.criterio_rilevanza, 'cpv_principale', OLD.cpv_principale,
                    'certificazioni', OLD.certificazioni, 'sede_legale_extra_ue', OLD.sede_legale_extra_ue,
                    'data_inizio_rapporto', OLD.data_inizio_rapporto, 'data_fine_rapporto', OLD.data_fine_rapporto,
                    'stato_rapporto', OLD.stato_rapporto, 'valid_from', OLD.valid_from,
                    'valid_to', OLD.valid_to, 'is_current', OLD.is_current),
        JSON_OBJECT('id', NEW.id, 'organizzazione_id', NEW.organizzazione_id, 'denominazione', NEW.denominazione,
                    'identificativo_fiscale', NEW.identificativo_fiscale, 'paese_sede', NEW.paese_sede,
                    'categoria', NEW.categoria, 'note', NEW.note, 'rilevanza_nis2', NEW.rilevanza_nis2,
                    'criterio_rilevanza', NEW.criterio_rilevanza, 'cpv_principale', NEW.cpv_principale,
                    'certificazioni', NEW.certificazioni, 'sede_legale_extra_ue', NEW.sede_legale_extra_ue,
                    'data_inizio_rapporto', NEW.data_inizio_rapporto, 'data_fine_rapporto', NEW.data_fine_rapporto,
                    'stato_rapporto', NEW.stato_rapporto, 'valid_from', NEW.valid_from,
                    'valid_to', NEW.valid_to, 'is_current', NEW.is_current));
END$$

CREATE TRIGGER trg_fornitore_audit_delete AFTER DELETE ON FornitoreTerzo FOR EACH ROW
BEGIN
    INSERT INTO audit_log (tabella, record_id, operazione, utente_db, organizzazione_id, payload_precedente)
    VALUES ('FornitoreTerzo', OLD.id, 'DELETE', CURRENT_USER(), OLD.organizzazione_id,
        JSON_OBJECT('id', OLD.id, 'organizzazione_id', OLD.organizzazione_id, 'denominazione', OLD.denominazione,
                    'identificativo_fiscale', OLD.identificativo_fiscale, 'paese_sede', OLD.paese_sede,
                    'categoria', OLD.categoria, 'note', OLD.note, 'rilevanza_nis2', OLD.rilevanza_nis2,
                    'criterio_rilevanza', OLD.criterio_rilevanza, 'cpv_principale', OLD.cpv_principale,
                    'certificazioni', OLD.certificazioni, 'sede_legale_extra_ue', OLD.sede_legale_extra_ue,
                    'data_inizio_rapporto', OLD.data_inizio_rapporto, 'data_fine_rapporto', OLD.data_fine_rapporto,
                    'stato_rapporto', OLD.stato_rapporto, 'valid_from', OLD.valid_from,
                    'valid_to', OLD.valid_to, 'is_current', OLD.is_current));
END$$

-- Ubicazione
CREATE TRIGGER trg_ubicazione_audit_insert AFTER INSERT ON Ubicazione FOR EACH ROW
BEGIN
    INSERT INTO audit_log (tabella, record_id, operazione, utente_db, organizzazione_id, payload_nuovo)
    VALUES ('Ubicazione', NEW.id, 'INSERT', CURRENT_USER(), NEW.organizzazione_id,
        JSON_OBJECT('id', NEW.id, 'organizzazione_id', NEW.organizzazione_id, 'denominazione', NEW.denominazione,
                    'tipo', NEW.tipo, 'tipo_gestione', NEW.tipo_gestione, 'paese', NEW.paese,
                    'regione_geografica', NEW.regione_geografica, 'indirizzo', NEW.indirizzo,
                    'fornitore_terzo_id', NEW.fornitore_terzo_id, 'valid_from', NEW.valid_from,
                    'valid_to', NEW.valid_to, 'is_current', NEW.is_current));
END$$

CREATE TRIGGER trg_ubicazione_audit_update AFTER UPDATE ON Ubicazione FOR EACH ROW
BEGIN
    INSERT INTO audit_log (tabella, record_id, operazione, utente_db, organizzazione_id, payload_precedente, payload_nuovo)
    VALUES ('Ubicazione', NEW.id, 'UPDATE', CURRENT_USER(), NEW.organizzazione_id,
        JSON_OBJECT('id', OLD.id, 'organizzazione_id', OLD.organizzazione_id, 'denominazione', OLD.denominazione,
                    'tipo', OLD.tipo, 'tipo_gestione', OLD.tipo_gestione, 'paese', OLD.paese,
                    'regione_geografica', OLD.regione_geografica, 'indirizzo', OLD.indirizzo,
                    'fornitore_terzo_id', OLD.fornitore_terzo_id, 'valid_from', OLD.valid_from,
                    'valid_to', OLD.valid_to, 'is_current', OLD.is_current),
        JSON_OBJECT('id', NEW.id, 'organizzazione_id', NEW.organizzazione_id, 'denominazione', NEW.denominazione,
                    'tipo', NEW.tipo, 'tipo_gestione', NEW.tipo_gestione, 'paese', NEW.paese,
                    'regione_geografica', NEW.regione_geografica, 'indirizzo', NEW.indirizzo,
                    'fornitore_terzo_id', NEW.fornitore_terzo_id, 'valid_from', NEW.valid_from,
                    'valid_to', NEW.valid_to, 'is_current', NEW.is_current));
END$$

CREATE TRIGGER trg_ubicazione_audit_delete AFTER DELETE ON Ubicazione FOR EACH ROW
BEGIN
    INSERT INTO audit_log (tabella, record_id, operazione, utente_db, organizzazione_id, payload_precedente)
    VALUES ('Ubicazione', OLD.id, 'DELETE', CURRENT_USER(), OLD.organizzazione_id,
        JSON_OBJECT('id', OLD.id, 'organizzazione_id', OLD.organizzazione_id, 'denominazione', OLD.denominazione,
                    'tipo', OLD.tipo, 'tipo_gestione', OLD.tipo_gestione, 'paese', OLD.paese,
                    'regione_geografica', OLD.regione_geografica, 'indirizzo', OLD.indirizzo,
                    'fornitore_terzo_id', OLD.fornitore_terzo_id, 'valid_from', OLD.valid_from,
                    'valid_to', OLD.valid_to, 'is_current', OLD.is_current));
END$$

-- Asset
CREATE TRIGGER trg_asset_audit_insert AFTER INSERT ON Asset FOR EACH ROW
BEGIN
    INSERT INTO audit_log (tabella, record_id, operazione, utente_db, organizzazione_id, payload_nuovo)
    VALUES ('Asset', NEW.id, 'INSERT', CURRENT_USER(), NEW.organizzazione_id,
        JSON_OBJECT('id', NEW.id, 'organizzazione_id', NEW.organizzazione_id, 'ubicazione_id', NEW.ubicazione_id,
                    'codice_interno', NEW.codice_interno, 'denominazione', NEW.denominazione,
                    'descrizione', NEW.descrizione, 'tipo', NEW.tipo,
                    'classificazione_c', NEW.classificazione_c, 'classificazione_i', NEW.classificazione_i,
                    'classificazione_a', NEW.classificazione_a, 'stato_ciclo_vita', NEW.stato_ciclo_vita,
                    'rilevanza_nis2', NEW.rilevanza_nis2, 'esposto_internet', NEW.esposto_internet,
                    'contiene_dati_personali', NEW.contiene_dati_personali,
                    'data_introduzione', NEW.data_introduzione,
                    'data_dismissione_prevista', NEW.data_dismissione_prevista,
                    'hostname', NEW.hostname, 'versione', NEW.versione,
                    'valid_from', NEW.valid_from, 'valid_to', NEW.valid_to, 'is_current', NEW.is_current));
END$$

CREATE TRIGGER trg_asset_audit_update AFTER UPDATE ON Asset FOR EACH ROW
BEGIN
    INSERT INTO audit_log (tabella, record_id, operazione, utente_db, organizzazione_id, payload_precedente, payload_nuovo)
    VALUES ('Asset', NEW.id, 'UPDATE', CURRENT_USER(), NEW.organizzazione_id,
        JSON_OBJECT('id', OLD.id, 'organizzazione_id', OLD.organizzazione_id, 'ubicazione_id', OLD.ubicazione_id,
                    'codice_interno', OLD.codice_interno, 'denominazione', OLD.denominazione,
                    'descrizione', OLD.descrizione, 'tipo', OLD.tipo,
                    'classificazione_c', OLD.classificazione_c, 'classificazione_i', OLD.classificazione_i,
                    'classificazione_a', OLD.classificazione_a, 'stato_ciclo_vita', OLD.stato_ciclo_vita,
                    'rilevanza_nis2', OLD.rilevanza_nis2, 'esposto_internet', OLD.esposto_internet,
                    'contiene_dati_personali', OLD.contiene_dati_personali,
                    'data_introduzione', OLD.data_introduzione,
                    'data_dismissione_prevista', OLD.data_dismissione_prevista,
                    'hostname', OLD.hostname, 'versione', OLD.versione,
                    'valid_from', OLD.valid_from, 'valid_to', OLD.valid_to, 'is_current', OLD.is_current),
        JSON_OBJECT('id', NEW.id, 'organizzazione_id', NEW.organizzazione_id, 'ubicazione_id', NEW.ubicazione_id,
                    'codice_interno', NEW.codice_interno, 'denominazione', NEW.denominazione,
                    'descrizione', NEW.descrizione, 'tipo', NEW.tipo,
                    'classificazione_c', NEW.classificazione_c, 'classificazione_i', NEW.classificazione_i,
                    'classificazione_a', NEW.classificazione_a, 'stato_ciclo_vita', NEW.stato_ciclo_vita,
                    'rilevanza_nis2', NEW.rilevanza_nis2, 'esposto_internet', NEW.esposto_internet,
                    'contiene_dati_personali', NEW.contiene_dati_personali,
                    'data_introduzione', NEW.data_introduzione,
                    'data_dismissione_prevista', NEW.data_dismissione_prevista,
                    'hostname', NEW.hostname, 'versione', NEW.versione,
                    'valid_from', NEW.valid_from, 'valid_to', NEW.valid_to, 'is_current', NEW.is_current));
END$$

CREATE TRIGGER trg_asset_audit_delete AFTER DELETE ON Asset FOR EACH ROW
BEGIN
    INSERT INTO audit_log (tabella, record_id, operazione, utente_db, organizzazione_id, payload_precedente)
    VALUES ('Asset', OLD.id, 'DELETE', CURRENT_USER(), OLD.organizzazione_id,
        JSON_OBJECT('id', OLD.id, 'organizzazione_id', OLD.organizzazione_id, 'ubicazione_id', OLD.ubicazione_id,
                    'codice_interno', OLD.codice_interno, 'denominazione', OLD.denominazione,
                    'descrizione', OLD.descrizione, 'tipo', OLD.tipo,
                    'classificazione_c', OLD.classificazione_c, 'classificazione_i', OLD.classificazione_i,
                    'classificazione_a', OLD.classificazione_a, 'stato_ciclo_vita', OLD.stato_ciclo_vita,
                    'rilevanza_nis2', OLD.rilevanza_nis2, 'esposto_internet', OLD.esposto_internet,
                    'contiene_dati_personali', OLD.contiene_dati_personali,
                    'data_introduzione', OLD.data_introduzione,
                    'data_dismissione_prevista', OLD.data_dismissione_prevista,
                    'hostname', OLD.hostname, 'versione', OLD.versione,
                    'valid_from', OLD.valid_from, 'valid_to', OLD.valid_to, 'is_current', OLD.is_current));
END$$

-- Servizio
CREATE TRIGGER trg_servizio_audit_insert AFTER INSERT ON Servizio FOR EACH ROW
BEGIN
    INSERT INTO audit_log (tabella, record_id, operazione, utente_db, organizzazione_id, payload_nuovo)
    VALUES ('Servizio', NEW.id, 'INSERT', CURRENT_USER(), NEW.organizzazione_id,
        JSON_OBJECT('id', NEW.id, 'organizzazione_id', NEW.organizzazione_id, 'codice_interno', NEW.codice_interno,
                    'denominazione', NEW.denominazione, 'descrizione', NEW.descrizione,
                    'criticita', NEW.criticita, 'ambito_nis2', NEW.ambito_nis2,
                    'uptime_target', NEW.uptime_target, 'rto_ore', NEW.rto_ore, 'rpo_ore', NEW.rpo_ore,
                    'orario_copertura', NEW.orario_copertura, 'data_attivazione', NEW.data_attivazione,
                    'data_dismissione', NEW.data_dismissione, 'stato_erogazione', NEW.stato_erogazione,
                    'valid_from', NEW.valid_from, 'valid_to', NEW.valid_to, 'is_current', NEW.is_current));
END$$

CREATE TRIGGER trg_servizio_audit_update AFTER UPDATE ON Servizio FOR EACH ROW
BEGIN
    INSERT INTO audit_log (tabella, record_id, operazione, utente_db, organizzazione_id, payload_precedente, payload_nuovo)
    VALUES ('Servizio', NEW.id, 'UPDATE', CURRENT_USER(), NEW.organizzazione_id,
        JSON_OBJECT('id', OLD.id, 'organizzazione_id', OLD.organizzazione_id, 'codice_interno', OLD.codice_interno,
                    'denominazione', OLD.denominazione, 'descrizione', OLD.descrizione,
                    'criticita', OLD.criticita, 'ambito_nis2', OLD.ambito_nis2,
                    'uptime_target', OLD.uptime_target, 'rto_ore', OLD.rto_ore, 'rpo_ore', OLD.rpo_ore,
                    'orario_copertura', OLD.orario_copertura, 'data_attivazione', OLD.data_attivazione,
                    'data_dismissione', OLD.data_dismissione, 'stato_erogazione', OLD.stato_erogazione,
                    'valid_from', OLD.valid_from, 'valid_to', OLD.valid_to, 'is_current', OLD.is_current),
        JSON_OBJECT('id', NEW.id, 'organizzazione_id', NEW.organizzazione_id, 'codice_interno', NEW.codice_interno,
                    'denominazione', NEW.denominazione, 'descrizione', NEW.descrizione,
                    'criticita', NEW.criticita, 'ambito_nis2', NEW.ambito_nis2,
                    'uptime_target', NEW.uptime_target, 'rto_ore', NEW.rto_ore, 'rpo_ore', NEW.rpo_ore,
                    'orario_copertura', NEW.orario_copertura, 'data_attivazione', NEW.data_attivazione,
                    'data_dismissione', NEW.data_dismissione, 'stato_erogazione', NEW.stato_erogazione,
                    'valid_from', NEW.valid_from, 'valid_to', NEW.valid_to, 'is_current', NEW.is_current));
END$$

CREATE TRIGGER trg_servizio_audit_delete AFTER DELETE ON Servizio FOR EACH ROW
BEGIN
    INSERT INTO audit_log (tabella, record_id, operazione, utente_db, organizzazione_id, payload_precedente)
    VALUES ('Servizio', OLD.id, 'DELETE', CURRENT_USER(), OLD.organizzazione_id,
        JSON_OBJECT('id', OLD.id, 'organizzazione_id', OLD.organizzazione_id, 'codice_interno', OLD.codice_interno,
                    'denominazione', OLD.denominazione, 'descrizione', OLD.descrizione,
                    'criticita', OLD.criticita, 'ambito_nis2', OLD.ambito_nis2,
                    'uptime_target', OLD.uptime_target, 'rto_ore', OLD.rto_ore, 'rpo_ore', OLD.rpo_ore,
                    'orario_copertura', OLD.orario_copertura, 'data_attivazione', OLD.data_attivazione,
                    'data_dismissione', OLD.data_dismissione, 'stato_erogazione', OLD.stato_erogazione,
                    'valid_from', OLD.valid_from, 'valid_to', OLD.valid_to, 'is_current', OLD.is_current));
END$$

-- Asset_Servizio
CREATE TRIGGER trg_asservizio_audit_insert AFTER INSERT ON Asset_Servizio FOR EACH ROW
BEGIN
    INSERT INTO audit_log (tabella, record_id, operazione, utente_db, payload_nuovo)
    VALUES ('Asset_Servizio', NEW.id, 'INSERT', CURRENT_USER(),
        JSON_OBJECT('id', NEW.id, 'asset_id', NEW.asset_id, 'servizio_id', NEW.servizio_id,
                    'ruolo', NEW.ruolo, 'note', NEW.note,
                    'valid_from', NEW.valid_from, 'valid_to', NEW.valid_to, 'is_current', NEW.is_current));
END$$

CREATE TRIGGER trg_asservizio_audit_update AFTER UPDATE ON Asset_Servizio FOR EACH ROW
BEGIN
    INSERT INTO audit_log (tabella, record_id, operazione, utente_db, payload_precedente, payload_nuovo)
    VALUES ('Asset_Servizio', NEW.id, 'UPDATE', CURRENT_USER(),
        JSON_OBJECT('id', OLD.id, 'asset_id', OLD.asset_id, 'servizio_id', OLD.servizio_id,
                    'ruolo', OLD.ruolo, 'note', OLD.note,
                    'valid_from', OLD.valid_from, 'valid_to', OLD.valid_to, 'is_current', OLD.is_current),
        JSON_OBJECT('id', NEW.id, 'asset_id', NEW.asset_id, 'servizio_id', NEW.servizio_id,
                    'ruolo', NEW.ruolo, 'note', NEW.note,
                    'valid_from', NEW.valid_from, 'valid_to', NEW.valid_to, 'is_current', NEW.is_current));
END$$

CREATE TRIGGER trg_asservizio_audit_delete AFTER DELETE ON Asset_Servizio FOR EACH ROW
BEGIN
    INSERT INTO audit_log (tabella, record_id, operazione, utente_db, payload_precedente)
    VALUES ('Asset_Servizio', OLD.id, 'DELETE', CURRENT_USER(),
        JSON_OBJECT('id', OLD.id, 'asset_id', OLD.asset_id, 'servizio_id', OLD.servizio_id,
                    'ruolo', OLD.ruolo, 'note', OLD.note,
                    'valid_from', OLD.valid_from, 'valid_to', OLD.valid_to, 'is_current', OLD.is_current));
END$$

-- Soggetto
CREATE TRIGGER trg_soggetto_audit_insert AFTER INSERT ON Soggetto FOR EACH ROW
BEGIN
    INSERT INTO audit_log (tabella, record_id, operazione, utente_db, organizzazione_id, payload_nuovo)
    VALUES ('Soggetto', NEW.id, 'INSERT', CURRENT_USER(), NEW.organizzazione_id,
        JSON_OBJECT('id', NEW.id, 'organizzazione_id', NEW.organizzazione_id, 'tipo', NEW.tipo,
                    'denominazione', NEW.denominazione, 'nome', NEW.nome, 'cognome', NEW.cognome,
                    'email', NEW.email, 'telefono', NEW.telefono,
                    'ruolo_organizzativo', NEW.ruolo_organizzativo,
                    'is_punto_contatto_acn', NEW.is_punto_contatto_acn, 'stato', NEW.stato,
                    'valid_from', NEW.valid_from, 'valid_to', NEW.valid_to, 'is_current', NEW.is_current));
END$$

CREATE TRIGGER trg_soggetto_audit_update AFTER UPDATE ON Soggetto FOR EACH ROW
BEGIN
    INSERT INTO audit_log (tabella, record_id, operazione, utente_db, organizzazione_id, payload_precedente, payload_nuovo)
    VALUES ('Soggetto', NEW.id, 'UPDATE', CURRENT_USER(), NEW.organizzazione_id,
        JSON_OBJECT('id', OLD.id, 'organizzazione_id', OLD.organizzazione_id, 'tipo', OLD.tipo,
                    'denominazione', OLD.denominazione, 'nome', OLD.nome, 'cognome', OLD.cognome,
                    'email', OLD.email, 'telefono', OLD.telefono,
                    'ruolo_organizzativo', OLD.ruolo_organizzativo,
                    'is_punto_contatto_acn', OLD.is_punto_contatto_acn, 'stato', OLD.stato,
                    'valid_from', OLD.valid_from, 'valid_to', OLD.valid_to, 'is_current', OLD.is_current),
        JSON_OBJECT('id', NEW.id, 'organizzazione_id', NEW.organizzazione_id, 'tipo', NEW.tipo,
                    'denominazione', NEW.denominazione, 'nome', NEW.nome, 'cognome', NEW.cognome,
                    'email', NEW.email, 'telefono', NEW.telefono,
                    'ruolo_organizzativo', NEW.ruolo_organizzativo,
                    'is_punto_contatto_acn', NEW.is_punto_contatto_acn, 'stato', NEW.stato,
                    'valid_from', NEW.valid_from, 'valid_to', NEW.valid_to, 'is_current', NEW.is_current));
END$$

CREATE TRIGGER trg_soggetto_audit_delete AFTER DELETE ON Soggetto FOR EACH ROW
BEGIN
    INSERT INTO audit_log (tabella, record_id, operazione, utente_db, organizzazione_id, payload_precedente)
    VALUES ('Soggetto', OLD.id, 'DELETE', CURRENT_USER(), OLD.organizzazione_id,
        JSON_OBJECT('id', OLD.id, 'organizzazione_id', OLD.organizzazione_id, 'tipo', OLD.tipo,
                    'denominazione', OLD.denominazione, 'nome', OLD.nome, 'cognome', OLD.cognome,
                    'email', OLD.email, 'telefono', OLD.telefono,
                    'ruolo_organizzativo', OLD.ruolo_organizzativo,
                    'is_punto_contatto_acn', OLD.is_punto_contatto_acn, 'stato', OLD.stato,
                    'valid_from', OLD.valid_from, 'valid_to', OLD.valid_to, 'is_current', OLD.is_current));
END$$

-- Dipendenza
CREATE TRIGGER trg_dipendenza_audit_insert AFTER INSERT ON Dipendenza FOR EACH ROW
BEGIN
    INSERT INTO audit_log (tabella, record_id, operazione, utente_db, organizzazione_id, payload_nuovo)
    VALUES ('Dipendenza', NEW.id, 'INSERT', CURRENT_USER(), NEW.organizzazione_id,
        JSON_OBJECT('id', NEW.id, 'organizzazione_id', NEW.organizzazione_id,
                    'sorgente_tipo', NEW.sorgente_tipo,
                    'sorgente_asset_id', NEW.sorgente_asset_id,
                    'sorgente_servizio_id', NEW.sorgente_servizio_id,
                    'destinazione_tipo', NEW.destinazione_tipo,
                    'destinazione_asset_id', NEW.destinazione_asset_id,
                    'destinazione_servizio_id', NEW.destinazione_servizio_id,
                    'destinazione_fornitore_id', NEW.destinazione_fornitore_id,
                    'tipo', NEW.tipo, 'criticita', NEW.criticita, 'descrizione', NEW.descrizione,
                    'valid_from', NEW.valid_from, 'valid_to', NEW.valid_to, 'is_current', NEW.is_current));
END$$

CREATE TRIGGER trg_dipendenza_audit_update AFTER UPDATE ON Dipendenza FOR EACH ROW
BEGIN
    INSERT INTO audit_log (tabella, record_id, operazione, utente_db, organizzazione_id, payload_precedente, payload_nuovo)
    VALUES ('Dipendenza', NEW.id, 'UPDATE', CURRENT_USER(), NEW.organizzazione_id,
        JSON_OBJECT('id', OLD.id, 'organizzazione_id', OLD.organizzazione_id,
                    'sorgente_tipo', OLD.sorgente_tipo,
                    'sorgente_asset_id', OLD.sorgente_asset_id,
                    'sorgente_servizio_id', OLD.sorgente_servizio_id,
                    'destinazione_tipo', OLD.destinazione_tipo,
                    'destinazione_asset_id', OLD.destinazione_asset_id,
                    'destinazione_servizio_id', OLD.destinazione_servizio_id,
                    'destinazione_fornitore_id', OLD.destinazione_fornitore_id,
                    'tipo', OLD.tipo, 'criticita', OLD.criticita, 'descrizione', OLD.descrizione,
                    'valid_from', OLD.valid_from, 'valid_to', OLD.valid_to, 'is_current', OLD.is_current),
        JSON_OBJECT('id', NEW.id, 'organizzazione_id', NEW.organizzazione_id,
                    'sorgente_tipo', NEW.sorgente_tipo,
                    'sorgente_asset_id', NEW.sorgente_asset_id,
                    'sorgente_servizio_id', NEW.sorgente_servizio_id,
                    'destinazione_tipo', NEW.destinazione_tipo,
                    'destinazione_asset_id', NEW.destinazione_asset_id,
                    'destinazione_servizio_id', NEW.destinazione_servizio_id,
                    'destinazione_fornitore_id', NEW.destinazione_fornitore_id,
                    'tipo', NEW.tipo, 'criticita', NEW.criticita, 'descrizione', NEW.descrizione,
                    'valid_from', NEW.valid_from, 'valid_to', NEW.valid_to, 'is_current', NEW.is_current));
END$$

CREATE TRIGGER trg_dipendenza_audit_delete AFTER DELETE ON Dipendenza FOR EACH ROW
BEGIN
    INSERT INTO audit_log (tabella, record_id, operazione, utente_db, organizzazione_id, payload_precedente)
    VALUES ('Dipendenza', OLD.id, 'DELETE', CURRENT_USER(), OLD.organizzazione_id,
        JSON_OBJECT('id', OLD.id, 'organizzazione_id', OLD.organizzazione_id,
                    'sorgente_tipo', OLD.sorgente_tipo,
                    'sorgente_asset_id', OLD.sorgente_asset_id,
                    'sorgente_servizio_id', OLD.sorgente_servizio_id,
                    'destinazione_tipo', OLD.destinazione_tipo,
                    'destinazione_asset_id', OLD.destinazione_asset_id,
                    'destinazione_servizio_id', OLD.destinazione_servizio_id,
                    'destinazione_fornitore_id', OLD.destinazione_fornitore_id,
                    'tipo', OLD.tipo, 'criticita', OLD.criticita, 'descrizione', OLD.descrizione,
                    'valid_from', OLD.valid_from, 'valid_to', OLD.valid_to, 'is_current', OLD.is_current));
END$$

-- Responsabilita
CREATE TRIGGER trg_responsabilita_audit_insert AFTER INSERT ON Responsabilita FOR EACH ROW
BEGIN
    INSERT INTO audit_log (tabella, record_id, operazione, utente_db, organizzazione_id, payload_nuovo)
    VALUES ('Responsabilita', NEW.id, 'INSERT', CURRENT_USER(), NEW.organizzazione_id,
        JSON_OBJECT('id', NEW.id, 'organizzazione_id', NEW.organizzazione_id, 'soggetto_id', NEW.soggetto_id,
                    'target_tipo', NEW.target_tipo,
                    'target_asset_id', NEW.target_asset_id,
                    'target_servizio_id', NEW.target_servizio_id,
                    'target_fornitore_id', NEW.target_fornitore_id,
                    'ruolo_raci', NEW.ruolo_raci, 'descrizione_ruolo', NEW.descrizione_ruolo,
                    'valid_from', NEW.valid_from, 'valid_to', NEW.valid_to, 'is_current', NEW.is_current));
END$$

CREATE TRIGGER trg_responsabilita_audit_update AFTER UPDATE ON Responsabilita FOR EACH ROW
BEGIN
    INSERT INTO audit_log (tabella, record_id, operazione, utente_db, organizzazione_id, payload_precedente, payload_nuovo)
    VALUES ('Responsabilita', NEW.id, 'UPDATE', CURRENT_USER(), NEW.organizzazione_id,
        JSON_OBJECT('id', OLD.id, 'organizzazione_id', OLD.organizzazione_id, 'soggetto_id', OLD.soggetto_id,
                    'target_tipo', OLD.target_tipo,
                    'target_asset_id', OLD.target_asset_id,
                    'target_servizio_id', OLD.target_servizio_id,
                    'target_fornitore_id', OLD.target_fornitore_id,
                    'ruolo_raci', OLD.ruolo_raci, 'descrizione_ruolo', OLD.descrizione_ruolo,
                    'valid_from', OLD.valid_from, 'valid_to', OLD.valid_to, 'is_current', OLD.is_current),
        JSON_OBJECT('id', NEW.id, 'organizzazione_id', NEW.organizzazione_id, 'soggetto_id', NEW.soggetto_id,
                    'target_tipo', NEW.target_tipo,
                    'target_asset_id', NEW.target_asset_id,
                    'target_servizio_id', NEW.target_servizio_id,
                    'target_fornitore_id', NEW.target_fornitore_id,
                    'ruolo_raci', NEW.ruolo_raci, 'descrizione_ruolo', NEW.descrizione_ruolo,
                    'valid_from', NEW.valid_from, 'valid_to', NEW.valid_to, 'is_current', NEW.is_current));
END$$

CREATE TRIGGER trg_responsabilita_audit_delete AFTER DELETE ON Responsabilita FOR EACH ROW
BEGIN
    INSERT INTO audit_log (tabella, record_id, operazione, utente_db, organizzazione_id, payload_precedente)
    VALUES ('Responsabilita', OLD.id, 'DELETE', CURRENT_USER(), OLD.organizzazione_id,
        JSON_OBJECT('id', OLD.id, 'organizzazione_id', OLD.organizzazione_id, 'soggetto_id', OLD.soggetto_id,
                    'target_tipo', OLD.target_tipo,
                    'target_asset_id', OLD.target_asset_id,
                    'target_servizio_id', OLD.target_servizio_id,
                    'target_fornitore_id', OLD.target_fornitore_id,
                    'ruolo_raci', OLD.ruolo_raci, 'descrizione_ruolo', OLD.descrizione_ruolo,
                    'valid_from', OLD.valid_from, 'valid_to', OLD.valid_to, 'is_current', OLD.is_current));
END$$

DELIMITER ;


-- Stored procedure per chiudere una versione corrente in SCD2.

DELIMITER $$

CREATE PROCEDURE sp_close_version(IN p_table VARCHAR(100), IN p_id BIGINT UNSIGNED)
BEGIN
    IF p_table NOT IN ('Organizzazione', 'FornitoreTerzo', 'Ubicazione', 'Asset', 'Servizio',
                       'Asset_Servizio', 'Soggetto', 'Dipendenza', 'Responsabilita') THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'sp_close_version: tabella non riconosciuta come versionata';
    END IF;

    SET @sql = CONCAT('UPDATE ', p_table,
                      ' SET valid_to = CURRENT_TIMESTAMP(6), is_current = FALSE',
                      ' WHERE id = ? AND is_current = TRUE');
    SET @v_id = p_id;
    PREPARE stmt FROM @sql;
    EXECUTE stmt USING @v_id;
    DEALLOCATE PREPARE stmt;
END$$

DELIMITER ;
