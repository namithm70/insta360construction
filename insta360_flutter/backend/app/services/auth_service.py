from fastapi import HTTPException
from .. import crud, schemas
from ..auth import create_access_token, verify_password


def signup(payload: schemas.SignupRequest, db) -> schemas.AuthResponse:
    existing = crud.get_user_by_email(db, payload.email)
    if existing:
        raise HTTPException(status_code=400, detail="Email already registered")
    role = payload.role if payload.role in {"worker", "admin"} else "worker"
    user = crud.create_user(db, payload.email, payload.full_name, payload.password, role)
    token = create_access_token(user["email"])
    return schemas.AuthResponse(token=token, user=crud.to_public_user(user))


def login(payload: schemas.LoginRequest, db) -> schemas.AuthResponse:
    user = crud.get_user_by_email(db, payload.email)
    if not user or not verify_password(payload.password, user["password_hash"]):
        raise HTTPException(status_code=401, detail="Invalid credentials")
    token = create_access_token(user["email"])
    return schemas.AuthResponse(token=token, user=crud.to_public_user(user))
