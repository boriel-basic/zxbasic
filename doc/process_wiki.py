#!/usr/bin/env python
# -*- coding: utf-8 -*-

from bs4 import BeautifulSoup as BS
import sys
import re
import os

RE_CODE = re.compile('<zxbasic>|</zxbasic>|<freebasic>|</freebasic>|<qbasic>|</qbasic>')
RE_INTERNAL_LINK = re.compile(r'\[\[([^]|]+)(\|[^]]+)?\]\]')
RE_EXTERNAL_LINK = re.compile(r'\[(http://[^ ]+) ([^]]+)\]')


def get_file_names(path):
    result = set()
    for root, dir, files in os.walk(path):
        result.update([os.path.basename(x) for x in files])

    return result


def link_to_fname(link):
    if link.startswith('ZX_BASIC:'):
        link = link[9:]
    return link.replace(' ', '_').lower() + '.md'


def write_page(title, text, sha1, already_done):
    fname = title.replace(' ', '_').lower() + '.md'
    if fname in already_done:
        return

    print('Processing {}'.format(fname))

    with open(fname, 'wt', encoding='utf-8') as fout:
        fout.write('#{}\n\n'.format(title))
        started = False
        verbatim = False

        for line in text.split('\n'):
            if line == sha1:
                continue

            started = started or line == 'text/x-wiki'
            if not started or line == 'text/x-wiki':
                continue

            prefix = ''
            if line.startswith(' ') or verbatim:
                if not verbatim:
                    fout.write('```\n')
                    verbatim = True
                elif line and not line.startswith(' '):
                    fout.write('\n```')
                    verbatim = False

            if not verbatim:
                while line and line[0] == line[-1] == '=':
                    line = line[1:-1]
                    prefix = prefix + '#'

                line = line.replace("'''", '**')
                line = line.replace("''", '_')
                line = RE_CODE.sub(repl='\n```\n', string=line)
                line = line.replace('<tt>', '_').replace('</tt>', '_')

                while True:
                    match = RE_INTERNAL_LINK.search(line)
                    if not match:
                        break
                    lline = list(line)
                    a, b = match.span()
                    fname, txt = match.groups()
                    txt = (txt or fname).lstrip('|')
                    lline[a: b] = list('[{}]({})'.format(txt, link_to_fname(fname)))
                    line = ''.join(lline)

                while True:
                    match = RE_EXTERNAL_LINK.search(line)
                    if not match:
                        break
                    lline = list(line)
                    a, b = match.span()
                    link, txt = match.groups()
                    txt = (txt or link).strip()
                    lline[a: b] = list('[{}]({})'.format(txt, link))
                    line = ''.join(lline)

                line = line.replace('&gt;', '>').replace('&lt;', '<').replace('&amp;', '&')
                if line.startswith('*') and line[:2] not in ('* ', '**'):
                    line = '* {}'.format(line[1:])

            fout.write(prefix + line + '\n')


# given your html as the variable 'html'
with open(sys.argv[1], 'rt') as f:
    soup = BS(f.read(), "xml")

already_done = get_file_names('./docs')

pages = soup.find_all('page')
for page in pages:
    title = page.title.text
    if not title.startswith('ZX BASIC:'):
        continue
    title = title[9:]
    write_page(title, page.text, page.sha1.text, already_done)