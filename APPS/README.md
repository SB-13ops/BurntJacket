# Burnt Jacket V1

Burnt Jacket is an intelligent vinyl-collecting platform that knows what you own, learns how you collect, helps hunt for records worth buying, and connects your collection to live music discovery.

## V1 goal

The first working path is:

1. Create an account
2. Connect Discogs
3. Import collection and wantlist
4. Browse the Burnt Jacket collection repository
5. Generate basic Collector DNA
6. Populate the personalized Home feed
7. Create Hunts and evaluate opportunities
8. Surface nearby Scout recommendations

## Architecture

- **Web:** Next.js + TypeScript
- **API:** FastAPI + Python
- **Database:** PostgreSQL
- **Vector support:** pgvector-ready schema
- **Local development:** Docker Compose
- **Architecture style:** modular monolith

## Quick start

Copy environment variables:

```bash
cp .env.example .env
```

Start PostgreSQL:

```bash
docker compose up -d db
```

Start API:

```bash
cd apps/api
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
alembic upgrade head          # create/upgrade the database schema
uvicorn app.main:app --reload --port 8000
```

The database schema is managed by **Alembic migrations** (in `apps/api/migrations/`).
`alembic upgrade head` creates the required Postgres extensions (`pgvector`,
`pgcrypto`) and all tables. After changing a model, generate a migration with
`alembic revision --autogenerate -m "describe change"`, review it, and commit it.
Migrations read the database URL from the `DATABASE_URL` environment variable,
so the same command works locally and on Railway.

Start web:

```bash
cd apps/web
npm ci          # installs exact versions from the committed lockfile
npm run dev
```

Dependencies are pinned and a `package-lock.json` is committed, so `npm ci`
gives a reproducible install (this is also what the Docker build and Railway
use).

## Deploying

See [docs/DEPLOY_RAILWAY.md](docs/DEPLOY_RAILWAY.md) for the full Railway setup
(Postgres + Redis + API + web). For local parity with that topology, `docker
compose up` runs all four components together.

Then open:

- Web: http://localhost:3000
- API docs: http://localhost:8000/docs

## Repository layout

```text
burntjacket-v1/
├── apps/
│   ├── api/       FastAPI backend
│   └── web/       Next.js frontend
├── infra/
│   └── postgres/  bootstrap SQL
├── docs/          architecture and product specs
├── docker-compose.yml
└── .env.example
```


## Current build status

The repository now contains a functional first-pass Discogs OAuth/import adapter.

See `docs/DISCOGS_INTEGRATION.md` for the exact local flow. You will need your own Discogs developer consumer key and secret before the OAuth connection can be exercised against a real account.


## Latest milestone

The web app now consumes live collection data from the API and includes a deterministic Collector DNA V1. After a Discogs sync, run `POST /api/v1/dna/rebuild`, then open the Collection and DNA screens to see real imported data.


## Real marketplace milestone

Hunter now prefers a connected Discogs account for real release discovery, current marketplace floor pricing, number-for-sale data, pricing suggestions, exact pressing matching, Collection checks and Wantlist checks. A fuzzy metadata release matcher is also included for future non-Discogs listing providers.


## Windows one-click launcher

For Windows local development, the repository now includes:

- `SETUP-BURNTJACKET.bat` — first-time setup
- `START-BURNTJACKET.bat` — starts database, API, web app, and opens the browser
- `STOP-BURNTJACKET.bat` — stops local Burnt Jacket services
- `WINDOWS-QUICK-START.txt` — simple instructions
- `CONFIGURE-KEYS.txt` — Discogs/Ticketmaster/OpenAI configuration notes

The user still needs Python 3.11+, Node.js LTS, and Docker Desktop installed on Windows.


## Consolidated full-stack UI

The approved Burnt Jacket brown/black/cream interface is now wired directly to the FastAPI backend.

Live pages:
- Home → `/api/v1/home/feed`
- Collection → `/api/v1/collection`
- Hunter → `/api/v1/hunter/*`
- Scout → `/api/v1/scout/*`
- Collector DNA → `/api/v1/dna`
- Profile / Discogs → `/api/v1/integrations/discogs/*`

Discogs release image URLs flow through the backend and are rendered directly in Collection, Hunter, and Home.
