# Script to generate coverage report
# Usage: vsim -c -do "do generate_coverage_report.do"

# 1. Create output directory
file mkdir coverage_report

# 2. Merge all coverage files
# Find all .ucdb files in coverage_db directory
set all_ucdb_files [glob -nocomplain coverage_db/*.ucdb]
set ucdb_files [list]

# Filter out the merged file itself to avoid input==output error
foreach f $all_ucdb_files {
    if { [file tail $f] != "merged_coverage.ucdb" } {
        lappend ucdb_files $f
    }
}

if { [llength $ucdb_files] > 0 } {
    puts "Merging coverage files: $ucdb_files"
    
    # Delete old merged file if exists to ensure fresh start
    file delete -force coverage_db/merged_coverage.ucdb
    
    # Merge into a single file
    vcover merge -out coverage_db/merged_coverage.ucdb {*}$ucdb_files
    
    # 3. Generate HTML Report directly from merged file
    puts "Generating HTML report..."
    vcover report -html -htmldir coverage_report -details -threshL 50 -threshH 90 coverage_db/merged_coverage.ucdb
    
    # 4. Generate Text Summary (to console)
    puts "----------------------------------------------------------------"
    puts "COVERAGE SUMMARY"
    puts "----------------------------------------------------------------"
     vcover report -cvg -details coverage_db/merged_coverage.ucdb
    
    puts "----------------------------------------------------------------"
    puts "Report generated at: coverage_report/index.html"
    puts "----------------------------------------------------------------"
    
    # Close database
    # vcover close
} else {
    puts "No coverage files found in coverage_db/"
}

quit
