import json
import logging
import os

import boto3

logger = logging.getLogger(__name__)


class S3Uploader:
    def __init__(self):
        self.s3 = boto3.client('s3')
        self.bucket = os.environ['S3_BUCKET']

    def upload_game_data(self, game_object: dict, partition_date: str):
        game_id = game_object['id']
        key = f"game_data={partition_date}/game_id={game_id}.json"
        
        logger.info(f"Uploading game to S3: bucket={self.bucket}, key={key}")
        
        self.s3.put_object(
            Bucket=self.bucket,
            Key=key,
            Body=json.dumps(game_object)
        )
        
        logger.info(f"Successfully uploaded game to S3: game_id={game_id}")