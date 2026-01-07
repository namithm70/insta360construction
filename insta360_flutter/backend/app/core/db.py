from pymongo import MongoClient

DATABASE_URL = "mongodb://localhost:27017"
DATABASE_NAME = "insta360"

client = MongoClient(DATABASE_URL)


def get_db():
    return client[DATABASE_NAME]
