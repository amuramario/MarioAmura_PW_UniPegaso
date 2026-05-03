-- Seed Acme Banking S.p.A.

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


INSERT INTO Organizzazione
    (ragione_sociale, codice_fiscale, partita_iva, pec, allegato, settore_nis2, categoria_nis2,
     perimetro_psnc, data_registrazione_acn, stato_registrazione)
VALUES
    ('Acme Banking S.p.A.', '07812340968', '07812340968', 'acmebanking@pec.it',
     'I', 'BANCARIO', 'ESSENZIALE', FALSE, '2025-02-15', 'ATTIVA');


INSERT INTO FornitoreTerzo
    (organizzazione_id, denominazione, identificativo_fiscale, paese_sede, categoria,
     rilevanza_nis2, criterio_rilevanza, cpv_principale, certificazioni, sede_legale_extra_ue,
     data_inizio_rapporto, stato_rapporto)
VALUES
    (1, 'Amazon Web Services EMEA SARL', 'LU26888617', 'LU', 'CLOUD_PROVIDER',
     TRUE, 'Hosting infrastruttura produzione home banking e core',
     '72000000-5', 'ISO 27001, SOC 2 Type II, ISAE 3402', FALSE,
     '2021-06-01', 'ATTIVO'),

    (1, 'SIA S.p.A.', '10810030152', 'IT', 'SOFTWARE_VENDOR',
     TRUE, 'Gateway pagamenti interbancari SEPA e bonifici istantanei',
     '72267100-0', 'ISO 27001, PCI-DSS', FALSE,
     '2018-01-01', 'ATTIVO'),

    (1, 'SysBank Services S.p.A.', '02345678903', 'IT', 'SOFTWARE_VENDOR',
     TRUE, 'Manutenzione e aggiornamenti software core bancario',
     '72267100-0', 'ISO 27001', FALSE,
     '2019-03-15', 'ATTIVO'),

    (1, 'IdentityHub EMEA B.V.', 'NL857392014', 'NL', 'SOFTWARE_VENDOR',
     TRUE, 'Identity provider SaaS per SSO clienti e dipendenti',
     '72212000-4', 'ISO 27001, SOC 2 Type II', FALSE,
     '2023-09-10', 'ATTIVO'),

    (1, 'SecureOps Italia S.r.l.', '12998877001', 'IT', 'SICUREZZA_GESTITA',
     TRUE, 'Servizio SOC gestito 24/7 e risposta a incidenti',
     '72611000-6', 'ISO 27001, ISO 27035', FALSE,
     '2022-11-01', 'ATTIVO'),

    (1, 'CompuRack Italia S.r.l.', '08223345099', 'IT', 'COLOCATION',
     FALSE, NULL, NULL, 'ISO 27001, TIER III', FALSE,
     '2015-04-20', 'ATTIVO'),

    (1, 'Nexia Consulting S.r.l.', '14455667123', 'IT', 'CONSULENZA',
     FALSE, NULL, NULL, NULL, FALSE,
     '2024-02-01', 'ATTIVO');


INSERT INTO Ubicazione
    (organizzazione_id, denominazione, tipo, tipo_gestione, paese, regione_geografica,
     indirizzo, fornitore_terzo_id)
VALUES
    (1, 'Sede legale Roma', 'SEDE_LEGALE', 'PROPRIETARIA', 'IT', 'Lazio',
     'Via del Corso 142, 00186 Roma', NULL),

    (1, 'Datacenter primario Milano', 'DATACENTER', 'PROPRIETARIA', 'IT', 'Lombardia',
     'Via Caldera 21, 20153 Milano', NULL),

    (1, 'Datacenter DR Torino', 'DATACENTER', 'COLOCATION', 'IT', 'Piemonte',
     'Strada del Drosso 33, 10135 Torino', 6),  -- CompuRack

    (1, 'AWS eu-south-1 (Milano)', 'CLOUD_REGION', 'CLOUD_PUBBLICO', 'IT', 'eu-south-1',
     NULL, 1),  -- AWS

    (1, 'Ufficio filiale Napoli', 'UFFICIO', 'AFFITTATA', 'IT', 'Campania',
     'Via Toledo 256, 80132 Napoli', NULL);


