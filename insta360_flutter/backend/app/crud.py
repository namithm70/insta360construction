from sqlalchemy.orm import Session

from . import models
from .auth import hash_password


def get_user_by_email(db: Session, email: str):
    return db.query(models.User).filter(models.User.email == email).first()


def create_user(db: Session, email: str, full_name: str, password: str, role: str):
    user = models.User(
        email=email,
        full_name=full_name,
        password_hash=hash_password(password),
        role=role,
    )
    db.add(user)
    db.commit()
    db.refresh(user)
    return user


def update_user_role(db: Session, user: models.User, role: str):
    user.role = role
    db.add(user)
    db.commit()
    db.refresh(user)
    return user
