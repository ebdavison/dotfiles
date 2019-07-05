#!/usr/bin/python3

from apiclient.discovery import build
from apiclient.errors import HttpError
from oauth2client.tools import argparser
import json
import pyodbc

DEVELOPER_KEY = "AIzaSyAI3tT4KtYKzeeh7QWXD-kdB2vcOUA_FBo"
YOUTUBE_API_SERVICE_NAME = "youtube"
YOUTUBE_API_VERSION = "v3"

def youtube_search(q, max_results=50,order="relevance", token=None, location=None, location_radius=None):

    youtube = build(YOUTUBE_API_SERVICE_NAME, YOUTUBE_API_VERSION,
        developerKey=DEVELOPER_KEY)

    search_response = youtube.search().list(
        q=q,
        type="video",
        pageToken=token,
        order = order,
        part="id,snippet",
        maxResults=max_results,
        location=location,
        locationRadius=location_radius

    ).execute()

    videos = []

    for search_result in search_response.get("items", []):
        if search_result["id"]["kind"] == "youtube#video":
            videos.append(search_result)
    try:
        nexttok = search_response["nextPageToken"]
        return(nexttok, videos)
    except Exception as e:
        nexttok = "last_page"
        return(nexttok, videos)


def geo_query(video_id):
    youtube = build(YOUTUBE_API_SERVICE_NAME, YOUTUBE_API_VERSION,
                    developerKey=DEVELOPER_KEY)

    video_response = youtube.videos().list(
        id=video_id,
        part='snippet, recordingDetails, statistics'

    ).execute()

    return video_response


def grab_videos(keyword, token=None):
    res = youtube_search(keyword)
    token = res[0]
    videos = res[1]

    filename = "videos.json"
    wjson = json.dumps(videos)
    with open(filename, "w") as f:
        f.write(wjson)

    for vid in videos:
        #print(vid['id']['videoId'])
        video_dict['youID'].append(vid['id']['videoId'])
        #print(vid['snippet']['title'])
        video_dict['title'].append(vid['snippet']['title'])
        #print(vid['snippet']['publishedAt'])
        video_dict['pub_date'].append(vid['snippet']['publishedAt'])
        #print(vid['snippet']['channelId'])
        video_dict['chanID'].append(vid['snippet']['channelId'])

    print("added " + str(len(videos)) + " videos to a total of " +
        str(len(video_dict['youID'])))

    return token

### MAIN ###

# test = youtube_search("exercise equipment")
# token = test[0]
# just_json = test[1]
# 
# print("First 50:")
# for video in just_json:
#     print(video['snippet']['title'])
# 
# test = youtube_search("exercise equipment", token=token)
# just_json = test[1]
# 
# print("Second 50:")
# for video in just_json:
#     print(video['snippet']['title'])

connection = pyodbc.connect(
    "DSN=VMC60ACDD;database=amzwiz;uid=amzwizmail;pwd=xa8rs29yLbcf"
)
cursor = connection.cursor()

sql_ins_video = """
    insert into YTResults values (?, ?, ?, ?, ?, current_timestamp)
"""
sql_ins_video = """
    if not exists (select VideoID
                   from YTResults
                   where VideoID = ?)
    insert into YTresults values
        (?, ?, ?, ?, current_timestamp, ?)
"""


video_dict = {'youID':[], 'title':[], 'pub_date':[], 'chanID':[]}
termID = 1
token = grab_videos("exercise equipment")

#while token != "last_page":
#    token = grab_videos("exercise equipment", token=token)

#print(video_dict)
for x,ele in enumerate(video_dict['youID']):
    print("ID: %s / Title: %s / Date: %s / Channel ID: %s" % 
            (video_dict['youID'][x], video_dict['title'][x], video_dict['pub_date'][x], 
             video_dict['chanID'][x]))
    cursor.execute(sql_ins_video, video_dict['youID'][x],
            video_dict['youID'][x], video_dict['title'][x], video_dict['pub_date'][x], 
             video_dict['chanID'][x], termID)
    cursor.commit()

cursor.close()
connection.close()