INSERT INTO Asset
    (organizzazione_id, ubicazione_id, codice_interno, denominazione, descrizione, tipo,
     classificazione_c, classificazione_i, classificazione_a, stato_ciclo_vita,
     rilevanza_nis2, esposto_internet, contiene_dati_personali,
     data_introduzione, hostname, versione)
VALUES
    (1, 2, 'ACME-DB-CLI',   'Database anagrafica clienti',           'Anagrafica, conti, profilo KYC', 'DATABASE',
     'ALTO', 'ALTO', 'ALTO', 'ATTIVO', TRUE, FALSE, TRUE, '2019-05-10', 'db-cli-prod01.acme.internal', '8.0'),

    (1, 2, 'ACME-DB-MOV',   'Database movimenti e saldi',            'Storico movimenti e saldi conti', 'DATABASE',
     'ALTO', 'ALTO', 'ALTO', 'ATTIVO', TRUE, FALSE, TRUE, '2019-05-10', 'db-mov-prod01.acme.internal', '8.0'),

    (1, 2, 'ACME-APP-CORE', 'Server applicativo core bancario',      'Logica transazionale del core', 'APPLICATIVO',
     'ALTO', 'ALTO', 'ALTO', 'ATTIVO', TRUE, FALSE, TRUE, '2019-07-01', 'core-app01.acme.internal', '3.4.12'),

    (1, 4, 'ACME-WEB-HB',   'Frontend web Home Banking',             'Portale home banking per clienti', 'APPLICATIVO',
     'MEDIO', 'ALTO', 'ALTO', 'ATTIVO', TRUE, TRUE, TRUE, '2020-02-14', 'hb.acme-banking.it', '5.2.0'),

    (1, 4, 'ACME-API-MOB',  'Backend API mobile banking',            'API REST per app iOS/Android', 'APPLICATIVO',
     'MEDIO', 'ALTO', 'ALTO', 'ATTIVO', TRUE, TRUE, TRUE, '2021-10-01', 'api.acme-banking.it', '2.7.3'),

    (1, 2, 'ACME-FW-PERIM', 'Firewall perimetrale primario',         'Filtraggio traffico Internet', 'APPARATO_RETE',
     'BASSO', 'ALTO', 'ALTO', 'ATTIVO', TRUE, FALSE, FALSE, '2018-03-10', 'fw-perim-01.acme.internal', '7.2.5'),

    (1, 2, 'ACME-FW-INT',   'Firewall segmentazione interna',        'Segmentazione rete uffici/produzione', 'APPARATO_RETE',
     'BASSO', 'ALTO', 'ALTO', 'ATTIVO', TRUE, FALSE, FALSE, '2018-03-10', 'fw-int-01.acme.internal', '7.2.5'),

    (1, 4, 'ACME-IDM',      'Identity e SSO',                        'Integrazione IdentityHub SaaS + AD interno', 'APPLICATIVO',
     'ALTO', 'ALTO', 'ALTO', 'ATTIVO', TRUE, TRUE, TRUE, '2023-10-01', NULL, NULL),

    (1, 2, 'ACME-AFD',      'Sistema antifrode',                     'Scoring tempo reale sulle transazioni', 'APPLICATIVO',
     'ALTO', 'ALTO', 'MEDIO', 'ATTIVO', TRUE, FALSE, TRUE, '2022-01-15', 'afd-prod.acme.internal', '1.9.0'),

    (1, 2, 'ACME-GW-SIA',   'Gateway integrazione SIA',              'Connettore pagamenti interbancari', 'APPLICATIVO',
     'ALTO', 'ALTO', 'ALTO', 'ATTIVO', TRUE, FALSE, TRUE, '2018-06-20', 'sia-gw.acme.internal', '4.1.2'),

    (1, 3, 'ACME-STO-BKP',  'Storage backup off-site',               'Repliche DB e snapshot sistemi critici', 'STORAGE',
     'ALTO', 'ALTO', 'BASSO', 'ATTIVO', TRUE, FALSE, TRUE, '2019-01-08', NULL, NULL),

    (1, 4, 'ACME-LB-HB',    'Load balancer Home Banking',            'Bilanciamento traffico HTTPS', 'APPARATO_RETE',
     'BASSO', 'MEDIO', 'ALTO', 'ATTIVO', TRUE, TRUE, FALSE, '2020-02-14', NULL, NULL),

    (1, 2, 'ACME-SIEM',     'SIEM monitoring centralizzato',         'Correlazione log e alert di sicurezza', 'APPLICATIVO',
     'MEDIO', 'ALTO', 'MEDIO', 'ATTIVO', TRUE, FALSE, TRUE, '2022-11-01', 'siem.acme.internal', '10.3'),

    (1, 2, 'ACME-AD',       'Active Directory aziendale',            'Directory dipendenti e servizi', 'APPLICATIVO',
     'ALTO', 'ALTO', 'ALTO', 'ATTIVO', FALSE, FALSE, TRUE, '2014-01-01', 'ad01.acme.internal', '2022'),

    (1, 1, 'ACME-ERP',      'ERP HR/Finanza interno',                'Amministrazione e paghe', 'APPLICATIVO',
     'MEDIO', 'MEDIO', 'MEDIO', 'ATTIVO', FALSE, FALSE, TRUE, '2017-09-01', NULL, NULL),

    (1, 1, 'ACME-TKT',      'Sistema ticketing interno',             'Gestione richieste IT/facility', 'APPLICATIVO',
     'BASSO', 'BASSO', 'MEDIO', 'ATTIVO', FALSE, FALSE, FALSE, '2019-03-01', NULL, NULL),

    (1, 1, 'ACME-DOC',      'Gestione documentale',                  'Archivio documenti operativi', 'APPLICATIVO',
     'MEDIO', 'MEDIO', 'BASSO', 'ATTIVO', FALSE, FALSE, TRUE, '2020-05-20', NULL, NULL),

    (1, 2, 'ACME-DB-IDM',   'Directory utenti IdentityHub locale',   'Cache locale directory federata', 'DATABASE',
     'ALTO', 'ALTO', 'ALTO', 'ATTIVO', TRUE, FALSE, TRUE, '2023-10-01', NULL, NULL),

    (1, 2, 'ACME-VOIP-LEG', 'Centralino VoIP legacy',                'In fase di dismissione, sostituito da cloud', 'APPARATO_RETE',
     'BASSO', 'BASSO', 'BASSO', 'DISMESSO', FALSE, FALSE, FALSE, '2016-01-01', NULL, '2019r3');


