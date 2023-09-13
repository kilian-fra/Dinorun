import base64
from flask import Flask, request, jsonify, make_response, render_template
from flask_restx import Api, Resource, reqparse, fields, Namespace, Model
from sqlalchemy import create_engine, Column, String, Integer, ForeignKey
from sqlalchemy.sql import text
from sqlalchemy.orm import sessionmaker, scoped_session, relationship
from sqlalchemy.orm import declarative_base
from flask_cors import CORS
import hashlib
from sqlalchemy.exc import OperationalError
from time import sleep
from auth import AuthManager

app = Flask(__name__)
CORS(app)
api = Api(app, version='1.0', title='Dino Run API', description='API for Highscores and Users', doc='/api/doc')
ns = api.namespace('api', description='Dino Run', path='/api')

# Decode the Base64-encoded credentials from the Secret
username = base64.b64decode('cm9vdA==').decode('utf-8')
password = base64.b64decode('YnFFWUpCeGVDS3ZmVTc=').decode('utf-8')

db_url = f"mysql://{username}:{password}@mariadb-svc:3306/dinorun" #'mysql+pymysql://root:@192.168.178.60:3306/game'
Base = declarative_base()

# Database deployment can take some time, so a reconnect function is needed
def create_db_engine(max_retries=20, retry_interval=5):
    retries = 0
    while retries < max_retries:
        try:
            engine = create_engine(db_url, pool_recycle=3600)
            engine.connect()  # Attempt to connect
            return engine
        except OperationalError as e:
            print(f"Database connection failed. Error: {e}")
            print(f"Retrying in {retry_interval} seconds...")
            sleep(retry_interval)
            retries += 1

    raise RuntimeError("Could not establish a connection to the database.")

# Create the database engine with retries
engine = create_db_engine()
db_session = scoped_session(sessionmaker(bind=engine))

class Highscore(Base):
    __tablename__ = 'highscore'
    user_id = Column(String(10), ForeignKey('users.username'), primary_key=True)
    level = Column(Integer, primary_key=True)
    score = Column(Integer, nullable=False)
    user = relationship('User', back_populates='highscores')


class User(Base):
    __tablename__ = 'users'
    username = Column(String(10), primary_key=True)
    password = Column(String(64), nullable=False)
    highscores = relationship('Highscore', back_populates='user', cascade='all, delete')

# Initialize auth manager
auth_manager = AuthManager()

# Request parsers
parser_user_delete = api.parser()
parser_user_delete.add_argument('auth_token', type=str, required=True, location='json')
parser_user_delete.add_argument('auth_token', type=str, required=True, location='json')

# post user parser
parser_post_user = reqparse.RequestParser()
parser_post_user.add_argument('username', type=str, required=True, location='json')
parser_post_user.add_argument('password', type=str, required=True, location='json')
parser_post_user.add_argument('action', type=str, required=True, location='json')

# To allow K8s run automatic liveness probes for self-healing
@app.route('/api/healthz', methods=["GET"])
def health():
    try:
        # Attempt to execute a simple database query to check connectivity
        db_session.execute(text('SELECT 1'))
        db_session.commit()
        
        # If the database query succeeds, return a healthy status
        return jsonify(status="OK", database_status="Connected"), 200
    except OperationalError as e:
        # Handle the database connection error
        return jsonify(status="Database Error", message=str(e)), 500
    except Exception as e:
        return jsonify(status="Error", message=str(e)), 500

