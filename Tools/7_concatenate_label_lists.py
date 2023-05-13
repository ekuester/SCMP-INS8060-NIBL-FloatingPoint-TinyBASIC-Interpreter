#!/usr/bin/env python3
# concatenate label lists to a big one
# default file name for big label file is 'big_labels.json'

import json, re, sys
 
def usage():
    print("concatenate label lists to a big one")
    print("get label list from json files")
    print("usage: ./7_concatenate_label_lists.py json_list_files")
    print("give at least two json_files without .json extension")
    print("example: ./7_concatenate_label_lists.py D802 DB00 DFC1")
    print("Erich Küster April 2023")
    quit()

argc = len(sys.argv)
if argc <= 2:
    usage()
files = []
r = range(1, argc)
for i in r:
    files.append(sys.argv[i])
big_labels = []
for file in files:
    f_name = file + '.json'
    with open(f_name, 'r') as json_f:
        l_list = json.load(json_f)
        big_labels.extend(l_list)
# delete duplicates and sort labels
real_labels = list(set(big_labels))
real_labels.sort()
# now look into names files
names_real = {}
labels_rest = []
for file in files:
    f_name = 'names_real_' + file + '.json'
    with open(f_name, 'r') as json_f:
        names = json.load(json_f)
        for label in real_labels:
            ignore = True
            if label in names.keys():
                name = names[label]
                print(f'{label}:{name} ', end='')
                result = input("accept? > ").lower()
                if not result:
                    result = "y"
                if result[0] != 'n':
                    ignore = False
                    names_real[label] = name
            if ignore:
                print(f'{label}: ')
                labels_rest.append(label)
with open ('names_merged.json', 'w') as json_f:
    json_f.write(json.dumps(names_real))
with open ('labels_rest.json', 'w') as json_f:
    json_f.write(json.dumps(labels_rest))
print("Done!")