INSERT INTO Servizio
    (organizzazione_id, codice_interno, denominazione, descrizione, criticita, ambito_nis2,
     uptime_target, rto_ore, rpo_ore, orario_copertura,
     data_attivazione, stato_erogazione)
VALUES
    (1, 'SRV-HB-WEB',   'Home banking web',
     'Operativita online per clienti retail: saldi, bonifici, pagamenti F24',
     'ALTA', TRUE, 99.900, 2, 1, 'H24', '2020-02-14', 'ATTIVO'),

    (1, 'SRV-HB-MOB',   'Home banking mobile',
     'App iOS e Android con funzioni equivalenti al portale web',
     'ALTA', TRUE, 99.900, 2, 1, 'H24', '2021-10-01', 'ATTIVO'),

    (1, 'SRV-POS',      'Servizio POS merchant',
     'Autorizzazione transazioni POS presso esercenti convenzionati',
     'ALTA', TRUE, 99.950, 1, 1, 'H24', '2016-05-01', 'ATTIVO'),

    (1, 'SRV-PAG-SEPA', 'Pagamenti SEPA e bonifici istantanei',
     'Emissione e ricezione di bonifici area SEPA, istantanei in tempo reale',
     'ALTA', TRUE, 99.500, 4, 2, 'H24', '2018-01-15', 'ATTIVO'),

    (1, 'SRV-CORE',     'Core bancario',
     'Gestione conti, saldi, movimenti: backbone di ogni operazione finanziaria',
     'ALTA', TRUE, 99.950, 4, 1, 'H24', '2019-07-01', 'ATTIVO'),

    (1, 'SRV-IDM',      'Identity provider e SSO',
     'Autenticazione unificata per clienti e dipendenti, MFA obbligatorio',
     'ALTA', TRUE, 99.900, 1, 1, 'H24', '2023-10-01', 'ATTIVO'),

    (1, 'SRV-PORT-DIP', 'Portale dipendenti',
     'Accesso interno a cedolini, ferie, comunicazioni aziendali',
     'BASSA', FALSE, NULL, NULL, NULL, NULL, '2017-09-01', 'ATTIVO'),

    (1, 'SRV-TKT',      'Sistema ticketing interno IT',
     'Gestione richieste di assistenza verso l amministrazione e IT',
     'MEDIA', FALSE, NULL, NULL, NULL, NULL, '2019-03-01', 'ATTIVO');


