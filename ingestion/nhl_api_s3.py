import datetime

from ingestion.lib.nhl_api import NHLAPIHandler
from ingestion.lib.s3_uploader import S3Uploader

def main(event: dict):

    # Get the date of the event
    base = datetime.datetime.fromisoformat(event['time'].replace('Z', '+00:00')).date()
    yesterday = base - datetime.timedelta(days=2)
    yesterday_str = yesterday.strftime('%Y-%m-%d')

    # Get the list of games objects for the date
    nhl_api = NHLAPIHandler()
    nhl_games = nhl_api.get_daily_games(yesterday_str)

    # Upload each game object to S3
    s3_uploader = S3Uploader()
    for game in nhl_games:
        s3_uploader.upload_game_data(game, yesterday_str)

def lambda_handler(event, context) -> dict:
    print("Lambda invoked")
    print(f"Event: {event}")

    main(event)

    return {"statusCode": 200, "body": "Success"}
