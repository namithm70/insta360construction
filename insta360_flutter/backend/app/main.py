from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from .api import auth as auth_api
from .api import users as users_api
from .core.db import Base, engine

app = FastAPI(title="Insta360 Backend", version="1.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.on_event("startup")
def on_startup():
    Base.metadata.create_all(bind=engine)


app.include_router(auth_api.router)
app.include_router(users_api.router)
