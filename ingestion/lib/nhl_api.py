import requests

class NHLAPIHandler:
    def __init__(self):
        self.base_url = 'https://api-web.nhle.com/v1'

    def _get_game_data(self, game_id) -> dict:
        """Returns the play-by-play data for a given game id"""
        url = f'{self.base_url}/gamecenter/{game_id}/play-by-play'
        r = requests.get(url=url)
        r.raise_for_status()
        return r.json()

    def get_daily_games(self, date: str) -> list[dict]:
        """Returns full game data (with play-by-play) for all games on a date"""
        url = f'{self.base_url}/schedule/{date}'
        r = requests.get(url=url)
        r.raise_for_status()
        schedule_data = r.json()

        games: list[dict] = []
        for week in schedule_data['gameWeek']:
            if week['date'] == date:
                for game in week['games']:
                    game['partition_date'] = date
                    game['event'] = self._get_game_data(game['id'])
                    games.append(game)
        return games
