#!/usr/bin/env python3
'''
Input a CSV that has ip and dns names.
Create a file in the format like /etc/hosts
'''

__version__ = '0.0.1'
__date__ = '2023-10-27'
__author__ = 'Todd Wintermute'

import argparse
import csv
import os
import pathlib
import sys

app = os.environ['APPNAME']
csv_file = pathlib.Path(f'/opt/{app}/upload/hosts.csv')
hosts_file = pathlib.Path('/etc/banner_add_hosts')

def parse_arguments():
    """Create command line arguments and auto generated help"""
    parser = argparse.ArgumentParser(
        description=__doc__,
        epilog='Enjoy!',
        )
    parser.add_argument(
        '-v', '--version',
        help='show the version number and exit',
        action='version',
        version=f'Version: %(prog)s  {__version__}  ({__date__})',
        )
    parser.add_argument(
        '-i', '--csv_file',
        nargs='?',
        type=pathlib.Path,
        default=csv_file,
        help=f'Input CSV dns hosts file (default={csv_file})',
        )
    parser.add_argument(
        '-o', '--hosts_file',
        nargs='?',
        default=hosts_file,
        type=pathlib.Path,
        help=f'Ouput /etc/hosts like file (default={hosts_file})',
        )
    return parser

def read_csv(csv_file, columns):
    """Read a pathlib filename containing CSV data. 
    Return a list of dictionaries per row of csv data.
    """
    if not csv_file.exists():
        print(f'[ERROR] `{csv_file.name}` was not found. Exiting.')
        sys.exit()
    with open(csv_file) as f:
        t = f.readlines()
    csv_reader = csv.DictReader(t, fieldnames=columns, restkey='aliases')
    original_column_names = next(csv_reader)
    csvdata = [row for row in csv_reader if row]
    return csvdata

parser = parse_arguments()
args = parser.parse_args()
csv_file = args.csv_file
hosts_file = args.hosts_file

columns = ['ip', 'name']
csvdata = read_csv(csv_file, columns)

ipdict = {d['ip']: [] for d in csvdata}
for row in csvdata:
    if row['name'] and (row['name'] not in ipdict[row['ip']]):
        ipdict[row['ip']].append(row['name'])
    if 'aliases' in row:
        for alias in row['aliases']:
            if alias not in ipdict[row['ip']]:
                ipdict[row['ip']].append(alias)

hosts_rows = ['\t'.join((ip,*names)) for ip, names in ipdict.items()]
hosts_text = '\n'.join(hosts_rows) + '\n'

if hosts_text:
    hosts_file.write_text(hosts_text)
    print(f'Added hosts to {hosts_file}')
else:
    print(f'No entries found. Nothing added to {hosts_file}')
print(f'Current DNS entries:')
print(hosts_text)
