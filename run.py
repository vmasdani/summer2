#!/bin/python3

import argparse
import subprocess
import sys

parser = argparse.ArgumentParser(
    description='===== Summer CLI: Python 3 =====')
parser.add_argument(
    'type', help='Run type [ build-tailwind | dev | prod | serve ]')

args = parser.parse_args()
type = args.type

try:
    if type == 'prod':
        print('Running prod')

    elif type == 'build-tailwind':
        subprocess.run('postcss tailwind.css -o css/tailwind.css',
                       cwd='.', shell=True)

    elif type == 'dev':
        print('Running dev')
        subprocess.run('npm run dev',
                       cwd='.', shell=True)

    else:
        print('Error: run type irrelevant. [dev | prod | serve]')
        sys.exit(1)

except KeyboardInterrupt:
    pass

finally:
    sys.exit(1)
