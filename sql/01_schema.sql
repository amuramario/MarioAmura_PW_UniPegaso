SET NAMES utf8mb4;
SET default_storage_engine = InnoDB;

-- ORGANIZZAZIONE — soggetto NIS2 (tenant), versionato SCD2.
CREATE TABLE Organizzazione (
    id                     BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,

    ragione_sociale        VARCHAR(255)  NOT NULL,
    codice_fiscale         VARCHAR(16)   NOT NULL,
    partita_iva            VARCHAR(11)   NULL,
    pec                    VARCHAR(255)  NOT NULL,

    allegato               ENUM('I', 'II', 'III', 'IV') NOT NULL,
    settore_nis2           ENUM(
        'ENERGIA_ELETTRICA', 'ENERGIA_GAS', 'ENERGIA_PETROLIO',
        'TRASPORTO_AEREO', 'TRASPORTO_FERROVIARIO',
        'TRASPORTO_NAVALE', 'TRASPORTO_STRADALE',
        'BANCARIO', 'MERCATI_FINANZIARI',
        'SANITA',
        'ACQUA_POTABILE', 'ACQUE_REFLUE',
        'INFRASTRUTTURA_DIGITALE', 'SERVIZI_TIC_B2B',
        'SPAZIO',
        'SERVIZI_POSTALI', 'GESTIONE_RIFIUTI',
        'CHIMICO', 'ALIMENTARE', 'MANIFATTURIERO',
        'SERVIZI_DIGITALI', 'RICERCA',
        'PA_CENTRALE', 'PA_LOCALE',
        'TRASPORTO_PUBBLICO_LOCALE', 'ISTRUZIONE_RICERCA',
        'CULTURALE', 'IN_HOUSE',
        'ALTRO'
    ) NOT NULL,
    categoria_nis2         ENUM('ESSENZIALE', 'IMPORTANTE') NOT NULL,
    perimetro_psnc         BOOLEAN NOT NULL DEFAULT FALSE,

    data_registrazione_acn DATE NULL,
    stato_registrazione    ENUM('ATTIVA', 'SOSPESA', 'CESSATA') NOT NULL DEFAULT 'ATTIVA',

    valid_from             TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    valid_to               TIMESTAMP(6) NULL,
    is_current             BOOLEAN      NOT NULL DEFAULT TRUE,

    -- Emula UNIQUE parziale sui record correnti
    cf_current             VARCHAR(16)
        GENERATED ALWAYS AS (IF(is_current, codice_fiscale, NULL)) STORED,

    PRIMARY KEY (id),
    UNIQUE KEY uk_organizzazione_cf_current (cf_current),

    CONSTRAINT chk_organizzazione_allegato_settore CHECK (
        (allegato = 'I' AND settore_nis2 IN (
            'ENERGIA_ELETTRICA', 'ENERGIA_GAS', 'ENERGIA_PETROLIO',
            'TRASPORTO_AEREO', 'TRASPORTO_FERROVIARIO',
            'TRASPORTO_NAVALE', 'TRASPORTO_STRADALE',
            'BANCARIO', 'MERCATI_FINANZIARI',
            'SANITA',
            'ACQUA_POTABILE', 'ACQUE_REFLUE',
            'INFRASTRUTTURA_DIGITALE', 'SERVIZI_TIC_B2B',
            'SPAZIO'
        ))
        OR (allegato = 'II' AND settore_nis2 IN (
            'SERVIZI_POSTALI', 'GESTIONE_RIFIUTI',
            'CHIMICO', 'ALIMENTARE', 'MANIFATTURIERO',
            'SERVIZI_DIGITALI', 'RICERCA'
        ))
        OR (allegato = 'III' AND settore_nis2 IN ('PA_CENTRALE', 'PA_LOCALE'))
        OR (allegato = 'IV' AND settore_nis2 IN (
            'TRASPORTO_PUBBLICO_LOCALE', 'ISTRUZIONE_RICERCA',
            'CULTURALE', 'IN_HOUSE'
        ))
        OR settore_nis2 = 'ALTRO'
    ),

    CONSTRAINT chk_organizzazione_scd2 CHECK (
        (is_current = TRUE AND valid_to IS NULL)
        OR (is_current = FALSE AND valid_to IS NOT NULL AND valid_to > valid_from)
    ),

    CONSTRAINT chk_organizzazione_cf_format   CHECK (CHAR_LENGTH(codice_fiscale) IN (11, 16)),
    CONSTRAINT chk_organizzazione_piva_format CHECK (partita_iva IS NULL OR CHAR_LENGTH(partita_iva) = 11)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE INDEX idx_organizzazione_settore_current   ON Organizzazione (settore_nis2, is_current);
CREATE INDEX idx_organizzazione_perimetro_current ON Organizzazione (perimetro_psnc, is_current);
CREATE INDEX idx_organizzazione_stato_current     ON Organizzazione (stato_registrazione, is_current);


-- FORNITORE_TERZO — fornitore ICT esterno all'organizzazione, versionato SCD2.
CREATE TABLE FornitoreTerzo (
    id                     BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    organizzazione_id      BIGINT UNSIGNED NOT NULL,

    denominazione          VARCHAR(255) NOT NULL,
    identificativo_fiscale VARCHAR(50)  NOT NULL,
    paese_sede             CHAR(2)      NOT NULL,

    categoria              ENUM(
        'CLOUD_PROVIDER', 'COLOCATION', 'MANUTENTORE_HW',
        'SOFTWARE_VENDOR', 'TELCO', 'SICUREZZA_GESTITA',
        'CONSULENZA', 'ALTRO'
    ) NOT NULL,
    note                   TEXT NULL,

    rilevanza_nis2         BOOLEAN NOT NULL DEFAULT FALSE,
    criterio_rilevanza     VARCHAR(255) NULL,
    cpv_principale         VARCHAR(10)  NULL,
    certificazioni         VARCHAR(500) NULL,
    sede_legale_extra_ue   BOOLEAN NOT NULL DEFAULT FALSE,

    data_inizio_rapporto   DATE NULL,
    data_fine_rapporto     DATE NULL,
    stato_rapporto         ENUM('ATTIVO', 'SOSPESO', 'CESSATO') NOT NULL DEFAULT 'ATTIVO',

    valid_from             TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    valid_to               TIMESTAMP(6) NULL,
    is_current             BOOLEAN      NOT NULL DEFAULT TRUE,

    -- Unicità (organizzazione, identificativo fiscale) solo fra record correnti.
    org_current            BIGINT UNSIGNED
        GENERATED ALWAYS AS (IF(is_current, organizzazione_id, NULL)) STORED,
    idfisc_current         VARCHAR(50)
        GENERATED ALWAYS AS (IF(is_current, identificativo_fiscale, NULL)) STORED,

    PRIMARY KEY (id),
    UNIQUE KEY uk_fornitore_idfisc_current (org_current, idfisc_current),

    FOREIGN KEY (organizzazione_id) REFERENCES Organizzazione(id)
        ON DELETE RESTRICT ON UPDATE RESTRICT,

    CONSTRAINT chk_fornitore_categoria_altro CHECK (
        categoria <> 'ALTRO'
        OR (note IS NOT NULL AND CHAR_LENGTH(TRIM(note)) > 0)
    ),

    CONSTRAINT chk_fornitore_rilevanza CHECK (
        rilevanza_nis2 = FALSE
        OR (
            criterio_rilevanza IS NOT NULL
            AND CHAR_LENGTH(TRIM(criterio_rilevanza)) > 0
            AND cpv_principale IS NOT NULL
        )
    ),

    CONSTRAINT chk_fornitore_cpv_format CHECK (
        cpv_principale IS NULL OR cpv_principale REGEXP '^[0-9]{8}-[0-9]$'
    ),

    CONSTRAINT chk_fornitore_cessato CHECK (
        stato_rapporto <> 'CESSATO' OR data_fine_rapporto IS NOT NULL
    ),

    CONSTRAINT chk_fornitore_date CHECK (
        data_fine_rapporto IS NULL
        OR data_inizio_rapporto IS NULL
        OR data_fine_rapporto >= data_inizio_rapporto
    ),

    -- La collation default e' case-insensitive: forziamo il binary matching per rifiutare 'it' / 'It'.
    CONSTRAINT chk_fornitore_paese_format CHECK (
        paese_sede COLLATE utf8mb4_bin REGEXP '^[A-Z]{2}$'
    ),

    CONSTRAINT chk_fornitore_scd2 CHECK (
        (is_current = TRUE AND valid_to IS NULL)
        OR (is_current = FALSE AND valid_to IS NOT NULL AND valid_to > valid_from)
    )
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE INDEX idx_fornitore_org_current       ON FornitoreTerzo (organizzazione_id, is_current);
CREATE INDEX idx_fornitore_rilevanza_current ON FornitoreTerzo (rilevanza_nis2, is_current);
CREATE INDEX idx_fornitore_categoria_current ON FornitoreTerzo (categoria, is_current);
CREATE INDEX idx_fornitore_paese_current     ON FornitoreTerzo (paese_sede, is_current);


-- UBICAZIONE — sede legale, ufficio, datacenter o cloud region. Tabella polimorfica.
CREATE TABLE Ubicazione (
    id                  BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    organizzazione_id   BIGINT UNSIGNED NOT NULL,

    denominazione       VARCHAR(255) NOT NULL,
    tipo                ENUM('SEDE_LEGALE', 'UFFICIO', 'DATACENTER', 'CLOUD_REGION', 'COLOCATION', 'ALTRO') NOT NULL,
    tipo_gestione       ENUM('PROPRIETARIA', 'AFFITTATA', 'COLOCATION', 'CLOUD_PUBBLICO', 'CLOUD_PRIVATO') NOT NULL,
    paese               CHAR(2)      NOT NULL,
    regione_geografica  VARCHAR(100) NULL,
    indirizzo           VARCHAR(500) NULL,
    fornitore_terzo_id  BIGINT UNSIGNED NULL,

    valid_from          TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    valid_to            TIMESTAMP(6) NULL,
    is_current          BOOLEAN      NOT NULL DEFAULT TRUE,

    -- Al piu' una sede legale corrente per organizzazione.
    sede_legale_key     BIGINT UNSIGNED
        GENERATED ALWAYS AS (
            IF(is_current AND tipo = 'SEDE_LEGALE', organizzazione_id, NULL)
        ) STORED,

    PRIMARY KEY (id),
    UNIQUE KEY uk_ubicazione_sede_legale (sede_legale_key),

    FOREIGN KEY (organizzazione_id) REFERENCES Organizzazione(id)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    FOREIGN KEY (fornitore_terzo_id) REFERENCES FornitoreTerzo(id)
        ON DELETE RESTRICT ON UPDATE RESTRICT,

    CONSTRAINT chk_ubicazione_gestione_fornitore CHECK (
        (tipo_gestione IN ('CLOUD_PUBBLICO', 'CLOUD_PRIVATO', 'COLOCATION')
            AND fornitore_terzo_id IS NOT NULL)
        OR
        (tipo_gestione IN ('PROPRIETARIA', 'AFFITTATA')
            AND fornitore_terzo_id IS NULL)
    ),

    CONSTRAINT chk_ubicazione_sede_indirizzo CHECK (
        tipo <> 'SEDE_LEGALE'
        OR (indirizzo IS NOT NULL AND CHAR_LENGTH(TRIM(indirizzo)) > 0)
    ),

    CONSTRAINT chk_ubicazione_paese_format CHECK (
        paese COLLATE utf8mb4_bin REGEXP '^[A-Z]{2}$'
    ),

    CONSTRAINT chk_ubicazione_scd2 CHECK (
        (is_current = TRUE AND valid_to IS NULL)
        OR (is_current = FALSE AND valid_to IS NOT NULL AND valid_to > valid_from)
    )
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE INDEX idx_ubicazione_org_current       ON Ubicazione (organizzazione_id, is_current);
CREATE INDEX idx_ubicazione_tipo_current      ON Ubicazione (tipo, is_current);
CREATE INDEX idx_ubicazione_fornitore_current ON Ubicazione (fornitore_terzo_id, is_current);
CREATE INDEX idx_ubicazione_paese_current     ON Ubicazione (paese, is_current);


-- ASSET — risorsa ICT (hardware, software, dato, servizio di rete), versionato SCD2.
CREATE TABLE Asset (
    id                         BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    organizzazione_id          BIGINT UNSIGNED NOT NULL,
    ubicazione_id              BIGINT UNSIGNED NOT NULL,

    codice_interno             VARCHAR(100) NOT NULL,
    denominazione              VARCHAR(255) NOT NULL,
    descrizione                TEXT NULL,

    tipo                       ENUM(
        'SERVER', 'APPARATO_RETE', 'STORAGE', 'CLIENT',
        'APPLICATIVO', 'DATABASE', 'SISTEMA_OPERATIVO',
        'SERVIZIO_RETE', 'DATO', 'DOCUMENTO', 'ALTRO'
    ) NOT NULL,

    classificazione_c          ENUM('BASSO', 'MEDIO', 'ALTO') NOT NULL,
    classificazione_i          ENUM('BASSO', 'MEDIO', 'ALTO') NOT NULL,
    classificazione_a          ENUM('BASSO', 'MEDIO', 'ALTO') NOT NULL,

    stato_ciclo_vita           ENUM(
        'PIANIFICATO', 'IN_COLLAUDO', 'ATTIVO', 'IN_MANUTENZIONE', 'DISMESSO'
    ) NOT NULL DEFAULT 'ATTIVO',

    rilevanza_nis2             BOOLEAN NOT NULL DEFAULT FALSE,
    esposto_internet           BOOLEAN NOT NULL DEFAULT FALSE,
    contiene_dati_personali    BOOLEAN NOT NULL DEFAULT FALSE,

    data_introduzione          DATE NULL,
    data_dismissione_prevista  DATE NULL,

    hostname                   VARCHAR(255) NULL,
    versione                   VARCHAR(100) NULL,

    valid_from                 TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    valid_to                   TIMESTAMP(6) NULL,
    is_current                 BOOLEAN      NOT NULL DEFAULT TRUE,

    -- Unicità (organizzazione, codice_interno) solo fra i record correnti.
    org_current                BIGINT UNSIGNED
        GENERATED ALWAYS AS (IF(is_current, organizzazione_id, NULL)) STORED,
    cod_current                VARCHAR(100)
        GENERATED ALWAYS AS (IF(is_current, codice_interno, NULL)) STORED,

    PRIMARY KEY (id),
    UNIQUE KEY uk_asset_codice_current (org_current, cod_current),

    FOREIGN KEY (organizzazione_id) REFERENCES Organizzazione(id)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    FOREIGN KEY (ubicazione_id) REFERENCES Ubicazione(id)
        ON DELETE RESTRICT ON UPDATE RESTRICT,

    CONSTRAINT chk_asset_tipo_altro CHECK (
        tipo <> 'ALTRO'
        OR (descrizione IS NOT NULL AND CHAR_LENGTH(TRIM(descrizione)) > 0)
    ),

    CONSTRAINT chk_asset_dismesso_rilevanza CHECK (
        stato_ciclo_vita <> 'DISMESSO' OR rilevanza_nis2 = FALSE
    ),

    CONSTRAINT chk_asset_date CHECK (
        data_dismissione_prevista IS NULL
        OR data_introduzione IS NULL
        OR data_dismissione_prevista >= data_introduzione
    ),

    CONSTRAINT chk_asset_scd2 CHECK (
        (is_current = TRUE AND valid_to IS NULL)
        OR (is_current = FALSE AND valid_to IS NOT NULL AND valid_to > valid_from)
    )
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE INDEX idx_asset_org_current        ON Asset (organizzazione_id, is_current);
CREATE INDEX idx_asset_ubicazione_current ON Asset (ubicazione_id, is_current);
CREATE INDEX idx_asset_tipo_current       ON Asset (tipo, is_current);
CREATE INDEX idx_asset_rilevanza_current  ON Asset (rilevanza_nis2, is_current);
CREATE INDEX idx_asset_stato_current      ON Asset (stato_ciclo_vita, is_current);


-- SERVIZIO — prestazione erogata all'esterno, con SLA inline. Versionato SCD2.
CREATE TABLE Servizio (
    id                 BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    organizzazione_id  BIGINT UNSIGNED NOT NULL,

    codice_interno     VARCHAR(100) NOT NULL,
    denominazione      VARCHAR(255) NOT NULL,
    descrizione        TEXT         NOT NULL,

    criticita          ENUM('BASSA', 'MEDIA', 'ALTA') NOT NULL,
    ambito_nis2        BOOLEAN NOT NULL DEFAULT FALSE,

    uptime_target      DECIMAL(6,3) NULL,
    rto_ore            INT UNSIGNED NULL,
    rpo_ore            INT UNSIGNED NULL,
    orario_copertura   ENUM('H24', 'H12_LAV', 'H8_LAV', 'ALTRO') NULL,

    data_attivazione   DATE NULL,
    data_dismissione   DATE NULL,
    stato_erogazione   ENUM('PIANIFICATO', 'ATTIVO', 'SOSPESO', 'DISMESSO') NOT NULL DEFAULT 'ATTIVO',

    valid_from         TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    valid_to           TIMESTAMP(6) NULL,
    is_current         BOOLEAN      NOT NULL DEFAULT TRUE,

    -- Unicità (organizzazione, codice_interno) solo fra record correnti.
    org_current        BIGINT UNSIGNED
        GENERATED ALWAYS AS (IF(is_current, organizzazione_id, NULL)) STORED,
    cod_current        VARCHAR(100)
        GENERATED ALWAYS AS (IF(is_current, codice_interno, NULL)) STORED,

    PRIMARY KEY (id),
    UNIQUE KEY uk_servizio_codice_current (org_current, cod_current),

    FOREIGN KEY (organizzazione_id) REFERENCES Organizzazione(id)
        ON DELETE RESTRICT ON UPDATE RESTRICT,

    -- Un servizio nel perimetro NIS2 non puo' avere criticita bassa.
    CONSTRAINT chk_servizio_nis2_criticita CHECK (
        ambito_nis2 = FALSE OR criticita IN ('MEDIA', 'ALTA')
    ),

    -- SLA obbligatori per servizi NIS2.
    CONSTRAINT chk_servizio_nis2_sla CHECK (
        ambito_nis2 = FALSE
        OR (
            uptime_target IS NOT NULL
            AND rto_ore IS NOT NULL
            AND rpo_ore IS NOT NULL
            AND orario_copertura IS NOT NULL
        )
    ),

    CONSTRAINT chk_servizio_dismesso CHECK (
        stato_erogazione <> 'DISMESSO' OR ambito_nis2 = FALSE
    ),

    CONSTRAINT chk_servizio_uptime_range CHECK (
        uptime_target IS NULL OR (uptime_target >= 0 AND uptime_target <= 100)
    ),

    CONSTRAINT chk_servizio_date CHECK (
        data_dismissione IS NULL
        OR data_attivazione IS NULL
        OR data_dismissione >= data_attivazione
    ),

    CONSTRAINT chk_servizio_scd2 CHECK (
        (is_current = TRUE AND valid_to IS NULL)
        OR (is_current = FALSE AND valid_to IS NOT NULL AND valid_to > valid_from)
    )
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE INDEX idx_servizio_org_current       ON Servizio (organizzazione_id, is_current);
CREATE INDEX idx_servizio_criticita_current ON Servizio (criticita, is_current);
CREATE INDEX idx_servizio_ambito_current    ON Servizio (ambito_nis2, is_current);
CREATE INDEX idx_servizio_stato_current     ON Servizio (stato_erogazione, is_current);


-- ASSET_SERVIZIO — relazione N:M fra Asset e Servizio, con ruolo dell'asset nel servizio.
CREATE TABLE Asset_Servizio (
    id          BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    asset_id    BIGINT UNSIGNED NOT NULL,
    servizio_id BIGINT UNSIGNED NOT NULL,

    ruolo       ENUM('PRIMARIO', 'SECONDARIO', 'SUPPORTO', 'ALTRO') NOT NULL,
    note        TEXT NULL,

    valid_from  TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    valid_to    TIMESTAMP(6) NULL,
    is_current  BOOLEAN      NOT NULL DEFAULT TRUE,

    -- Unicità (asset, servizio) solo sui record correnti.
    asset_current    BIGINT UNSIGNED
        GENERATED ALWAYS AS (IF(is_current, asset_id, NULL)) STORED,
    servizio_current BIGINT UNSIGNED
        GENERATED ALWAYS AS (IF(is_current, servizio_id, NULL)) STORED,

    PRIMARY KEY (id),
    UNIQUE KEY uk_asset_servizio_current (asset_current, servizio_current),

    FOREIGN KEY (asset_id)    REFERENCES Asset(id)    ON DELETE RESTRICT ON UPDATE RESTRICT,
    FOREIGN KEY (servizio_id) REFERENCES Servizio(id) ON DELETE RESTRICT ON UPDATE RESTRICT,

    CONSTRAINT chk_asservizio_ruolo_altro CHECK (
        ruolo <> 'ALTRO'
        OR (note IS NOT NULL AND CHAR_LENGTH(TRIM(note)) > 0)
    ),

    CONSTRAINT chk_asservizio_scd2 CHECK (
        (is_current = TRUE AND valid_to IS NULL)
        OR (is_current = FALSE AND valid_to IS NOT NULL AND valid_to > valid_from)
    )
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE INDEX idx_asservizio_asset_current    ON Asset_Servizio (asset_id, is_current);
CREATE INDEX idx_asservizio_servizio_current ON Asset_Servizio (servizio_id, is_current);
CREATE INDEX idx_asservizio_ruolo_current    ON Asset_Servizio (ruolo, is_current);


-- SOGGETTO — persona fisica o ruolo organizzativo, tabella polimorfica.
CREATE TABLE Soggetto (
    id                    BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    organizzazione_id     BIGINT UNSIGNED NOT NULL,

    tipo                  ENUM('PERSONA', 'RUOLO') NOT NULL,
    denominazione         VARCHAR(255) NOT NULL,

    nome                  VARCHAR(100) NULL,
    cognome               VARCHAR(100) NULL,
    email                 VARCHAR(255) NULL,
    telefono              VARCHAR(50)  NULL,
    ruolo_organizzativo   VARCHAR(255) NULL,

    is_punto_contatto_acn BOOLEAN NOT NULL DEFAULT FALSE,
    stato                 ENUM('ATTIVO', 'INATTIVO') NOT NULL DEFAULT 'ATTIVO',

    valid_from            TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    valid_to              TIMESTAMP(6) NULL,
    is_current            BOOLEAN      NOT NULL DEFAULT TRUE,

    -- Al max un punto di contatto ACN corrente per organizzazione.
    pdc_key               BIGINT UNSIGNED
        GENERATED ALWAYS AS (
            IF(is_punto_contatto_acn AND is_current, organizzazione_id, NULL)
        ) STORED,

    PRIMARY KEY (id),
    UNIQUE KEY uk_soggetto_punto_contatto (pdc_key),

    FOREIGN KEY (organizzazione_id) REFERENCES Organizzazione(id)
        ON DELETE RESTRICT ON UPDATE RESTRICT,

    CONSTRAINT chk_soggetto_persona_nome CHECK (
        (tipo = 'PERSONA' AND nome IS NOT NULL AND cognome IS NOT NULL)
        OR (tipo = 'RUOLO' AND nome IS NULL AND cognome IS NULL)
    ),

    CONSTRAINT chk_soggetto_punto_contatto CHECK (
        is_punto_contatto_acn = FALSE
        OR (tipo = 'PERSONA' AND email IS NOT NULL AND CHAR_LENGTH(TRIM(email)) > 0)
    ),

    CONSTRAINT chk_soggetto_inattivo CHECK (
        stato <> 'INATTIVO' OR is_punto_contatto_acn = FALSE
    ),

    CONSTRAINT chk_soggetto_scd2 CHECK (
        (is_current = TRUE AND valid_to IS NULL)
        OR (is_current = FALSE AND valid_to IS NOT NULL AND valid_to > valid_from)
    )
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE INDEX idx_soggetto_org_current   ON Soggetto (organizzazione_id, is_current);
CREATE INDEX idx_soggetto_tipo_current  ON Soggetto (tipo, is_current);
CREATE INDEX idx_soggetto_stato_current ON Soggetto (stato, is_current);


-- DIPENDENZA — relazione polimorfica. Sorgente Asset/Servizio, destinazione Asset/Servizio/Fornitore.
CREATE TABLE Dipendenza (
    id                        BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    organizzazione_id         BIGINT UNSIGNED NOT NULL,

    sorgente_tipo             ENUM('ASSET', 'SERVIZIO') NOT NULL,
    sorgente_asset_id         BIGINT UNSIGNED NULL,
    sorgente_servizio_id      BIGINT UNSIGNED NULL,

    destinazione_tipo         ENUM('ASSET', 'SERVIZIO', 'FORNITORE') NOT NULL,
    destinazione_asset_id     BIGINT UNSIGNED NULL,
    destinazione_servizio_id  BIGINT UNSIGNED NULL,
    destinazione_fornitore_id BIGINT UNSIGNED NULL,

    tipo                      ENUM('RETE', 'TECNICA', 'LOGICA', 'ORGANIZZATIVA') NOT NULL,
    criticita                 ENUM('BASSA', 'MEDIA', 'ALTA') NOT NULL,
    descrizione               TEXT NULL,

    valid_from                TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    valid_to                  TIMESTAMP(6) NULL,
    is_current                BOOLEAN      NOT NULL DEFAULT TRUE,

    -- Chiave di unicita: una sola dipendenza attiva.
    dip_key                   VARCHAR(100)
        GENERATED ALWAYS AS (
            IF(is_current,
                CONCAT_WS('-',
                    sorgente_tipo,
                    COALESCE(sorgente_asset_id, sorgente_servizio_id),
                    destinazione_tipo,
                    COALESCE(destinazione_asset_id, destinazione_servizio_id, destinazione_fornitore_id),
                    tipo
                ),
                NULL
            )
        ) STORED,

    PRIMARY KEY (id),
    UNIQUE KEY uk_dipendenza_current (dip_key),

    FOREIGN KEY (organizzazione_id)         REFERENCES Organizzazione(id)  ON DELETE RESTRICT ON UPDATE RESTRICT,
    FOREIGN KEY (sorgente_asset_id)         REFERENCES Asset(id)           ON DELETE RESTRICT ON UPDATE RESTRICT,
    FOREIGN KEY (sorgente_servizio_id)      REFERENCES Servizio(id)        ON DELETE RESTRICT ON UPDATE RESTRICT,
    FOREIGN KEY (destinazione_asset_id)     REFERENCES Asset(id)           ON DELETE RESTRICT ON UPDATE RESTRICT,
    FOREIGN KEY (destinazione_servizio_id)  REFERENCES Servizio(id)        ON DELETE RESTRICT ON UPDATE RESTRICT,
    FOREIGN KEY (destinazione_fornitore_id) REFERENCES FornitoreTerzo(id)  ON DELETE RESTRICT ON UPDATE RESTRICT,

    CONSTRAINT chk_dip_sorgente CHECK (
        (sorgente_tipo = 'ASSET'
            AND sorgente_asset_id IS NOT NULL
            AND sorgente_servizio_id IS NULL)
        OR
        (sorgente_tipo = 'SERVIZIO'
            AND sorgente_servizio_id IS NOT NULL
            AND sorgente_asset_id IS NULL)
    ),

    CONSTRAINT chk_dip_destinazione CHECK (
        (destinazione_tipo = 'ASSET'
            AND destinazione_asset_id IS NOT NULL
            AND destinazione_servizio_id IS NULL
            AND destinazione_fornitore_id IS NULL)
        OR
        (destinazione_tipo = 'SERVIZIO'
            AND destinazione_servizio_id IS NOT NULL
            AND destinazione_asset_id IS NULL
            AND destinazione_fornitore_id IS NULL)
        OR
        (destinazione_tipo = 'FORNITORE'
            AND destinazione_fornitore_id IS NOT NULL
            AND destinazione_asset_id IS NULL
            AND destinazione_servizio_id IS NULL)
    ),

    -- Un elemento non dipende da sé stesso.
    CONSTRAINT chk_dip_no_self CHECK (
        NOT (sorgente_tipo = destinazione_tipo
             AND (
                (sorgente_asset_id IS NOT NULL AND sorgente_asset_id = destinazione_asset_id)
                OR (sorgente_servizio_id IS NOT NULL AND sorgente_servizio_id = destinazione_servizio_id)
             ))
    ),

    -- Una dipendenza organizzativa va sempre verso un fornitore terzo.
    CONSTRAINT chk_dip_organizzativa_fornitore CHECK (
        tipo <> 'ORGANIZZATIVA' OR destinazione_tipo = 'FORNITORE'
    ),

    CONSTRAINT chk_dip_scd2 CHECK (
        (is_current = TRUE AND valid_to IS NULL)
        OR (is_current = FALSE AND valid_to IS NOT NULL AND valid_to > valid_from)
    )
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE INDEX idx_dip_org_current  ON Dipendenza (organizzazione_id, is_current);
CREATE INDEX idx_dip_tipo_current ON Dipendenza (tipo, is_current);


-- RESPONSABILITA — matrice RACI: Soggetto responsabile di Asset/Servizio/Fornitore.
CREATE TABLE Responsabilita (
    id                      BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    organizzazione_id       BIGINT UNSIGNED NOT NULL,
    soggetto_id             BIGINT UNSIGNED NOT NULL,

    target_tipo             ENUM('ASSET', 'SERVIZIO', 'FORNITORE') NOT NULL,
    target_asset_id         BIGINT UNSIGNED NULL,
    target_servizio_id      BIGINT UNSIGNED NULL,
    target_fornitore_id     BIGINT UNSIGNED NULL,

    ruolo_raci              ENUM('RESPONSIBLE', 'ACCOUNTABLE', 'CONSULTED', 'INFORMED') NOT NULL,
    descrizione_ruolo       VARCHAR(255) NULL,

    valid_from              TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    valid_to                TIMESTAMP(6) NULL,
    is_current              BOOLEAN      NOT NULL DEFAULT TRUE,

    -- Unicita (soggetto, target, ruolo) sui correnti.
    resp_key                VARCHAR(100)
        GENERATED ALWAYS AS (
            IF(is_current,
                CONCAT_WS('-',
                    soggetto_id,
                    target_tipo,
                    COALESCE(target_asset_id, target_servizio_id, target_fornitore_id),
                    ruolo_raci
                ),
                NULL
            )
        ) STORED,

    -- Un solo Accountable corrente per target.
    accountable_key         VARCHAR(50)
        GENERATED ALWAYS AS (
            IF(is_current AND ruolo_raci = 'ACCOUNTABLE',
                CONCAT_WS('-',
                    target_tipo,
                    COALESCE(target_asset_id, target_servizio_id, target_fornitore_id)
                ),
                NULL
            )
        ) STORED,

    PRIMARY KEY (id),
    UNIQUE KEY uk_resp_current      (resp_key),
    UNIQUE KEY uk_resp_accountable  (accountable_key),

    FOREIGN KEY (organizzazione_id)   REFERENCES Organizzazione(id)  ON DELETE RESTRICT ON UPDATE RESTRICT,
    FOREIGN KEY (soggetto_id)         REFERENCES Soggetto(id)        ON DELETE RESTRICT ON UPDATE RESTRICT,
    FOREIGN KEY (target_asset_id)     REFERENCES Asset(id)           ON DELETE RESTRICT ON UPDATE RESTRICT,
    FOREIGN KEY (target_servizio_id)  REFERENCES Servizio(id)        ON DELETE RESTRICT ON UPDATE RESTRICT,
    FOREIGN KEY (target_fornitore_id) REFERENCES FornitoreTerzo(id)  ON DELETE RESTRICT ON UPDATE RESTRICT,

    CONSTRAINT chk_resp_target CHECK (
        (target_tipo = 'ASSET'
            AND target_asset_id IS NOT NULL
            AND target_servizio_id IS NULL
            AND target_fornitore_id IS NULL)
        OR
        (target_tipo = 'SERVIZIO'
            AND target_servizio_id IS NOT NULL
            AND target_asset_id IS NULL
            AND target_fornitore_id IS NULL)
        OR
        (target_tipo = 'FORNITORE'
            AND target_fornitore_id IS NOT NULL
            AND target_asset_id IS NULL
            AND target_servizio_id IS NULL)
    ),

    CONSTRAINT chk_resp_scd2 CHECK (
        (is_current = TRUE AND valid_to IS NULL)
        OR (is_current = FALSE AND valid_to IS NOT NULL AND valid_to > valid_from)
    )
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE INDEX idx_resp_org_current      ON Responsabilita (organizzazione_id, is_current);
CREATE INDEX idx_resp_soggetto_current ON Responsabilita (soggetto_id, is_current);
CREATE INDEX idx_resp_ruolo_current    ON Responsabilita (ruolo_raci, is_current);


-- AUDIT_LOG — tracciabilita immutabile delle modifiche su tutte le tabelle versionate.

CREATE TABLE audit_log (
    id                  BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,

    tabella             VARCHAR(100) NOT NULL,
    record_id           BIGINT UNSIGNED NOT NULL,
    operazione          ENUM('INSERT', 'UPDATE', 'DELETE') NOT NULL,
    ts_evento           TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    utente_db           VARCHAR(255) NOT NULL,

    organizzazione_id   BIGINT UNSIGNED NULL,

    payload_precedente  JSON NULL,
    payload_nuovo       JSON NULL,

    PRIMARY KEY (id),


    CONSTRAINT chk_audit_payload_insert CHECK (
        operazione <> 'INSERT'
        OR (payload_precedente IS NULL AND payload_nuovo IS NOT NULL)
    ),
    CONSTRAINT chk_audit_payload_update CHECK (
        operazione <> 'UPDATE'
        OR (payload_precedente IS NOT NULL AND payload_nuovo IS NOT NULL)
    ),
    CONSTRAINT chk_audit_payload_delete CHECK (
        operazione <> 'DELETE'
        OR (payload_precedente IS NOT NULL AND payload_nuovo IS NULL)
    )
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE INDEX idx_audit_tabella_record ON audit_log (tabella, record_id);
CREATE INDEX idx_audit_org_ts         ON audit_log (organizzazione_id, ts_evento);
CREATE INDEX idx_audit_ts             ON audit_log (ts_evento);
