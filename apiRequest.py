import urllib.parse
import urllib.request
import urllib.error
import hashlib
import json
import re
import os
import sys
import time # for time.sleep
from caching import *
from caching_to_files import *
from invocation_logging import *

API_BASE   = 'https://ru.openlist.wiki/api.php'
WIKIDATA_API_BASE = 'https://www.wikidata.org/w/api.php'
INDEX_BASE = 'https://ru.openlist.wiki/w/index.php'

# caching by URL is much more efficient when params are in the same order each time
def urlencoded_fix_order(params):
    return urllib.parse.urlencode(sorted(params.items()), doseq=True)

def stable_url(urlBase, params):
    return urlBase + '?' + urlencoded_fix_order(params)


def urlCacheFilename(url):
    url_hash = hashlib.sha512( url.encode('utf-8') ).hexdigest()
    return os.path.join('cache', 'apiRequests', url_hash)

@loggingDecorator(file=sys.stderr, logInvocations=False, logResults=False, logFailures=True)
@cacheRequestDecorator(cacheFileLoader(urlCacheFilename), cacheFileStorer(urlCacheFilename))
def contentByURL(url):
    return urllib.request.urlopen(url).read().decode('utf-8')

################

# @cacheRequestDecorator(cacheFileLoader(categoryPagesCacheFilename), cacheFileStorer(categoryPagesCacheFilename))
def categoryPages(categoryName, cmtype='page', cmcontinue=None):
    params = {
        'action': 'query',
        'list': 'categorymembers',
        'format': 'json',
        'cmlimit': '500',
        'cmtitle': categoryName,
        'cmtype': cmtype,
    }
    if cmcontinue:
        params['cmcontinue'] = cmcontinue
    return contentByURL(stable_url(API_BASE, params))

################

def transcludedInLimited(templateName, gticontinue='', gtilimit='max'):
    params = {
        'action': 'query',
        'generator': 'transcludedin',
        'titles': templateName,
        'format': 'json',
        'gtilimit': gtilimit,
        'gtinamespace': 0,
        'gticontinue': gticontinue
    }
    return contentByURL(stable_url(API_BASE, params))


def transcludedIn(templateName, gtilimit='max'):
    res = json.loads( transcludedInLimited(templateName, gtilimit=gtilimit) )
    for page in res['query']['pages'].values():
        yield page

    while 'continue' in res:
        time.sleep(5)
        res = json.loads( transcludedInLimited(templateName, gticontinue=res['continue']['gticontinue'], gtilimit=gtilimit) )
        for page in res['query']['pages'].values():
            yield page
