import re
import pynvim

@pynvim.plugin
class Translator(object):
    def __init__(self, nvim):
        self.nvim = nvim

    @pynvim.command('JsonFold', range=True, nargs='*', sync=True)
    def command_handler(self, args, range):
        bracketCount = 0
        oneLine = ""
        shouldDecrese = False
        lines = []
        self.nvim.feedkeys("gg=G")
        self.nvim.command("%!python -m json.tool")
        for el, line in enumerate(self.nvim.current.buffer):
            for ec, char in enumerate(line):
                if (char == "{"):
                    bracketCount += 1
                elif (char == "}"):
                    bracketCount -= 1
            if (bracketCount == 4 and "{" in line):
                    oneLine += line
            elif (bracketCount == 3 and "}" in line):
                    oneLine += line.lstrip()
                    lines.append(oneLine)
                    oneLine = ""
            elif (bracketCount >= 4):
                    oneLine += line.lstrip()
            else:
                lines.append(line)
        self.nvim.current.buffer[:] = lines
