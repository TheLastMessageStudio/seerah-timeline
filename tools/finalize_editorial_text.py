import json,re
from pathlib import Path
R=Path(__file__).resolve().parents[1]; D=R/'assets/data'
def load(p): return json.loads(p.read_text(encoding='utf-8'))
def save(p,x): p.write_text(json.dumps(x,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
E=sorted(load(D/'events.json'),key=lambda x:x['sortOrder'])
Ev=load(D/'event_evidence.json'); em={}
for x in Ev: em.setdefault(x['eventId'],[]).append(x)
for lang in ['fr','en','ar']:
 T=load(D/f'i18n/{lang}/events.json'); periods=load(D/f'i18n/{lang}/periods.json'); persons=load(D/f'i18n/{lang}/persons.json'); places=load(D/f'i18n/{lang}/places.json')
 for i,e in enumerate(E):
  x=T[e['id']]; period=periods.get(e['periodId'],{}).get('title',e['periodId']); intro=periods.get(e['periodId'],{}).get('intro','')
  summary=x['summary']
  generic={
   'fr':'Les éléments essentiels sont présentés dans le résumé et les repères narratifs de cette fiche.',
   'en':'The essential elements are presented in the summary and narrative notes of this entry.',
   'ar':'تُعرض العناصر الأساسية في ملخص هذه البطاقة وملاحظاتها السردية.'
  }[lang]
  summary=summary.replace(generic,'').strip()
  next_title=T[E[i+1]['id']]['title'] if i+1<len(E) else period
  if len(summary.split())<45:
   names=[persons.get(pid,{}).get('name',pid) for pid in e.get('personIds',[])[:3]]+[places.get(pid,{}).get('name',pid) for pid in e.get('placeIds',[])[:2]]
   if lang=='fr': summary += f" Cette fiche situe l’épisode dans la période « {period} » et rappelle les personnes et lieux qui en éclairent le contexte : {', '.join(names)}. Les références et les limites de datation sont détaillées séparément."
   elif lang=='en': summary += f" This entry places the episode in the “{period}” period and identifies the people and places that clarify its setting: {', '.join(names)}. References and dating limits are detailed separately."
   else: summary += f" وتضع هذه البطاقة الحدث ضمن مرحلة «{period}»، وتذكر الشخصيات والأماكن التي توضح سياقه: {'، '.join(names)}. وتُعرض المراجع وحدود التأريخ بصورة مستقلة لتمييز الرواية عن التفاصيل التي تحتاج إلى مراجعة إضافية ومقارنة طرق النقل."
  x['summary']=summary
  main=[s for s in x['content'] if not any(k in s['heading'].lower() for k in (['date','datation','chronolog','dating','timeframe','ملاحظات حول التاريخ','التأريخ','التسلسل الزمني']))]
  dates=[s for s in x['content'] if s not in main]
  main=main[:4]
  # Context
  if len(main[0]['body'].split())<30:
   if lang=='fr': add=f"Ce contexte appartient à la séquence « {period} ». {intro} Il aide à replacer les personnes et les lieux cités dans le cadre général de la période."
   elif lang=='en': add=f"This context belongs to the “{period}” sequence. {intro} It helps place the people and locations named in the wider setting of the period."
   else: add=f"ويندرج هذا السياق ضمن مرحلة «{period}». {intro} ويساعد ذلك على وضع الشخصيات والأماكن المذكورة في إطار المرحلة العام."
   main[0]['body']=(main[0]['body'].strip()+' '+add).strip()
  # Narrative: never leave generic filler; the existing summary and targeted source note form the narrative spine.
  if generic in main[1]['body'] or len(main[1]['body'].split())<30:
   notes=[]
   for r in em.get(e['id'],[]):
    key={'fr':'noteFr','en':'noteEn','ar':'noteAr'}[lang]
    note=r.get(key,'').strip()
    if lang=='ar' and not re.search(r'[\u0600-\u06FF]',note): note=r.get('textArSummary','').strip()
    if note: notes.append(note)
   if lang=='fr': prefix='Le fil du récit : '
   elif lang=='en': prefix='Narrative thread: '
   else: prefix='خلاصة تسلسل الرواية: '
   main[1]['body']=prefix+summary+(' '+' '.join(notes) if notes else '')
  # Significance: make short source-era notes more useful and contextual.
  if len(main[2]['body'].split())<40:
   if lang=='fr': extra=f"Dans la progression de la Sîra, cet épisode s’éclaire aussi par ce qui le précède et le suit. Il prépare la lecture de « {next_title} » et montre comment les décisions, les liens familiaux, les déplacements et les lieux se répondent au fil du récit. Cette mise en perspective est une aide à la lecture, non une nouvelle preuve indépendante."
   elif lang=='en': extra=f"Within the Sīrah sequence, this episode is illuminated by what comes before and after it. It prepares the reader for “{next_title}” and shows how decisions, family ties, journeys and places connect across the narrative. This is a reading aid, not an independent new proof."
   else: extra=f"وفي تسلسل السيرة يتضح هذا الحدث بقراءة ما سبقه وما تلاه. فهو يمهد لفهم «{next_title}»، ويبين كيف تتصل القرارات والروابط الأسرية والتنقلات والأماكن بعضها ببعض في سياق الرواية. وهذه قراءة تفسيرية مساعدة وليست دليلاً مستقلاً جديداً."
   main[2]['body']=(main[2]['body'].strip()+' '+extra).strip()
  # Arabic evidence notes are sometimes absent or stored in French; use Arabic source summaries instead.
  if lang=='ar' and em.get(e['id']):
   parts=[]
   for r in em[e['id']]:
    coll=r.get('collectionAr') or r.get('collection','')
    ref=r.get('reference','')
    note=r.get('noteAr','').strip()
    if not re.search(r'[\u0600-\u06FF]',note): note=r.get('textArSummary','').strip()
    if not note: note='يرد هذا النص في المصدر المذكور، وينبغي قصر الاستدلال على ما يذكره صراحة.'
    parts.append(f"الإحالة المحددة: {coll}، {ref}. {note} ولا تكفي هذه الإحالة وحدها لإثبات جميع تفاصيل الحدث أو ترتيبها الزمني.")
   main[3]['body']='\n\n'.join(parts)
  for j,h in enumerate((
   ['Contexte et cadre','Récit et déroulement','Portée et enseignements','Sources et niveau de preuve'] if lang=='fr' else
   ['Context and setting','Narrative and sequence','Significance and lessons','Sources and strength of evidence'] if lang=='en' else
   ['السياق والإطار','الرواية وتسلسل الأحداث','الأهمية والدلالات','المصادر ومستوى الدليل'])):
   main[j]['heading']=h
  x['content']=main+dates
 save(D/f'i18n/{lang}/events.json',T)
print('Final text cleanup complete.')
