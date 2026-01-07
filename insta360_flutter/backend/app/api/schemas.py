from pydantic import BaseModel, EmailStr, Field


class SignupRequest(BaseModel):
    email: EmailStr
    full_name: str = Field(min_length=2, max_length=255)
    password: str = Field(min_length=6, max_length=128)
    role: str = Field(default="worker")


class LoginRequest(BaseModel):
    email: EmailStr
    password: str


class UserResponse(BaseModel):
    id: str
    email: EmailStr
    full_name: str
    role: str

    class Config:
        from_attributes = True


class AuthResponse(BaseModel):
    token: str
    user: UserResponse
