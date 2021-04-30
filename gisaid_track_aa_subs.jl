#=
gisaid_track_aa_subs.jl
    Create a CSV file of AA substituions in human sequences by date and country from a
    GISAID metafile.

@author
    Bill Thompson
@copyright
    GPL 3
@date
    2021_04-25
=#

using DataFrames
using CSV
using Dates
using ArgParse

function GetArgs()
    # read arguments from command line
    # from https://argparsejl.readthedocs.io/en/latest/argparse.html
    s = ArgParseSettings(description = "Extract AA substituions from GISAID metefile.",
                         version = "1.0",
                         add_version = true)

    @add_arg_table s begin
        "--input_file", "-i"
        required = true
        help = "GISAID meteafile, (required)."
        arg_type = String

        "--output_file", "-o"
        required = true
        help = "CSV file with results. (required)."
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

function main()
    #=
    Check sequences for valid date and host. 
    Write a CSV file with a row for each AA substitution.
    =#
    args = GetArgs()
    meta_table = args["input_file"]
    aa_subs_table = args["output_file"]
    host = args["host"]
   
    # Read the metfile and then make a new empty dataframe.
    df = DataFrame(CSV.File(meta_table, delim = '\t'))
    df2 = DataFrame(Date = Date[], 
                    Country = String[],
                    Virus_name = String[], 
                    Accession_ID = String[], 
                    Pango_lineage = String[],
                    AA_subs = String[])

    for i in 1:size(df)[1]
        if i % 10000 == 0
            println(i)
        end
        
        if df[i, "Host"] != host
            continue
        end

        if ismissing(df[i, "Pango lineage"])
            continue
        end

        date = check_date(df[i, "Collection date"])
        if isnothing(date)
            continue
        end
        
        aas = split(df[i, "AA Substitutions"][2:end-1], ",")
        if isempty(aas)
            continue
        end

        country = strip(split(df[i, "Location"], "/")[2], ' ')

        for aa in aas
            # Debugging - just in case.
            # println(i, [date,
            #           country,
            #           df[i, "Virus name"],
            #           df[i, "Accession ID"],
            #           df[i, "Pango lineage"],
            #           aa])
            push!(df2, [date,
                        country, 
                        df[i, "Virus name"],
                        df[i, "Accession ID"],
                        df[i, "Pango lineage"],
                        aa])
        end
    end

    CSV.write(aa_subs_table, df2)
end

main()