"""

Arguments:
- hogehoge.txt

Exceptions:
- IO Error when file was not found

Returns:
- a list of all words in hogehoge.txt

Requires:
sys

"""

import sys


def load(file):

    try:
        with open(file) as in_file:
            loaded_txt = in_file.read().strip().split('\n')
            loaded_txt = [x.lower() for x in loaded_txt]
            return loaded_txt
    except IOError as e:
        print(f'{e}\nError opening {file}. Terminating program',
              file=sys.stderr)
        sys.exit(1)
