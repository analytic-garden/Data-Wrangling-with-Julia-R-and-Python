#=
gisaid_track_aa_subs_2.jl
    Create a CSV file of AA substitutions in human sequences by date and country from a
    GISAID metafile.
    version 1.1

@author Bill Thompson
@copyright 2021_04-28
@dlicense GPL 3
=#

using DataFrames
using CSV
using Dates
using ArgParse

function GetArgs()
    # read arguments from command line
    # from https://argparsejl.readthedocs.io/en/latest/argparse.html
    s = ArgParseSettings(description = "Extract AA substituions from GISAID metefile.",
                         version = "1.1",
                         add_version = true)

    @add_arg_table s begin
        "--input_file", "-i"
        required = true
        help = "GISAID meteafile (required)."
        arg_type = String

        "--output_file", "-o"
        required = true
        help = "CSV file with results (required)."
        arg_type = String

        "--host", "-s"
        required = false
        help = "Host species (default = Human)."
        arg_type = String
        default = "Human"
    end

    return parse_args(s)
end

function check_date(date_str)
    #=
    Check that data is formatted as yyyy-mm-dd.

    @arguments
    data_str - String
        A string representing a date.

    @returns
    A Date in yyyy-mm-dd of nothing if string is not properly formatted.
    =#
    r = r"^\d\d\d\d\-\d\d\-\d\d$"
    if isnothing(match(r, date_str))
        return nothing
    end

    return Date(date_str, "yyyy-mm-dd")
end

function country_from_location(location_str)
    #=
    Split and trim country from a GISAID Location. 
    Country is the second term in Location.

    @arguments
    location_str - String   
        A Location value from GISAID.
        
    @returns
    A String containing the country name.
    =#
    return strip(split(location_str, "/")[2], ' ')
end

function main()
    #=
    Check sequences for valid date and host. 
    Write a CSV file with a row for each AA substitution.
    =#
    args = GetArgs()
    meta_table = args["input_file"]
    aa_subs_table = args["output_file"]
    host = args["host"]
   
    # Read the metfile.
    df = DataFrame(CSV.File(meta_table, delim = '\t'))
    
    # select columns and filter the data
    df2 = df[!, ["Virus name", "Accession ID", 
                "Collection date", "Location",
                "Pango lineage", "AA Substitutions",
                "Host"]]

    
    df2 = df2[df2[!, :Host] .== host, :] # filter host and remove NAs from lineade
    df2 = dropmissing(df2, "Pango lineage")

    # Throw out invalid dates
    df2[!, "Date"] = check_date.(df2[!, "Collection date"])
    df2 = df2[df2[!, "Date"] .!== nothing, :]

    df2[!, "Country"] = country_from_location.(df2[!, "Location"])

    # Clean up AA substitutions and explode AA into rows
    df2[!, "AA Substitutions"] = chop.(df2[!, "AA Substitutions"], head = 1, tail = 1)
    df2[!, "AA Substitutions"] = split.(df2[!, "AA Substitutions"], ",")
    df2 = flatten(df2, ["AA Substitutions"])

    select!(df2, Not(["Location", "Host", "Collection date"])) # We don't need these

    CSV.write(aa_subs_table, df2) 
end

main()