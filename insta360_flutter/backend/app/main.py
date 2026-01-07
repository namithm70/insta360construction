from fastapi import Depends, FastAPI, HTTPException, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from sqlalchemy.orm import Session

from . import crud, models, schemas
from .auth import create_access_token, decode_access_token, verify_password
from .db import Base, engine, get_db

app = FastAPI(title="Insta360 Backend", version="1.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

security = HTTPBearer()


@app.on_event("startup")
def on_startup():
    Base.metadata.create_all(bind=engine)


def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(security),
    db: Session = Depends(get_db),
):
    token = credentials.credentials
    subject = decode_access_token(token)
    if not subject:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid token")
    user = crud.get_user_by_email(db, subject)
    if not user:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="User not found")
    return user


@app.post("/auth/signup", response_model=schemas.AuthResponse)
def signup(payload: schemas.SignupRequest, db: Session = Depends(get_db)):
    existing = crud.get_user_by_email(db, payload.email)
    if existing:
        raise HTTPException(status_code=400, detail="Email already registered")
    role = payload.role if payload.role in {"worker", "admin"} else "worker"
    user = crud.create_user(db, payload.email, payload.full_name, payload.password, role)
    token = create_access_token(user.email)
    return schemas.AuthResponse(token=token, user=user)


@app.post("/auth/login", response_model=schemas.AuthResponse)
def login(payload: schemas.LoginRequest, db: Session = Depends(get_db)):
    user = crud.get_user_by_email(db, payload.email)
    if not user or not verify_password(payload.password, user.password_hash):
        raise HTTPException(status_code=401, detail="Invalid credentials")
    token = create_access_token(user.email)
    return schemas.AuthResponse(token=token, user=user)


@app.post("/auth/forgot")
def forgot_password(payload: schemas.ForgotPasswordRequest, db: Session = Depends(get_db)):
    user = crud.get_user_by_email(db, payload.email)
    if not user:
        return {"message": "If that account exists, a reset link has been sent."}
    return {"message": "Password reset link sent to your email."}


@app.get("/users/me", response_model=schemas.UserResponse)
def me(user: models.User = Depends(get_current_user)):
    return user


@app.patch("/users/me/role", response_model=schemas.UserResponse)
def update_role(
    payload: schemas.RoleUpdateRequest,
    db: Session = Depends(get_db),
    user: models.User = Depends(get_current_user),
):
    role = payload.role if payload.role in {"worker", "admin"} else user.role
    updated = crud.update_user_role(db, user, role)
    return updated