INSERT INTO Asset_Servizio (asset_id, servizio_id, ruolo, note)
VALUES
    -- Home banking web
    (4, 1, 'PRIMARIO', NULL),
    (1, 1, 'PRIMARIO', NULL),
    (2, 1, 'PRIMARIO', NULL),
    (3, 1, 'PRIMARIO', NULL),
    (8, 1, 'PRIMARIO', NULL),
    (12, 1, 'SUPPORTO', NULL),
    (6, 1, 'SUPPORTO', NULL),
    (9, 1, 'SUPPORTO', 'antifrode realtime'),
    (13, 1, 'SUPPORTO', NULL),

    -- Home banking mobile
    (5, 2, 'PRIMARIO', NULL),
    (1, 2, 'PRIMARIO', NULL),
    (2, 2, 'PRIMARIO', NULL),
    (3, 2, 'PRIMARIO', NULL),
    (8, 2, 'PRIMARIO', NULL),
    (6, 2, 'SUPPORTO', NULL),
    (9, 2, 'SUPPORTO', NULL),

    -- POS merchant
    (3, 3, 'PRIMARIO', NULL),
    (1, 3, 'PRIMARIO', NULL),
    (9, 3, 'SUPPORTO', NULL),

    -- SEPA
    (10, 4, 'PRIMARIO', 'gateway SIA'),
    (3, 4, 'PRIMARIO', NULL),
    (2, 4, 'PRIMARIO', NULL),

    -- Core bancario
    (3, 5, 'PRIMARIO', NULL),
    (1, 5, 'PRIMARIO', NULL),
    (2, 5, 'PRIMARIO', NULL),
    (11, 5, 'SECONDARIO', 'storage backup per DR'),

    -- SSO
    (8, 6, 'PRIMARIO', NULL),
    (18, 6, 'PRIMARIO', 'directory utenti'),
    (14, 6, 'SECONDARIO', 'AD come backup directory'),

    -- Portale dipendenti
    (15, 7, 'PRIMARIO', NULL),
    (14, 7, 'SUPPORTO', NULL),

    -- Ticketing
    (16, 8, 'PRIMARIO', NULL);


INSERT INTO Soggetto
    (organizzazione_id, tipo, denominazione, nome, cognome, email, telefono,
     ruolo_organizzativo, is_punto_contatto_acn, stato)