@ns.route('/user')
class UserRessource(Resource):
    @api.expect(parser_user_delete)
    @api.doc(responses={200: 'User wurde erfolgreich gelöscht', 401: 'Authentisierungfehler'})
    def delete(self):
        data = request.get_json()
        auth_token = data.get('auth_token')
            
        auth_result = auth_manager.is_auth(auth_token)
        if isinstance(auth_result, bool) and not auth_result:
            return make_response(jsonify({'message': 'Authorization unsuccessful'}), 401)
            
        username = None
        if isinstance(auth_result, str):
            username = auth_manager.get_username_for_auth_token(auth_result)
        else:
            username = auth_manager.get_username_for_auth_token(auth_token)

        user = db_session.query(User).filter_by(username=username).first()    
        db_session.delete(user)
        db_session.commit()

        # Delete auth data
        auth_manager.remove_auth_data(auth_token)

        return make_response(jsonify({'message': 'User and associated highscores deleted'}), 200)
        
    @api.expect(parser_post_user)
    @api.doc(responses={
        200: 'Login/Registrierung erfolgreich',
        400: 'Falsche Aktion (weder Login noch Registrierung)',
        500: 'Unbekannter Fehler'
    })
    def post(self):
        data = request.get_json()
        action = data.get('action')
        username = data.get('username')
        password = data.get('password')

        # Check action (either login or register)
        if action == 'login':
            return self.login(username, password)
        elif action == 'register':
            return self.register(username, password)
        else:
            return make_response(jsonify({'message': 'Invalid action'}), 400)
            
    def validate_input(self, username, password):
        return username and password and len(username) <= 10 and len(password) <= 64
        
    def login(self, username, password):
        user = db_session.query(User).filter_by(username=username).first()
        if not user or not self.validate_input(username, password):
            return make_response(jsonify({'message': 'Invalid username or password'}), 401)
        
        # Hash the input password
        hashed_password = hashlib.sha256(password.encode('utf-8')).hexdigest()

        # Verfiy password
        if hashed_password != user.password:
            return make_response(jsonify({'message': 'Invalid username or password'}), 401)
        
        # Add session to auth manager
        auth_token = auth_manager.login_auth(username)

        return make_response(jsonify({'message': 'Login successful', 'auth_token': auth_token}), 200)

    def register(self, username, password):
        if db_session.query(User).filter_by(username=username).first():
            return make_response(jsonify({'message': 'Username already exists'}), 400)
        
        # Validate input
        if not self.validate_input(username, password):
            return make_response(jsonify({'message': 'Invalid username or password'}, 400))

        hashed_password = hashlib.sha256(password.encode('utf-8')).hexdigest()
        db_session.add(User(username=username, password=hashed_password))
        db_session.commit()

        return make_response(jsonify({'message': 'User registered successfully'}), 201)

# patch highscore parser
parser_patch_highscore = reqparse.RequestParser()
parser_patch_highscore.add_argument('auth_token', type=str, required=True, location='json')
parser_patch_highscore.add_argument('score', type=int, required=True, location='json')
parser_patch_highscore.add_argument('level', type=int, required=True, location='json')

# delete highscore parser
parser_delete_highscore = reqparse.RequestParser()
parser_delete_highscore.add_argument('auth_token', type=str, required=True, location='json')
parser_delete_highscore.add_argument('level', type=int, required=True, location='json')

