from fastapi import Depends, FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware

from . import auth, crud, schemas
from .core.db import client, get_db

app = FastAPI(title="Insta360 Backend", version="1.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.on_event("shutdown")
def on_shutdown():
    client.close()


@app.post("/auth/signup", response_model=schemas.AuthResponse)
def signup(payload: schemas.SignupRequest, db=Depends(get_db)):
    existing = crud.get_user_by_email(db, payload.email)
    if existing:
        raise HTTPException(status_code=400, detail="Email already registered")
    role = payload.role if payload.role in {"worker", "admin"} else "worker"
    user = crud.create_user(db, payload.email, payload.full_name, payload.password, role)
    token = auth.create_access_token(user["email"])
    return schemas.AuthResponse(token=token, user=crud.to_public_user(user))


@app.post("/auth/login", response_model=schemas.AuthResponse)
def login(payload: schemas.LoginRequest, db=Depends(get_db)):
    user = crud.get_user_by_email(db, payload.email)
    if not user or not auth.verify_password(payload.password, user["password_hash"]):
        raise HTTPException(status_code=401, detail="Invalid credentials")
    token = auth.create_access_token(user["email"])
    return schemas.AuthResponse(token=token, user=crud.to_public_user(user))
