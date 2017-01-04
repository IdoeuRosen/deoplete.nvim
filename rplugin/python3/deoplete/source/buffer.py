# ============================================================================
# FILE: buffer.py
# AUTHOR: Shougo Matsushita <Shougo.Matsu at gmail.com>
# License: MIT license
# ============================================================================

from .base import Base

from itertools import chain
from deoplete.util import parse_buffer_pattern, getlines


class Source(Base):

    def __init__(self, vim):
        super().__init__(vim)

        self.name = 'buffer'
        self.mark = '[B]'
        self.__buffers = {}
        self.__max_lines = 5000

    def on_event(self, context):
        if ((context['bufnr'] not in self.__buffers) or
                context['event'] == 'BufWritePost'):
            self.__make_cache(context)

    def gather_candidates(self, context):
        self.on_event(context)

        same_filetype = context['vars'].get(
            'deoplete#buffer#require_same_filetype', True)
        candidates = (x['candidates'] for x in self.__buffers.values()
                      if not same_filetype or
                      x['filetype'] in context['filetypes'] or
                      x['filetype'] in context['same_filetypes'])
        return [{'word': x} for x in chain(*candidates)]

    def __make_cache(self, context):
        try:
            self.__buffers[context['bufnr']] = {
                'filetype': context['filetype'],
                'candidates': parse_buffer_pattern(
                    getlines(self.vim),
                    context['keyword_patterns'],
                    context['complete_str'])
            }
        except UnicodeDecodeError:
            return []