@ns.route('/highscore')
class HighscoreRessource(Resource):

    @api.doc('list_highscors')
    @api.doc('highscore_level_list', params={'auth_token': 'Token zur Authentisierung', 'level': 'Level für Highscore-Abfrage'})
    @api.doc(responses={
        200: 'Highscore-Abfrage erfolgreich',
        401: 'Authentisierungsfehler',
        404: 'Keine Highscors vorhanden für gefordertes Level',
        500: 'Unbekannter Fehler'
    })
    def get(self):
        parser = reqparse.RequestParser()
        parser.add_argument('auth_token', type=str, required=True, location='args')
        parser.add_argument('level', required=True, type=int, location='args')
        args = parser.parse_args()

        auth_token = args['auth_token']
        level = args['level']
            
        auth_result = auth_manager.is_auth(auth_token)
        if isinstance(auth_result, bool) and not auth_result:
            return make_response(jsonify({'message': 'Authorization unsuccessful'}), 401)
        
        highscores = db_session.query(Highscore).filter_by(level=level).order_by(Highscore.score.desc()).all()
        if not highscores:
            if isinstance(auth_result, str):
                return make_response(jsonify({'message': 'No highscores found for this level', 'session_expired': 'true', 'auth_token': auth_result}), 404)
            else:
                return make_response(jsonify({'message': 'No highscores found for this level', 'session_expired': 'false'}), 404)

        highscore_list = []
        for score in highscores:
            highscore_list.append({
                'username': score.user.username,
                'score': score.score,
                'level': score.level
        })
                
        if isinstance(auth_result, str):
            return make_response(jsonify({'highscore': highscore_list, 'session_expired': 'true', 'auth_token': auth_result}), 200)
        else:
            return make_response(jsonify({'highscore': highscore_list, 'session_expired': 'false'}), 200)
    
    @api.expect(parser_patch_highscore)
    @api.doc(responses={
        200: 'Highscore-Update erfolgreich bzw. kein neuer Highscore',
        401: 'Authentisierungfehler',
        500: 'Unbekannter Fehler'
    })
    def patch(self):
        data = request.get_json()
        auth_token = data.get('auth_token')
        level = int(data.get('level'))
        new_score = int(data.get('score'))
            
        auth_result = auth_manager.is_auth(auth_token)
        if isinstance(auth_result, bool) and not auth_result:
            return make_response(jsonify({'message': 'Authorization unsuccessful'}), 401)
            
        username = None
        if isinstance(auth_result, str):
            username = auth_manager.get_username_for_auth_token(auth_result)
        else:
            username = auth_manager.get_username_for_auth_token(auth_token)

        user = db_session.query(User).filter_by(username=username).first()
        
        highscore = db_session.query(Highscore).filter_by(user_id=user.username, level=level).first()
        if not highscore:
            db_session.add(Highscore(score=new_score, level=level, user=user))
            db_session.commit()
            if isinstance(auth_result, str):
                return make_response(jsonify({'message': 'Highscore created successfully', 'highscore': new_score, 'session_expired': 'true', 'auth_token': auth_result}), 200)
            else:
                return make_response(jsonify({'message': 'Highscore created successfully', 'highscore': new_score, 'session_expired': 'false'}), 200)
        
        score_result = highscore.score
        if new_score > highscore.score:
            highscore.score = new_score
            db_session.commit()
            score_result = new_score
            
        if isinstance(auth_result, str):
            return make_response(jsonify({'message': 'Highscore updated successfully', 'highscore':  score_result, 'session_expired': 'true', 'auth_token': auth_result}), 200)
        else:
            return make_response(jsonify({'message': 'Highscore updated successfully', 'highscore':  score_result, 'session_expired': 'false'}), 200)
    
    @api.expect(parser_delete_highscore)
    @api.doc(responses={
        200: 'Highscore wurde erfolgreich gelöscht',
        401: 'Authentisierungsfehler',
        404: 'Highscore nicht gefunden',
        500: 'Unbekannter Fehler'
    })
    def delete(self):
        data = request.get_json()
        auth_token = data.get('auth_token')
        level = int(data.get('level'))
            
        auth_result = auth_manager.is_auth(auth_token)
        if isinstance(auth_result, bool) and not auth_result:
            return make_response(jsonify({'message': 'Authorization unsuccessful'}), 401)
            
        username = None
        if isinstance(auth_result, str):
            username = auth_manager.get_username_for_auth_token(auth_result)
        else:
            username = auth_manager.get_username_for_auth_token(auth_token)

        highscore = db_session.get(Highscore, (username, level))
        if not highscore:
            if isinstance(auth_result, str):
                return make_response(jsonify({'message': 'Highscore not found', 'session_expired': 'true', 'auth_token': auth_result}), 404)
            else:
                return make_response(jsonify({'message': 'Highscore not found', 'session_expired': 'false'}), 404)
        
        db_session.delete(highscore)
        db_session.commit()

        if isinstance(auth_result, str):
            return make_response(jsonify({'message': 'Highscore deleted successfully', 'session_expired': 'true', 'auth_token': auth_result}), 200)
        else:
            return make_response(jsonify({'message': 'Highscore deleted successfully', 'session_expired': 'false'}), 200)      

if __name__ == '__main__':
    app.run(host='0.0.0.0', debug=False)