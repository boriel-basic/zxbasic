#!/usr/bin/env python
# -*- coding: utf-8 -*-

from bs4 import BeautifulSoup as BS
import sys
import re

RE_CODE = re.compile('<zxbasic>|</zxbasic>|<freebasic>|</freebasic>')


def write_page(title, text, sha1):
    fname = title.replace(' ', '_') + '.md'
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
                    fout.write('```\n')
                    verbatim = False
                print(line, sha1)
            else:
                while line and line[0] == line[-1] == '=':
                    line = line[1:-1]
                    prefix = prefix + '#'

                line = line.replace("'''", '**')
                line = RE_CODE.sub(repl='```\n', string=line)
                line = line.replace('<tt>', '_').replace('</tt>', '_')
            fout.write(prefix + line + '\n')


# given your html as the variable 'html'
with open(sys.argv[1], 'rt') as f:
    soup = BS(f.read(), "xml")

pages = soup.find_all('page')
for page in pages:
    title = page.title.text
    if not title.startswith('ZX BASIC:'):
        continue
    title = title[9:]
    write_page(title, page.text, page.sha1.text)
