#!/usr/bin/env python3
"""Download raw Ganjoor API responses for a poet into a resumable on-disk cache."""
import json, os, subprocess, sys, time

API = "https://api.ganjoor.net/api/ganjoor"
POEM_Q = ("verseDetails=true&recitations=true&catInfo=false&rhymes=false&next=false"
          "&prev=false&images=false&songs=false&comments=false&navigation=false&relatedpoems=false")

def get(url, path):
    if os.path.exists(path):
        with open(path, encoding="utf-8") as f:
            return json.load(f)
    for attempt in range(5):
        try:
            # curl uses the system trust store (python.org builds often lack CA certs)
            out = subprocess.run(["curl", "-sSfL", "-m", "30", "-A", "Azbar-content-builder/1.0", url],
                                 check=True, capture_output=True).stdout
            data = json.loads(out.decode("utf-8"))
            with open(path, "w", encoding="utf-8") as f:
                json.dump(data, f, ensure_ascii=False)
            time.sleep(0.25)
            return data
        except Exception as e:
            print("retry", url, e, file=sys.stderr); time.sleep(2 * (attempt + 1))
    raise SystemExit(f"failed: {url}")

def walk_cat(cat_id, cache):
    d = get(f"{API}/cat/{cat_id}?poems=true", os.path.join(cache, f"cat-{cat_id}.json"))
    for p in d["cat"].get("poems") or []:
        get(f"{API}/poem/{p['id']}?{POEM_Q}", os.path.join(cache, f"poem-{p['id']}.json"))
    for c in d["cat"].get("children") or []:
        walk_cat(c["id"], cache)

if __name__ == "__main__":
    poet_id, cache = int(sys.argv[1]), sys.argv[2]
    os.makedirs(cache, exist_ok=True)
    d = get(f"{API}/poet/{poet_id}", os.path.join(cache, f"poet-{poet_id}.json"))
    for c in d["cat"]["children"]:
        walk_cat(c["id"], cache)
    print("done", len(os.listdir(cache)), "files")
