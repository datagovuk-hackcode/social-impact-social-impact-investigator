#!/bin/sh
mongoimport -d social_impact -c most_reputable --type csv --file most_reputable.csv --headerline --drop
mongoimport -d social_impact -c best_regarded --type csv --file best_regarded.csv --headerline --drop
mongoimport -d social_impact -c vigeo --type csv --file vigeo.csv --headerline --drop
mongoimport -d social_impact -c cdp --type csv --file cdp.csv --headerline --drop
