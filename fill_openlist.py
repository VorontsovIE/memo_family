import sys
import time
import json
import re
import hashlib
import requests
import wiki_template

API_BASE = 'https://ru.openlist.wiki/api.php'
session = requests.Session();
session.headers={'user-agent': 'family-hypot-bot/0.1'}
def api_get(params):
    params = params.copy()
    params['format'] = 'json'
    response = session.get(API_BASE, params=params)
    # print('---------------')
    # print('params:', params)
    # print('-->', response.status_code, response.json(), file = sys.stderr)
    return response.json()

def api_post(data):
    data = data.copy()
    data['format'] = 'json'
    response = session.post(API_BASE, data=data)
    # print('---------------')
    # print('data:', data)
    # print('-->', response.status_code, response.json(), file = sys.stderr)
    return response.json()

def relatives_to_add_text(relatives_to_add):
    result = '{{Шаблон:Предположительные родственники'
    sons = []
    daughters = []
    brothers = []
    sisters = []
    siblings = []
    fathers = []
    for (relation, relative) in relatives_to_add:
        if relation == 'has_son':
            sons.append(relative)
        elif relation == 'has_daughter':
            daughters.append(relative)
        elif relation == 'has_brother':
            brothers.append(relative)
        elif relation == 'has_sister':
            sisters.append(relative)
        elif relation == 'has_brother/sister':
            siblings.append(relative)
        elif relation == 'has_father':
            fathers.append(relative)
    if len(fathers) > 1:
        raise Exception('more than one father')
    elif len(fathers) == 1:
        result += '\n|отец = ' + '[[' + fathers[0] + ']]'
    if len(sons) > 1:
        result += '\n|сыновья = ' + ', '.join(map(lambda person: '[[' + person + ']]', sons))
    elif len(sons) == 1:
        result += '\n|сын = ' + '[[' + sons[0] + ']]'
    if len(daughters) > 1:
        result += '\n|дочери = ' + ', '.join(map(lambda person: '[[' + person + ']]', daughters))
    elif len(daughters) == 1:
        result += '\n|дочь = ' + '[[' + daughters[0] + ']]'
    if len(brothers) > 1:
        result += '\n|братья = ' + ', '.join(map(lambda person: '[[' + person + ']]', brothers))
    elif len(brothers) == 1:
        result += '\n|брат = ' + '[[' + brothers[0] + ']]'
    if len(sisters) > 1:
        result += '\n|сестры = ' + ', '.join(map(lambda person: '[[' + person + ']]', sisters))
    elif len(sisters) == 1:
        result += '\n|сестра = ' + '[[' + sisters[0] + ']]'
    if len(siblings) > 0:
        result += '\n|братья/сестры = ' + ', '.join(map(lambda person: '[[' + person + ']]', siblings))
    result += '\n}}'
    return result

def edit_page(page_title, relatives_to_add, csrf_token):
    getpage = api_get({'action': 'query', 'prop': 'revisions', 'titles': page_title, 'rvprop': 'content|timestamp'})
    page_result = list(getpage['query']['pages'].values())[0]
    if 'missing' in page_result:
        print("Page `{}` missing".format(page_result['title']), file=sys.stderr)
        return
    page_content = page_result['revisions'][0]['*']
    page_timestamp = page_result['revisions'][0]['timestamp']
    repressed_relatives_template_names = ['Шаблон:Репрессированные родственники', 'Шаблон:Предположительные родственники',
                                          'Шаблон:Репрессированные_родственники', 'Шаблон:Предположительные_родственники']
    templates = list(wiki_template.get_parsed_templates_on_page(page_content))
    templates_repressed_relatives = list(filter(lambda template: template['template_name'] in repressed_relatives_template_names, templates))
    if len(templates_repressed_relatives) > 0:
        print('Page `{}` already has template with relatives'.format(page_title), file=sys.stderr)
        return
    relatives_to_add_template = relatives_to_add_text(relatives_to_add)
    # if re.search('==Биография==', page_content):
    #     new_page_content = re.sub('==Биография==', '==Биография==' + '\n' + relatives_to_add_template, page_content)
    # else:
    #     new_page_content = page_content + '\n' + relatives_to_add_template
    new_page_content = page_content + '\n' + relatives_to_add_template
    md5hash = hashlib.md5()
    md5hash.update(new_page_content.encode('utf-8'))
    api_post({'action': 'edit', 'title': page_title, 'summary': 'Добавлены предположительные родственники', 'text': new_page_content.encode('utf-8'),
             'basetimestamp': page_timestamp, 'contentmodel': 'wikitext', 'nocreate':'', 'notminor':'', 'bot':'', 
             'md5': md5hash.hexdigest(), 'token': csrf_token})

login = 'FamilyHypotBot'
password = sys.argv[1]
login_token = api_post({'action': 'login', 'lgname': login})['login']['token']
login_result = api_post({'action':'login', 'lgname': login, 'lgpassword': password, 'lgtoken': login_token})
if login_result['login']['result'] != 'Success':
    raise Exception('Unsuccessful login')
csrf_token = api_get(params={'action': 'query', 'meta': 'tokens', 'type': 'csrf'})['query']['tokens']['csrftoken']

relatives_by_person = {}
with open('relative_templates.txt') as f:
    for line in f:
        infos = line.rstrip('\n').split('\t')
        if infos[0] not in relatives_by_person:
            relatives_by_person[infos[0]] = []
        relatives_by_person[infos[0]].append([infos[1], infos[2]])

ind = 1
print('Total:', len(relatives_by_person), file=sys.stderr)
for (person, relatives) in relatives_by_person.items():
    print(ind, person, file=sys.stderr)
    edit_page(person, relatives_by_person[person], csrf_token)
    ind += 1
    time.sleep(1)
