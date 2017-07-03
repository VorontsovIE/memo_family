import sys
import apiRequest

def main():
    templateName = 'Шаблон:' + 'Репрессированные_родственники' #sys.argv[1]
    print(templateName, file=sys.stderr)
    for page in apiRequest.transcludedIn(templateName):
        print(page['title'])
    
if __name__ == '__main__':
    main()
