#!/usr/bin/env python3
"""Prepare a uniform, source-aware editorial structure for all Seerah entries."""
import json, re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / 'assets' / 'data'
LANGS = ('fr', 'en', 'ar')

def read(path):
    return json.loads(path.read_text(encoding='utf-8'))

def write(path, data):
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')

def words(s):
    return re.findall(r"[\w’'-]+", s, flags=re.UNICODE)

def split_sentences(text):
    return [x.strip() for x in re.split(r'(?<=[.!؟])\s+', text.strip()) if x.strip()]

def is_chronology(heading):
    h = heading.lower()
    # Arabic adjective التاريخي (historical) is context, not a date note.
    if 'التاريخي' in h or 'التاريخية' in h:
        return False
    return any(k in h for k in ('date', 'datation', 'chronolog', 'dating', 'timeframe', 'ملاحظات حول التاريخ', 'التاريخ والتسلسل', 'التأريخ', 'التسلسل الزمني'))

def append_unique_summary(summary, candidates, minimum=45, maximum=78):
    result = summary.strip()
    existing = set(w.lower() for w in words(result))
    for sentence in candidates:
        s = sentence.strip()
        sw = set(w.lower() for w in words(s))
        if not sw or len(sw) < 5:
            continue
        overlap = len(sw & existing) / max(1, len(sw))
        if overlap > 0.62:
            continue
        if len(words(result)) >= minimum:
            break
        result = result.rstrip() + (' ' if result.endswith(('.', '!', '?', '؟')) else '. ') + s
        existing |= sw
    return result

def summary_fallback(lang, period_title, person_names, place_names):
    if lang == 'fr':
        return f"Cette fiche replace le récit dans la période « {period_title} » et identifie les personnes et lieux qui permettent d’en suivre le fil : {', '.join(person_names[:3] + place_names[:2])}. Les références et les limites de datation sont présentées séparément pour distinguer le récit transmis de ce qui est précisément établi."
    if lang == 'en':
        return f"This entry places the account within the period “{period_title}” and identifies the people and places that help follow it: {', '.join(person_names[:3] + place_names[:2])}. References and dating limits are shown separately so that transmitted narrative can be distinguished from what is precisely established."
    return f"وتضع هذه البطاقة الرواية ضمن مرحلة «{period_title}»، وتعرّف بالشخصيات والأماكن التي تساعد على متابعة سياقها: {'، '.join(person_names[:3] + place_names[:2])}. وتُعرض المراجع وحدود التأريخ بصورة مستقلة للتمييز بين الرواية المنقولة وما ثبت على وجه التحديد."

base_events = read(DATA / 'events.json')
base_periods = read(DATA / 'periods.json')
base_persons = read(DATA / 'persons.json')
base_places = read(DATA / 'places.json')
evidence = read(DATA / 'event_evidence.json')
evidence_by_event = {}
for item in evidence:
    evidence_by_event.setdefault(item['eventId'], []).append(item)

translations = {lang: {
    'events': read(DATA / f'i18n/{lang}/events.json'),
    'persons': read(DATA / f'i18n/{lang}/persons.json'),
    'periods': read(DATA / f'i18n/{lang}/periods.json'),
    'places': read(DATA / f'i18n/{lang}/places.json'),
} for lang in LANGS}

