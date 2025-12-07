import requests
import boto3
import json
import datetime
import os

client = boto3.client('s3')
S3_BUCKET = 'nhl-data-test'


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

def main():
    base = datetime.date(2025, 12, 7)
    numdays = 7
    for date in [base - datetime.timedelta(days=x) for x in range(numdays)]:
        date = date.strftime('%Y-%m-%d')
        games = get_schedule_games(date)
        for game in games:
            game_data = get_game_data(game['id'])
            upload_game_data(game_data, date)


if __name__ == '__main__':
    main()

def lambda_handler(event, context) -> dict:
    print("Lambda invoked")
    print(f"Event: {event}")

    main()

    return {"statusCode": 200, "body": "Success"}
