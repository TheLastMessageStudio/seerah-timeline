#!/usr/bin/env python3
"""Download and normalize Arabic hadith/Qur'an corpora into Flutter assets.

Hadith source: Jaguar16/open-hadith-data (CC0 structured data; Arabic text).
Qur'an source: quran-json.risanb.com Uthmani text profile (Tanzil text, CC BY 3.0).
English hadith translations are deliberately omitted: the upstream README says
those are sourced from Sunnah.com and subject to separate redistribution terms.
"""
from __future__ import annotations
import argparse, json, re, sys, urllib.request, zipfile, io
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ASSETS = ROOT / 'assets' / 'data'
API = 'https://api.github.com/repos/Jaguar16/open-hadith-data/releases/latest'
ALIASES = {
 'bukhari': ['bukhari', 'sahih_al_bukhari', 'sahih-bukhari'],
 'muslim': ['muslim', 'sahih_muslim', 'sahih-muslim'],
 'abu_dawud': ['abu_dawud', 'abudawud', 'abu_daud', 'sunan_abi_dawud'],
 'tirmidhi': ['tirmidhi', 'at_tirmidhi', 'jami_at_tirmidhi'],
 'nasai': ['nasai', 'an_nasai', 'sunan_an_nasai'],
 'ibn_majah': ['ibn_majah', 'ibnemajah', 'ibnmajah'],
 'malik': ['malik', 'muwatta'],
 'ahmad': ['ahmad', 'musnad_ahmad'],
 'darimi': ['darimi', 'ad_darimi'],
 'adab_al_mufrad': ['adab_al_mufrad', 'adabalmufrad'],
 'riyad_as_salihin': ['riyad_as_salihin', 'riyadassalihin'],
 'bulugh_al_maram': ['bulugh_al_maram', 'bulughalmaram'],
 'shamail': ['shamail', 'shama_il'],
 'mishkat': ['mishkat', 'mishkat_al_masabih'],
 'nawawi40': ['nawawi40', 'forty_hadith_an_nawawi'],
 'hadith_qudsi40': ['hadith_qudsi40', 'forty_hadith_qudsi'],
 'shah_waliullah40': ['shah_waliullah40', 'forty_hadith_shah_waliullah'],
}
META = {
 'bukhari': ('Sahih al-Bukhari','صحيح البخاري'), 'muslim': ('Sahih Muslim','صحيح مسلم'),
 'abu_dawud': ('Sunan Abi Dawud','سنن أبي داود'), 'tirmidhi': ('Jami at-Tirmidhi','جامع الترمذي'),
 'nasai': ("Sunan an-Nasa’i",'سنن النسائي'), 'ibn_majah': ('Sunan Ibn Majah','سنن ابن ماجه'),
 'malik': ('Muwatta Malik','موطأ مالك'), 'ahmad': ('Musnad Ahmad','مسند أحمد'),
 'darimi': ('Sunan al-Darimi','سنن الدارمي'), 'adab_al_mufrad': ('Al-Adab al-Mufrad','الأدب المفرد'),
 'riyad_as_salihin': ('Riyad as-Salihin','رياض الصالحين'), 'bulugh_al_maram': ('Bulugh al-Maram','بلوغ المرام'),
 'shamail': ('Ash-Shama’il al-Muhammadiyah','الشمائل المحمدية'), 'mishkat': ('Mishkat al-Masabih','مشكاة المصابيح'),
 'nawawi40': ('Forty Hadith of al-Nawawi','الأربعون النووية'), 'hadith_qudsi40': ('Forty Hadith Qudsi','الأربعون القدسية'),
 'shah_waliullah40': ('Forty Hadith of Shah Waliullah','أربعون شاه ولي الله')}

def get(url):
    req=urllib.request.Request(url, headers={'User-Agent':'SeerahTimeline-CorpusImporter/1.0','Accept':'application/vnd.github+json'})
    with urllib.request.urlopen(req, timeout=90) as r: return r.read()

def norm(s): return re.sub(r'[^a-z0-9]+','_',s.lower()).strip('_')

def collect_records(obj, chapter=''):
    out=[]
    def walk(x, ch=''):
        if isinstance(x, list):
            for y in x: walk(y,ch)
        elif isinstance(x, dict):
            here = str(x.get('name_ar') or x.get('chapter_ar') or x.get('chapter_title_ar') or x.get('name') or x.get('chapter') or ch)
            ar = x.get('text_ar') or x.get('arabic') or x.get('arabic_text') or x.get('textArabic')
            if isinstance(ar,str) and ar.strip():
                out.append({
                  'number': x.get('hadith_number') or x.get('number') or x.get('id') or len(out)+1,
                  'chapterAr': here,
                  'textAr': ar.strip(),
                  'matnAr': (x.get('matn_ar') or x.get('matn') or '').strip() if isinstance(x.get('matn_ar') or x.get('matn') or '',str) else '',
                  'isnadAr': (x.get('isnad_ar') or '').strip() if isinstance(x.get('isnad_ar') or '',str) else '',
                  'gradeAr': x.get('grade_ar') or '',
                  'reference': x.get('reference') or '',
                })
            for k,v in x.items():
                if isinstance(v,(dict,list)) and k not in ('translations','english','text_en'):
                    walk(v, here if ('chapter' in k.lower() or 'book' in k.lower() or k.lower() == 'hadiths') else ch)
    walk(obj, chapter)
    seen=set(); result=[]
    for r in out:
        key=(str(r['number']),r['textAr'])
        if key not in seen: seen.add(key); result.append(r)
    return result

