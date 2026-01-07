from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from .. import models, schemas
from ..core.db import get_db
from ..services import user_service
from .deps import get_current_user

router = APIRouter(prefix="/users", tags=["users"])


@router.get("/me", response_model=schemas.UserResponse)
def me(user: models.User = Depends(get_current_user)):
    return user_service.me(user)


@router.patch("/me/role", response_model=schemas.UserResponse)
def update_role(
    payload: schemas.RoleUpdateRequest,
    db: Session = Depends(get_db),
    user: models.User = Depends(get_current_user),
):
    return user_service.update_role(payload, db, user)
