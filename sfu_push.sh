make html
rsync --delete -avz _build/ amiralis@fraser.sfu.ca:/home/amiralis/pub_html