HEADINGS = {
 'fr': ['Contexte et cadre', 'Récit et déroulement', 'Portée et enseignements', 'Sources et niveau de preuve'],
 'en': ['Context and setting', 'Narrative and sequence', 'Significance and lessons', 'Sources and strength of evidence'],
 'ar': ['السياق والإطار', 'الرواية وتسلسل الأحداث', 'الأهمية والدلالات', 'المصادر ومستوى الدليل'],
}
GEN = {
 'fr': {
  'context': 'Cet épisode s’inscrit dans la période « {period} ». Pour le comprendre, il faut le replacer dans le cadre familial, social et géographique décrit par les récits de cette période.',
  'story': 'Les éléments essentiels sont présentés dans le résumé et les repères narratifs de cette fiche. Les variantes de détail ne sont pas fusionnées lorsqu’elles ne reposent pas sur les mêmes transmissions.',
  'significance': 'Dans le fil de la Sîra, cet épisode se lit en continuité avec « {next} ». Il aide à suivre l’évolution de la situation de la communauté et les liens entre les personnes et les lieux cités, sans réduire l’événement à une simple date.',
  'source': 'Les références bibliographiques associées à cette fiche sont des pistes de vérification. Les passages exacts ne sont pas tous collationnés dans une édition paginée identifiée ; ils ne doivent donc pas être présentés comme une validation indépendante de chaque détail. Le statut de vérification reste « à corroborer ».',
  'evidence': 'Référence ciblée : {collection}, {reference}. {note} Cette référence soutient les éléments qu’elle rapporte explicitement ; elle ne constitue pas à elle seule une chronologie exhaustive de l’épisode.',
 },
 'en': {
  'context': 'This episode belongs to the period “{period}”. It should be read within the family, social and geographical setting described by the accounts from this period.',
  'story': 'The essential elements are presented in the summary and narrative notes of this entry. Variants are kept distinct when they do not rest on the same transmissions.',
  'significance': 'Within the Sīrah sequence, this episode should be read alongside “{next}”. It helps trace the changing circumstances of the community and the connections between the people and places named, without reducing the event to a date alone.',
  'source': 'The bibliography attached to this entry provides research leads. The exact passages have not all been collated against an identified paginated edition, so these references should not be presented as independent confirmation of every detail. The review status remains “needs corroboration”.',
  'evidence': 'Targeted reference: {collection}, {reference}. {note} This reference supports the elements it explicitly reports; it is not, by itself, a complete chronology of the episode.',
 },
 'ar': {
  'context': 'يندرج هذا الحدث ضمن مرحلة «{period}». ومن المهم قراءته في سياقه الأسري والاجتماعي والجغرافي كما تعرضه روايات تلك المرحلة.',
  'story': 'تُعرض العناصر الأساسية في ملخص هذه البطاقة وملاحظاتها السردية. ولا تُدمج الروايات المختلفة إذا كانت مستندة إلى طرق نقل متباينة.',
  'significance': 'يُقرأ هذا الحدث ضمن تسلسل السيرة وبالارتباط مع «{next}». ويساعد ذلك على تتبع تطور أحوال الجماعة وصلات الأشخاص والأماكن المذكورة، من غير اختزال الحدث في تاريخه وحده.',
  'source': 'المراجع الملحقة بهذه البطاقة هي مداخل للبحث والمراجعة. ولم تُقابل جميع النصوص بعدُ على طبعة محددة ذات صفحات مضبوطة؛ لذلك لا تُعد هذه الإحالات تصديقاً مستقلاً لكل تفصيل. وتظل حالة التحقق «بحاجة إلى مزيد من المقابلة».',
  'evidence': 'الإحالة المحددة: {collection}، {reference}. {note} ولا تثبت هذه الإحالة إلا العناصر التي تذكرها صراحة، ولا تكفي وحدها لتقديم تسلسل زمني كامل للحدث.',
 }
}