def import_hadith():
    print('Récupération des métadonnées GitHub…')
    release=json.loads(get(API))
    assets=release.get('assets',[])
    asset=next((a for a in assets if 'collections-json' in a['name'].lower() and a['name'].lower().endswith('.zip')),None)
    if not asset:
        # v1.0.0 is the initial complete multi-collection release; v1.1.0
        # may expose only incremental assets depending on its release packaging.
        release=json.loads(get('https://api.github.com/repos/Jaguar16/open-hadith-data/releases/tags/v1.0.0'))
        assets=release.get('assets',[])
        asset=next((a for a in assets if 'collections-json' in a['name'].lower() and a['name'].lower().endswith('.zip')),None)
    if not asset:
        raise RuntimeError('Aucune release ne contient collections-json.zip. Aucune donnée n’a été remplacée.')
    print('Téléchargement',asset['name'], 'depuis', release.get('tag_name'))
    archive=zipfile.ZipFile(io.BytesIO(get(asset['browser_download_url'])))
    json_files=[n for n in archive.namelist() if n.lower().endswith('.json')]
    written=[]
    staged={}
    for cid, aliases in ALIASES.items():
        matches=[n for n in json_files if any(a in norm(n) for a in aliases)]
        if not matches: continue
        # Prefer a consolidated by-book file; otherwise merge every chapter file.
        consolidated=[n for n in matches if 'by_book' in n.lower() or norm(Path(n).stem) in aliases]
        selected=consolidated[:1] if consolidated else sorted(matches)
        records=[]
        for match in selected:
            obj=json.loads(archive.read(match).decode('utf-8-sig'))
            records.extend(collect_records(obj, Path(match).parent.name))
        if not records: continue
        # Dataset source counts may include variants; preserve every distinct text.
        staged[cid]={'collectionId':cid,'title':META[cid][0],'titleAr':META[cid][1],
          'source':'Jaguar16/open-hadith-data','sourceVersion':release.get('tag_name'),
          'license':'CC0 1.0 (structured data and Arabic corpus; English translations excluded)',
          'note':'Automatically extracted dataset; verify against authenticated printed editions. Musnad Ahmad has known missing chapters 8–30 in the upstream source.',
          'hadiths':records}
        written.append((cid,len(records)))
    counts=dict(written)
    required={'bukhari','muslim'}
    if not required.issubset(counts):
        raise RuntimeError('Bukhari et Muslim n’ont pas tous deux été trouvés. Aucun fichier final n’a été écrit. Collections trouvées: '+str(written))
    if counts['bukhari'] < 6000 or counts['muslim'] < 2500:
        raise RuntimeError(f"Corpus incomplets (Bukhari={counts['bukhari']}, Muslim={counts['muslim']}). Aucun fichier final n’a été écrit.")
    target_dir=ASSETS/'hadith'; target_dir.mkdir(parents=True,exist_ok=True)
    for cid,obj in staged.items():
        (target_dir/f'{cid}.json').write_text(json.dumps(obj,ensure_ascii=False,indent=2),encoding='utf-8')
    print('Collections importées:',', '.join(f'{k} ({n})' for k,n in written))

def import_quran():
    verses=[]
    for surah in range(1,115):
        url=f'https://quran-json.risanb.com/text/uthmani/chapters/{surah}.json'
        obj=json.loads(get(url).decode('utf-8'))
        name=obj.get('name') or obj.get('name_ar') or obj.get('nameArabic') or ''
        for v in obj.get('verses',[]):
            verses.append({'surah':surah,'surahNameAr':name,'ayah':int(v.get('id')),'textAr':v.get('text','')})
        print(f'Coran: sourate {surah}/114')
    if len(verses) != 6236 or any(not v['textAr'] for v in verses):
        raise RuntimeError(f'Contrôle du Coran échoué: {len(verses)} versets; fichier non écrit.')
    target=ASSETS/'quran_ar.json'
    target.write_text(json.dumps({'source':'quran-json.risanb.com / Tanzil','license':'CC BY 3.0; Arabic text reproduced verbatim','reading':'Hafs/Uthmani','verses':verses},ensure_ascii=False,separators=(',',':')),encoding='utf-8')
    print('Coran arabe importé:',len(verses),'versets.')

if __name__=='__main__':
    ap=argparse.ArgumentParser()
    ap.add_argument('--hadith-only',action='store_true'); ap.add_argument('--quran-only',action='store_true')
    args=ap.parse_args()
    try:
        if not args.quran_only: import_hadith()
        if not args.hadith_only: import_quran()
    except Exception as exc:
        print('ERREUR:',exc,file=sys.stderr); sys.exit(1)
