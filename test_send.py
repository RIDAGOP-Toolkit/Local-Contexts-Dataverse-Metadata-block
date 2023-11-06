import json

import requests

url = "https://ridagop.net/"
doi = "doi:10.5072/FK2/HWMAPH"
api_key = "84a1ebba-357b-4cd6-b965-8810a8e3866d"

data = json.load(open("update_md.json", encoding="utf-8"))

def update():

    resp = requests.put(url + f"/api/datasets/:persistentId/versions/:draft?persistentId={doi}",
                 json.dumps(data, ensure_ascii=False),
                 headers={
                     "X-Dataverse-key": api_key,
                 })

    print(resp.status_code, resp.text)

def get():
    resp = requests.get(url + f"/api/datasets/:persistentId/?persistentId={doi}",
                        headers={
                            "X-Dataverse-key": api_key,
                        })
    print(resp.status_code, resp.text)
    return resp.json()

json.dump(get(), open("temp.json", "w", encoding="utf-8"), ensure_ascii=False, indent=4)
# update()