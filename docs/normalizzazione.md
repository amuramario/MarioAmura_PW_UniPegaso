# Scelte di normalizzazione

Questo documento spiega come lo schema rispetta i principi della normalizzazione e dove invece se ne discosta in maniera consapevole. 

## Perché 3FN come riferimento

Lo schema è stato pensato per essere in **terza forma normale**. La 3FN è il giusto compromesso fra rigore teorico e usabilità nella realta: garantisce che ogni fatto sia memorizzato una sola volta, evita le anomalie di aggiornamento più comuni e resta sufficientemente flessibile da non costringere a join su cinque tabelle per ricavare un'informazione di base.


## Verifica 3FN


**Organizzazione, FornitoreTerzo, Soggetto, Servizio, Asset.** Tutti gli attributi descrittivi (ragione sociale, denominazione, email, criticita, ecc.) dipendono direttamente dalla PK surrogata `id`. Niente attributi calcolabili da altri attributi della stessa riga e le enum sono valori atomici. 

**Ubicazione.** Stesso discorso dei precedenti, 'unico punto da chiarire è che `regione_geografica` non dipende da `paese`. Sono valori indipendenti scelti dall'utente in fase di inserimento, non derivati in modo da non avere  dipendenze transitive.

**Asset_Servizio.** Chiave primaria `id`, attributo  `ruolo` che dipende dalla coppia (asset_id, servizio_id). Non c'è nessuna informazione duplicata da Asset o da Servizio: il ruolo è proprio del legame, non dell'asset né del servizio presi separatamente.

**Dipendenza, Responsabilita.** I discriminatori (`sorgente_tipo`, `destinazione_tipo`, `target_tipo`) e le FK opzionali sono attributi propri della relazione, non duplicazioni: ogni FK ha la sua semantica (punta a una specifica tabella) e la coerenza con il discriminatore è garantita dai CHECK. La forma "una FK valorizzata, le altre NULL" non introduce dipendenze fra attributi non-chiave, quindi la 3FN resta rispettata.

**audit_log.** Tabella di logging, approfondita successivamente



## La denormalizzazione consapevole: `audit_log` senza FK su `organizzazione_id`

Il campo `organizzazione_id` esiste in `audit_log` come `BIGINT` semplice, **senza vincolo di FK** verso `Organizzazione(id)`.

La scelta è intenzionale e risponde a un requisito di natura normativa, non tecnica. L'audit deve restare leggibile anche se l'organizzazione che ha generato gli eventi viene rimossa dal registro. Una FK con `ON DELETE RESTRICT` impedirebbe la cancellazione dell'organizzazione finché esistono righe di audit che la referenziano (che è la maggior parte dei casi); una `ON DELETE CASCADE` cancellerebbe la storia. Entrambe sono inaccettabili: nel primo caso il registro viene paralizzato, nel secondo viene distrutta la tracciabilità.

In pratica in `audit_log` il campo `organizzazione_id` è solo un'etichetta. Dice a quale organizzazione si riferiva l'evento, ma non obbliga quell'organizzazione a esistere ancora nel registro. Se domani un'organizzazione viene rimossa, l'audit resta leggibile e continua a dirci a chi appartenevano quegli eventi.

## Un limite di MySQL

Lo schema gira su MySQL 8, scelta che porta con sé un piccolo limite che vale la pena dichiarare.

PostgreSQL permette di scrivere indici unici "filtrati", cioè vincoli di unicità che valgono solo per un sottoinsieme di righe. Per esempio "il codice fiscale deve essere univoco solo fra i record correnti" si scrive in una riga.

MySQL non supporta questa sintassi. Per ottenere lo stesso risultato bisogna aggiungere alle tabelle alcune **colonne calcolate** (`cf_current`, `org_current`, `cod_current`, `sede_legale_key`, `pdc_key`, ecc.). Sono colonne che il motore valorizza da solo a partire dal contenuto delle altre colonne della stessa riga, e su quelle si mette il vincolo `UNIQUE`. 

## Trade-off del pattern SCD2

Il registro deve conservare la storia delle modifiche, non solo lo stato attuale: se un asset cambia denominazione, l'inventario di sei mesi fa deve poter essere ricostruito com'era. Il pattern SCD2 risponde a questo bisogno tenendo nella stessa tabella sia le righe storiche sia quella corrente, distinte dai campi `valid_from`, `valid_to` e `is_current`.

Per implementarlo è stata scelta la soluzione più semplice fra quelle disponibili: ogni entità resta in una sola tabella e le FK fra tabelle versionate puntano all'`id` della singola riga, corrente o storica che sia. Le motivazioni sono pratiche:

- **Numero di tabelle contenuto.** Le alternative tipiche del pattern SCD2 raddoppierebbero le entità versionate (da 9 a 18), appesantendo ER e DDL senza un beneficio proporzionato per un registro di questa dimensione.
- **Query più semplici.** Per ottenere "tutti gli asset correnti dell'organizzazione X" basta `WHERE organizzazione_id = X AND is_current = TRUE`. Nessuna JOIN aggiuntiva.
- **Coerenza con MySQL.** Le viste (`v_profilo_*`) e gli indici si scrivono in modo più diretto.

Il prezzo da pagare riguarda le FK fra tabelle versionate. Quando un record cambia versione (per esempio un asset viene aggiornato), la vecchia versione resta nella tabella con `is_current = FALSE` e ne nasce una nuova con un nuovo `id`. Le FK delle altre tabelle che puntavano alla vecchia versione continuano a puntare al vecchio `id`: la FK non si rompe (il record c'è ancora, come riga storica), ma punta a una versione del passato, non a quella attualmente in vigore. Per ricostruire la versione corrente serve un passaggio in più, di solito risalendo dal `codice_interno`, che resta stabile fra le versioni.

In sintesi, il trade-off è fra semplicità dello schema e necessità di un passaggio in più quando serve la versione corrente di un record referenziato. Per un registro di compliance, dove la storia conta più della "freschezza" del singolo legame,  il primo lato pesa di più.




