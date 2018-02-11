# ============================================================================
# FILE: dp_main.py
# AUTHOR: Shougo Matsushita <Shougo.Matsu at gmail.com>
# License: MIT license
# ============================================================================

import sys
import io

from neovim import attach


def attach_vim(serveraddr):
    if len(serveraddr.split(':')) == 2:
        serveraddr, port = serveraddr.split(':')
        port = int(port)
        vim = attach('tcp', address=serveraddr, port=port)
    else:
        vim = attach('socket', path=serveraddr)

    # sync path
    for path in vim.call(
            'globpath', vim.options['runtimepath'],
            'rplugin/python3', 1).split('\n'):
        sys.path.append(path)
    # Remove current path
    del sys.path[0]

    return vim


class RedirectStream(io.IOBase):
    def __init__(self, handler):
        self.handler = handler

    def write(self, line):
        self.handler(line)

    def writelines(self, lines):
        self.handler('\n'.join(lines))


def main(serveraddr):
    vim = attach_vim(serveraddr)
    from deoplete.child import Child
    from deoplete.util import error_tb
    sys.stdout = RedirectStream(lambda data: vim.out_write(data))
    try:
        child = Child(vim)
        child.main()
    except Exception:
        error_tb(vim, 'Error in child')


if __name__ == '__main__':
    main(sys.argv[1])
