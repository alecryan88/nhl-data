import datetime
import logging

from ingestion.lib.nhl_api import NHLAPIHandler
from ingestion.lib.supbase_uploader import SupabaseUploader

# Configure logging for Lambda
logger = logging.getLogger()
logger.setLevel(logging.INFO)


def main(event: dict):
    logger.info(f"Processing event: {event}")

    base = datetime.datetime.fromisoformat(event['time'].replace('Z', '+00:00')).date()
    yesterday = base - datetime.timedelta(days=1)
    yesterday_str = yesterday.strftime('%Y-%m-%d')

    logger.info(f"Fetching games for date: {yesterday_str}")

    # Get the list of games objects for the date
    nhl_api = NHLAPIHandler()
    nhl_games = nhl_api.get_daily_games(yesterday_str)

    logger.info(f"Found {len(nhl_games)} games to upload")

    # Upload each game object to Supabase
    supabase_uploader = SupabaseUploader(table_name='game_data')
    for game in nhl_games:
        supabase_uploader.upload_game_data(game)

    logger.info(f"Completed uploading {len(nhl_games)} games to Supabase")


def lambda_handler(event, context) -> dict:
    logger.info("Lambda invoked")

    main(event)

    return {"statusCode": 200, "body": "Success"}