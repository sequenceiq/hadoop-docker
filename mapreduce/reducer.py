#!/usr/bin/env python
"""reducer.py"""

from operator import itemgetter
import sys


current_category_id = None
current_interactions_count = 0
videos_count = 0

for line in sys.stdin:
	# remove leading and trailing whitespace
	line = line.strip()

	try:
		# parse the input we got from mapper.py
		category_id, likes, dislikes, comment_count = line.split('\t')
		# convert to int
		interactions_count = int(likes) + int(dislikes) + int(comment_count)
	except Exception:
		# not a number, so silently discard this line
		print >> sys.stderr, "ERROR"
		print >> sys.stderr, line
		continue


	if current_category_id == category_id:
		videos_count += 1
		current_interactions_count += interactions_count
	else:
		if current_category_id:
			average_interactions = interactions_count / videos_count
			print '%s\t%s' % (current_category_id, average_interactions)
		current_interactions_count = interactions_count
		current_category_id = category_id
		videos_count = 1

if current_category_id == category_id:
	average_interactions = interactions_count / videos_count
	print '%s\t%s' % (current_category_id, average_interactions)
