# Data dictionary
## Convenzioni

**Tipi MySQL** riportati come compaiono nel DDL (`sql/01_schema.sql`). Tutti gli `BIGINT` sono `UNSIGNED`; 

**SCD2** — nove tabelle su dieci sono versionate. I tre campi seguenti compaiono identici ovunque:

| Colonna | Tipo | NN | Default | Descrizione |
|---|---|---|---|---|
| `valid_from` | `TIMESTAMP(6)` | sì | `CURRENT_TIMESTAMP(6)` | Inizio validità della versione |
| `valid_to` | `TIMESTAMP(6)` | no | — | Fine validità (NULL per la versione corrente) |
| `is_current` | `BOOLEAN` | sì | `TRUE` | Flag di riga corrente |

L'unica tabella senza SCD2 è `audit_log`, che usa `ts_evento` (timestamp puntuale dell'evento osservato).

**Multi-tenant** — sette tabelle portano `organizzazione_id BIGINT UNSIGNED NOT NULL` con FK verso `Organizzazione(id)`. Nei dettagli per tabella la colonna è inclusa ma il significato non viene ripetuto.

**Colonne generate STORED** — diverse tabelle contengono colonne `GENERATED ALWAYS AS (...) STORED` usate per emulare gli indici parziali (assenti in MySQL 8). Sono colonne tecniche: non vanno mai inserite a mano, le calcola il motore. Compaiono in tabella con la formula generatrice; il loro ruolo è abilitare un vincolo `UNIQUE` filtrato.

**Naming dei vincoli e degli indici** — prefissi: `chk_` per CHECK, `uk_` per UNIQUE, `idx_` per indici non-unique. Questo aiuta a interpretare i messaggi d'errore di MySQL, che riportano direttamente il nome dell'oggetto violato.

**Charset e collation** — tutte le tabelle usano `utf8mb4` con collation `utf8mb4_0900_ai_ci` (case-insensitive, accent-insensitive). Quando serve un confronto case-sensitive (es. codici paese ISO) il CHECK forza esplicitamente `utf8mb4_bin` nella regex.

**Indice delle tabelle**:

