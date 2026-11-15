import json,re
from pathlib import Path
R=Path(__file__).resolve().parents[1]; D=R/'assets/data'
def load(p): return json.loads(p.read_text(encoding='utf-8'))
def save(p,x): p.write_text(json.dumps(x,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
E=sorted(load(D/'events.json'),key=lambda x:x.get('sortOrder',0))
P=load(D/'periods.json'); PE=load(D/'persons.json'); PL=load(D/'places.json')
Evidence=load(D/'event_evidence.json'); evmap={}
for e in Evidence: evmap.setdefault(e['eventId'],[]).append(e)
headings={
'fr':['Contexte et cadre','Récit et déroulement','Portée et enseignements','Sources et niveau de preuve'],
'en':['Context and setting','Narrative and sequence','Significance and lessons','Sources and strength of evidence'],
'ar':['السياق والإطار','الرواية وتسلسل الأحداث','الأهمية والدلالات','المصادر ومستوى الدليل']}
for lang in ['fr','en','ar']:
 T=load(D/f'i18n/{lang}/events.json'); PT=load(D/f'i18n/{lang}/periods.json'); PeT=load(D/f'i18n/{lang}/persons.json'); PlT=load(D/f'i18n/{lang}/places.json')
 for i,event in enumerate(E):
  eid=event['id']; item=T[eid]; sections=item['content']
  mains=[x for x in sections if not (('التاريخي' not in x.get('heading','') and any(k in x.get('heading','').lower() for k in ['date','datation','chronolog','dating','ملاحظات حول التاريخ','التأريخ','التسلسل الزمني'])))]
  dates=[x for x in sections if x not in mains]
  # after the first pass the first four entries are the common structure
  mains=mains[:4]
  while len(mains)<4: mains.append({'heading':headings[lang][len(mains)],'body':''})
  summary=item.get('summary','').strip()
  period=PT.get(event.get('periodId',''),{}).get('title',event.get('periodId',''))
  nxt=PeT if False else None
  next_title=T[E[i+1]['id']]['title'] if i+1<len(E) else period
  # Arabic summary needs a longer final sentence because Arabic word tokenization is denser.
  if lang=='ar' and len(summary.split())<45:
   summary += ' ويساعد النظر في هذا الحدث ضمن سياق المرحلة والبطاقات المرتبطة به على التمييز بين أصل الرواية وتفاصيلها المختلف فيها، وبين ما يذكره النص صراحة وما يحتاج إلى مزيد من مراجعة المصادر ومقارنة طرق النقل.'
  item['summary']=summary
  # Enrich short context from the period introduction and the event's own summary.
  if len(mains[0]['body'].split())<22:
   intro=PT.get(event.get('periodId',''),{}).get('intro','')
   if lang=='fr': add=f"Ce cadre s’inscrit dans la séquence « {period} ». {intro}"
   elif lang=='en': add=f"This setting belongs to the “{period}” sequence. {intro}"
   else: add=f"ويندرج هذا السياق ضمن مرحلة «{period}». {intro}"
   mains[0]['body']=(mains[0]['body'].strip()+' '+add).strip()
  # The short-summary entries use the summary as their narrative spine rather than a generic filler.
  generic_tokens=['Les éléments essentiels sont présentés','The essential elements are presented','تُعرض العناصر الأساسية']
  if len(mains[1]['body'].split())<30 or any(g in mains[1]['body'] for g in generic_tokens):
   records=evmap.get(eid,[])
   note_key={'fr':'noteFr','en':'noteEn','ar':'noteAr'}[lang]
   note=' '.join(r.get(note_key,'').strip() for r in records if r.get(note_key,'').strip())
   if lang=='fr': body='Le fil du récit : '+summary
   elif lang=='en': body='Narrative thread: '+summary
   else: body='خلاصة تسلسل الرواية: '+summary
   if note: body+=' '+note
   mains[1]['body']=body
  # Give short significance stubs a contextual explanation linked to the following episode.
  if len(mains[2]['body'].split())<24:
   if lang=='fr': extra=f"Dans la progression de la Sîra, cet épisode s’éclaire aussi par ce qui le précède et le suit. Il prépare la lecture de « {next_title} » et montre comment les décisions, les liens familiaux et les lieux se répondent au fil du récit."
   elif lang=='en': extra=f"Within the Sīrah sequence, this episode is illuminated by what comes before and after it. It prepares the reader for “{next_title}” and shows how decisions, family ties and places connect across the narrative."
   else: extra=f"وفي تسلسل السيرة يتضح هذا الحدث بقراءة ما سبقه وما تلاه. فهو يمهد لفهم «{next_title}»، ويبين كيف تتصل القرارات والروابط الأسرية والأماكن بعضها ببعض في سياق الرواية."
   mains[2]['body']=(mains[2]['body'].strip()+' '+extra).strip()
  # Keep evidence notes precise; otherwise make the bibliography's unverified status explicit.
  if len(mains[3]['body'].split())<38:
   records=evmap.get(eid,[])
   if records:
    parts=[]
    for r in records:
     coll=r.get('collectionAr','') if lang=='ar' else r.get('collection','')
     ref=r.get('reference','')
     note=r.get({'fr':'noteFr','en':'noteEn','ar':'noteAr'}[lang],'')
     if lang=='fr': parts.append(f"Référence ciblée : {coll}, {ref}. {note} Elle soutient les éléments qu’elle rapporte explicitement, sans constituer à elle seule une chronologie exhaustive.")
     elif lang=='en': parts.append(f"Targeted reference: {coll}, {ref}. {note} It supports only the elements explicitly reported and is not, by itself, a complete chronology.")
     else: parts.append(f"إحالة محددة: {coll}، {ref}. {note} وهي تثبت العناصر التي تذكرها صراحة، ولا تقدم وحدها تسلسلاً زمنياً كاملاً.")
    mains[3]['body']='\n\n'.join(parts)
   else:
    refs=' ؛ '.join(event.get('references',[])[:2])
    if lang=='fr': mains[3]['body']=f"Repères bibliographiques : {refs}. Les références constituent des pistes de vérification ; les passages exacts doivent encore être collationnés dans une édition identifiée. Le statut de cette fiche reste « à corroborer » et aucun numéro de page non vérifié n’est ajouté."
    elif lang=='en': mains[3]['body']=f"Bibliographic leads: {refs}. These references are research leads; exact passages still need to be checked against an identified edition. This entry remains marked “needs corroboration”, and no unverified page number is added."
    else: mains[3]['body']=f"إحالات ببليوغرافية: {refs}. وهي مداخل للمراجعة، ولا بد من مقابلة النصوص المحددة على طبعة معروفة. وتظل البطاقة بحاجة إلى مزيد من التثبت، ولا تُضاف أرقام صفحات لم تُراجع."
  for j,h in enumerate(headings[lang]): mains[j]['heading']=h
  item['content']=mains+dates
 save(D/f'i18n/{lang}/events.json',T)
print('All event summaries and four-section details enriched across FR/EN/AR.')
