#!/usr/bin/env python3
"""Build an AzBar content pack from the Ganjoor API (stdlib only; network via curl).

Usage:
  python3 -I Tools/fetch_ganjoor.py --poet-id 2 --slug hafez \
      [--out AzBar/Resources/Content/pack-hafez.json] [--cache Tools/.cache/poet-2] \
      [--delay 0.5] [--only-cats 24,25] [--no-summaries]

--only-cats takes category ids at any depth: ancestors stay navigable, other siblings become
onlineOnly refs, and only missing selected files are fetched (never non-selected categories).

Every raw response is cached as {cache}/{poet|cat|poem}-{id}.json, so re-runs resume and
a fully cached poet needs no network. --no-summaries omits all Ganjoor poem/couplet summaries
(meanings) from the pack. The couplet-building algorithm (docs/ARCHITECTURE.md)
must stay identical to AzBarKit's GanjoorMapper.
"""
import argparse
import datetime
import json
import os
import re
import subprocess
import sys
import time

API = "https://api.ganjoor.net/api/ganjoor"
POEM_QUERY = ("verseDetails=true&recitations=true&catInfo=false&rhymes=false&next=false&prev=false"
              "&images=false&songs=false&comments=false&navigation=false&relatedpoems=false")
USER_AGENT = "AzBar-ContentTool/1.0"
SIZE_LIMIT = 15 * 1024 * 1024
SPACES = re.compile(r"[ \t]+")


# ---------- fetching ----------

def curl_json(url, delay):
    last = None
    for attempt in range(5):
        try:
            out = subprocess.run(
                ["curl", "-sSfL", "-m", "30", "-A", USER_AGENT, url],
                check=True, capture_output=True).stdout
            data = json.loads(out.decode("utf-8"))
            time.sleep(delay)
            return data
        except (subprocess.CalledProcessError, ValueError) as e:
            last = e
            time.sleep(2 ** attempt)
    raise SystemExit(f"failed after retries: {url}: {last}")