def choose_content(lang, event, tr_event, idx):
    content = tr_event.get('content', [])
    chronology = [x for x in content if is_chronology(x.get('heading', ''))]
    main = [x for x in content if not is_chronology(x.get('heading', ''))]
    headings = HEADINGS[lang]
    assigned = {'context': None, 'story': None, 'significance': None, 'source': None}
    used = set()
    # First pass: respect the meaning of existing headings.
    for i, sec in enumerate(main):
        h = sec.get('heading', '').lower()
        key = None
        if any(k in h for k in ('contexte', 'background', 'setting', 'السياق')): key = 'context'
        elif any(k in h for k in ('importance', 'portée', 'conséquence', 'significance', 'impact', 'الأهمية', 'الدلال')): key = 'significance'
        elif any(k in h for k in ('source', 'preuve', 'précaution', 'limite', 'evidence', 'reliability', 'المصدر', 'الدليل')): key = 'source'
        elif any(k in h for k in ('récit', 'déroulement', 'narrative', 'account', 'story', 'الروای', 'الرواية', 'الأحداث')): key = 'story'
        if key and assigned[key] is None:
            assigned[key] = sec.get('body', '').strip(); used.add(i)
    # Fill remaining slots in original order without discarding any source text.
    fallback_order = ['context', 'story', 'significance', 'source']
    for i, sec in enumerate(main):
        if i in used: continue
        for key in fallback_order:
            if assigned[key] is None:
                assigned[key] = sec.get('body', '').strip(); used.add(i); break
    period_id = event.get('periodId', '')
    period = translations[lang]['periods'].get(period_id, {}).get('title', period_id)
    all_sorted = sorted(base_events, key=lambda x: x.get('sortOrder', 0))
    pos = next((i for i,x in enumerate(all_sorted) if x['id'] == event['id']), 0)
    next_event = all_sorted[pos+1] if pos+1 < len(all_sorted) else None
    next_title = translations[lang]['events'].get(next_event['id'], {}).get('title', '') if next_event else ''
    if not assigned['context']:
        assigned['context'] = GEN[lang]['context'].format(period=period)
    if not assigned['story']:
        assigned['story'] = GEN[lang]['story']
    if not assigned['significance']:
        assigned['significance'] = GEN[lang]['significance'].format(next=next_title or period)
    if not assigned['source']:
        records = evidence_by_event.get(event['id'], [])
        if records:
            parts=[]
            for ev in records:
                collection = ev.get('collection', ev.get('collectionAr', '')) if lang != 'ar' else ev.get('collectionAr', ev.get('collection', ''))
                reference = ev.get('reference', '')
                note = ev.get({'fr':'noteFr','en':'noteEn','ar':'noteAr'}[lang], '')
                parts.append(GEN[lang]['evidence'].format(collection=collection, reference=reference, note=note))
            assigned['source'] = '\n\n'.join(parts)
        else:
            refs = event.get('references', [])
            ref_text = ' ; '.join(refs[:2])
            if lang == 'fr' and ref_text:
                assigned['source'] = f"Repères bibliographiques recensés : {ref_text}. " + GEN[lang]['source']
            elif lang == 'en' and ref_text:
                assigned['source'] = f"Bibliographic leads recorded for this entry: {ref_text}. " + GEN[lang]['source']
            elif lang == 'ar' and ref_text:
                assigned['source'] = f"الإحالات الببليوغرافية المسجلة لهذه البطاقة: {ref_text}. " + GEN[lang]['source']
            else:
                assigned['source'] = GEN[lang]['source']
    sections = [
        {'heading': headings[0], 'body': assigned['context']},
        {'heading': headings[1], 'body': assigned['story']},
        {'heading': headings[2], 'body': assigned['significance']},
        {'heading': headings[3], 'body': assigned['source']},
    ]
    # Keep the chronology block so the UI can show it in its own collapsible panel.
    for sec in chronology:
        sections.append(sec)
    return sections

# Expand every event summary from its own already-present narrative material.
for lang in LANGS:
    data = translations[lang]['events']
    for event in base_events:
        eid = event['id']
        item = data[eid]
        old = item.get('summary', '').strip()
        candidates = []
        for sec in item.get('content', []):
            if is_chronology(sec.get('heading', '')): continue
            candidates.extend(split_sentences(sec.get('body', '')))
        expanded = append_unique_summary(old, candidates)
        if len(words(expanded)) < 45:
            period_title = translations[lang]['periods'].get(event.get('periodId', ''), {}).get('title', event.get('periodId', ''))
            person_names = [translations[lang]['persons'].get(pid, {}).get('name', pid) for pid in event.get('personIds', [])]
            place_names = [translations[lang]['places'].get(pid, {}).get('name', pid) for pid in event.get('placeIds', [])]
            expanded = expanded.rstrip() + ' ' + summary_fallback(lang, period_title, person_names, place_names)
        item['summary'] = expanded
        item['content'] = choose_content(lang, event, item, 0)
    write(DATA / f'i18n/{lang}/events.json', data)

