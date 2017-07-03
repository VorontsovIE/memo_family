import hashlib
import os
import os.path
import urllib.parse

def cacheRequestDecorator(cacheLoadFn, cacheStoreFn, forceCacheStoring = False):
    '''
    Decorator with parameter. It accepts two functions which load and store cache.
    If cache exists, its content is returned.
    Otherwise wrapped function is invoked and its result'd be stored to cache.
    Also there is an optional parameter to force storing cache even if it was
    successfully loaded. It's useful when you want to load from one cache provider
    and store to another one (temporary fix on caching scheme change)

    Cache load function accept the same parameters, wrapped function accepts.
    Loading function should return a tuple: (result, True) on success
    or (None, False) on failure.

    Storing function accepts result to be stored and the same parameters
    which were passed to calculate a value. It returns nothing.

    One can change default caching behavior (specified when method is decorated)
        by providing `cacheLoadFn` or `cacheStore` at invocation time.
    '''
    def actualDecorator(requestFunction):
        def wrappedRequest(*args, **kwargs):
            kwargs = kwargs.copy()
            # One can change default caching behavior
            #   (specified when method is decorated)
            #    by providing `cacheLoadFn` or `cacheStore`
            #    at invocation time
            cacheLoader = kwargs.pop('cacheLoadFn', cacheLoadFn)
            cacheStorer = kwargs.pop('cacheStoreFn', cacheStoreFn)
            do_forceCacheStoring = kwargs.pop('forceCacheStoring', forceCacheStoring)
            # Don't load from cache when `cacheLoadFn = None` is specified
            if not cacheLoader:
                cacheLoader = lambda *args, **kwargs: (None, False)
            # Don't store to cache when `cacheStoreFn = None` is specified
            if not cacheStorer:
                cacheStorer = lambda result, *args, **kwargs: None

            result, result_is_in_cache = cacheLoader(*args, **kwargs)
            if not result_is_in_cache:
                result = requestFunction(*args, **kwargs)
            if (not result_is_in_cache) or do_forceCacheStoring:
                cacheStorer(result, *args, **kwargs)
            return result
        wrappedRequest.__name__ = "cached:{}".format(requestFunction.__name__)
        return wrappedRequest
    return actualDecorator
