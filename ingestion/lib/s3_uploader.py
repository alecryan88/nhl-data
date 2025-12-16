import boto3
import json
import os


class S3Uploader:
    def __init__(self):
        self.s3 = boto3.client('s3')
        self.bucket = os.environ['S3_BUCKET']

    def upload_game_data(self, game_object: dict, partition_date: str):
        self.s3.put_object(
            Bucket=self.bucket,
            Key=f"game_data={partition_date}/game_id={game_object['id']}.json",
            Body=json.dumps(game_object)
        )