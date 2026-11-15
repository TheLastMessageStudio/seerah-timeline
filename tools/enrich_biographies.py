import json
from pathlib import Path
R=Path(__file__).resolve().parents[1]; D=R/'assets/data'
def load(p): return json.loads(p.read_text(encoding='utf-8'))
def save(p,x): p.write_text(json.dumps(x,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
P=load(D/'persons.json'); E=sorted(load(D/'events.json'),key=lambda x:x['sortOrder'])
parent={}; spouse={}; mother={}
def child(a,b): parent[b]=a
chain=['adnan','maadd','nizar','mudar','ilyas','mudrika','khuzayma','kinana','al_nadr','malik_ancestor','fihr','ghalib','luayy','kab','murrah','kilab','qusayy','abd_manaf','hashim','abd_al_muttalib','abdullah','muhammad']
for a,b in zip(chain,chain[1:]): child(a,b)
for c in ['abu_talib','hamzah','al_abbas','abu_lahab','al_harith','safiyyah_bint_abd_al_muttalib']: child('abd_al_muttalib',c)
for c in ['ali','jafar']: child('abu_talib',c)
for c in ['qasim','zaynab_bint_muhammad','ruqayyah','umm_kulthum','abdullah_ibn_muhammad','fatimah_bint_muhammad','ibrahim']: child('muhammad',c)
child('zaynab_bint_muhammad','umama')
for c in ['hasan','husayn']: child('fatimah_bint_muhammad',c)
for a,b in [('abdullah','aminah'),('muhammad','khadijah'),('muhammad','sawda'),('muhammad','aisha'),('muhammad','hafsa'),('muhammad','umm_salama'),('muhammad','zaynab_bint_jahsh'),('muhammad','juwayriya'),('muhammad','safiyya_bint_huyayy'),('muhammad','umm_habiba'),('muhammad','maymuna'),('abu_talib','fatimah_bint_asad'),('zaynab_bint_muhammad','abu_al_as'),('ruqayyah','uthman'),('umm_kulthum','uthman'),('fatimah_bint_muhammad','ali')]:
 spouse.setdefault(a,[]).append(b); spouse.setdefault(b,[]).append(a)
for c,m in [('muhammad','aminah'),('ali','fatimah_bint_asad'),('jafar','fatimah_bint_asad'),('qasim','khadijah'),('zaynab_bint_muhammad','khadijah'),('ruqayyah','khadijah'),('umm_kulthum','khadijah'),('abdullah_ibn_muhammad','khadijah'),('fatimah_bint_muhammad','khadijah'),('ibrahim','mariya_al_qibtiyya'),('umama','zaynab_bint_muhammad'),('hasan','fatimah_bint_muhammad'),('husayn','fatimah_bint_muhammad')]: mother[c]=m
relations={p['id']:[] for p in P}
def add(a,b,k):
 if a in relations and b in relations and a!=b and (b,k) not in relations[a]: relations[a].append((b,k))
for c,f in parent.items(): add(c,f,'parent'); add(f,c,'child')
for a,bs in spouse.items():
 for b in bs: add(a,b,'spouse')
for c,m in mother.items(): add(c,m,'parent'); add(m,c,'child')
people_by_lang={l:load(D/f'i18n/{l}/persons.json') for l in ['fr','en','ar']}
events_by_lang={l:load(D/f'i18n/{l}/events.json') for l in ['fr','en','ar']}
for lang in ['fr','en','ar']:
 tr=people_by_lang[lang]; evtr=events_by_lang[lang]
 for person in P:
  pid=person['id']; item=tr[pid]
  linked=[e for e in E if pid in e.get('personIds',[])]
  if linked:
   cards=[]
   for e in linked[:3]:
    x=evtr[e['id']]
    cards.append(f"{x.get('title',e['id'])} — {x.get('summary','')}")
   if lang=='fr': journey='Les épisodes directement reliés à cette personne dans la chronologie sont : '+' '.join(cards)+' Ces repères permettent de suivre son rôle dans plusieurs moments de la Sîra, tout en conservant les réserves propres à chaque récit.'
   elif lang=='en': journey='The timeline episodes directly connected with this person are: '+' '.join(cards)+' These references help trace this person’s role across the Sīrah while preserving the qualifications attached to each report.'
   else: journey='ومن الأحداث المرتبطة بهذه الشخصية في التسلسل الزمني: '+' '.join(cards)+' وتساعد هذه المحطات على تتبع دورها في مراحل السيرة مع إبقاء التحفظات الخاصة بكل رواية.'
  else:
   if lang=='fr': journey='Aucun événement autonome de la chronologie actuelle ne lui est directement rattaché. Sa notice est donc complétée par les liens familiaux et généalogiques présentés ci-dessous, sans lui attribuer un épisode supplémentaire qui ne figure pas dans les sources recensées par l’application.'
   elif lang=='en': journey='No standalone event in the current timeline is directly linked to this person. The biography is therefore supplemented by the family and genealogical relationships below, without assigning an additional episode not present in the app’s source record.'
   else: journey='لا ترتبط بهذه الشخصية بطاقة مستقلة في التسلسل الزمني الحالي. لذلك تُستكمل ترجمتها بالروابط الأسرية والنسبية أدناه، من غير أن تُنسب إليها أحداث إضافية لا تظهر في سجل المصادر المعتمد في التطبيق.'
  rels=relations.get(pid,[])
  def nm(rid): return tr.get(rid,{}).get('name',rid)
  chunks=[]
  for rid,kind in rels[:6]:
   if lang=='fr': label={'parent':'parent ou ascendant','child':'enfant ou descendant','spouse':'conjoint(e)'}[kind]
   elif lang=='en': label={'parent':'parent or ancestor','child':'child or descendant','spouse':'spouse'}[kind]
   else: label={'parent':'والد أو سلف','child':'ابن أو من نسلها','spouse':'زوج أو زوجة'}[kind]
   chunks.append(f"{label} : {nm(rid)}")
  if chunks:
   if lang=='fr': family='Dans le schéma généalogique retenu pour cette application, les liens affichés sont : '+' ; '.join(chunks)+'. Ces liens sont également cliquables dans l’arbre et ouvrent les notices correspondantes.'
   elif lang=='en': family='In the genealogical structure adopted by this app, the displayed connections are: '+'; '.join(chunks)+'. These links are also clickable in the family tree and open the corresponding biographies.'
   else: family='وفي مخطط النسب المعتمد في التطبيق، تظهر الروابط الآتية: '+'؛ '.join(chunks)+'. ويمكن الضغط على هذه الروابط في شجرة العائلة لفتح التراجم المقابلة.'
  else:
   if lang=='fr': family='Aucun lien familial direct n’est représenté dans l’arbre actuel. La notice conserve donc les informations biographiques et les épisodes de la chronologie sans inventer une filiation.'
   elif lang=='en': family='No direct family connection is represented in the current tree. The biography therefore retains its biographical information and timeline links without inventing a lineage.'
   else: family='لا يظهر في شجرة العائلة الحالية رابط أسري مباشر لهذه الشخصية؛ لذلك تقتصر الترجمة على المعلومات البيوغرافية والأحداث المرتبطة بها من غير اختلاق نسب.'
  if lang=='fr':
   headings=['Parcours dans la Sîra','Liens familiaux et généalogiques','Précautions de lecture']
   method='Les récits biographiques, les hadiths et les reconstructions généalogiques n’ont pas tous le même statut. Les filiations suivent la présentation traditionnelle retenue par l’application ; les chaînes antérieures à Adnân ne sont pas présentées comme certaines. Pour les épisodes, les dates et les détails doivent être lus avec les références et les notes de chaque fiche.'
  elif lang=='en':
   headings=['Place in the Sīrah','Family and genealogical connections','Reading notes']
   method='Biographical reports, hadith and genealogical reconstructions do not all have the same status. Lineage follows the traditional presentation adopted by the app; chains before ʿAdnān are not presented as certain. For events, dates and details should be read alongside the references and notes in each entry.'
  else:
   headings=['الموضع في السيرة','الروابط الأسرية والنسبية','تنبيهات القراءة']
   method='لا تتساوى الروايات البيوغرافية والأحاديث وإعادة بناء الأنساب في درجتها وطبيعتها. ويتبع النسب العرض التقليدي المعتمد في التطبيق، ولا تُعرض السلاسل السابقة لعدنان على أنها يقينية. وينبغي قراءة تواريخ الأحداث وتفاصيلها مع المراجع والملاحظات الخاصة بكل بطاقة.'
  item['bioSections']=[{'heading':headings[0],'body':journey},{'heading':headings[1],'body':family},{'heading':headings[2],'body':method}]
 save(D/f'i18n/{lang}/persons.json',tr)
print('Biographies enriched and linked to family relations for all 68 people.')
