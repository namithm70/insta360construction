from sqlalchemy.orm import Session

from .. import crud, models, schemas


def me(user: models.User) -> schemas.UserResponse:
    return user


def update_role(
    payload: schemas.RoleUpdateRequest,
    db: Session,
    user: models.User,
) -> schemas.UserResponse:
    role = payload.role if payload.role in {"worker", "admin"} else user.role
    updated = crud.update_user_role(db, user, role)
    return updated