VALUES
    (1, 'PERSONA', 'Laura Bianchi',     'Laura',    'Bianchi',    'laura.bianchi@acme-banking.it',   '+39 06 4000101',
     'CISO — Chief Information Security Officer', TRUE, 'ATTIVO'),

    (1, 'PERSONA', 'Marco Rossi',       'Marco',    'Rossi',      'marco.rossi@acme-banking.it',     '+39 06 4000102',
     'DPO — Data Protection Officer', FALSE, 'ATTIVO'),

    (1, 'PERSONA', 'Giovanni Ferri',    'Giovanni', 'Ferri',      'giovanni.ferri@acme-banking.it',  '+39 06 4000100',
     'CEO', FALSE, 'ATTIVO'),

    (1, 'PERSONA', 'Elena Mancini',     'Elena',    'Mancini',    'elena.mancini@acme-banking.it',   '+39 02 8000201',
     'DBA Senior', FALSE, 'ATTIVO'),

    (1, 'PERSONA', 'Paolo Conti',       'Paolo',    'Conti',      'paolo.conti@acme-banking.it',     '+39 06 4000105',
     'Responsabile Compliance', FALSE, 'ATTIVO'),

    (1, 'PERSONA', 'Giulia Romano',     'Giulia',   'Romano',     'giulia.romano@acme-banking.it',   '+39 06 4000110',
     'CIO', FALSE, 'ATTIVO'),

    (1, 'RUOLO',   'Team DevOps',       NULL, NULL, 'devops@acme-banking.it', NULL,
     'Team DevOps e Operations', FALSE, 'ATTIVO'),

    (1, 'RUOLO',   'Team SOC esterno',  NULL, NULL, 'soc@secureops.it',       NULL,
     'SOC gestito (SecureOps Italia)', FALSE, 'ATTIVO'),

    (1, 'PERSONA', 'Andrea Martini',    'Andrea',   'Martini',    'andrea.martini@aws.com',          '+39 02 9000301',
     'AWS Enterprise Account Manager', FALSE, 'ATTIVO');


INSERT INTO Dipendenza
    (organizzazione_id, sorgente_tipo, sorgente_asset_id, sorgente_servizio_id,
     destinazione_tipo, destinazione_asset_id, destinazione_servizio_id, destinazione_fornitore_id,
     tipo, criticita, descrizione)
VALUES
    (1, 'SERVIZIO', NULL, 1, 'SERVIZIO', NULL, 5, NULL, 'LOGICA', 'ALTA', 'HB web invoca il core per ogni operazione sul conto'),
    (1, 'SERVIZIO', NULL, 1, 'SERVIZIO', NULL, 6, NULL, 'LOGICA', 'ALTA', 'HB web richiede SSO'),
    (1, 'SERVIZIO', NULL, 2, 'SERVIZIO', NULL, 5, NULL, 'LOGICA', 'ALTA', 'App mobile invoca il core tramite API'),
    (1, 'SERVIZIO', NULL, 2, 'SERVIZIO', NULL, 6, NULL, 'LOGICA', 'ALTA', 'App mobile richiede SSO'),
    (1, 'SERVIZIO', NULL, 5, 'ASSET', 1, NULL, NULL, 'TECNICA', 'ALTA', NULL),
    (1, 'SERVIZIO', NULL, 5, 'ASSET', 2, NULL, NULL, 'TECNICA', 'ALTA', NULL),
    (1, 'ASSET', 4, NULL, 'FORNITORE', NULL, NULL, 1, 'ORGANIZZATIVA', 'ALTA', 'Hosting AWS region eu-south-1'),
    (1, 'ASSET', 5, NULL, 'FORNITORE', NULL, NULL, 1, 'ORGANIZZATIVA', 'ALTA', 'Hosting AWS region eu-south-1'),
    (1, 'ASSET', 8, NULL, 'FORNITORE', NULL, NULL, 4, 'ORGANIZZATIVA', 'ALTA', 'Identity delegato a IdentityHub'),
    (1, 'SERVIZIO', NULL, 4, 'ASSET', 10, NULL, NULL, 'TECNICA', 'ALTA', NULL),
    (1, 'ASSET', 10, NULL, 'FORNITORE', NULL, NULL, 2, 'ORGANIZZATIVA', 'ALTA', 'Gateway SIA per pagamenti interbancari'),
    (1, 'ASSET', 3, NULL, 'FORNITORE', NULL, NULL, 3, 'ORGANIZZATIVA', 'ALTA', 'Manutenzione core bancario'),
    (1, 'ASSET', 11, NULL, 'FORNITORE', NULL, NULL, 6, 'ORGANIZZATIVA', 'MEDIA', 'Colocation DC Torino'),
    (1, 'ASSET', 13, NULL, 'FORNITORE', NULL, NULL, 5, 'ORGANIZZATIVA', 'MEDIA', 'SOC gestito da SecureOps'),
    (1, 'ASSET', 4, NULL, 'ASSET', 12, NULL, NULL, 'RETE', 'MEDIA', 'Frontend passa dal load balancer'),
    (1, 'ASSET', 5, NULL, 'ASSET', 6, NULL, NULL, 'RETE', 'MEDIA', 'API mobile dietro firewall perimetrale');


