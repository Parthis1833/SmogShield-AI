import os
from pathlib import Path
from datetime import datetime, timezone
from typing import Any, Dict, Optional


BACKEND_DIR = Path(__file__).resolve().parents[2]


class FirebaseAuthenticationUnavailable(Exception):
    pass


class InvalidFirebaseToken(Exception):
    pass


class FirebaseService:
    def __init__(self):
        self.project_id: Optional[str] = None
        self.is_configured = False
        self._app = None
        self._in_memory_db: Dict[str, Dict[str, Any]] = {}

        configured_path = os.getenv("FIREBASE_SERVICE_ACCOUNT_PATH", "").strip()
        if not configured_path:
            return

        credential_path = Path(configured_path).expanduser()
        if not credential_path.is_absolute():
            credential_path = BACKEND_DIR / credential_path
        if not credential_path.is_file():
            raise RuntimeError(
                "The configured Firebase service-account file does not exist."
            )

        try:
            import firebase_admin
            from firebase_admin import credentials

            certificate = credentials.Certificate(str(credential_path))
            configured_project_id = os.getenv("FIREBASE_PROJECT_ID", "").strip()
            certificate_project_id = certificate.project_id
            project_id = configured_project_id or certificate_project_id
            if not project_id or (
                certificate_project_id
                and project_id != certificate_project_id
            ):
                raise RuntimeError(
                    "The configured Firebase project does not match the service account."
                )
            try:
                self._app = firebase_admin.get_app()
            except ValueError:
                self._app = firebase_admin.initialize_app(
                    certificate,
                    options={"projectId": project_id},
                )
            app_project_id = (
                self._app.options.get("projectId")
                or getattr(self._app.credential, "project_id", None)
            )
            if app_project_id and app_project_id != project_id:
                raise RuntimeError(
                    "The initialized Firebase app does not match the configured project."
                )
            self.project_id = project_id
            self.is_configured = True
        except ImportError as error:
            raise RuntimeError(
                "Firebase Admin SDK is required when service-account credentials are configured."
            ) from error
        except Exception:
            raise RuntimeError(
                "Firebase Admin SDK could not initialize from the configured service-account file."
            ) from None

    def _firestore_client(self):
        if not self.is_configured or self._app is None:
            raise FirebaseAuthenticationUnavailable(
                "Firebase/Firestore is not configured."
            )
        try:
            from firebase_admin import firestore

            return firestore.client(app=self._app)
        except Exception as error:
            raise FirebaseAuthenticationUnavailable(
                "Firestore is temporarily unavailable."
            ) from error

    def verify_id_token(self, token: str) -> Dict[str, Any]:
        if not self.is_configured or self._app is None:
            raise FirebaseAuthenticationUnavailable(
                "Firebase authentication is not configured."
            )

        from firebase_admin import auth
        from firebase_admin.exceptions import FirebaseError

        try:
            return auth.verify_id_token(token, app=self._app, check_revoked=True)
        except (auth.InvalidIdTokenError, auth.UserDisabledError, ValueError) as error:
            raise InvalidFirebaseToken("The Firebase ID token is invalid.") from error
        except FirebaseError as error:
            raise FirebaseAuthenticationUnavailable(
                "Firebase authentication is temporarily unavailable."
            ) from error

    def get_user_profile(self, user_id: str) -> Optional[Dict[str, Any]]:
        if not self.is_configured:
            return None
        try:
            from firebase_admin import firestore

            document = firestore.client(app=self._app).collection("users").document(user_id).get()
            return document.to_dict() if document.exists else None
        except Exception as error:
            raise FirebaseAuthenticationUnavailable(
                "Firestore profile data is temporarily unavailable."
            ) from error

    def save_user_profile(self, user_id: str, data: Dict[str, Any]) -> Dict[str, Any]:
        if not self.is_configured:
            raise FirebaseAuthenticationUnavailable(
                "Firebase/Firestore is not configured."
            )
        try:
            from firebase_admin import firestore

            firestore.client(app=self._app).collection("users").document(user_id).set(
                data, merge=True
            )
            return {"status": "saved", "user_id": user_id}
        except Exception as error:
            raise FirebaseAuthenticationUnavailable(
                "Firestore profile data could not be saved."
            ) from error

    def save_impact_action(
        self, user_id: str, data: Dict[str, Any]
    ) -> Dict[str, Any]:
        client = self._firestore_client()
        try:
            recorded_at = datetime.now(timezone.utc).isoformat()
            reference = (
                client.collection("users")
                .document(user_id)
                .collection("impact_actions")
                .document()
            )
            action = {**data, "recorded_at": recorded_at}
            reference.set(action)
            return {"id": reference.id, **action}
        except Exception as error:
            raise FirebaseAuthenticationUnavailable(
                "Impact action could not be saved."
            ) from error

    def list_impact_actions(self, user_id: str) -> list[Dict[str, Any]]:
        client = self._firestore_client()
        try:
            documents = (
                client.collection("users")
                .document(user_id)
                .collection("impact_actions")
                .order_by("recorded_at")
                .stream()
            )
            return [
                {"id": document.id, **(document.to_dict() or {})}
                for document in documents
            ]
        except Exception as error:
            raise FirebaseAuthenticationUnavailable(
                "Impact actions could not be loaded."
            ) from error

    def create_community_challenge(
        self, user_id: str, data: Dict[str, Any]
    ) -> Dict[str, Any]:
        client = self._firestore_client()
        try:
            reference = client.collection("community_challenges").document()
            challenge = {
                **data,
                "created_by": user_id,
                "created_at": datetime.now(timezone.utc).isoformat(),
            }
            reference.set(challenge)
            return {
                "id": reference.id,
                **challenge,
                "participants_count": 0,
                "joined": False,
            }
        except Exception as error:
            raise FirebaseAuthenticationUnavailable(
                "Community challenge could not be created."
            ) from error

    def list_community_challenges(
        self, user_id: str
    ) -> list[Dict[str, Any]]:
        client = self._firestore_client()
        try:
            documents = (
                client.collection("community_challenges")
                .order_by("ends_at")
                .stream()
            )
            challenges = []
            for document in documents:
                challenge = document.to_dict() or {}
                participants = list(
                    document.reference.collection("participants").stream()
                )
                challenges.append(
                    {
                        "id": document.id,
                        **challenge,
                        "participants_count": len(participants),
                        "joined": any(
                            participant.id == user_id
                            for participant in participants
                        ),
                    }
                )
            return challenges
        except Exception as error:
            raise FirebaseAuthenticationUnavailable(
                "Community challenges could not be loaded."
            ) from error

    def join_community_challenge(self, user_id: str, challenge_id: str) -> None:
        client = self._firestore_client()
        try:
            challenge = client.collection("community_challenges").document(
                challenge_id
            )
            if not challenge.get().exists:
                raise KeyError(challenge_id)
            challenge.collection("participants").document(user_id).set(
                {"joined_at": datetime.now(timezone.utc).isoformat()}
            )
        except KeyError:
            raise
        except Exception as error:
            raise FirebaseAuthenticationUnavailable(
                "Could not join this community challenge."
            ) from error

    def leave_community_challenge(self, user_id: str, challenge_id: str) -> None:
        client = self._firestore_client()
        try:
            challenge = client.collection("community_challenges").document(
                challenge_id
            )
            if not challenge.get().exists:
                raise KeyError(challenge_id)
            challenge.collection("participants").document(user_id).delete()
        except KeyError:
            raise
        except Exception as error:
            raise FirebaseAuthenticationUnavailable(
                "Could not leave this community challenge."
            ) from error


firebase_service = FirebaseService()
