import requests
import json
import datetime


from ingestion.lib.nhl_api import NHLAPIHandler
from ingestion.lib.supbase_uploader import SupabaseUploader


def main(event: dict):
    print(f"Event: {event}")

    base = datetime.datetime.fromisoformat(event['time'].replace('Z', '+00:00')).date()
    yesterday = base - datetime.timedelta(days=1)
    yesterday_str = yesterday.strftime('%Y-%m-%d')

    # Get the list of games objects for the date
    nhl_api = NHLAPIHandler()
    nhl_games = nhl_api.get_daily_games(yesterday_str)

    # Upload each game object to Supabase
    supabase_uploader = SupabaseUploader(table_name='game_data')
    for game in nhl_games:
        supabase_uploader.upload_game_data(game)


def lambda_handler(event, context) -> dict:
    print("Lambda invoked")
    print(f"Event: {event}")

    main(event)

    return {"statusCode": 200, "body": "Success"}