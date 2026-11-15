import json,re
from pathlib import Path
R=Path(__file__).resolve().parents[1];D=R/'assets/data'
def load(p):return json.loads(p.read_text(encoding='utf-8'))
def save(p,x):p.write_text(json.dumps(x,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
E=load(D/'events.json'); evidence=load(D/'event_evidence.json'); by={}
for x in evidence:by.setdefault(x['eventId'],[]).append(x)
for lang in ['fr','en','ar']:
 path=D/f'i18n/{lang}/events.json'; tr=load(path)
 for e in E:
  x=tr[e['id']]; records=by.get(e['id'],[])
  if records:
   parts=[]
   for r in records:
    if lang=='fr':
     coll=r.get('collection',''); ref=r.get('reference',''); note=r.get('noteFr','')
     parts.append(f"Référence ciblée : {coll}, {ref}. {note} Cette référence soutient les éléments qu’elle rapporte explicitement ; elle ne constitue pas à elle seule une chronologie exhaustive de l’épisode.")
    elif lang=='en':
     coll=r.get('collection',''); ref=r.get('reference',''); note=r.get('noteEn','')
     parts.append(f"Targeted reference: {coll}, {ref}. {note} This reference supports only the elements it explicitly reports; it is not, by itself, a complete chronology of the episode.")
    else:
     coll=r.get('collectionAr') or r.get('collection','')
     ref=r.get('reference','').split('·')[0].strip()
     note=r.get('noteAr','').strip()
     if not re.search(r'[\u0600-\u06FF]',note): note=r.get('textArSummary','').strip()
     if not note: note='يرد هذا النص في المصدر المذكور، وينبغي قصر الاستدلال على ما يذكره صراحة.'
     parts.append(f"الإحالة المحددة: {coll}، {ref}. {note} ولا تكفي هذه الإحالة وحدها لإثبات جميع تفاصيل الحدث أو ترتيبها الزمني.")
   body='\n\n'.join(parts)
  else:
   if lang=='fr': body='Les références bibliographiques détaillées figurent dans le panneau « Sources et références ». Elles constituent des pistes de vérification ; les passages exacts doivent être collationnés dans une édition identifiée avant de leur attribuer une pagination ou de confirmer chaque détail. Une référence générale ne valide pas automatiquement l’ensemble du récit.'
   elif lang=='en': body='The detailed bibliography is listed in the “Bibliography and references” panel. These entries are research leads; exact passages should be checked against an identified edition before assigning page numbers or confirming individual details. A general reference does not automatically validate the whole account.'
   else: body='تظهر المراجع التفصيلية في لوحة «المراجع والمصادر». وهي مداخل للبحث والمراجعة؛ وينبغي مقابلة المواضع على طبعة محددة قبل اعتماد أرقام الصفحات أو تأكيد كل تفصيل. فالإحالة العامة لا تثبت تلقائياً جميع عناصر الرواية.'
  x['content'][3]['body']=body
  for sec in x['content']:
   sec['body']=re.sub(r'\.\s*\.', '.', sec['body'])
 save(path,tr)
print('Localized evidence sections and standardized bibliography notes.')