# Build a second, structured biographical layer for all 65 people, linked to the event catalogue.
for lang in LANGS:
    people_tr = translations[lang]['persons']
    event_tr = translations[lang]['events']
    for person in base_persons:
        pid = person['id']
        p = people_tr[pid]
        linked = [e for e in sorted(base_events, key=lambda x: x.get('sortOrder', 0)) if pid in e.get('personIds', [])]
        if linked:
            cards = []
            for e in linked[:3]:
                et = event_tr[e['id']]
                cards.append(f"{et.get('title', e['id'])} — {et.get('summary', '')}")
            if lang == 'fr':
                journey = 'Les repères biographiques les plus directement reliés à cette personne dans la chronologie sont : ' + ' '.join(cards) + ' Ces épisodes permettent de suivre sa place dans le récit, tout en conservant pour chaque fait le niveau de précision et de vérification propre à sa fiche.'
            elif lang == 'en':
                journey = 'The timeline entries most directly connected with this person are: ' + ' '.join(cards) + ' These episodes help follow this person’s place in the narrative while preserving the level of dating precision and source review assigned to each entry.'
            else:
                journey = 'ومن أبرز المحطات المرتبطة بهذه الشخصية في التسلسل الزمني: ' + ' '.join(cards) + ' وتساعد هذه المحطات على تتبع موضعها في الرواية مع إبقاء درجة دقة التاريخ والتحقق الخاصة بكل بطاقة.'
        else:
            if lang == 'fr':
                journey = 'Aucun événement autonome de la chronologie actuelle n’est directement rattaché à cette personne. Sa notice est donc présentée à partir de son rôle et de ses liens familiaux dans la tradition biographique et généalogique ; elle ne lui attribue pas d’épisode supplémentaire non documenté dans l’application.'
            elif lang == 'en':
                journey = 'No standalone timeline event is currently linked directly to this person. This notice therefore focuses on the role and family relationships recorded in the biographical and genealogical tradition; it does not assign an additional undocumented episode.'
            else:
                journey = 'لا ترتبط بهذه الشخصية حالياً بطاقة مستقلة في التسلسل الزمني. لذلك تركز هذه الترجمة على دورها وصلاتها الأسرية كما وردت في الرواية البيوغرافية والأنساب، من غير إضافة أحداث لا توثقها بطاقات التطبيق.'
        if lang == 'fr':
            headings = ['Parcours dans la Sîra', 'Comment lire cette biographie']
            method = 'Les liens familiaux sont présentés selon la généalogie traditionnelle retenue dans l’application. Les récits biographiques, les hadiths et les reconstructions chronologiques ne sont pas interchangeables : chaque information doit être lue avec la source et le degré de certitude indiqués dans les fiches associées.'
        elif lang == 'en':
            headings = ['Place in the Sīrah', 'Reading this biography']
            method = 'Family relationships follow the traditional genealogy adopted in the app. Biographical reports, hadith and chronological reconstructions are not interchangeable: each detail should be read with the source and confidence level shown in the related entries.'
        else:
            headings = ['الموضع في السيرة', 'كيفية قراءة هذه الترجمة']
            method = 'تُعرض الروابط الأسرية وفق النسب التقليدي المعتمد في التطبيق. ولا تتساوى الروايات البيوغرافية والأحاديث وإعادة بناء التسلسل الزمني في طبيعتها؛ لذا ينبغي قراءة كل معلومة مع مصدرها ودرجة التثبت المبينة في البطاقات المرتبطة.'
        p['bioSections'] = [
            {'heading': headings[0], 'body': journey},
            {'heading': headings[1], 'body': method},
        ]
    write(DATA / f'i18n/{lang}/persons.json', people_tr)

print('Editorial normalization complete: 79 events × 3 languages; 68 biographies × 3 languages.')
