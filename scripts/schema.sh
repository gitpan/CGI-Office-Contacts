#!/bin/bash

dbigraph.pl --dsn=dbi:Pg:dbname=contacts --user=contact --pass=contact --as=png > contacts.schema.png

echo Wrote contacts.schema.png
