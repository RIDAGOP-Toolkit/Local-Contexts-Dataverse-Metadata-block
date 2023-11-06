import sys
from xml.etree import ElementTree as ET
import os
import shutil
from urllib import request

# read the parameters. there should be at least 1.
arguments = len(sys.argv) - 1
if arguments < 1:
    print("Not enough arguments. Add the path to the solr schema.xml file as the first argument.")
    exit(1)

# 1. the path to the solr schema.xml file
solr_schema_path = sys.argv[1]

generated_fields_file_path = None

if arguments > 1:
    # 2. the path or url to the generated fields file
    file_path_or_url = sys.argv[2]
    # check if it is a path or an url
    if os.path.exists(file_path_or_url):
        generated_fields_file_path = file_path_or_url
    else:
        generated_fields_endpoint = file_path_or_url
else:
    generated_fields_endpoint = "http://localhost:8080/api/admin/index/solr/schema"
    generated_fields_file_path = None


create_schema_backup = True

if not os.path.exists(solr_schema_path):
    print("No schema.xml file found. Exiting.")
    exit(1)

if create_schema_backup:
    if os.path.exists(solr_schema_path) and not os.path.exists("schema.backup.xml"):
        shutil.copyfile(solr_schema_path, "schema.backup.xml")

xml_fields_text = ""


if generated_fields_file_path != None:
    # get generated fields from solr
    if not os.path.exists(generated_fields_file_path):
        print("No generated fields file found. Exiting.")
        exit(1)
    with open(generated_fields_file_path, "r") as generated_fields_file:
        xml_fields_text = generated_fields_file.read()
        # print(xml_fields_text)

elif generated_fields_endpoint:
    # get generated fields from solr, with vanilla python
    response = request.urlopen(generated_fields_endpoint)
    # Check if the request was successful
    if response.status == 200:
        # Get the response body content as text
        xml_fields_text = response.read().decode("utf-8")
    else:
        print(f"Request failed with status code {response.status}")
        exit(1)


# its not a proper xml file, so we need to add the root element
# print(xml_fields_text)
xml_fields_text = f'<?xml version="1.0" encoding="UTF-8" ?><root>{xml_fields_text}</root>'
#print(xml_fields_text)
tree = ET.fromstring(xml_fields_text)
# get the attribute name
generated_fields = {field.attrib["name"]: field for field in tree.findall("field")}
generated_copyFields = {field.attrib["source"]: field for field in tree.findall("copyField")}

# open schema.xml file
with open(solr_schema_path, "r") as schema_file:
    schema = schema_file.read()
    # parse xml
    # create ElementTree object
    tree = ET.fromstring(schema)

    # get a list of field tags
    fields = tree.findall("field")
    field_names = [field.attrib["name"] for field in fields]
    # get the difference between the two
    missing_fields = set(generated_fields.keys()) - set(field_names)
    # print(f"Missing fields: {missing_fields}")
    for field in missing_fields:
        print(ET.tostring(generated_fields[field], encoding='unicode').strip())

    copyFields = tree.findall("copyField")
    copyField_sources = [copyField.attrib["source"] for copyField in copyFields]
    missing_copyFields = set(generated_copyFields.keys()) - set(copyField_sources)
    # print(f"Missing fields: {missing_copyFields}")
    for field in missing_copyFields:
        print(ET.tostring(generated_copyFields[field], encoding='unicode').strip())
