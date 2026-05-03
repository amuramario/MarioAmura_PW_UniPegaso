# Deploy

Istruzioni per il database in locale e caricare lo schema, i trigger, le viste e il seed di prova. La strada consigliata è quella con Docker ma in fondo c'è una nota per installare MySQL direttamente sulla macchina.

## Prerequisiti

Serve solo **Docker Desktop**.  Bisogna installarlo e avviarlo.

Per chi non vuole Docker: serve **MySQL 8.0** già installato e funzionante (vedi sezione finale).

## Avvio del container

Dal terminale, posizionarsi nella cartella del repo e lanciare:

```bash
docker compose up -d
```

 Docker scarica l'immagine MySQL 8 (solo la prima volta), crea il container `pw-nis2-mysql`, crea il database `nis2_acn_registry` e configura due utenti. Per verificare che il container sia su e funzionante:

```bash
docker compose ps
```

Si dovrebbe vedere `pw-nis2-mysql` con stato `running`.

## Caricamento degli script

Gli script SQL stanno nella cartella `sql/` e vanno eseguiti **in questo ordine**:

```bash
docker exec -i pw-nis2-mysql mysql -u nis2_user -pnis2pass nis2_acn_registry < sql/01_schema.sql
docker exec -i pw-nis2-mysql mysql -u nis2_user -pnis2pass nis2_acn_registry < sql/02_triggers_procedures.sql
docker exec -i pw-nis2-mysql mysql -u nis2_user -pnis2pass nis2_acn_registry < sql/03_views.sql
docker exec -i pw-nis2-mysql mysql -u nis2_user -pnis2pass nis2_acn_registry < sql/04_seed.sql
```

Cosa fa ciascuno:

| Script | Cosa fa |
|---|---|
| `01_schema.sql` | Crea le 10 tabelle, vincoli, CHECK e indici |
| `02_triggers_procedures.sql` | Crea i 35 trigger (8 multi-tenant + 27 audit) e la stored procedure `sp_close_version` |
| `03_views.sql` | Crea le 5 viste per l'export CSV del profilo ACN |
| `04_seed.sql` | Popola il dataset di prova `Acme Banking S.p.A.` |
| `05_queries.sql` | Le query operative  |

L'ordine non è opzionale e va rispettato: i trigger referenziano tabelle dello schema, le viste si appoggiano alle tabelle e ai trigger, e il seed presuppone che lo schema sia già completo.

## Verifica del setup

Nel repo ci sono due script di test da lanciare appena finito il caricamento e  servono a confermare che vincoli e versionamento funzionino:

```bash
docker exec -i pw-nis2-mysql mysql -u nis2_user -pnis2pass nis2_acn_registry < test/test_integrita.sql
docker exec -i pw-nis2-mysql mysql -u nis2_user -pnis2pass nis2_acn_registry < test/test_scd2.sql
```

`test_integrita.sql` prova a inserire 43 violazioni dei vincoli (CHECK, FK, UNIQUE) e si aspetta che il DB le rifiuti tutte. Se si vedono tutte righe `OK`, lo schema sta facendo in maniera corretta il suo lavoro.

`test_scd2.sql` simula un cambio di versione di un record e verifica che lo storico venga conservato correttamente. Anche qui bisogna aspettarsi `OK` su tutte le righe.

## Connessione al DB

Per collegarsi con un client  questi sono i  parametri:

| Parametro | Valore |
|---|---|
| Host | `127.0.0.1` |
| Porta | `3306` |
| Database | `nis2_acn_registry` |
| Utente applicativo | `nis2_user` |
| Password applicativa | `nis2pass` |
| Utente root (solo amministrazione) | `root` |
| Password root | `rootpass` |

Le credenziali sono quelle definite in `docker-compose.yml`. 

Se si preferisce la riga di comando direttamente nel container:

```bash
docker exec -it pw-nis2-mysql mysql -u nis2_user -pnis2pass nis2_acn_registry
```

Da qui è possibile  lanciare  qualsiasi query, oppure caricare `sql/05_queries.sql` per vericicare le 5 richieste della traccia.


## Setup alternativo: MySQL nativo

Per chi non vuole installare Docker, ecco i passaggi equivalenti su un MySQL 8.0 già installato.

Da utente root del DB:

```sql
CREATE DATABASE nis2_acn_registry
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_0900_ai_ci;

CREATE USER 'nis2_user'@'localhost' IDENTIFIED BY 'nis2pass';
GRANT ALL PRIVILEGES ON nis2_acn_registry.* TO 'nis2_user'@'localhost';
FLUSH PRIVILEGES;
```

Poi, dalla shell del sistema operativo, gli script SQL si caricano con:

```bash
mysql -h 127.0.0.1 -u nis2_user -p nis2_acn_registry < sql/01_schema.sql
mysql -h 127.0.0.1 -u nis2_user -p nis2_acn_registry < sql/02_triggers_procedures.sql
mysql -h 127.0.0.1 -u nis2_user -p nis2_acn_registry < sql/03_views.sql
mysql -h 127.0.0.1 -u nis2_user -p nis2_acn_registry < sql/04_seed.sql
```

E gli stessi due test di verifica:

```bash
mysql -h 127.0.0.1 -u nis2_user -p nis2_acn_registry < test/test_integrita.sql
mysql -h 127.0.0.1 -u nis2_user -p nis2_acn_registry < test/test_scd2.sql
```


