import os
import requests


class SupabaseUploader:
    def __init__(self, table_name: str):
        self.url = os.environ['SUPABASE_URL']
        self.secret = os.environ['SUPABASE_SECRET']
        self.table_name = table_name

    def upload_game_data(self, game_object: dict):
        url = f"{self.url}/rest/v1/{self.table_name}"
        headers = {
            "apikey": self.secret,
            "Authorization": f"Bearer {self.secret}",
            "Content-Type": "application/json",
            # Merge duplicates to avoid duplicates in the database
            "Prefer": "return=minimal,resolution=merge-duplicates"
        }
        payload = {
            "game_id": game_object['id'],
            "partition_date": game_object['partition_date'],
            "event": game_object
        }
        response = requests.post(url, json=payload, headers=headers)
        response.raise_for_status()
        return {"status": "ok", "game_id": game_object['id']}