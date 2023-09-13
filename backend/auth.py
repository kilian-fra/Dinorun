import secrets
from datetime import datetime, timedelta

class AuthData:

    def __init__(self, username, last_activity):
        self.username = username
        self.last_activity = last_activity

class AuthManager:
    _instance = None
    auth_data_map = {}
    SESSION_EXPIRATION_MINUTES = 5

    def __new__(cls):
        if cls._instance is None:
            cls._instance = super(AuthManager, cls).__new__(cls)
        return cls._instance
    
    def get_auth_by_username(self, username):
        for auth_token, auth_data in self.auth_data_map.items():
            if auth_data.username == username:
                return auth_token
        return None
    
    def login_auth(self, username):
        auth_token = self.get_auth_by_username(username)
        # Delete old auth data (if available)
        if auth_token:
            del self.auth_data_map[auth_token]

        return self.add_auth_data(username)

    
    def generate_unique_auth_token(self):
        while True:
            auth_token = secrets.token_hex(16)
            if not self.auth_data_map.get(auth_token):
                return auth_token

    def add_auth_data(self, username):
        auth_data = AuthData(username, datetime.now())
        auth_token = self.generate_unique_auth_token()
        self.auth_data_map[auth_token] = auth_data
        return auth_token
    
    def get_username_for_auth_token(self, auth_token):
        auth_data = self.auth_data_map.get(auth_token)
        if auth_data:
            return auth_data.username
        else:
            return None
        
    def remove_auth_data(self, auth_token):
        if auth_token in self.auth_data_map:
            del self.auth_data_map[auth_token]

    def is_auth(self, auth_token):
        auth_data = self.auth_data_map.get(auth_token)
        if not auth_data:
            return False

        # Check if the session has expired
        expiration_time = auth_data.last_activity + timedelta(minutes=self.SESSION_EXPIRATION_MINUTES)
        if datetime.now() > expiration_time:
            username = auth_data.username
            self.remove_auth_data(auth_token)
            new_auth_token = self.add_auth_data(username)
            return new_auth_token

        auth_data.last_activity = datetime.now()
        return True