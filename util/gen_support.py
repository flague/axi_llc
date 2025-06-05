
def _tabs(n):
    n = 2 + n
    return "\t" * n

class Arg(object):
    def __init__(self, name, description, csr_address = None) -> None:
        self.name = name
        self.description = description
        self.swaccess = "rw"
        self.hwaccess = "hrw"
        self.resval = "0"
        self.bits = "31:0"
        self.csr_address = csr_address

    def __str__(self) -> str:
        return f"{_tabs(0)}"+"{\n" +\
            f"{_tabs(1)}name: \"{self.name}\",\n" +\
            f"{_tabs(1)}desc: \"{self.description}\",\n" +\
            f"{_tabs(1)}fields: [\n" +\
            f"{_tabs(2)}"+"{\n" +\
            f"{_tabs(3)}bits: \"{self.bits}\",\n" +\
            f"{_tabs(3)}name: \"{self.name}\",\n" +\
            f"{_tabs(3)}desc: \"{self.description}\",\n" +\
            f"{_tabs(3)}swaccess: \"{self.swaccess}\",\n" +\
            f"{_tabs(3)}hwaccess: \"{self.hwaccess}\",\n" +\
            f"{_tabs(3)}resval: \"{self.resval}\",\n" +\
            f"{_tabs(2)}"+"}\n" +\
            f"{_tabs(1)}"+"]\n" +\
            f"{_tabs(1)}swaccess: \"ro\",\n" +\
            f"{_tabs(1)}hwaccess: \"none\",\n" +\
            f"{_tabs(1)}resval: \"0\",\n" +\
            f"{_tabs(0)}"+"},\n"

class RefArg(Arg):
    def __init__(self, name, description) -> None:
        super().__init__(name, description)

class Kernel(Arg):
    def __init__(self, name, description) -> None:
        super().__init__(name, description)
        self.swaccess = "rw"
        self.hwaccess = "hro"
        self.match = None
        self.mask = None

def parseEncodingFile(file, kernels):
    import re

    regexp = re.compile(r".*XMK(\d+)_W (.*)")

    with open(file, 'r') as f:
        for line in f:
            match = regexp.match(line)
            if match:
                i = int(match.group(1))
                if ("MATCH" in line):
                    kernels[i].match = match.group(2)
                elif ("MASK" in line):
                    kernels[i].mask = match.group(2)

