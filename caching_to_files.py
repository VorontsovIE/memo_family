import os
# Loader and storer to save cache into files. 
# getCacheFileName should be passed to a decorator to generate cache filename

def cacheFileLoader(getCacheFileName):
    def actual_cacheLoader(*args, **kwargs):
        cacheFilename = getCacheFileName(*args, **kwargs)
        if os.path.isfile(cacheFilename):
            with open(cacheFilename, encoding = 'utf-8') as f:
                return (f.read(), True)
        else:
            return (None, False)
    return actual_cacheLoader

def cacheFileStorer(getCacheFileName):
    def actual_cacheStorer(result, *args, **kwargs):
        cacheFilename = getCacheFileName(*args, **kwargs)
        os.makedirs(os.path.dirname(cacheFilename), exist_ok = True)
        with open(cacheFilename, 'w', encoding = 'utf-8') as f:
            f.write(result)
    return actual_cacheStorer
