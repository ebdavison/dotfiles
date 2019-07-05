#!/usr/bin/python3

from apiclient.discovery import build
from apiclient.errors import HttpError
from oauth2client.tools import argparser
import json
import pyodbc
import argparse

def init():
    with open("youtube_api.json", "r") as f:
        apicreds=(json.load(f))
    return apicreds

def youtube_search(q, apicreds, max_results=50,order="relevance", token=None, location=None, location_radius=None):

    youtube = build(apicreds['YOUTUBE_API_SERVICE_NAME'], apicreds['YOUTUBE_API_VERSION'],
        developerKey=apicreds['DEVELOPER_KEY'])

    search_response = youtube.channels().list(
        id=q,
        pageToken=token,
        part="id,snippet,contentDetails,statistics",
        maxResults=max_results

    ).execute()

    #print(search_response)

    channels = []

    for search_result in search_response.get("items", []):
        if search_result["kind"] == "youtube#channel":
            channels.append(search_result)
    try:
        nexttok = search_response["nextPageToken"]
        return(nexttok, channels)
    except Exception as e:
        nexttok = "last_page"
        return(nexttok, channels)

def geo_query(video_id):
    youtube = build(YOUTUBE_API_SERVICE_NAME, YOUTUBE_API_VERSION,
                    developerKey=DEVELOPER_KEY)

    video_response = youtube.videos().list(
        id=video_id,
        part='snippet, recordingDetails, statistics'

    ).execute()

    return video_response


def grab_channel_info(keyword, apicreds, token=None):
    res = youtube_search(keyword, apicreds)
    channels = res[1]

    filename = "chaninfo.json"
    wjson = json.dumps(res)
    with open(filename, "w") as f:
        f.write(wjson)

    #print(res)

    for chan in channels:
        #chan_dict = {'chanID':[], 'title':[], 'pub_date':[], 'viewCount': [], 'subscriberCount': [], 'videoCount': [], 'country': []}
        #print(chan)
        #print(chan['id'])
        chan_dict['chanID'].append(chan['id'])
        #print(chan['snippet']['title'])
        chan_dict['title'].append(chan['snippet']['title'])
        chan_dict['pub_date'].append(chan['snippet']['publishedAt'])
        chan_dict['viewCount'].append(chan['statistics']['viewCount'])
        chan_dict['subscriberCount'].append(chan['statistics']['subscriberCount'])
        chan_dict['videoCount'].append(chan['statistics']['videoCount'])
        if 'country' in chan['snippet']:
            chan_dict['country'].append(chan['snippet']['country'])
        else:
            chan_dict['country'].append("  ")


### MAIN ###

creds = init()
#parser = argparse.ArgumentParser()
#parser.add_argument("channel", help="Channel to search")
#args = parser.parse_args()

connection = pyodbc.connect(
    "DSN=VMC60ACDD;database=amzwiz;uid=amzwizmail;pwd=xa8rs29yLbcf"
)
cursor = connection.cursor()

sql_get_channels = """
    select ChannelID
    from YTResults
"""
sql_ins_channel = """
    if not exists (select ChanID
                   from YTChannels
                   where ChanID = ?)
    insert into YTChannels values
        (?, ?, ?, ?, ?, ?, null, ?, current_timestamp)
"""
sql_upd_channel = """
    update YTChannels 
    set ViewCount = ?, 
    SubscriberCount = ?,
    VideosCount = ?,
    UpdatedTime = current_timestamp
    where ChanID = ?
"""


chan_dict = {'chanID':[], 'title':[], 'pub_date':[], 'viewCount': [], 'subscriberCount': [], 'videoCount': [], 'country': []}

#grab_channel_info("UC_x5XG1OV2P6uZZ5FSM9Ttw")

cursor.execute(sql_get_channels)
for row in cursor.fetchall():
    print("Processing channel: %s" % (row[0]))
    grab_channel_info(row[0], creds)

for x,ele in enumerate(chan_dict['chanID']):
    print("ID: %s / Title: %s / Date: %s / Views: %s / Subscribers: %s / Videos: %s" % 
            (chan_dict['chanID'][x], chan_dict['title'][x], chan_dict['pub_date'][x], 
             chan_dict['viewCount'][x], chan_dict['subscriberCount'][x], chan_dict['videoCount'][x]))
    cursor.execute(sql_ins_channel, chan_dict['chanID'][x],
            chan_dict['chanID'][x], chan_dict['title'][x], chan_dict['pub_date'][x], 
             chan_dict['viewCount'][x], chan_dict['subscriberCount'][x],
             chan_dict['videoCount'][x], chan_dict['country'][x])
    cursor.commit()
    cursor.execute(sql_upd_channel, 
             chan_dict['viewCount'][x], chan_dict['subscriberCount'][x],
             chan_dict['videoCount'][x], chan_dict['chanID'][x])
    cursor.commit()

cursor.close()
connection.close()

