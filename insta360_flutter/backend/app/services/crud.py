from .auth import hash_password


def get_user_by_email(db, email: str):
    return db.users.find_one({"email": email})


def create_user(db, email: str, full_name: str, password: str, role: str):
    user = {
        "email": email,
        "full_name": full_name,
        "password_hash": hash_password(password),
        "role": role,
    }
    result = db.users.insert_one(user)
    user["_id"] = result.inserted_id
    return user


def to_public_user(user: dict):
    return {
        "id": str(user["_id"]),
        "email": user["email"],
        "full_name": user["full_name"],
        "role": user["role"],
    }