1. [Organizzazione](#organizzazione)
2. [FornitoreTerzo](#fornitoreterzo)
3. [Ubicazione](#ubicazione)
4. [Asset](#asset)
5. [Servizio](#servizio)
6. [Asset_Servizio](#asset_servizio)
7. [Soggetto](#soggetto)
8. [Dipendenza](#dipendenza)
9. [Responsabilita](#responsabilita)
10. [audit_log](#audit_log)

---

## Organizzazione

Soggetto giuridico obbligato agli adempimenti NIS2: quasi tutte le altre tabelle puntano qui tramite `organizzazione_id`.

### Colonne

| Colonna | Tipo | NN | Default | Descrizione |
|---|---|---|---|---|
| `id` | `BIGINT` | sì | auto-increment | Chiave surrogata |
| `ragione_sociale` | `VARCHAR(255)` | sì | — | Denominazione ufficiale del soggetto |
| `codice_fiscale` | `VARCHAR(16)` | sì | — | Codice fiscale o partita IVA usata come CF (11 o 16 caratteri) |
| `partita_iva` | `VARCHAR(11)` | no | — | Partita IVA italiana; opzionale (alcune PA non l'hanno) |
| `pec` | `VARCHAR(255)` | sì | — | Posta certificata, canale formale verso l'ACN |
| `allegato` | `ENUM` | sì | — | Allegato del D.Lgs 138/2024 di appartenenza (vedi dominio) |
| `settore_nis2` | `ENUM` | sì | — | Settore specifico del soggetto (vedi dominio) |
| `categoria_nis2` | `ENUM` | sì | — | `ESSENZIALE` o `IMPORTANTE`: gradua gli obblighi |
| `perimetro_psnc` | `BOOLEAN` | sì | `FALSE` | TRUE se appartiene anche al PSNC (DPCM 131/2020) |
| `data_registrazione_acn` | `DATE` | no | — | Data di iscrizione sul portale ACN |
| `stato_registrazione` | `ENUM` | sì | `'ATTIVA'` | Ciclo di vita della registrazione |
| `valid_from`, `valid_to`, `is_current` | SCD2 | — | — | Vedi sezione Convenzioni |
| `cf_current` | `VARCHAR(16)` | calc. | `IF(is_current, codice_fiscale, NULL)` | Colonna generata STORED — abilita la UNIQUE sul CF dei soli record correnti |

### Domini enumerati

**`allegato`** — riferito agli allegati del D.Lgs 138/2024:

| Valore | Significato |
|---|---|
| `I` | Settori altamente critici |
| `II` | Settori critici |
| `III` | Pubblica amministrazione |
| `IV` | Settori italiani aggiuntivi (estensione nazionale) |

**`settore_nis2`** — 29 valori, raggruppati per allegato di appartenenza (il CHECK `chk_organizzazione_allegato_settore` impone la coerenza):

| Allegato | Settori ammessi |
|---|---|
| I | `ENERGIA_ELETTRICA`, `ENERGIA_GAS`, `ENERGIA_PETROLIO`, `TRASPORTO_AEREO`, `TRASPORTO_FERROVIARIO`, `TRASPORTO_NAVALE`, `TRASPORTO_STRADALE`, `BANCARIO`, `MERCATI_FINANZIARI`, `SANITA`, `ACQUA_POTABILE`, `ACQUE_REFLUE`, `INFRASTRUTTURA_DIGITALE`, `SERVIZI_TIC_B2B`, `SPAZIO` |
| II | `SERVIZI_POSTALI`, `GESTIONE_RIFIUTI`, `CHIMICO`, `ALIMENTARE`, `MANIFATTURIERO`, `SERVIZI_DIGITALI`, `RICERCA` |
| III | `PA_CENTRALE`, `PA_LOCALE` |
| IV | `TRASPORTO_PUBBLICO_LOCALE`, `ISTRUZIONE_RICERCA`, `CULTURALE`, `IN_HOUSE` |
| qualsiasi | `ALTRO` (sempre ammesso) |

**`categoria_nis2`**: `ESSENZIALE` (vincoli più stringenti), `IMPORTANTE` (obblighi base).

**`stato_registrazione`**: `ATTIVA`, `SOSPESA`, `CESSATA`.

### Vincoli

- **PK**: `id`.
- **FK**: nessuna (è la radice).
- **UNIQUE**:
  - `uk_organizzazione_cf_current` su `cf_current` — un solo record corrente per ciascun codice fiscale.
- **CHECK**:
  - `chk_organizzazione_allegato_settore` — coerenza fra `allegato` e `settore_nis2` (mappa nei domini sopra).
  - `chk_organizzazione_scd2` — invariante SCD2: `(is_current=TRUE ∧ valid_to IS NULL)` oppure `(is_current=FALSE ∧ valid_to>valid_from)`.
  - `chk_organizzazione_cf_format` — `CHAR_LENGTH(codice_fiscale) ∈ {11, 16}`.
  - `chk_organizzazione_piva_format` — `partita_iva` NULL oppure di lunghezza esatta 11.

### Indici

| Nome | Colonne | Scopo |
|---|---|---|
| `idx_organizzazione_settore_current` | `(settore_nis2, is_current)` | Filtro per settore sui record correnti |
| `idx_organizzazione_perimetro_current` | `(perimetro_psnc, is_current)` | Selezione dei soggetti PSNC |
| `idx_organizzazione_stato_current` | `(stato_registrazione, is_current)` | Cruscotti sullo stato di registrazione |

### Note operative

- Per chiudere una versione e aprirne una nuova si usa la stored procedure `sp_close_version` (vedi `sql/02_triggers_procedures.sql`).

---

## FornitoreTerzo

Fornitore ICT esterno all'organizzazione: cloud provider, colocation, manutentore HW, software vendor, telco, ecc. Riferito da `Ubicazione`, `Dipendenza` e `Responsabilita`.

### Colonne

| Colonna | Tipo | NN | Default | Descrizione |
|---|---|---|---|---|
| `id` | `BIGINT` | sì | auto-increment | Chiave surrogata |
| `organizzazione_id` | `BIGINT` | sì | — | FK → `Organizzazione(id)` |
| `denominazione` | `VARCHAR(255)` | sì | — | Ragione sociale del fornitore |
| `identificativo_fiscale` | `VARCHAR(50)` | sì | — | CF, P.IVA o equivalente estero |
| `paese_sede` | `CHAR(2)` | sì | — | ISO 3166-1 alpha-2, maiuscolo |
| `categoria` | `ENUM` | sì | — | Tipologia funzionale (vedi dominio) |
| `note` | `TEXT` | no | — | Obbligatoria solo se `categoria='ALTRO'` |
| `rilevanza_nis2` | `BOOLEAN` | sì | `FALSE` | TRUE se rientra nel perimetro NIS2 dell'organizzazione |
| `criterio_rilevanza` | `VARCHAR(255)` | no | — | Motivazione testuale; obbligatorio se `rilevanza_nis2=TRUE` |
| `cpv_principale` | `VARCHAR(10)` | no | — | Codice CPV principale (formato `NNNNNNNN-N`); obbligatorio se rilevante |
| `certificazioni` | `VARCHAR(500)` | no | — | Elenco libero (es. "ISO 27001, ISO 22301") |
| `sede_legale_extra_ue` | `BOOLEAN` | sì | `FALSE` | Per dovuta diligenza sulla filiera di fornitura |
| `data_inizio_rapporto` | `DATE` | no | — | Inizio del rapporto contrattuale |
| `data_fine_rapporto` | `DATE` | no | — | Fine; obbligatoria se `stato_rapporto='CESSATO'` |
| `stato_rapporto` | `ENUM` | sì | `'ATTIVO'` | Stato corrente del rapporto |
| `valid_from`, `valid_to`, `is_current` | SCD2 | — | — | |
| `org_current` | `BIGINT` | calc. | `IF(is_current, organizzazione_id, NULL)` | Colonna generata per UNIQUE filtrata |
| `idfisc_current` | `VARCHAR(50)` | calc. | `IF(is_current, identificativo_fiscale, NULL)` | Colonna generata per UNIQUE filtrata |

### Domini enumerati

**`categoria`** — natura funzionale del fornitore:

| Valore | Significato |
|---|---|
| `CLOUD_PROVIDER` | IaaS / PaaS / SaaS pubblico |
| `COLOCATION` | Hosting di hardware proprietario in datacenter terzo |
| `MANUTENTORE_HW` | Manutenzione e supporto hardware in loco |
| `SOFTWARE_VENDOR` | Fornitore di prodotto software (licenza o SaaS verticale) |
| `TELCO` | Connettività e servizi di rete |
| `SICUREZZA_GESTITA` | MSSP, SOC, threat intelligence |
| `CONSULENZA` | Servizi professionali (compliance, audit, sviluppo) |
| `ALTRO` | Voce generica; richiede `note` valorizzata |

**`stato_rapporto`**: `ATTIVO`, `SOSPESO`, `CESSATO`.

### Vincoli

- **PK**: `id`.
- **FK**: `organizzazione_id` → `Organizzazione(id)` `ON DELETE/UPDATE RESTRICT`.
- **UNIQUE**:
  - `uk_fornitore_idfisc_current` su `(org_current, idfisc_current)` — stesso identificativo fiscale ammesso più volte solo come storico, non come corrente, per la stessa organizzazione.
- **CHECK**:
  - `chk_fornitore_categoria_altro` — `categoria='ALTRO' → note non vuota`.
  - `chk_fornitore_rilevanza` — `rilevanza_nis2=TRUE → criterio_rilevanza non vuoto AND cpv_principale NOT NULL`.
  - `chk_fornitore_cpv_format` — se valorizzato, `cpv_principale` matcha `^[0-9]{8}-[0-9]$`.
  - `chk_fornitore_cessato` — `stato_rapporto='CESSATO' → data_fine_rapporto NOT NULL`.
  - `chk_fornitore_date` — coerenza temporale: `data_fine_rapporto >= data_inizio_rapporto` quando entrambe sono valorizzate.
  - `chk_fornitore_paese_format` — `paese_sede` matcha `^[A-Z]{2}$` valutato in `utf8mb4_bin` (rifiuta minuscole come `it`).
  - `chk_fornitore_scd2` — invariante SCD2.

### Indici

| Nome | Colonne | Scopo |
|---|---|---|
| `idx_fornitore_org_current` | `(organizzazione_id, is_current)` | Ricerca dei fornitori correnti per organizzazione |
| `idx_fornitore_rilevanza_current` | `(rilevanza_nis2, is_current)` | Estrazione fornitori rilevanti per il profilo ACN |
| `idx_fornitore_categoria_current` | `(categoria, is_current)` | Cruscotti per categoria |
| `idx_fornitore_paese_current` | `(paese_sede, is_current)` | Analisi geografica della filiera |

### Note operative

- I codici CPV sono quelli del Vocabolario Comune Appalti UE; il formato controllato è `NNNNNNNN-N` (8 cifre, trattino, cifra di controllo).
- Per disattivare un fornitore senza perdere lo storico, chiudere la riga corrente con `sp_close_version` e inserirne una nuova con `stato_rapporto='CESSATO'` e `data_fine_rapporto` valorizzata.

---

## Ubicazione

Sede legale, ufficio, datacenter, cloud region o colocation. Tabella polimorfica attraverso `tipo`. Riferita da `Asset`.

### Colonne

| Colonna | Tipo | NN | Default | Descrizione |
|---|---|---|---|---|
| `id` | `BIGINT` | sì | auto-increment | Chiave surrogata |
| `organizzazione_id` | `BIGINT` | sì | — | FK → `Organizzazione(id)` |
| `denominazione` | `VARCHAR(255)` | sì | — | Nome leggibile (es. "Sede Roma", "DC Milano Nord", "AWS eu-south-1") |
| `tipo` | `ENUM` | sì | — | Natura dell'ubicazione (vedi dominio) |
| `tipo_gestione` | `ENUM` | sì | — | Chi gestisce l'infrastruttura |
| `paese` | `CHAR(2)` | sì | — | ISO 3166-1 alpha-2, maiuscolo |
| `regione_geografica` | `VARCHAR(100)` | no | — | "Lombardia" per fisiche, "eu-south-1" per cloud |
| `indirizzo` | `VARCHAR(500)` | no | — | Solo per ubicazioni fisiche; obbligatorio se `tipo='SEDE_LEGALE'` |
| `fornitore_terzo_id` | `BIGINT` | no | — | FK → `FornitoreTerzo(id)`; vincolata da `tipo_gestione` |
| `valid_from`, `valid_to`, `is_current` | SCD2 | — | — | |
| `sede_legale_key` | `BIGINT` | calc. | `IF(is_current AND tipo='SEDE_LEGALE', organizzazione_id, NULL)` | Colonna generata per garantire una sola sede legale corrente per organizzazione |

### Domini enumerati

**`tipo`** — cosa è l'ubicazione:

| Valore | Significato |
|---|---|
| `SEDE_LEGALE` | Sede registrata della persona giuridica |
| `UFFICIO` | Sede operativa |
| `DATACENTER` | Centro elaborazione dati (proprio o terzo) |
| `CLOUD_REGION` | Region di un cloud provider |
| `COLOCATION` | Spazio in datacenter terzo dove ospitare HW proprio |
| `ALTRO` | Casi non riconducibili ai precedenti |

**`tipo_gestione`** — chi controlla l'infrastruttura:

| Valore | Significato |
|---|---|
| `PROPRIETARIA` | Gestita direttamente dall'organizzazione |
| `AFFITTATA` | Spazio in locazione, ma gestione tecnica interna |
| `COLOCATION` | Hardware proprio in datacenter terzo |
| `CLOUD_PUBBLICO` | IaaS/PaaS multi-tenant di un provider |
| `CLOUD_PRIVATO` | Cloud dedicato gestito da un fornitore |

### Vincoli

- **PK**: `id`.
- **FK**:
  - `organizzazione_id` → `Organizzazione(id)` `ON DELETE/UPDATE RESTRICT`.
  - `fornitore_terzo_id` → `FornitoreTerzo(id)` `ON DELETE/UPDATE RESTRICT` (nullable).
- **UNIQUE**:
  - `uk_ubicazione_sede_legale` su `sede_legale_key` — impedisce di avere due sedi legali correnti per la stessa organizzazione.
- **CHECK**:
  - `chk_ubicazione_gestione_fornitore` — coerenza: `tipo_gestione ∈ {CLOUD_PUBBLICO, CLOUD_PRIVATO, COLOCATION} ↔ fornitore_terzo_id NOT NULL`; `tipo_gestione ∈ {PROPRIETARIA, AFFITTATA} ↔ fornitore_terzo_id NULL`.
  - `chk_ubicazione_sede_indirizzo` — `tipo='SEDE_LEGALE' → indirizzo non vuoto` (obbligo di registrazione ACN).
  - `chk_ubicazione_paese_format` — `paese` matcha `^[A-Z]{2}$` valutato in `utf8mb4_bin`.
  - `chk_ubicazione_scd2` — invariante SCD2.

### Indici

| Nome | Colonne | Scopo |
|---|---|---|
| `idx_ubicazione_org_current` | `(organizzazione_id, is_current)` | Ubicazioni per organizzazione |
| `idx_ubicazione_tipo_current` | `(tipo, is_current)` | Filtri per natura |
| `idx_ubicazione_fornitore_current` | `(fornitore_terzo_id, is_current)` | Inverso: tutte le ubicazioni gestite da un dato fornitore |
| `idx_ubicazione_paese_current` | `(paese, is_current)` | Analisi geografica |

### Note operative

- Inserire un'ubicazione di tipo `CLOUD_PUBBLICO` senza `fornitore_terzo_id` produce errore di CHECK; e viceversa, una `PROPRIETARIA` con un fornitore valorizzato viene rifiutata. Sono i due casi più frequenti di rifiuto in inserimento.
- Il vincolo "una sola sede legale corrente" è realizzato tramite `sede_legale_key` (colonna generata): tentando di inserire una seconda sede legale corrente per la stessa organizzazione, MySQL risponde con `Duplicate entry ... for key 'uk_ubicazione_sede_legale'`.

---

## Asset

Risorsa ICT — hardware, software, dato o servizio di rete — che l'organizzazione utilizza o possiede. È il fulcro del registro: si collega a `Servizio` attraverso `Asset_Servizio`, a `Dipendenza` (in entrambi i ruoli) e a `Responsabilita`.

### Colonne

| Colonna | Tipo | NN | Default | Descrizione |
|---|---|---|---|---|
| `id` | `BIGINT` | sì | auto-increment | Chiave surrogata |
| `organizzazione_id` | `BIGINT` | sì | — | FK → `Organizzazione(id)` |
| `ubicazione_id` | `BIGINT` | sì | — | FK → `Ubicazione(id)`; dove risiede |
| `codice_interno` | `VARCHAR(100)` | sì | — | Identificativo univoco nell'organizzazione (analogo del CI ID di ITIL) |
| `denominazione` | `VARCHAR(255)` | sì | — | Nome leggibile |
| `descrizione` | `TEXT` | no | — | Libera; obbligatoria se `tipo='ALTRO'` |
| `tipo` | `ENUM` | sì | — | Categoria tecnica (vedi dominio) |
| `classificazione_c` | `ENUM` | sì | — | Confidentiality (BASSO/MEDIO/ALTO) |
| `classificazione_i` | `ENUM` | sì | — | Integrity |
| `classificazione_a` | `ENUM` | sì | — | Availability |
| `stato_ciclo_vita` | `ENUM` | sì | `'ATTIVO'` | Fase nel ciclo di vita |
| `rilevanza_nis2` | `BOOLEAN` | sì | `FALSE` | TRUE se l'asset supporta un servizio NIS2 |
| `esposto_internet` | `BOOLEAN` | sì | `FALSE` | TRUE se ha superficie di attacco pubblica |
| `contiene_dati_personali` | `BOOLEAN` | sì | `FALSE` | TRUE se tratta dati personali ex GDPR |
| `data_introduzione` | `DATE` | no | — | Entrata in produzione |
| `data_dismissione_prevista` | `DATE` | no | — | Pianificazione dismissione |
| `hostname` | `VARCHAR(255)` | no | — | Metadato tecnico opzionale |
| `versione` | `VARCHAR(100)` | no | — | Versione software/firmware |
| `valid_from`, `valid_to`, `is_current` | SCD2 | — | — | |
| `org_current` | `BIGINT` | calc. | `IF(is_current, organizzazione_id, NULL)` | Per UNIQUE filtrata |
| `cod_current` | `VARCHAR(100)` | calc. | `IF(is_current, codice_interno, NULL)` | Per UNIQUE filtrata |

### Domini enumerati

**`tipo`** — natura tecnica dell'asset:

| Valore | Significato |
|---|---|
| `SERVER` | Macchina fisica o virtuale che eroga servizi lato server |
| `APPARATO_RETE` | Switch, router, firewall, load balancer |
| `STORAGE` | NAS, SAN, disco di rete |
| `CLIENT` | Postazione utente (desktop, laptop, mobile) |
| `APPLICATIVO` | Applicazione software (gestionale, web app) |
| `DATABASE` | Istanza DBMS |
| `SISTEMA_OPERATIVO` | OS tracciato come asset a sé (es. per inventario licenze) |
| `SERVIZIO_RETE` | Servizio di rete (DNS, NTP, LDAP) |
| `DATO` | Dataset, archivio, repository informativo |
| `DOCUMENTO` | Documento o documentazione classificata |
| `ALTRO` | Voce generica; richiede `descrizione` valorizzata |

**`classificazione_c` / `classificazione_i` / `classificazione_a`** — scala CIA a tre livelli: `BASSO`, `MEDIO`, `ALTO`. Le tre dimensioni sono indipendenti (un firewall può avere C=BASSO, I=ALTO, A=ALTO).

**`stato_ciclo_vita`**:

| Valore | Significato |
|---|---|
| `PIANIFICATO` | Acquisto deciso, non ancora introdotto |
| `IN_COLLAUDO` | Installato ma non ancora in produzione |
| `ATTIVO` | In produzione |
| `IN_MANUTENZIONE` | Temporaneamente fuori servizio |
| `DISMESSO` | Fuori uso definitivo |

### Vincoli

- **PK**: `id`.
- **FK**:
  - `organizzazione_id` → `Organizzazione(id)` `ON DELETE/UPDATE RESTRICT`.
  - `ubicazione_id` → `Ubicazione(id)` `ON DELETE/UPDATE RESTRICT`.
- **UNIQUE**:
  - `uk_asset_codice_current` su `(org_current, cod_current)` — `codice_interno` univoco fra i record correnti della stessa organizzazione.
- **CHECK**:
  - `chk_asset_tipo_altro` — `tipo='ALTRO' → descrizione non vuota`.
  - `chk_asset_dismesso_rilevanza` — `stato_ciclo_vita='DISMESSO' → rilevanza_nis2=FALSE`. Un asset non operativo esce dal perimetro NIS2.
  - `chk_asset_date` — `data_dismissione_prevista >= data_introduzione` se entrambe valorizzate.
  - `chk_asset_scd2` — invariante SCD2.

### Indici

| Nome | Colonne | Scopo |
|---|---|---|
| `idx_asset_org_current` | `(organizzazione_id, is_current)` | Inventario per organizzazione |
| `idx_asset_ubicazione_current` | `(ubicazione_id, is_current)` | Inverso: asset presenti in una data ubicazione |
| `idx_asset_tipo_current` | `(tipo, is_current)` | Filtri per tipologia |
| `idx_asset_rilevanza_current` | `(rilevanza_nis2, is_current)` | Estrazione asset nel perimetro NIS2 |
| `idx_asset_stato_current` | `(stato_ciclo_vita, is_current)` | Cruscotti operativi |

### Note operative

- I tre flag `rilevanza_nis2`, `esposto_internet`, `contiene_dati_personali` abilitano query trasversali utili in fase di profilazione: la combinazione `esposto_internet=TRUE AND classificazione_a='ALTO'` identifica gli asset critici da monitorare per la disponibilità.
- Per dismettere un asset rilevante NIS2, occorre prima azzerare `rilevanza_nis2` (chiudendo la riga corrente e aprendone una nuova con `rilevanza_nis2=FALSE`), poi cambiare lo stato in `DISMESSO`. L'inverso viene rifiutato dal CHECK `chk_asset_dismesso_rilevanza`.

---

## Servizio

Prestazione che l'organizzazione eroga all'esterno (home banking, distribuzione energia, cartella clinica). Gli SLA sono inline. Riferito da `Asset_Servizio`, `Dipendenza` e `Responsabilita`.

### Colonne

| Colonna | Tipo | NN | Default | Descrizione |
|---|---|---|---|---|
| `id` | `BIGINT` | sì | auto-increment | Chiave surrogata |
| `organizzazione_id` | `BIGINT` | sì | — | FK → `Organizzazione(id)` |
| `codice_interno` | `VARCHAR(100)` | sì | — | Identificativo univoco nell'organizzazione |
| `denominazione` | `VARCHAR(255)` | sì | — | Nome leggibile del servizio |
| `descrizione` | `TEXT` | sì | — | Cosa fa il servizio in linguaggio naturale |
| `criticita` | `ENUM` | sì | — | Impatto sul business in caso di indisponibilità |
| `ambito_nis2` | `BOOLEAN` | sì | `FALSE` | TRUE se rientra nel perimetro NIS2 dichiarato all'ACN |
| `uptime_target` | `DECIMAL(6,3)` | cond. | — | Percentuale di disponibilità target (es. 99.900). NN se `ambito_nis2=TRUE` |
| `rto_ore` | `INT` | cond. | — | Recovery Time Objective in ore. NN se `ambito_nis2=TRUE` |
| `rpo_ore` | `INT` | cond. | — | Recovery Point Objective in ore. NN se `ambito_nis2=TRUE` |
| `orario_copertura` | `ENUM` | cond. | — | Fascia di erogazione. NN se `ambito_nis2=TRUE` |
| `data_attivazione` | `DATE` | no | — | Messa in produzione |
| `data_dismissione` | `DATE` | no | — | Pianificazione dismissione |
| `stato_erogazione` | `ENUM` | sì | `'ATTIVO'` | Stato operativo corrente |
| `valid_from`, `valid_to`, `is_current` | SCD2 | — | — | |
| `org_current` | `BIGINT` | calc. | `IF(is_current, organizzazione_id, NULL)` | Per UNIQUE filtrata |
| `cod_current` | `VARCHAR(100)` | calc. | `IF(is_current, codice_interno, NULL)` | Per UNIQUE filtrata |

### Domini enumerati

**`criticita`**: `BASSA`, `MEDIA`, `ALTA`. Per servizi NIS2 ammessi solo `MEDIA` e `ALTA`.

**`orario_copertura`**:

| Valore | Significato |
|---|---|
| `H24` | 24 ore su 24, 7 giorni su 7 |
| `H12_LAV` | 12 ore nei giorni lavorativi |
| `H8_LAV` | 8 ore nei giorni lavorativi |
| `ALTRO` | Fasce particolari (specificare in `descrizione`) |

**`stato_erogazione`**:

| Valore | Significato |
|---|---|
| `PIANIFICATO` | Definito, non ancora attivo |
| `ATTIVO` | In erogazione |
| `SOSPESO` | Temporaneamente fermo |
| `DISMESSO` | Cessato |

### Vincoli

- **PK**: `id`.
- **FK**: `organizzazione_id` → `Organizzazione(id)` `ON DELETE/UPDATE RESTRICT`.
- **UNIQUE**:
  - `uk_servizio_codice_current` su `(org_current, cod_current)` — `codice_interno` univoco fra i record correnti per organizzazione.
- **CHECK**:
  - `chk_servizio_nis2_criticita` — `ambito_nis2=TRUE → criticita ∈ {MEDIA, ALTA}`.
  - `chk_servizio_nis2_sla` — `ambito_nis2=TRUE → uptime_target, rto_ore, rpo_ore, orario_copertura tutti NOT NULL`. Traduzione del requisito IS-3 della FNCDP direttamente in vincolo di schema.
  - `chk_servizio_dismesso` — `stato_erogazione='DISMESSO' → ambito_nis2=FALSE`. Un servizio cessato esce dal perimetro.
  - `chk_servizio_uptime_range` — `0 ≤ uptime_target ≤ 100`.
  - `chk_servizio_date` — `data_dismissione >= data_attivazione` se entrambe valorizzate.
  - `chk_servizio_scd2` — invariante SCD2.

### Indici

| Nome | Colonne | Scopo |
|---|---|---|
| `idx_servizio_org_current` | `(organizzazione_id, is_current)` | Catalogo per organizzazione |
| `idx_servizio_criticita_current` | `(criticita, is_current)` | Filtri per livello di impatto |
| `idx_servizio_ambito_current` | `(ambito_nis2, is_current)` | Selezione perimetro NIS2 |
| `idx_servizio_stato_current` | `(stato_erogazione, is_current)` | Cruscotti operativi |

### Note operative

- Per dichiarare un servizio NIS2 occorre compilare insieme i quattro campi SLA (`uptime_target`, `rto_ore`, `rpo_ore`, `orario_copertura`): l'inserimento parziale è rifiutato dal CHECK. Tipico errore in seed o import: ricordarsi di valorizzarli tutti contestualmente.
- `uptime_target` accetta tre decimali: `99.999` per la massima disponibilità, `99.900` per uno SLA standard di servizio.

---

## Asset_Servizio

Reifica la relazione N:M fra `Asset` e `Servizio` qualificandola con un ruolo. Non ha `organizzazione_id`: il vincolo cross-tenant `Asset.organizzazione_id = Servizio.organizzazione_id` è applicato dal trigger `trg_asservizio_tenant`.

### Colonne

| Colonna | Tipo | NN | Default | Descrizione |
|---|---|---|---|---|
| `id` | `BIGINT` | sì | auto-increment | Chiave surrogata |
| `asset_id` | `BIGINT` | sì | — | FK → `Asset(id)` |
| `servizio_id` | `BIGINT` | sì | — | FK → `Servizio(id)` |
| `ruolo` | `ENUM` | sì | — | Contributo dell'asset al servizio (vedi dominio) |
| `note` | `TEXT` | no | — | Obbligatoria se `ruolo='ALTRO'` |
| `valid_from`, `valid_to`, `is_current` | SCD2 | — | — | |
| `asset_current` | `BIGINT` | calc. | `IF(is_current, asset_id, NULL)` | Per UNIQUE filtrata |
| `servizio_current` | `BIGINT` | calc. | `IF(is_current, servizio_id, NULL)` | Per UNIQUE filtrata |

### Domini enumerati

**`ruolo`** — contributo dell'asset al servizio:

| Valore | Significato |
|---|---|
| `PRIMARIO` | Indispensabile: se cade, il servizio non funziona |
| `SECONDARIO` | Ridondanza attiva o backup; subentra in caso di guasto del primario |
| `SUPPORTO` | Ausiliario (firewall, monitoring, antifrode); il servizio funziona anche senza, ma in modo degradato |
| `ALTRO` | Casi particolari; richiede `note` valorizzata |

### Vincoli

- **PK**: `id`.
- **FK**:
  - `asset_id` → `Asset(id)` `ON DELETE/UPDATE RESTRICT`.
  - `servizio_id` → `Servizio(id)` `ON DELETE/UPDATE RESTRICT`.
- **UNIQUE**:
  - `uk_asset_servizio_current` su `(asset_current, servizio_current)` — un asset può avere un solo ruolo attivo per ciascun servizio. Cambiando ruolo si chiude la riga corrente e se ne apre una nuova.
- **CHECK**:
  - `chk_asservizio_ruolo_altro` — `ruolo='ALTRO' → note non vuota`.
  - `chk_asservizio_scd2` — invariante SCD2.
- **Trigger** (definito in `02_triggers_procedures.sql`): `trg_asservizio_tenant` su INSERT/UPDATE rifiuta righe con asset e servizio appartenenti a organizzazioni diverse. È il vincolo cross-tabella che CHECK puro non può esprimere in MySQL (non ammette sottoquery).

### Indici

| Nome | Colonne | Scopo |
|---|---|---|
| `idx_asservizio_asset_current` | `(asset_id, is_current)` | A quali servizi è collegato un dato asset |
| `idx_asservizio_servizio_current` | `(servizio_id, is_current)` | Quali asset supportano un dato servizio |
| `idx_asservizio_ruolo_current` | `(ruolo, is_current)` | Filtri per ruolo (es. tutti i PRIMARIO) |

---

## Soggetto

Persona fisica o ruolo organizzativo astratto. Anagrafica delle persone del registro, riferita dalla matrice RACI in `Responsabilita`.

### Colonne

| Colonna | Tipo | NN | Default | Descrizione |
|---|---|---|---|---|
| `id` | `BIGINT` | sì | auto-increment | Chiave surrogata |
| `organizzazione_id` | `BIGINT` | sì | — | FK → `Organizzazione(id)` |
| `tipo` | `ENUM` | sì | — | `PERSONA` o `RUOLO` |
| `denominazione` | `VARCHAR(255)` | sì | — | Etichetta usata nei report (es. "Mario Rossi" o "DPO") |
| `nome` | `VARCHAR(100)` | cond. | — | NN se `tipo='PERSONA'`, NULL se `tipo='RUOLO'` |
| `cognome` | `VARCHAR(100)` | cond. | — | Stesso vincolo di `nome` |
| `email` | `VARCHAR(255)` | no | — | Obbligatoria se `is_punto_contatto_acn=TRUE` |
| `telefono` | `VARCHAR(50)` | no | — | Recapito telefonico opzionale |
| `ruolo_organizzativo` | `VARCHAR(255)` | no | — | Carica/posizione (es. "CISO", "Responsabile Sistemi") |
| `is_punto_contatto_acn` | `BOOLEAN` | sì | `FALSE` | Marca il punto di contatto formale verso l'ACN |
| `stato` | `ENUM` | sì | `'ATTIVO'` | Stato operativo del soggetto |
| `valid_from`, `valid_to`, `is_current` | SCD2 | — | — | |
| `pdc_key` | `BIGINT` | calc. | `IF(is_punto_contatto_acn AND is_current, organizzazione_id, NULL)` | Per garantire un solo PdC corrente per organizzazione |

### Domini enumerati

**`tipo`**:

| Valore | Significato |
|---|---|
| `PERSONA` | Persona fisica identificata (richiede nome e cognome) |
| `RUOLO` | Funzione astratta (es. "DPO", "Comitato Sicurezza") |

**`stato`**: `ATTIVO`, `INATTIVO`. Un soggetto INATTIVO non può essere punto di contatto ACN.

### Vincoli

- **PK**: `id`.
- **FK**: `organizzazione_id` → `Organizzazione(id)` `ON DELETE/UPDATE RESTRICT`.
- **UNIQUE**:
  - `uk_soggetto_punto_contatto` su `pdc_key` — al massimo un soggetto con `is_punto_contatto_acn=TRUE` corrente per organizzazione.
- **CHECK**:
  - `chk_soggetto_persona_nome` — `tipo='PERSONA' → nome AND cognome NOT NULL`; `tipo='RUOLO' → nome AND cognome NULL`.
  - `chk_soggetto_punto_contatto` — `is_punto_contatto_acn=TRUE → tipo='PERSONA' AND email non vuota`. Un ruolo astratto non può fare da PdC.
  - `chk_soggetto_inattivo` — `stato='INATTIVO' → is_punto_contatto_acn=FALSE`.
  - `chk_soggetto_scd2` — invariante SCD2.

### Indici

| Nome | Colonne | Scopo |
|---|---|---|
| `idx_soggetto_org_current` | `(organizzazione_id, is_current)` | Soggetti per organizzazione |
| `idx_soggetto_tipo_current` | `(tipo, is_current)` | Separazione PERSONA/RUOLO |
| `idx_soggetto_stato_current` | `(stato, is_current)` | Filtri attivi/inattivi |

### Note operative

- Per cambiare il punto di contatto ACN occorre prima togliere il flag al soggetto uscente (chiusura SCD2 + nuova versione con `is_punto_contatto_acn=FALSE`) e poi attivarlo sul nuovo. L'inserimento del nuovo PdC senza chiusura del precedente viene rifiutato dalla UNIQUE su `pdc_key`.

---

## Dipendenza

Relazione direzionale "X dipende da Y" fra elementi del registro. Doppiamente polimorfica: la sorgente può essere `Asset` o `Servizio`, la destinazione può essere `Asset`, `Servizio` o `FornitoreTerzo`.

### Colonne

| Colonna | Tipo | NN | Default | Descrizione |
|---|---|---|---|---|
| `id` | `BIGINT` | sì | auto-increment | Chiave surrogata |
| `organizzazione_id` | `BIGINT` | sì | — | FK → `Organizzazione(id)` |
| `sorgente_tipo` | `ENUM` | sì | — | Discriminatore sorgente (`ASSET` o `SERVIZIO`) |
| `sorgente_asset_id` | `BIGINT` | no | — | FK → `Asset(id)`; valorizzato se `sorgente_tipo='ASSET'` |
| `sorgente_servizio_id` | `BIGINT` | no | — | FK → `Servizio(id)`; valorizzato se `sorgente_tipo='SERVIZIO'` |
| `destinazione_tipo` | `ENUM` | sì | — | Discriminatore destinazione (`ASSET`, `SERVIZIO`, `FORNITORE`) |
| `destinazione_asset_id` | `BIGINT` | no | — | FK → `Asset(id)`; valorizzato se destinazione=`ASSET` |
| `destinazione_servizio_id` | `BIGINT` | no | — | FK → `Servizio(id)`; valorizzato se destinazione=`SERVIZIO` |
| `destinazione_fornitore_id` | `BIGINT` | no | — | FK → `FornitoreTerzo(id)`; valorizzato se destinazione=`FORNITORE` |
| `tipo` | `ENUM` | sì | — | Natura della dipendenza (vedi dominio) |
| `criticita` | `ENUM` | sì | — | Impatto del legame (`BASSA`/`MEDIA`/`ALTA`) |
| `descrizione` | `TEXT` | no | — | Annotazione libera |
| `valid_from`, `valid_to`, `is_current` | SCD2 | — | — | |
| `dip_key` | `VARCHAR(100)` | calc. | concat di sorgente, destinazione e tipo se `is_current` | Chiave di unicità sui correnti |

### Domini enumerati

**`sorgente_tipo`**: `ASSET`, `SERVIZIO`.

**`destinazione_tipo`**: `ASSET`, `SERVIZIO`, `FORNITORE`.

**`tipo`** — natura del legame:

| Valore | Significato |
|---|---|
| `RETE` | Connettività di rete (un servizio dipende da un firewall, da un router) |
| `TECNICA` | Dipendenza tecnologica (un applicativo dipende da un DBMS) |
| `LOGICA` | Dipendenza funzionale di alto livello (un servizio dipende da un altro servizio) |
| `ORGANIZZATIVA` | Rapporto contrattuale verso un terzo; ammesso solo verso `FORNITORE` |

**`criticita`**: `BASSA`, `MEDIA`, `ALTA`. Indica quanto pesa la dipendenza sull'erogazione.

### Vincoli

- **PK**: `id`.
- **FK** (tutte `ON DELETE/UPDATE RESTRICT`):
  - `organizzazione_id` → `Organizzazione(id)`.
  - `sorgente_asset_id` → `Asset(id)`.
  - `sorgente_servizio_id` → `Servizio(id)`.
  - `destinazione_asset_id` → `Asset(id)`.
  - `destinazione_servizio_id` → `Servizio(id)`.
  - `destinazione_fornitore_id` → `FornitoreTerzo(id)`.
- **UNIQUE**:
  - `uk_dipendenza_current` su `dip_key` — non possono esistere due dipendenze identiche correnti (stessa sorgente, stessa destinazione, stesso tipo).
- **CHECK**:
  - `chk_dip_sorgente` — esattamente una FK sorgente valorizzata, coerente con `sorgente_tipo`.
  - `chk_dip_destinazione` — esattamente una FK destinazione valorizzata, coerente con `destinazione_tipo`.
  - `chk_dip_no_self` — un elemento non dipende da se stesso (sorgente e destinazione non possono coincidere).
  - `chk_dip_organizzativa_fornitore` — `tipo='ORGANIZZATIVA' → destinazione_tipo='FORNITORE'`.
  - `chk_dip_scd2` — invariante SCD2.

### Indici

| Nome | Colonne | Scopo |
|---|---|---|
| `idx_dip_org_current` | `(organizzazione_id, is_current)` | Dipendenze per organizzazione |
| `idx_dip_tipo_current` | `(tipo, is_current)` | Filtri per tipologia di dipendenza |

### Note operative

- L'inserimento corretto richiede di valorizzare il discriminatore `sorgente_tipo`/`destinazione_tipo` insieme alla sola FK corrispondente; le altre FK del lato vanno lasciate `NULL`. Tipico errore: valorizzare due FK destinazione contemporaneamente, che il CHECK rifiuta.
- La `dip_key` viene calcolata da MySQL come stringa concatenata; in caso di violazione il messaggio è `Duplicate entry 'ASSET-1-FORNITORE-3-RETE' for key 'uk_dipendenza_current'`, dove i numeri sono gli ID coinvolti.
- Le dipendenze di tipo `ORGANIZZATIVA` rappresentano i rapporti contrattuali verso terzi (es. "il servizio Y dipende contrattualmente dal fornitore Z"). La regola `chk_dip_organizzativa_fornitore` impedisce di marcare come ORGANIZZATIVA una dipendenza interna.

---

## Responsabilita

Matrice RACI: collega un `Soggetto` a un target polimorfico (`Asset` / `Servizio` / `FornitoreTerzo`) qualificando il ruolo. Una sola riga può essere `ACCOUNTABLE` per ciascun target, vincolo garantito a livello di schema.

### Colonne

| Colonna | Tipo | NN | Default | Descrizione |
|---|---|---|---|---|
| `id` | `BIGINT` | sì | auto-increment | Chiave surrogata |
| `organizzazione_id` | `BIGINT` | sì | — | FK → `Organizzazione(id)` |
| `soggetto_id` | `BIGINT` | sì | — | FK → `Soggetto(id)` |
| `target_tipo` | `ENUM` | sì | — | Discriminatore target (`ASSET`, `SERVIZIO`, `FORNITORE`) |
| `target_asset_id` | `BIGINT` | no | — | FK → `Asset(id)`; valorizzato se target=`ASSET` |
| `target_servizio_id` | `BIGINT` | no | — | FK → `Servizio(id)`; valorizzato se target=`SERVIZIO` |
| `target_fornitore_id` | `BIGINT` | no | — | FK → `FornitoreTerzo(id)`; valorizzato se target=`FORNITORE` |
| `ruolo_raci` | `ENUM` | sì | — | Ruolo nella matrice RACI |
| `descrizione_ruolo` | `VARCHAR(255)` | no | — | Annotazione libera (es. "Operatore di backup") |
| `valid_from`, `valid_to`, `is_current` | SCD2 | — | — | |
| `resp_key` | `VARCHAR(100)` | calc. | concat di soggetto, target, ruolo se `is_current` | Per UNIQUE su (soggetto, target, ruolo) corrente |
| `accountable_key` | `VARCHAR(50)` | calc. | concat di target se `ruolo_raci='ACCOUNTABLE' AND is_current` | Per UNIQUE su singolo Accountable per target |

### Domini enumerati

**`target_tipo`**: `ASSET`, `SERVIZIO`, `FORNITORE`.

**`ruolo_raci`** — ruoli della matrice RACI:

| Valore | Significato |
|---|---|
| `RESPONSIBLE` | Esegue il lavoro operativo |
| `ACCOUNTABLE` | Risponde dell'esito; uno solo per target (regola dell'unico responsabile finale) |
| `CONSULTED` | Viene consultato prima della decisione |
| `INFORMED` | Viene informato dopo l'azione |

### Vincoli

- **PK**: `id`.
- **FK** (tutte `ON DELETE/UPDATE RESTRICT`):
  - `organizzazione_id` → `Organizzazione(id)`.
  - `soggetto_id` → `Soggetto(id)`.
  - `target_asset_id` → `Asset(id)`.
  - `target_servizio_id` → `Servizio(id)`.
  - `target_fornitore_id` → `FornitoreTerzo(id)`.
- **UNIQUE**:
  - `uk_resp_current` su `resp_key` — la stessa terna (soggetto, target, ruolo) non può esistere due volte come corrente.
  - `uk_resp_accountable` su `accountable_key` — per ogni target esiste al massimo un `ACCOUNTABLE` corrente. È la traduzione a livello di schema della regola dell'unico responsabile finale del modello RACI.
- **CHECK**:
  - `chk_resp_target` — esattamente una FK target valorizzata, coerente con `target_tipo`.
  - `chk_resp_scd2` — invariante SCD2.

### Indici

| Nome | Colonne | Scopo |
|---|---|---|
| `idx_resp_org_current` | `(organizzazione_id, is_current)` | Matrice RACI per organizzazione |
| `idx_resp_soggetto_current` | `(soggetto_id, is_current)` | "Di cosa è responsabile il soggetto X?" |
| `idx_resp_ruolo_current` | `(ruolo_raci, is_current)` | Filtri per ruolo (es. tutti gli `ACCOUNTABLE`) |

### Note operative

- Per spostare l'Accountable da un soggetto a un altro su uno stesso target, occorre chiudere prima la riga corrente del vecchio Accountable (SCD2) e poi inserire la nuova. L'inserimento contestuale di due Accountable correnti per lo stesso target viene rifiutato da `uk_resp_accountable`.
- Lo stesso soggetto può comparire più volte sullo stesso target con ruoli diversi (es. `RESPONSIBLE` su un asset e `INFORMED` su un altro), ma non con lo stesso ruolo: lo impedisce `uk_resp_current`.

---

## audit_log

Log immutabile delle modifiche su tutte le tabelle versionate. Popolato dai 27 trigger di audit definiti in `sql/02_triggers_procedures.sql`. Non SCD2: ogni riga è un evento puntuale.

### Colonne

| Colonna | Tipo | NN | Default | Descrizione |
|---|---|---|---|---|
| `id` | `BIGINT` | sì | auto-increment | Chiave surrogata |
| `tabella` | `VARCHAR(100)` | sì | — | Nome della tabella su cui è avvenuta la modifica |
| `record_id` | `BIGINT` | sì | — | Valore di `id` del record toccato |
| `operazione` | `ENUM` | sì | — | `INSERT`, `UPDATE`, `DELETE` |
| `ts_evento` | `TIMESTAMP(6)` | sì | `CURRENT_TIMESTAMP(6)` | Quando è avvenuto l'evento (microsecondi) |
| `utente_db` | `VARCHAR(255)` | sì | — | Utente MySQL che ha eseguito l'operazione (`CURRENT_USER()`) |
| `organizzazione_id` | `BIGINT` | no | — | Organizzazione di appartenenza del record (denormalizzato, **senza FK**) |
| `payload_precedente` | `JSON` | no | — | Snapshot del record prima della modifica (NULL su INSERT) |
| `payload_nuovo` | `JSON` | no | — | Snapshot del record dopo la modifica (NULL su DELETE) |

### Domini enumerati

**`operazione`**: `INSERT`, `UPDATE`, `DELETE`.

### Vincoli

- **PK**: `id`.
- **FK**: nessuna. La mancanza di FK su `organizzazione_id` è una scelta di design: l'audit deve sopravvivere alla rimozione dell'organizzazione.
- **UNIQUE**: nessuna.
- **CHECK**:
  - `chk_audit_payload_insert` — `operazione='INSERT' → payload_precedente IS NULL AND payload_nuovo NOT NULL`.
  - `chk_audit_payload_update` — `operazione='UPDATE' → payload_precedente IS NOT NULL AND payload_nuovo IS NOT NULL`.
  - `chk_audit_payload_delete` — `operazione='DELETE' → payload_precedente IS NOT NULL AND payload_nuovo IS NULL`.

### Indici

| Nome | Colonne | Scopo |
|---|---|---|
| `idx_audit_tabella_record` | `(tabella, record_id)` | Ricostruire la storia di un singolo record |
| `idx_audit_org_ts` | `(organizzazione_id, ts_evento)` | Cronologia degli eventi per organizzazione |
| `idx_audit_ts` | `ts_evento` | Estrazioni temporali globali |

### Note operative

- L'audit è solo in scrittura: i trigger inseriscono, nessuno aggiorna o elimina. Eventuali tentativi manuali di `UPDATE` o `DELETE` su `audit_log` non sono bloccati dallo schema; la protezione si applica a livello di permessi, perché l'utente `nis2_user` definito in `docker-compose.yml` non ha il privilegio per modificare o eliminare righe di audit.
- I payload JSON contengono lo snapshot completo della riga, comprese le colonne generate STORED. Per estrarre un campo specifico si usa `JSON_EXTRACT(payload_nuovo, '$.codice_interno')` o l'operatore breve `->>` introdotto in MySQL 5.7.
