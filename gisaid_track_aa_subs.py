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
import warnings
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

def main():
    args = GetArgs()
    meta_file = args.input_file
    out_file = args.output_file
    host = args.host
    
    df = pd.read_csv(meta_file,
                     sep = '\t', 
                     dtype={'Location': str, "Variant": str, "Is reference?": str})
    
    # select columns and filter the data
    df2 = df.filter(["Virus name", "Accession ID", 
                     "Collection date", "Location",
                     "Pango lineage", "AA Substitutions",
                     "Host"])

    # country is the second part of location                      
    df2["Country"] = df2.Location.str.split("/", expand = True)[1] 

    df2 = df2[df2["Host"] == host]   # filter host and remove NAs from lineage
    df2 = df2.dropna(subset = ["Pango lineage"])

    df2 = df2.drop(["Location", "Host"], axis = 1) # We don't need these anymore

    # throw out malformed dates
    # regex for dates
    p = re.compile(r"^\d\d\d\d\-\d\d\-\d\d$")
    df2 = df2[df2["Collection date"].apply(lambda x: True if p.match(x) else False)]

    # clean up Country and AAs
    # these throw warnings, but they are actually OK.
    with warnings.catch_warnings():
        warnings.simplefilter("ignore")
        df2["Country"] = df2["Country"].str.strip()
        df2["AA Substitutions"] = df2["AA Substitutions"].str.strip("()")
    
    # Explode AA substitutions. Each AA has it's own row
    # from https://stackoverflow.com/questions/50731229/split-cell-into-multiple-rows-in-pandas-dataframe
    df2 = df2.set_index(["Virus name", "Accession ID", 
                     "Collection date", "Country",
                     "Pango lineage"]).apply(lambda x: x.str.split(',').explode()).reset_index()
    
    df2.to_csv(out_file, index = False)

if __name__ == '__main__':
    main()