def cached(kind, ident, url, cache, delay):
    path = os.path.join(cache, f"{kind}-{ident}.json")
    if os.path.exists(path):
        with open(path, encoding="utf-8") as f:
            return json.load(f)
    data = curl_json(url, delay)
    os.makedirs(cache, exist_ok=True)
    with open(path, "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False)
    return data


# ---------- mapping (section 3b) ----------

def clean(text):
    if text is None:
        return ""
    return SPACES.sub(" ", text.replace("\r", "")).strip()


def build_couplets(verses):
    ordered = sorted(verses, key=lambda v: v["vOrder"])
    groups = {}
    order = []  # keys in first-seen order
    for v in ordered:
        ci = v.get("coupletIndex")
        key = ci if ci is not None else -v["vOrder"]
        if key not in groups:
            groups[key] = {"null": ci is None, "verses": []}
            order.append(key)
        groups[key]["verses"].append(v)
    couplets = []
    for key in order:
        g = groups[key]
        vs = g["verses"]
        first_pos = vs[0].get("versePosition")
        if g["null"]:
            kind = "paragraph"
        elif len(vs) >= 2 and first_pos in (0, 2):
            kind = "beyt"
        elif len(vs) == 1 and first_pos in (4, 0):
            kind = "single"
        else:
            kind = "paragraph"
        summary = ""
        for v in (vs if INCLUDE_SUMMARIES else []):
            s = clean(v.get("coupletSummary"))
            if s:
                summary = s
                break
        c = {"index": key, "kind": kind,
             "verses": [{"id": v["id"], "order": v["vOrder"], "position": v.get("versePosition") or 0,
                         "text": clean(v.get("text"))} for v in vs]}
        if summary:
            c["summary"] = summary
        couplets.append(c)
    return couplets


def build_recitations(raw):
    out = []
    items = [r for r in (raw or []) if (r.get("mp3Url") or "").strip()]
    items.sort(key=lambda r: r.get("audioOrder") or 0)  # stable
    for r in items:
        rec = {"id": r["id"], "artist": clean(r.get("audioArtist")), "mp3Url": r["mp3Url"].strip(),
               "order": r.get("audioOrder") or 0, "type": r.get("recitationType") or 0,
               "synced": bool(r.get("inSyncWithText"))}
        if (r.get("xmlText") or "").strip():
            rec["syncUrl"] = r["xmlText"].strip()
        out.append(rec)
    return out


def build_poem(raw, poet_id, category_id):
    p = {"id": raw["id"], "poetId": poet_id, "categoryId": category_id,
         "title": clean(raw.get("title")), "fullTitle": clean(raw.get("fullTitle")),
         "urlSlug": raw.get("urlSlug") or "", "fullUrl": raw.get("fullUrl") or ""}
    summary = clean(raw.get("poemSummary")) if INCLUDE_SUMMARIES else ""
    if summary:
        p["summary"] = summary
    p["couplets"] = build_couplets(raw.get("verses") or [])
    recs = build_recitations(raw.get("recitations"))
    if recs:
        p["recitations"] = recs
    return p


def memorizable_count(poem):
    return sum(1 for c in poem["couplets"] if c["kind"] != "paragraph" and c["index"] >= 0)


# ---------- main ----------

INCLUDE_SUMMARIES = True


def main():
    global INCLUDE_SUMMARIES
    ap = argparse.ArgumentParser()
    ap.add_argument("--poet-id", type=int, required=True)
    ap.add_argument("--slug", required=True)
    ap.add_argument("--out")
    ap.add_argument("--cache")
    ap.add_argument("--delay", type=float, default=0.5)
    ap.add_argument("--only-cats", default="")
    ap.add_argument("--no-summaries", action="store_true",
                    help="do not write poem/couplet summaries (Ganjoor meanings)")
    a = ap.parse_args()
    INCLUDE_SUMMARIES = not a.no_summaries

    root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    out_path = a.out or os.path.join(root, "AzBar", "Resources", "Content", f"pack-{a.slug}.json")
    cache = a.cache or os.path.join(root, "Tools", ".cache", f"poet-{a.poet_id}")
    only = {int(x) for x in a.only_cats.split(",") if x.strip()}

    poet_raw = cached("poet", a.poet_id, f"{API}/poet/{a.poet_id}", cache, a.delay)
    pr, root_cat = poet_raw["poet"], poet_raw["cat"]
    root_id = pr["rootCatId"]
    poet = {"id": pr["id"], "name": clean(pr.get("nickname")) or clean(pr["name"]),
            "fullName": clean(pr["name"]), "slug": a.slug, "rootCategoryId": root_id}
    if clean(pr.get("description")):
        poet["description"] = clean(pr["description"])
    if pr.get("birthYearInLHijri"):
        poet["birthYearHijri"] = pr["birthYearInLHijri"]
    if pr.get("deathYearInLHijri"):
        poet["deathYearHijri"] = pr["deathYearInLHijri"]

    root_children = root_cat.get("children") or []

    # --only-cats accepts category ids at any depth. Ancestors (minus the root) stay navigable and
    # every other child of the root/ancestors is kept as an {"onlineOnly": true} reference.
    parent_of = {}      # requested id -> real parent id
    parent_chain = {}   # intermediate id -> its parent id
    depth_of = {}
    for rid in sorted(only):
        info = cached("cat", rid, f"{API}/cat/{rid}?poems=true", cache, a.delay)["cat"]
        chain = [x["id"] for x in (info.get("ancestors") or []) if x["id"] != root_id]
        parent_of[rid] = chain[-1] if chain else root_id
        prev = root_id
        for depth, aid in enumerate(chain):
            parent_chain.setdefault(aid, prev)
            depth_of.setdefault(aid, depth)
            prev = aid
    ancestor_ids = sorted((x for x in parent_chain if x not in only), key=lambda x: (depth_of[x], x))
    keep = set(only) | set(ancestor_ids)

    def child_ref(c):
        ref = {"id": c["id"], "title": clean(c["title"])}
        if only and c["id"] not in keep:
            ref["onlineOnly"] = True
        return ref

    def summary_of(ps, cid, count=None):
        s = {"id": ps["id"], "categoryId": cid, "title": clean(ps.get("title")),
             "urlSlug": ps.get("urlSlug") or ""}
        if count is not None:
            s["coupletCount"] = count
        ex = clean(ps.get("excerpt"))
        if ex:
            s["excerpt"] = ex
        return s

    categories = [{"id": root_id, "poetId": a.poet_id, "title": clean(root_cat["title"]),
                   "slug": root_cat.get("urlSlug") or a.slug,
                   "children": [child_ref(c) for c in root_children],
                   "poems": []}]
    poems = []

    # Intermediate categories: navigable shells with poem summaries (no bodies, no coupletCount).
    for aid in ancestor_ids:
        cat = cached("cat", aid, f"{API}/cat/{aid}?poems=true", cache, a.delay)["cat"]
        categories.append({"id": aid, "poetId": a.poet_id, "title": clean(cat["title"]),
                           "slug": cat.get("urlSlug") or "", "parentId": parent_chain.get(aid, root_id),
                           "children": [child_ref(c) for c in (cat.get("children") or [])],
                           "poems": [summary_of(ps, aid) for ps in (cat.get("poems") or [])]})

    # Requested categories (or every root child): full subtree, breadth-first.
    if only:
        queue = [(cid, parent_of[cid]) for cid in sorted(only)]
    else:
        queue = [(c["id"], root_id) for c in root_children]
    seen = set()
    while queue:
        cid, parent = queue.pop(0)
        if cid in seen:
            continue
        seen.add(cid)
        cat = cached("cat", cid, f"{API}/cat/{cid}?poems=true", cache, a.delay)["cat"]
        subs = cat.get("children") or []
        summaries = []
        for ps in cat.get("poems") or []:
            raw = cached("poem", ps["id"], f"{API}/poem/{ps['id']}?{POEM_QUERY}", cache, a.delay)
            poem = build_poem(raw, a.poet_id, cid)
            poems.append(poem)
            summaries.append(summary_of({"id": poem["id"], "title": poem["title"],
                                         "urlSlug": poem["urlSlug"], "excerpt": ps.get("excerpt")},
                                        cid, memorizable_count(poem)))
        categories.append({"id": cid, "poetId": a.poet_id, "title": clean(cat["title"]),
                           "slug": cat.get("urlSlug") or "", "parentId": parent,
                           "children": [{"id": c["id"], "title": clean(c["title"])} for c in subs],
                           "poems": summaries})
        queue.extend((c["id"], cid) for c in subs)

    pack = {"schemaVersion": 1,
            "generatedAt": datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
            "source": "api.ganjoor.net", "poet": poet, "categories": categories, "poems": poems}

    def dump():
        return json.dumps(pack, ensure_ascii=False, separators=(",", ":"))

    text = dump()
    if len(text.encode("utf-8")) > SIZE_LIMIT:
        for p in poems:
            if "recitations" in p:
                p["recitations"] = p["recitations"][:8]
        text = dump()
        print("size guard applied: recitations limited to 8 per poem", file=sys.stderr)
    os.makedirs(os.path.dirname(out_path), exist_ok=True)
    with open(out_path, "w", encoding="utf-8") as f:
        f.write(text)
    size = os.path.getsize(out_path)
    couplets = sum(len(p["couplets"]) for p in poems)
    memo = sum(memorizable_count(p) for p in poems)
    print(f"poems: {len(poems)}\ncouplets: {couplets} (memorizable {memo})\n"
          f"size: {size / 1048576:.2f} MB -> {out_path}")
    hint = {"bundledCategoryIds": sorted(only) or None,
            "birthYearHijri": poet.get("birthYearHijri"), "deathYearHijri": poet.get("deathYearHijri")}
    print("catalog hint: " + json.dumps(hint))


if __name__ == "__main__":
    main()
