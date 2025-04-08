# A simple project to proof that simple things can work effectively

This project implements a simple availability context for a ticket reservation system. Used technologies are:
- .Net 9 & C#
- HTMX
- Portgres
- Just it

For test purposes k6 is used to simulate a load test.

# Running

## Prerequisites

- Podman

## Scripts

- setup.sh -> create the database and populate it with some data
- load.sh -> run the load test, don't forget to run the app before
- clean.sh -> remove the database

# Contributing

If you found any typos, bugs or have any suggestion feel free to make a PR or contact with me.

# License
This project is licensed under the MIT License 
