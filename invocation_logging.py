import sys

def loggingDecorator(file=sys.stderr, logInvocations=True, logResults=False, logFailures=True):
    def actualDecorator(func):
        def wrappedFunc(*args, **kwargs):
            invocation_cmd = ['Invoke', func.__name__]
            if len(args) > 0:
                invocation_cmd += ['args:', args]
            if len(kwargs) > 0:
                invocation_cmd += ['with kwargs:', kwargs]
            try:
                if logInvocations:
                    print(*invocation_cmd, file = file)
                result = func(*args, **kwargs)
                if logResults:
                    print('Result: `{}`'.format(result), file = file)
                return result
            except Exception as exception:
                if logFailures:
                    if not logInvocations: # if invocation not yet printed, print it now
                        print(*invocation_cmd, file = file)
                    print('Raised', exception, file = file)
                raise
        wrappedFunc.__name__ = "logged:{}".format(func.__name__)
        return wrappedFunc
    return actualDecorator
