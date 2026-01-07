# Insta360 FastAPI Backend

## Setup

```bash
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

## Run

```bash
uvicorn app.main:app --reload
```

## Render deploy

- Use the root `render.yaml`
- Service root directory: `backend`
- Start command: `uvicorn app.main:app --host 0.0.0.0 --port $PORT`

## Endpoints

- `POST /auth/signup`
- `POST /auth/login`
- `POST /auth/forgot`
- `GET /users/me`
- `PATCH /users/me/role`
