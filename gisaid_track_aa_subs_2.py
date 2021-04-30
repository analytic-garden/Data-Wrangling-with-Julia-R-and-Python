#!/home/bill/anaconda3/envs/bio2/bin/python
# -*- coding: utf-8 -*-
"""
gisaid_track_aa_subs.py
    Create a CSV file of AA substitutions in human sequences by date and country from a
    GISAID metafile.

@author: Bill Thompson
@license: GPL 3
@copyright: 2021_04_28
"""
import argparse
import sys
import re
import datetime
import pandas as pd

def GetArgs():
    def ParseArgs(parser):
        class Parser(argparse.ArgumentParser):
            def error(self, message):
                sys.stderr.write('error: %s\n' % message)
                self.print_help()
                sys.exit(2)
                
        parser = Parser(description='Reformat GISAID metefile.')
        parser.add_argument('-i', '--input_file',
                            required = True,
                            help = 'GISAID metafile (required).',
                            type = str)
        parser.add_argument('-o', '--output_file',
                            required = True,
                            help = 'Output CSV file.',
                            type = str)
        parser.add_argument('-s', '--host',
                            required = False,
                            help = 'Virus host species (default = Human).',
                            default = "Human",
                            type = str)

        return parser.parse_args()

    parser = argparse.ArgumentParser()
    args = ParseArgs(parser)
    
    return args

def check_date(date_str):
    """
    Check that data is formatted as yyyy-mm-dd.

    @arguments
    data_str - String
        A string representing a date.

    @returns
    A Date in yyyy-mm-dd of nothing if string is not properly formatted.
    """
    p = re.compile(r"^\d\d\d\d\-\d\d\-\d\d$")
    if p.match(date_str) is None:
        return None

    return datetime.datetime.strptime(date_str, "%Y-%m-%d")

def main():
    args = GetArgs()
    meta_file = args.input_file
    out_file = args.output_file
    host = args.host
    
    df = pd.read_csv(meta_file,
                     sep = '\t', 
                     dtype={'Location': str, "Variant": str, "Is reference?": str})

    # create an empty dataframe
    df2 = pd.DataFrame(columns = ["Date", "Country", "Virus_name",
                                  "Accession_ID", "Pango_lineage",
                                  "AA_subs"])

    for i in range(df.shape[0]):
        if i % 10000 == 0:
            print(i)
        
        if df.loc[i, "Host"] != host:
            continue

        if df.loc[i, "Pango lineage"] == "":
            continue

        date = check_date(df.loc[i, "Collection date"])
        if date is None:
            continue

        country = df.loc[i, "Location"].split("/")[1].strip()
        
        aas = df.loc[i, "AA Substitutions"][1:len(df.loc[i, "AA Substitutions"])-1].split(",")
        if aas is None:
            continue

        for aa in aas:
            df2 = df2.append({"Date": date,
                              "Country": country, 
                              "Virus_name": df.loc[i, "Virus name"],
                              "Accession_ID": df.loc[i, "Accession ID"],
                              "Pango_lineage": df.loc[i, "Pango lineage"],
                              "AA_sub": aa}, ignore_index = True)
    
    df2.to_csv(out_file, index = False)

if __name__ == '__main__':
    main()