import logging
import os

import boto3
import requests

logger = logging.getLogger(__name__)


def get_supabase_credentials():
    """Fetch Supabase credentials from AWS Parameter Store."""
    param_prefix = os.environ.get('SUPABASE_PARAM_PREFIX')
    
    # Fall back to env vars for local development
    if not param_prefix:
        return {
            'url': os.environ['SUPABASE_URL'],
            'secret': os.environ['SUPABASE_SECRET']
        }
    
    ssm = boto3.client('ssm')
    response = ssm.get_parameters(
        Names=[
            f'{param_prefix}/url',
            f'{param_prefix}/secret'
        ],
        WithDecryption=True
    )
    
    params = {p['Name'].split('/')[-1]: p['Value'] for p in response['Parameters']}
    return params


class SupabaseUploader:
    def __init__(self, table_name: str):
        credentials = get_supabase_credentials()
        self.url = credentials['url']
        self.secret = credentials['secret']
        self.table_name = table_name

    def upload_game_data(self, game_object: dict):
        game_id = game_object['id']
        partition_date = game_object['partition_date']
        
        logger.info(f"Uploading game to Supabase: game_id={game_id}, partition_date={partition_date}, table={self.table_name}")
        
        url = f"{self.url}/rest/v1/{self.table_name}"
        headers = {
            "apikey": self.secret,
            "Authorization": f"Bearer {self.secret}",
            "Content-Type": "application/json",
            # Merge duplicates to avoid duplicates in the database
            "Prefer": "return=minimal,resolution=merge-duplicates"
        }
        payload = {
            "game_id": game_id,
            "partition_date": partition_date,
            "event": game_object
        }
        response = requests.post(url, json=payload, headers=headers)
        response.raise_for_status()
        
        logger.info(f"Successfully uploaded game to Supabase: game_id={game_id}")
        return {"status": "ok", "game_id": game_id}
