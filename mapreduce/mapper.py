#!/usr/bin/env python
"""mapper.py"""

import sys
import re
import csv
import os
import re
import json


input = sys.stdin
csv_reader = csv.reader(input)
country_code = re.search(r"(\/)([A-Z]+)(videos\.csv)", os.environ["map_input_file"]).group(2)
categories = {}
with open("/data/youtube-statistics/categories/" + country_code + "_category_id.json") as json_file:
	category = json.load(json_file)
	categories = dict([(f['id'], f['snippet']['title']) for f in category['items']])

# skip first line in file which is header describing data columns
csv_reader.next()
labels = ["video_id", "trending_date", "title", "channel_title", "category_id", "publish_time",
		  "tags", "views", "likes", "dislikes", "comment_count", "thumbnail_link", "comments_disabled",
		  "ratings_disabled", "video_error_or_removed", "description"]
labels_indices = dict(zip(labels, range(len(labels))))

for data_row in csv_reader:
	# extract informations that are important

	if categories.has_key(data_row[labels_indices['category_id']]):
		print '%s\t%s\t%s\t%s' % (categories[data_row[labels_indices['category_id']]],
							data_row[labels_indices['likes']],
							data_row[labels_indices['dislikes']],
							data_row[labels_indices['comment_count']])
	else:
		continue
