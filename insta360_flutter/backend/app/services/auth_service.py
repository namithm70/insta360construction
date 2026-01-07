from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from .. import crud, models, schemas
from ..auth import create_access_token, decode_access_token, verify_password


def get_current_user(token: str, db: Session) -> models.User:
    subject = decode_access_token(token)
    if not subject:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid token",
        )
    user = crud.get_user_by_email(db, subject)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="User not found",
        )
    return user


def signup(payload: schemas.SignupRequest, db: Session) -> schemas.AuthResponse:
    existing = crud.get_user_by_email(db, payload.email)
    if existing:
        raise HTTPException(status_code=400, detail="Email already registered")
    role = payload.role if payload.role in {"worker", "admin"} else "worker"
    user = crud.create_user(db, payload.email, payload.full_name, payload.password, role)
    token = create_access_token(user.email)
    return schemas.AuthResponse(token=token, user=user)


def login(payload: schemas.LoginRequest, db: Session) -> schemas.AuthResponse:
    user = crud.get_user_by_email(db, payload.email)
    if not user or not verify_password(payload.password, user.password_hash):
        raise HTTPException(status_code=401, detail="Invalid credentials")
    token = create_access_token(user.email)
    return schemas.AuthResponse(token=token, user=user)


def forgot_password(payload: schemas.ForgotPasswordRequest, db: Session) -> dict:
    user = crud.get_user_by_email(db, payload.email)
    if not user:
        return {"message": "If that account exists, a reset link has been sent."}
    return {"message": "Password reset link sent to your email."}
