from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from ..core.db import get_db
from ..services import auth_service
from .. import schemas

router = APIRouter(prefix="/auth", tags=["auth"])


@router.post("/signup", response_model=schemas.AuthResponse)
def signup(payload: schemas.SignupRequest, db: Session = Depends(get_db)):
    return auth_service.signup(payload, db)


@router.post("/login", response_model=schemas.AuthResponse)
def login(payload: schemas.LoginRequest, db: Session = Depends(get_db)):
    return auth_service.login(payload, db)