INSERT INTO Responsabilita
    (organizzazione_id, soggetto_id, target_tipo, target_asset_id, target_servizio_id, target_fornitore_id,
     ruolo_raci, descrizione_ruolo)
VALUES
    (1, 6, 'SERVIZIO', NULL, 1, NULL, 'ACCOUNTABLE', 'CIO'),
    (1, 7, 'SERVIZIO', NULL, 1, NULL, 'RESPONSIBLE', 'Team DevOps'),
    (1, 2, 'SERVIZIO', NULL, 1, NULL, 'CONSULTED',   'DPO'),
    (1, 3, 'SERVIZIO', NULL, 1, NULL, 'INFORMED',    NULL),

    (1, 6, 'SERVIZIO', NULL, 2, NULL, 'ACCOUNTABLE', NULL),
    (1, 7, 'SERVIZIO', NULL, 2, NULL, 'RESPONSIBLE', NULL),
    (1, 2, 'SERVIZIO', NULL, 2, NULL, 'CONSULTED',   NULL),

    (1, 6, 'SERVIZIO', NULL, 3, NULL, 'ACCOUNTABLE', NULL),
    (1, 7, 'SERVIZIO', NULL, 3, NULL, 'RESPONSIBLE', NULL),
    (1, 5, 'SERVIZIO', NULL, 3, NULL, 'CONSULTED',   'Compliance PCI-DSS'),

    (1, 6, 'SERVIZIO', NULL, 4, NULL, 'ACCOUNTABLE', NULL),
    (1, 4, 'SERVIZIO', NULL, 4, NULL, 'RESPONSIBLE', 'DBA senior per DB movimenti'),
    (1, 5, 'SERVIZIO', NULL, 4, NULL, 'CONSULTED',   NULL),

    (1, 6, 'SERVIZIO', NULL, 5, NULL, 'ACCOUNTABLE', NULL),
    (1, 4, 'SERVIZIO', NULL, 5, NULL, 'RESPONSIBLE', NULL),
    (1, 1, 'SERVIZIO', NULL, 5, NULL, 'CONSULTED',   'CISO'),

    (1, 6, 'SERVIZIO', NULL, 6, NULL, 'ACCOUNTABLE', NULL),
    (1, 1, 'SERVIZIO', NULL, 6, NULL, 'RESPONSIBLE', 'CISO — governance identity'),
    (1, 2, 'SERVIZIO', NULL, 6, NULL, 'CONSULTED',   NULL),

    (1, 6, 'ASSET', 1, NULL, NULL, 'ACCOUNTABLE', NULL),
    (1, 4, 'ASSET', 1, NULL, NULL, 'RESPONSIBLE', 'DBA senior'),
    (1, 2, 'ASSET', 1, NULL, NULL, 'CONSULTED',   'DPO'),

    (1, 6, 'ASSET', 2, NULL, NULL, 'ACCOUNTABLE', NULL),
    (1, 4, 'ASSET', 2, NULL, NULL, 'RESPONSIBLE', NULL),

    (1, 9, 'FORNITORE', NULL, NULL, 1, 'RESPONSIBLE', 'Account Manager AWS'),
    (1, 1, 'FORNITORE', NULL, NULL, 1, 'ACCOUNTABLE', 'CISO'),
    (1, 1, 'FORNITORE', NULL, NULL, 5, 'ACCOUNTABLE', 'CISO'),
    (1, 8, 'FORNITORE', NULL, NULL, 5, 'RESPONSIBLE', 'Team SOC esterno');
