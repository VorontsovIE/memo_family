import re
import itertools

__all__ = ['parse_template', 'get_templates_on_page', 'get_parsed_templates_on_page', 'get_template_by_its_start']

# Find template starts on the page
def locate_template_starts(page):
    if page.startswith('{{', 0) and (not page.startswith('{{{', 0)):
        yield 0
    for start in range(1, len(page)): # if pattern goes out of string, substring would be shorter than '{{' and thus inequal to it
        if page.startswith('{{', start) and (not page.startswith('{{{', start)) and (not page.startswith('{{{', start - 1)):
            yield start

def get_templates_on_page(page):
    return map(lambda start_pos: get_template_by_its_start(page, start_pos), locate_template_starts(page))

def get_parsed_templates_on_page(page):
    return map(parse_template, get_templates_on_page(page))

# We'd locate to a start of template and get template till its end
def get_template_by_its_start(page_text, template_start_position):
    if not page_text.startswith('{{', template_start_position):
        raise ValueError("It isn't start of the template")

    index = template_start_position + 2
    brace_count = 2

    while (index < len(page_text)) and (brace_count > 0):
        if page_text[index] == '{':
            brace_count += 1
        elif page_text[index] == '}':
            brace_count -= 1
        index += 1
    return page_text[template_start_position : index]

# Parse template argument. Either as 'key=value' pair or as a positional argument (at `arg_index` position)
# Inner links and templates are handled properly (equal sign don't work inside of inner links/templates).
def parse_template_parameter(key_value_string, arg_index):
    index = 0
    square_braces = 0
    curly_braces = 0
    while index < len(key_value_string):
        cur_symbol = key_value_string[index]
        if cur_symbol == '{':
            curly_braces += 1
        elif cur_symbol == '}':
            curly_braces -= 1
        elif cur_symbol == '[':
            square_braces += 1
        elif cur_symbol == ']':
            square_braces -= 1
        elif (cur_symbol == '=') and (curly_braces == 0) and (square_braces == 0):
            return (key_value_string[0 : index].strip(), key_value_string[index + 1 : ].strip() )
        index += 1
    return (arg_index, key_value_string.strip())

def parse_template(template_text):
    index = 2
    parts = []
    last_segment_start = index
    square_braces = 0
    curly_braces = 0
    while index < len(template_text) - 2:
        cur_symbol = template_text[index]
        if cur_symbol == '{':
            curly_braces += 1
        elif cur_symbol == '}':
            curly_braces -= 1
        elif cur_symbol == '[':
            square_braces += 1
        elif cur_symbol == ']':
            square_braces -= 1
        elif (cur_symbol == '|') and (curly_braces == 0) and (square_braces == 0):
            parts.append(template_text[last_segment_start : index])
            last_segment_start = index + 1
        index += 1
    parts.append(template_text[last_segment_start : (len(template_text) - 2)])
    options = map(lambda kv: parse_template_parameter(*kv), zip(parts[1 : ], itertools.count(start = 1) ) )
    return { 'template_name': parts[0].strip(), 'options': dict(options), 'raw_text': template_text }
