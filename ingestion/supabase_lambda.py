import requests
import json
import datetime
import os

SUPABASE_URL = os.environ['SUPABASE_URL']
SUPABASE_KEY = os.environ['SUPABASE_SECRET']

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
    url = f"{SUPABASE_URL}/rest/v1/game_data"

    headers = {
        "apikey": SUPABASE_KEY,
        "Authorization": f"Bearer {SUPABASE_KEY}",
        "Content-Type": "application/json",
        # Merge duplicates to avoid duplicates in the database
        "Prefer": "return=minimal,resolution=merge-duplicates"
    }

    payload = {
        "game_id": game_object['id'],
        "partition_date": partition_date,
        "event": game_object
    }

    r = requests.post(url, json=payload, headers=headers)
    r.raise_for_status()

    return {"status": "ok"}

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
    with open('ingestion/test_event.json', 'r') as f:
        event = json.load(f)
    main(event)

def lambda_handler(event, context) -> dict:
    print("Lambda invoked")
    print(f"Event: {event}")

    main(event)

    return {"statusCode": 200, "body": "Success"}
