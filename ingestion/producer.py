import requests
import boto3
import json
import datetime
import os

client = boto3.client('s3')
S3_BUCKET = 'nhl-data-pipeline-data'


def get_game_data(game_id):
    url =f'https://api-web.nhle.com/v1/gamecenter/{game_id}/play-by-play'
    r = requests.get(url = url)
    return r.json()



def get_schedule_data(date: str):
    url = f'https://api-web.nhle.com/v1/schedule/{date}'
    r = requests.get(url=url)
    return r.json()


def get_schedule_games(date: str):
    schedule_data = get_schedule_data(date)

    games: list[dict] = []
    for week in schedule_data['gameWeek']:
        if week['date'] == date: 
            for game in week['games']:
                game['partition_date'] = date
                games.append(game)

    if len(games) == 0:
        print('No games found for this date')
        return []
    else:
        print(f"Found {len(games)} games on {date}")
        return games


def upload_game_data(game_object: dict, partition_date: str):
    client.put_object(
        Bucket=S3_BUCKET,
        Key=f"game_data={partition_date}/game_id={game_object['id']}.json",
        Body=json.dumps(game_object)
    )

def main(event: dict):
    print(f"Event: {event}")

    base = datetime.datetime.fromisoformat(event['time'].replace('Z', '+00:00')).date()
    yesterday = base - datetime.timedelta(days=1)
    for date in [yesterday]:
        date = date.strftime('%Y-%m-%d')
        games = get_schedule_games(date)
        for game in games:
            game_data = get_game_data(game['id'])
            upload_game_data(game_data, date)


if __name__ == '__main__':
    # Used for local testing with uv run
    with open('ingestion/test_event.json', 'r') as f:
        event = json.load(f)
    main(event)

def lambda_handler(event, context) -> dict:
    print("Lambda invoked")
    print(f"Event: {event}")

    main(event)

    return {"statusCode": 200, "body": "Success"}
