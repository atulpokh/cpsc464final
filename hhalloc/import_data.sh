#!/bin/bash
#
# Imports data into sqlite from hh.csv and hu.csv
# Assumes the first line of csv file is the header
# TODO: make this part of hhalloc
# TODO: Change data types of imported columns
# 

echo "Stripping headers from csv files..."
tail -n +2 hh.csv > hh_nohead.csv
tail -n +2 hu.csv > hu_nohead.csv

echo "Importing the following tables into hhalloc.sqlite..."
rm hhalloc.sqlite
cat import.sql | sqlite3 hhalloc.sqlite 
echo ""
echo "Table hh: "
sqlite3 hhalloc.sqlite "PRAGMA table_info(hh)"
echo ""
echo "First five rows of hh..."
sqlite3 hhalloc.sqlite "select * from hh limit 5"
echo ""
echo "Table hu: "
sqlite3 hhalloc.sqlite "PRAGMA table_info(hu)"
echo ""
echo "First five rows of hu..."
sqlite3 hhalloc.sqlite "select * from hu limit 5"
echo ""
echo "Done."
